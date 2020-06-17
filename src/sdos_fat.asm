;;;
;;; FAT file system core routines
;;;

.include "sdos_bios.asm"
.include "sdos_dir.asm"

.dpage SDOS_VARIABLES
.databank `DOS_HIGH_VARIABLES

;;
;; Record structures
;;

; A record to name devices
DEVICE_DESC     .struct name, number, next
DEVNAME         .dword \name            ; A pointer to the ASCIIZ name of the device
DEVNUMBER       .byte \number           ; The BIOS_DEV number for the device
NEXT            .dword \next            ; A pointer to the next device descriptor
                .ends

; Directory entry
DIRENTRY                .struct
SHORTNAME               .fill 11        ; $00 - The short name of the file (8 name, 3 extension)
ATTRIBUTE               .byte ?         ; $0B - The attribute bits
IGNORED1                .word ?         ; $0C - Unused (by us) bytes
CREATE_TIME             .word ?         ; $0E - Creation time
CREATE_DATE             .word ?         ; $10 - Creation date
ACCESS_DATE             .word ?         ; $12 - Last access date
CLUSTER_H               .word ?         ; $14 - High word of the first cluster #
MODIFIED_TIME           .word ?         ; $16 - Last modified time
MODIFIED_DATE           .word ?         ; $18 - Last modified date
CLUSTER_L               .word ?         ; $1A - Low word of the first cluster #
SIZE                    .dword ?        ; $1C - The size of the file (in bytes)
                        .ends

; Directory entry attribute flags

DOS_ATTR_RO = $01                       ; File is read-only
DOS_ATTR_HIDDEN = $02                   ; File is hidden
DOS_ATTR_SYSTEM = $04                   ; File is a system file
DOS_ATTR_VOLUME = $08                   ; Entry is the volume label
DOS_ATTR_DIR = $10                      ; Entry is a directory
DOS_ATTR_ARCH = $20                     ; Entry has changed since last backup
DOS_ATTR_LONGNAME = $0F                 ; Entry is the long file name

; File Descriptor -- Used as parameter for higher level DOS functions
FILEDESC            .struct
STATUS              .byte ?             ; The status flags of the file descriptor (open, closed, error, EOF, etc.)
DEV                 .byte ?             ; The ID of the device holding the file
PATH                .dword ?            ; Pointer to a NULL terminated path string
CLUSTER             .dword ?            ; The current cluster of the file.
FIRST_CLUSTER       .dword ?            ; The ID of the first cluster in the file
BUFFER              .dword ?            ; Pointer to a cluster-sized buffer
SIZE                .dword ?            ; The size of the file
CREATE_DATE         .word ?             ; The creation date of the file
CREATE_TIME         .word ?             ; The creation time of the file
MODIFIED_DATE       .word ?             ; The modification date of the file
MODIFIED_TIME       .word ?             ; The modification time of the file
                    .ends

; File descriptor status flags

FD_STAT_READ = $01                      ; The file is readable
FD_STAT_WRITE = $02                     ; The file is writable
FD_STAT_OPEN = $40                      ; The file is open
FD_STAT_ERROR = $60                     ; The file is in an error condition
FD_STAT_EOF = $80                       ; The file cursor is at the end of the file

;;
;; Constants
;;

FAT_LAST_CLUSTER = $0FFFFFFF            ; Code to mark the last cluster of a file
VOLUMEMAX = 1                           ; The maximum number of mounted volumes we support
DOS_DIR_ENTRY_SIZE = 32                 ; The size of a directory entry
DOS_SECTOR_SIZE = 512                   ; The size of a sector
DOS_DIR_ENT_UNUSED = $E5                ; Marker for an unused directory entry 

PART_TYPE_FAT12 = $00                   ; "Partition" type: FAT12, used for floppy disks
PART_TYPE_FAT32_LBA = $0C               ; Patition type: FAT32 with LBA addressing 
BPB_EXTENDED_RECORD = $29               ; If SIGNATUREB of the BPB has this byte, the volume label is valid

DOS_DIR_TYPE_FAT12ROOT = 0              ; Directory is a FAT12 root directory
DOS_DIR_TYPE_FILE = 1                   ; Directory is a file type directory

; Error Codes

DOS_ERR_READ = 1                        ; We could not read a sector, check BIOS_STATUS for details
DOS_ERR_NOTMBR = 2                      ; We could not find the MBR
DOS_ERR_NOFAT32 = 3                     ; We could not find a FAT32 parition using LBA
DOS_ERR_NOINIT = 4                      ; We could not INIT the block device
DOS_ERR_VOLID = 5                       ; Volume ID sector could not be loaded
DOS_ERR_FAT = 6                         ; Can't scan the FAT for some reason
DOS_ERR_BADPATH = 7                     ; The path was badly formatted
DOS_ERR_NODIR = 8                       ; Could not read the directory
DOS_ERR_NOTFOUND = 9                    ; File/directory requested was not found
DOS_ERR_NOCLUSTER = 10                  ; There are no more clusters
DOS_ERR_FILEEXISTS = 11                 ; There is already a file of that name
DOS_ERR_NOTOPEN = 12                    ; File has not been open
DOS_ERR_NOTREAD = 13                    ; File is not open for reading
DOS_ERR_NOTWRITE = 14                   ; File is not open for writing
DOS_ERR_OPEN = 15                       ; File is already open
DOS_ERR_PGXSIG = 16                     ; File does not have the PGX signature
DOS_ERR_NOEXEC = 17                     ; File does is not an executable format
DOS_ERR_MEDIAFULL = 18                  ; There are no more free clusters on the drive
DOS_ERR_WRITEPROT = 19                  ; The medium is write-protected
DOS_ERR_FATUPDATE = 20                  ; Can't update the FAT
DOS_ERR_DIRFULL = 21                    ; The directory is full

; MBR Field Offsets

PART0_OFF = 446                         ; Offset to the first partition in the MBR
PART_TYPE_OFF = 4                       ; Offset to the partition's type
PART_LBA_OFF = 8                        ; Offset to the LBA of the first sector of the partition
PART_SECT_COUNT_OFF = 13                ; Offset to the sector count of the partition
MBR_SIGNATURE = 510                     ; The offset to the MBR signature bytes

; BPB Field Offsets

BPB_BYTEPERSEC_OFF = 11                 ; Offset in the BPB sector to the Bytes Per Sector
BPB_SECPERCLUS_OFF = 13                 ; Offset in the BPB sector to the Sectors Per Cluster
BPB_RSRVCLUS_OFF = 14                   ; Offset in the BPB sector to the Number of Reserved Clusters
BPB_NUMFAT_OFF = 16                     ; Offset in the BPB sector to the Number of FATs
BPB_ROOT_MAX_ENTRY_OFF = 17             ; Offset in the BPB sector to the Maximum # of entries in the root directory (FAT12)
BPB_TOTAL_SECTORS = 19                  ; Offset in the BPB sector to the number of sectors on the partition or disk (FAT12)
BPB_SECPERFAT_OFF = $24                 ; Offset in the BPB sector to the Sectors Per FAT
BPB_SIGNATUREB = 38                     ; Offset in the BPB sector to the second signature byte
BPB_VOLUMEID = 39                       ; Offset in the BPB sector to the volume ID
BPB_ROOTCLUS_OFF = $2C                  ; Offset in the BPB sector to the Root Cluster Number
BPB_SIGNATURE = 510                     ; The offset to the MBR signature bytes

;;
;; Data storage needed by the file system (internal variables user apps shouldn't need)
;;

; Device information from master boot record and boot sector

DOS_HIGH_VARIABLES      = $38E000
DEVICE                  = $38E000       ; 1 byte - The number of the block device
FILE_SYSTEM             = $38E001       ; 1 byte - The type of filesystem (FAT12, FAT32, etc.)
PARTITION               = $38E002       ; 1 byte - The number of the partitions on the device
SECTORS_PER_CLUSTER     = $38E003       ; 1 byte - The number of sectors in a cluster
FIRSTSECTOR             = $38E004       ; 4 bytes - The LBA of the first sector on the volume
SECTORCOUNT             = $38E008       ; 4 bytes - The number of sectors in the volume
NUM_RSRV_SEC            = $38E00C       ; 2 bytes - The number of hidden or reserved sectors
CLUSTER_SIZE            = $38E00E       ; 2 bytes - The size of a cluster in bytes 
SEC_PER_FAT             = $38E010       ; 4 bytes - The number of sectors per FAT
FAT_BEGIN_LBA           = $38E014       ; 4 bytes - The LBA of the first sector of FAT #1
FAT2_BEGIN_LBA          = $38E018       ; 4 bytes - The LBA of the first sector of FAT #2
CLUSTER_BEGIN_LBA       = $38E01C       ; 4 bytes - The LBA of the first cluster in the storage area
ROOT_DIR_FIRST_CLUSTER  = $38E020       ; 4 bytes - The number of the first cluster in the root directory
ROOT_DIR_MAX_ENTRY      = $38E024       ; 2 bytes - The maximum number of entries in the root directory (0 = no limit)
VOLUME_ID               = $38E026       ; 4 bytes - The ID of the volume

; Other variables we don't need in bank 0

DOS_CURR_CLUS           = $38E02A       ; 4 bytes - The current cluster (for delete)
DOS_NEXT_CLUS           = $38E02E       ; 4 bytes - The next cluster in a file (for delete)
DOS_DIR_BLOCK_ID        = $38E032       ; 4 bytes - The ID of the current directory block
                                        ;   If DOS_DIR_TYPE = 0, this is a cluster ID
                                        ;   If DOS_DIR_TYPE = $80, this is a sector LBA
DOS_NEW_CLUSTER         = $38E036       ; 4 bytes - Space to store a newly written cluster ID
DOS_SHORT_NAME          = $38E03A       ; 11 bytes - The short name for a desired file
DOS_DIR_TYPE            = $38E045       ; 1 byte - a code indicating the type of the current directory (0 = cluster based, $80 = sector based)
DOS_CURR_DIR_ID         = $38E046       ; 4 byte - the ID of the first sector or cluster of the current directory
DOS_DEV_NAMES           = $38E04A       ; 4 byte - pointer to the linked list of device names
FDC_MOTOR_TIMER         = $38E04E       ; 2 bytes - count-down timer to automatically turn off the FDC spindle motor

; Larger buffers

DOS_DIR_CLUSTER         = $38E100       ; 512 bytes - A buffer for directory entries
DOS_DIR_CLUSTER_END     = $38E300       ; The byte just past the end of the directory cluster buffer
DOS_SECTOR              = $38E300       ; 512 bytes - A buffer for block device read/write
DOS_SECTOR_END          = $38E500       ; The byte just past the end of the cluster buffer
DOS_FAT_SECTORS         = $38E500       ; 1024 bytes - two sectors worth of the FAT
DOS_FAT_SECTORS_END     = $38E900       ; The byte just past the end of the FAT buffers
DOS_BOOT_SECTOR         = $38E900       ; A sector for holding the boot sector
DOS_BOOT_SECTOR_END     = $38EB00
DOS_SPARE_SECTOR        = $38EB00       ; A spare 512 byte buffer for loading sectors
DOS_SPARE_SECTOR_END    = $38ED00
DOS_SPARE_FD            = $38ED00       ; A spare file descriptor buffer

;;
;; Code for the file system
;;

;
; Initialize the internal variables for the file system
;
; Only to be called on boot
;
DOS_INIT        .proc
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setal
                LDA #<>DOS_HD_DESC      ; Initialize the device names list
                STA @l DOS_DEV_NAMES
                LDA #`DOS_HD_DESC
                STA @l DOS_DEV_NAMES+2

                setas
                LDA #BIOS_DEV_SD        ; Default to the SD card
                STA BIOS_DEV

                PLP
                PLD
                PLB
                RTL
                .pend

;
; Mount a volume and load its information into a volume description
;
; Inputs:
;   BIOS_DEV = the number of the device to mount
;   VOLUME = the volume table describing the layout of the mounted drive
;
; Outputs:
;   C set on success, clear on failure
;
DOS_MOUNT       .proc
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setas
                LDA BIOS_DEV            ; Check the device
                CMP #BIOS_DEV_SD        ; Is it the SDC?
                BEQ do_sdc_mount        ; Yes: attempt to mount it

                CMP #BIOS_DEV_HD0       ; Is it HD0?
                BEQ do_ide_mount        ; Yes: attempt to mount the IDE drive

                CMP #BIOS_DEV_FDC       ; Is it the FDC?
                BEQ do_fdc_mount        ; Yes: attempt to mount it

                LDA #DOS_ERR_NOINIT     ; Otherwise: return a bad device error
                STA DOS_STATUS
                LDA #BIOS_ERR_BADDEV
                STA BIOS_STATUS
                BRL ret_failure

do_fdc_mount    JSL FDC_MOUNT           ; Attempt to mount the floppy disk
                BCS fdc_success
                BRL ret_failure
fdc_success     BRL ret_success

do_sdc_mount    JSL SDC_INIT            ; Yes: Initialize access to the SDC
                BCS get_mbr             ; Continue if success
                LDA #DOS_ERR_NOINIT     ; Otherwise: return an error
                BRL ret_failure

do_ide_mount    JSL IDE_INIT            ; Yes: Initialize access to the IDE drive
                BCS get_mbr             ; Continue if success
                LDA #DOS_ERR_NOINIT     ; Otherwise: return an error
                BRL ret_failure

get_mbr         setaxl
                STZ BIOS_LBA            ; Get the MBR
                STZ BIOS_LBA+2

                LDA #<>DOS_SECTOR       ; Into DOS_SECTOR
                STA BIOS_BUFF_PTR
                LDA #`DOS_SECTOR
                STA BIOS_BUFF_PTR+2

                JSL GETBLOCK            ; Try to read the MBR
                BCS chk_signature       ; If success, check the signature bytes
                setas
                LDA #DOS_ERR_READ       ; Otherwise: report we couldn't read the first sector
                BRL ret_failure

                ; Check signature bytes

chk_signature   setas
                LDA DOS_SECTOR+MBR_SIGNATURE
                CMP #$55                ; Is first byte of signature $55?
                BNE not_mbr             ; No: signal we could find the MBR
                LDA DOS_SECTOR+MBR_SIGNATURE+1
                CMP #$AA                ; Is second byte of signature $AA?
                BEQ chk_part_type       ; Yes: we have an MBR
not_mbr         LDA #DOS_ERR_NOTMBR     ; Return that we didn't find the MBR
                BRL ret_failure

                ; Make sure it's a FAT32 with LBA addressing
chk_part_type   LDA DOS_SECTOR+PART0_OFF+PART_TYPE_OFF
                CMP #PART_TYPE_FAT32_LBA
                BEQ get_LBA             ; Is FAT32 with LBA?
                LDA #DOS_ERR_NOFAT32    ; No: return No FAT32 found error
                BRL ret_failure

get_LBA         STA FILE_SYSTEM         ; Save the file system of the partition

                setal
                ; Get the LBA of the first sector and put it in the volume descriptor
                LDA DOS_SECTOR+PART0_OFF+PART_LBA_OFF
                STA FIRSTSECTOR
                LDA DOS_SECTOR+PART0_OFF+PART_LBA_OFF+2
                STA FIRSTSECTOR+2

                ; Get the number of sectors from the partition table and put it in the volume descriptor
                LDA DOS_SECTOR+PART0_OFF+PART_SECT_COUNT_OFF
                STA SECTORCOUNT
                LDA DOS_SECTOR+PART0_OFF+PART_SECT_COUNT_OFF+2
                STA SECTORCOUNT+2

                setas
                LDA BIOS_DEV            ; Save the device number
                STA DEVICE

                LDA #0
                STA PARTITION           ; For the moment, we only support the first partition

                setal
                ; Get the volume identifier record
                LDA #<>DOS_SECTOR
                STA BIOS_BUFF_PTR
                LDA #`DOS_SECTOR
                STA BIOS_BUFF_PTR+2

                LDA FIRSTSECTOR
                STA BIOS_LBA
                LDA FIRSTSECTOR+2
                STA BIOS_LBA+2

                JSL GETBLOCK            ; Attempt to load the volume ID
                BCS get_first_sec       ; Got it? Start parsing it

                setas
                LDA #DOS_ERR_VOLID      ; Otherwise: return an error
                BRL ret_failure

chk_bpb_sig     setas
                LDA DOS_SECTOR+BPB_SIGNATURE
                CMP #$55                ; Is first byte of signature $55?
                BNE not_bpb             ; No: signal we could find the volume ID
                LDA DOS_SECTOR+BPB_SIGNATURE+1
                CMP #$AA                ; Is second byte of signature $AA?
                BEQ get_first_sec       ; Yes: we have an volume ID
not_bpb         LDA #DOS_ERR_VOLID      ; Return that we didn't find the Volume ID (BPB)
                BRL ret_failure

                ; Calculate the first sector of the FAT

get_first_sec   ; Get the first cluster of the directory
                setal
                LDA DOS_SECTOR+BPB_ROOTCLUS_OFF
                STA ROOT_DIR_FIRST_CLUSTER
                LDA DOS_SECTOR+BPB_ROOTCLUS_OFF+2
                STA ROOT_DIR_FIRST_CLUSTER+2  

                ; Get number of reserved sectors
                LDA DOS_SECTOR+BPB_RSRVCLUS_OFF
                STA NUM_RSRV_SEC
                
                CLC                     ; fat_begin_lba := FirstSector + Number_of_Reserved_Sectors
                LDA FIRSTSECTOR
                ADC NUM_RSRV_SEC
                STA FAT_BEGIN_LBA
                LDA FIRSTSECTOR+2
                ADC #0
                STA FAT_BEGIN_LBA+2

                ; Calculate the first sector of the data area
                
                ; Get the number of sectors per FAT
                LDA DOS_SECTOR+BPB_SECPERFAT_OFF
                STA SEC_PER_FAT
                LDA DOS_SECTOR+BPB_SECPERFAT_OFF+2
                STA SEC_PER_FAT+2

                LDA SEC_PER_FAT
                ASL A
                STA CLUSTER_BEGIN_LBA
                LDA SEC_PER_FAT+2
                ROL A
                STA CLUSTER_BEGIN_LBA+2

                CLC
                LDA CLUSTER_BEGIN_LBA                    ; Sectors Per FAT * 2 + fat_begin_lba
                ADC FAT_BEGIN_LBA
                STA CLUSTER_BEGIN_LBA
                LDA CLUSTER_BEGIN_LBA+2
                ADC FAT_BEGIN_LBA+2
                STA CLUSTER_BEGIN_LBA+2

                ; Get the sectors per cluster
                setas
                LDA DOS_SECTOR+BPB_SECPERCLUS_OFF
                STA SECTORS_PER_CLUSTER

                setal
                AND #$00FF
                PHA                                     ; Save the number of sectors per cluster

                LDA #<>DOS_SECTOR_SIZE                  ; Default to one sector's worth of bytes
                STA CLUSTER_SIZE
                LDA #`DOS_SECTOR_SIZE
                STA CLUSTER_SIZE+2

                PLA                                     ; Restore the number of sectors per cluster

clus_size_loop  CMP #1                                  ; If there's only one cluster, return success
                BEQ ret_success

                ASL CLUSTER_SIZE                        ; Otherwise, multiply the number of bytes by 2
                ROL CLUSTER_SIZE+2

                LSR A                                   ; And divide the number of sectors by 2
                BRA clus_size_loop

ret_success     setas
                STZ DOS_STATUS          ; Set status code to 0
                PLP
                PLD
                PLB
                SEC
                RTL

ret_failure     setas              
                STA DOS_STATUS          ; Save the status code
                PLP
                PLD
                PLB
                CLC
                RTL
                .pend

;
; Check the the MBR or VBR loaded in DOS_SECTOR to see if it is bootable.
; If it is, execute the code found in the sector. Otherwise, this code just
; returns.
;
DOS_TESTBOOT    .proc
                PHB
                PHD
                PHX
                PHP

                TRACE "DOS_TESTBOOT"

                setdbr 0
                setdp SDOS_VARIABLES
                
                setxl

chk_dev         setas
                LDA @b BIOS_DEV             ; Look at the device #
                CMP #BIOS_DEV_FDC           ; Is it the floppy drive?
                BEQ chk_vbr_brl             ; Yes: check if BRL is in the right place in the VBR

                setaxl                      ; Otherwise, we need to check the MBR/VBR
                LDA #0                      ; Point to the MBR
                STA @b BIOS_LBA
                STA @b BIOS_LBA+2

                LDA #<>DOS_SECTOR           ; And the buffer
                STA @b BIOS_BUFF_PTR
                LDA #`DOS_SECTOR
                STA @b BIOS_BUFF_PTR+2

                JSL GETBLOCK                ; Try to load the MBR
                BCS chk_mbr_brl
                BRL done                    ; If failed... just return

chk_mbr_brl     setas
                LDA @l DOS_SECTOR           ; Check the first byte of the MBR
                BRA chk_brl

chk_vbr_brl     LDA @l DOS_SECTOR+FDC_BOOT_START
chk_brl         CMP #$80                    ; Is the first byte a BRL/BRA instruction?
                BEQ chk_magic               ; Yes: check for the magic text
                CMP #$82
                BEQ chk_magic
                BRA done                    ; No: just return

chk_magic       LDX #0
magic_loop      LDA @l DOS_SECTOR+3,X       ; Check the "vendor" byte
                CMP DOS_BOOT_MAGIC,X        ; Compare it against our boot magic code
                BNE done                    ; If it's not equal, just return
                INX                         ; Otherwise, check the next one
                CPX #8
                BNE magic_loop              ; Until we've checked all 8 bytes

                setaxl                      ; Copy the data from DOS_SECTOR to DOS_BOOT_SECTOR
                LDA #DOS_SECTOR_SIZE
                LDX #<>(DOS_SECTOR+DOS_SECTOR_SIZE)
                LDY #<>(DOS_BOOT_SECTOR+DOS_SECTOR_SIZE)
                MVP #`DOS_SECTOR, #`DOS_BOOT_SECTOR

                TRACE "Attempt bootstrap..."

                ; Launch the boot code
                setas
                LDA @b BIOS_DEV             ; Check the device
                CMP #BIOS_DEV_FDC           ; Is it the FDC?
                BEQ jmp_fdc_start           ; Yes: jump to the start of the VBR code

                JML DOS_BOOT_SECTOR         ; No: it's an MBR, start at the first byte

jmp_fdc_start   JML DOS_BOOT_SECTOR+FDC_BOOT_START

done            PLP
                PLD
                PLB
                PLX
                RTL
                .pend

DOS_BOOT_MAGIC  .text "C256DOS "

;
; Give a cluster number, calculate the LBA
;
; lba_addr = cluster_begin_lba + (cluster_number - 2) * sectors_per_cluster;
;
; Inputs:
;   DOS_CLUS_ID = the cluster desired
;
; Outputs:
;   BIOS_LBA = the LBA for the sector
;
DOS_CALC_LBA    .proc
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setal

                SEC
                LDA DOS_CLUS_ID                     ; cluster - 2
                SBC #2
                STA DOS_TEMP
                LDA DOS_CLUS_ID+2
                SBC #0
                STA DOS_TEMP+2

                ; Calculate (cluster - 2) * SECTORS_PER_CLUSTER
                ; NOTE: assumes SECTORS_PER_CLUSTER is 1, 2, 4, 8, 16, etc.
                setxs
                LDX SECTORS_PER_CLUSTER
mult_loop       CPX #1
                BEQ add_offset

                ASL DOS_TEMP
                ROL DOS_TEMP

                DEX
                BRA mult_loop

add_offset      CLC
                LDA DOS_TEMP                        ; cluster_being_lba + (cluster - 2) * SECTORS_PER_CLUSTER
                ADC CLUSTER_BEGIN_LBA
                STA BIOS_LBA
                LDA DOS_TEMP+2
                ADC CLUSTER_BEGIN_LBA+2
                STA BIOS_LBA+2 

                PLP
                PLD
                PLB
                RTL
                .pend

;
; Read a 512 byte block from the selected block device into memory
;
; Inputs:
;   BIOS_DEV = the number of the block device
;   DOS_CLUS_ID = the number of the cluster desired
;   DOS_BUFF_PTR = pointer to the location to store the block
;
; Returns:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
DOS_GETCLUSTER  .proc
                PHB
                PHD
                PHP

                TRACE "DOS_GETCLUSTER"

                setdbr 0
                setdp SDOS_VARIABLES

                setal
                LDA DOS_BUFF_PTR                    ; Set the BIOS BUFFER
                STA BIOS_BUFF_PTR
                LDA DOS_BUFF_PTR+2
                STA BIOS_BUFF_PTR+2               

                JSL DOS_CALC_LBA                    ; Convert the cluster # to the first sector's LBA

                JSL GETBLOCK                        ; Get the first block of the cluster
                BCC ret_failure

                ; TODO: handle multiple sectors in the cluster

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL

ret_failure     setas
                STA DOS_STATUS
                PLP
                PLD
                PLB
                CLC
                RTL
                .pend

;
; Write a 512 byte block from memory to the selected block device
;
; Inputs:
;   BIOS_DEV = the number of the block device
;   DOS_CLUS_ID = the number of the cluster to write
;   DOS_BUFF_PTR = pointer to the location that holds the data to write
;
; Returns:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
DOS_PUTCLUSTER  .proc
                PHB
                PHD
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                setal
                LDA DOS_BUFF_PTR                    ; Set the BIOS BUFFER
                STA BIOS_BUFF_PTR
                LDA DOS_BUFF_PTR+2
                STA BIOS_BUFF_PTR+2               

                JSL DOS_CALC_LBA                    ; Convert the cluster # to the first sector's LBA

                JSL PUTBLOCK                        ; PUT the first block of the cluster
                BCC ret_failure

                ; TODO: handle multiple sectors in the cluster

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL

ret_failure     setas
                STA DOS_STATUS
                PLP
                PLD
                PLB
                CLC
                RTL
                .pend

;
; A linked list of device names
;
; The idea is that this might be expanded to support other names or even
; volume names.
;

; The floppy drive
DOS_FDC_NAME    .null "@F"
DOS_FDC_DESC    .dstruct DEVICE_DESC, DOS_FDC_NAME, BIOS_DEV_FDC, 0

; The SD card interface (partition 0)
DOS_SDC_NAME    .null "@S"
DOS_SDC_DESC    .dstruct DEVICE_DESC, DOS_SDC_NAME, BIOS_DEV_SD, DOS_FDC_DESC

; The IDE master drive (partition 0)
DOS_HDC_NAME    .null "@H"
DOS_HD_DESC     .dstruct DEVICE_DESC, DOS_HDC_NAME, BIOS_DEV_HD0, DOS_SDC_DESC

;
; Parse the device name
;
; Inputs:
;   DOS_PATH_BUFF = a buffer containing the full path to the file (NULL terminated)
;
;   Device names are of the form ":xxx"
;   where "xxx" is one of (others may be supported in time):
;       "SD0" for the first partition of the SD card
;       "FD0" for floppy drive #0
;       "HD0" for partition 0 of the master IDE drive
;
; Outputs:
;   DOS_PATH_BUFF = a buffer containing the path without device name
;   BIOS_DEV = the number of the device to use (unchanged if no device name found)
;
DOS_PARSE_DEV   .proc
                PHB
                PHD
                PHP

                TRACE "DOS_PARSE_DEV"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                
                LDA @l DOS_DEV_NAMES        ; Point to the first device name to check
                STA DOS_TEMP
                LDA @l DOS_DEV_NAMES+2
                STA DOS_TEMP+2

                LDA #<>DOS_PATH_BUFF        ; Make DOS_STR2_PTR point to the path to check
                STA DOS_STR2_PTR
                LDA #`DOS_PATH_BUFF
                STA DOS_STR2_PTR+2               

dev_loop        LDY #DEVICE_DESC.DEVNAME    ; Get the name of the current device into DOS_STR1_PTR
                LDA [DOS_TEMP],Y
                STA DOS_STR1_PTR
                INY
                INY
                LDA [DOS_TEMP],Y
                STA DOS_STR1_PTR+2

                setas
                LDY #0
cmp_loop        LDA [DOS_STR1_PTR],Y        ; Get the Yth character of the device name
                BEQ found                   ; If it's NULL, we found a match
                CMP [DOS_STR2_PTR],Y        ; Compare it to the Yth character of the path
                BNE next_device             ; If no match, try to load the next device
                INY                         ; Go to the next character
                BRA cmp_loop

next_device     TRACE "next_device"
                setal
                LDY #DEVICE_DESC.NEXT       ; DOS_TEMP := DOS_TEMP->NEXT
                LDA [DOS_TEMP],Y
                PHA
                INY
                INY
                LDA [DOS_TEMP],Y
                STA DOS_TEMP+2
                PLA
                STA DOS_TEMP

                LDA DOS_TEMP                ; Is DOS_TEMP = NULL?
                BNE dev_loop                ; No: check this device
                LDA DOS_TEMP+2
                BNE dev_loop

done            PLP                         ; Otherwise, return having not found a match
                PLD
                PLB
                RTL

found           JSL DOS_ADJUSTPATH          ; Remove the device name from the buffer
                
                setas
                LDY #DEVICE_DESC.DEVNUMBER  ; Set the BIOS device number from the found device
                LDA [DOS_TEMP],Y
                STA @l BIOS_DEV

                BRA done
                .pend

;
; Remove leading characters from the DOS_PATH_BUFF
;
; Inputs:
;   DOS_PATH_BUFF = the path to modify
;   Y = the index of the first character in the buffer to remain
;
; Outputs:
;   DOS_PATH_BUFF 
DOS_ADJUSTPATH  .proc
                PHX
                PHY
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                STY DOS_SCRATCH                 ; Save the index to later compute the size

                TYA                             ; Compute the address of the first source byte
                CLC
                ADC #<>DOS_PATH_BUFF
                TAX
                
                LDA #<>DOS_PATH_BUFF            ; Compute the destination address for the source byte
                TAY

                SEC                             ; Compute the number of bytes to copy
                LDA #256
                SBC DOS_SCRATCH

                MVN #`DOS_PATH_BUFF, #`DOS_PATH_BUFF

                PLP
                PLD
                PLB
                PLY
                PLX
                RTL
                .pend

;
; Parse a path
;
; Inputs:
;   DOS_PATH_BUFF = a buffer containing the full path to the file (NULL terminated)
;
; Outputs
;   BIOS_DEV = the device number for the path
;   DOS_PATH_BUFF = the directories to traverse to get to the file
;   DOS_SHORT_NAME = the 8.3 name for the desired file
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
DOS_PARSE_PATH  .proc
                PHB
                PHD
                PHP

                TRACE "DOS_PARSE_PATH"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setxl
                setas

                ; Convert the path to upper-case and check for bad characters

                LDX #0
upcase_loop     LDA DOS_PATH_BUFF,X     ; Get the character
                BEQ parse_dev           ; If it's NULL, the path is upper case, attempt to parse the device

                CMP #' '                ; Is a control character?
                BGE check_case          ; No: check the case

                LDA #DOS_ERR_BADPATH    ; Yes: return a bad path error
                BRL ret_failure

check_case      CMP #'a'                ; Is the character lower case?
                BLT next_char
                CMP #'z'+1
                BGE next_char

                AND #%01011111          ; Yes: Convert to uppercase
                STA DOS_PATH_BUFF,X

next_char       INX                     ; Move to the next character
                CPX #$100
                BNE upcase_loop
         
parse_dev       JSL DOS_PARSE_DEV       ; Parse and extract a device specifier ":xxx:"

                ; TODO: skip over the directory paths to get to the short name

                LDA DOS_PATH_BUFF       ; Check the first character of the path
                CMP #':'
                BNE clr_name            ; If not colon, treat it as a file name
                LDY #1                  ; Otherwise...
                JSL DOS_ADJUSTPATH      ; For now, just remove the leading ":"

clr_name        LDY #0                  ; Set the short name to blanks
                LDA #' '
clr_loop        STA DOS_SHORT_NAME,Y
                INY
                CPY #11
                BNE clr_loop            

                LDX #0
                LDY #0
cpy_name_loop   LDA DOS_PATH_BUFF,X     ; Get the character of the name
                BEQ ret_success         ; If NULL: we've finished parsing the path
                CMP #'.'                ; If it's a dot, we've finished the name part
                BEQ cpy_ext             ; And move to the extension
                STA DOS_SHORT_NAME,Y    ; Otherwise, store it to the name portion
                INX
                INY                     ; Move to the next character
                CPY #8                  ; Have we processed 8?
                BNE cpy_name_loop       ; No: process this one

cpy_ext         INX                     ; Skip the dot

                LDY #8
cpy_ext_loop    LDA DOS_PATH_BUFF,X     ; Get the character of the extension
                BEQ ret_success         ; If it's NULL, we've finished
                STA DOS_SHORT_NAME,Y    ; Otherwise, copy it to the short name
                INX
                INY                     ; Move to the next character
                CPY #11                 ; Have we processed the three ext characters?
                BNE cpy_ext_loop        ; No: process this one

ret_success     setas
                STZ DOS_STATUS

                PLP
                PLD
                PLB
                SEC
                RTL

ret_failure     setas
                STA DOS_STATUS

                PLP
                PLD
                PLB
                CLC
                RTL
                .pend

;
; Find the first cluster of a file, given its path
;
; Inputs:
;   DOS_PATH_BUFF = a buffer containing the full path to the file (NULL terminated)
;
; Outputs:
;   DOS_CLUS_ID = the first cluster of the file, if found
;   DOS_DIR_CLUS_ID = the ID of the cluster for the current directory
;   DOS_DIR_PTR = pointer to the directory entry that was found
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
DOS_FINDFILE    .proc
                PHB
                PHD
                PHP

                TRACE "DOS_FINDFILE"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl
                JSL DOS_PARSE_PATH              ; Break out the path into its components
                BCS mount                       ; If success: try to open the directory
            
pass_failure    PLP                             ; If failure, just pass the failure back up
                PLD
                PLB
                CLC
                RTL

mount           JSL DOS_MOUNT

get_directory   setal
                JSL DOS_DIROPEN                 ; Get the directory
                BCS scan_entries                ; If success: start scanning the directory entries

                setas
                LDA #DOS_ERR_NODIR              ; Otherwise: return a no directory error
                BRL ret_failure

scan_entries    JSL DOS_DIRFIRST                ; Move the DIR pointer to the beginning of the sector

scan_loop       setas
                LDY #0
                LDA [DOS_DIR_PTR],Y             ; Check the directory entry
                BNE chk_unused                  ; If there's an entry, check to see if it's unused             
                LDA #DOS_ERR_NOTFOUND           ; If end-of-directory, we couldn't find a match
                BRL ret_failure

chk_unused      CMP #DOS_DIR_ENT_UNUSED         ; If it's unused...
                BEQ next_entry                  ; Go to the next entry

                LDY #DIRENTRY.ATTRIBUTE         ; Check the entry's attributes
                LDA [DOS_DIR_PTR],Y
                BIT #DOS_ATTR_VOLUME            ; Is it a volume name?
                BNE next_entry                  ; Yes: skip it!

                AND #DOS_ATTR_LONGNAME
                CMP #DOS_ATTR_LONGNAME          ; Is it a long name field?
                BEQ next_entry                  ; Yes: skip it!

                LDX #0
                LDY #DIRENTRY.SHORTNAME
scan_cmp_loop   LDA [DOS_DIR_PTR],Y             ; Get the X'th character of the entry
                CMP DOS_SHORT_NAME,X            ; And compare to the X'th character of the name we want
                BNE next_entry                  ; If not equal: try the next entry

                INY                             ; Advance to the next character
                INX
                CPX #11                         ; Did we reach the end of the names?
                BEQ match                       ; Yes: we have a match!
                BRA scan_cmp_loop               ; No: keep checking

next_entry      JSL DOS_DIRNEXT                 ; Try to get the next directory entry
                BCC ret_failure                 ; If we're at the end of the directory, return a failure.
                BRL scan_loop                   ; If found: keep scanning

bad_dir         LDA #DOS_ERR_NODIR              ; Otherwise: fail with a NODIR error (maybe something else is better)

ret_failure     setas
                STA DOS_STATUS
                PLP
                PLD
                PLB
                CLC
                RTL

match           setal
                LDY #DIRENTRY.CLUSTER_L         ; Copy the cluster number from the directory entry
                LDA [DOS_DIR_PTR],Y
                STA DOS_CLUS_ID                 ; To DOS_CLUS_ID
                LDY #DIRENTRY.CLUSTER_H
                LDA [DOS_DIR_PTR],Y
                STA DOS_CLUS_ID+2               

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL
                .pend

;
; Open a file for reading and read the first cluster off the disk
;
; Inputs:
;   DOS_PATH_BUFF = a buffer containing the full path to the file (NULL terminated)
;   DOS_BUFF_PTR = pointer to the buffer to contain the first cluster of the file
;
; Outputs:
;   DOS_CLUS_ID = the first cluster of the file, if found
;   DOS_DIR_PTR = pointer to the directory entry that was found
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
DOS_READFILE    .proc
                PHB
                PHD
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl

                LDA DOS_BUFF_PTR+2
                PHA
                LDA DOS_BUFF_PTR
                PHA
                JSL DOS_FINDFILE                    ; Attempt to find the file's directory entry
                PLA
                STA DOS_BUFF_PTR
                PLA
                STA DOS_BUFF_PTR+2
                BCC pass_failure                    ; If found: try to load the cluster

load_cluster    JSL DOS_GETCLUSTER                  ; Get the first block of the cluster
                BCC pass_failure                    ; If there's an error... pass it up the chain

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL

pass_failure    PLP                                 ; Otherwise: pass any error up the chain
                PLD
                PLB
                CLC
                RTL
                .pend

;
; Calculate the LBA of the given cluster's FAT entry
; and the offset to its entry in the table
;
; Inputs:
;   DOS_CLUS_ID = the number of the target cluster
;
; Outputs:
;   DOS_FAT_LBA = the LBA of the FAT sector currently loaded
;   X = offset to the cluster's entry in the sector
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
ENTRYFORCLUS12  .proc
                PHB
                PHD
                PHP

                TRACE "ENTRYFORCLUS12"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl
                LDA DOS_CLUS_ID                 ; DOS_TEMP := DOS_CLUS_ID * 3
                ASL A
                STA DOS_TEMP
                LDA DOS_CLUS_ID+2
                ROL A
                STA DOS_TEMP+2

                CLC
                LDA DOS_CLUS_ID
                ADC DOS_TEMP
                STA DOS_TEMP
                LDA DOS_CLUS_ID+2
                ADC DOS_TEMP+2
                STA DOS_TEMP+2

                LSR DOS_TEMP+2                  ; DOS_TEMP := (DOS_CLUS_ID * 3) / 2
                ROR DOS_TEMP                    ; DOS_TEMP is now the offset to the cluster's entry in the FAT

                LDA DOS_TEMP                    ; X should be the offset within the FAT buffer
                AND #$003FF
                TAX

                .rept 9
                LSR DOS_TEMP+2                  ; DOS_TEMP := DOS_TEMP / 512
                ROR DOS_TEMP
                .next

                CLC                             ; DOS_FAT_LBA should be the LBA of the first FAT sector we need
                LDA FAT_BEGIN_LBA
                ADC DOS_TEMP
                STA DOS_FAT_LBA
                LDA FAT_BEGIN_LBA+2
                ADC DOS_TEMP+2
                STA DOS_FAT_LBA+2

                PLP
                PLD
                PLB
                RTL
                .pend

;
; Load the FAT entry that contains a specific cluster (FAT12)
;
; Inputs:
;   DOS_CLUS_ID = the number of the target cluster
;
; Outputs:
;   DOS_FAT_SECTORS = a copy of the FAT sector(s) containing the cluster
;   DOS_FAT_LBA = the LBA of the FAT sector currently loaded
;   X = offset to the cluster's entry in the sector
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
FATFORCLUSTER12 .proc
                PHB
                PHD
                PHP

                TRACE "FATFORCLUSTER12"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl
                LDX #0
                LDA #$5A5A
clr_loop        STA DOS_FAT_SECTORS
                INX
                INX
                CPX #1024
                BNE clr_loop

                JSL ENTRYFORCLUS12              ; Calculate the LBA

                LDA DOS_FAT_LBA                 ; Point to the desired sector in the FAT
                STA BIOS_LBA
                LDA DOS_FAT_LBA+2
                STA BIOS_LBA+2

                LDA #<>DOS_FAT_SECTORS          ; Point to the first 512 bytes of the FAT buffer
                STA BIOS_BUFF_PTR
                LDA #`DOS_FAT_SECTORS
                STA BIOS_BUFF_PTR+2

                JSL GETBLOCK                    ; Attempt to load the first FAT sector
                BCC error

                INC BIOS_LBA                    ; Move to the next sector

                LDA #<>DOS_FAT_SECTORS+512      ; And point to the second 512 bytes of teh FAT buffer
                STA BIOS_BUFF_PTR
                LDA #`DOS_FAT_SECTORS
                STA BIOS_BUFF_PTR+2

                JSL GETBLOCK                    ; Attempt to load the first FAT sector
                BCC error

                PLP
                PLD
                PLB
                SEC
                RTL

error           setas
                LDA #DOS_ERR_FAT
                STA DOS_STATUS

                PLP
                PLD
                PLB
                CLC
                RTL
                .pend

;
; Load the FAT entry that contains a specific cluster
;
; Inputs:
;   DOS_CLUS_ID = the number of the target cluster
;
; Outputs:
;   DOS_FAT_SECTORS = a copy of the FAT sector containing the cluster
;   DOS_FAT_LBA = the LBA of the FAT sector currently loaded
;   X = offset to the cluster's entry in the sector
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
FATFORCLUSTER32 .proc
                PHB
                PHD

                TRACE "FATFORCLUSTER32"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl
                ; DOS_FAT_LBA = FAT_BEGIN_LBA + ((clusterNumber * 4) / bytesPerSector) ;

                LDA DOS_CLUS_ID
                STA DOS_FAT_LBA
                LDA DOS_CLUS_ID+2
                STA DOS_FAT_LBA+2

                LDX #7
div_loop        LSR DOS_FAT_LBA+2
                ROR DOS_FAT_LBA
                DEX
                BNE div_loop

                CLC
                LDA DOS_FAT_LBA
                ADC FAT_BEGIN_LBA
                STA DOS_FAT_LBA
                LDA DOS_FAT_LBA+2
                ADC FAT_BEGIN_LBA+2
                STA DOS_FAT_LBA+2

                ; Try to get the desired FAT sector into memory

                LDA DOS_FAT_LBA                 ; We want to load the FAT sector
                STA BIOS_LBA
                LDA DOS_FAT_LBA+2
                STA BIOS_LBA+2

                LDA #<>DOS_FAT_SECTORS          ; We want to load the FAT sector in DOS_FAT_SECTORS
                STA BIOS_BUFF_PTR
                LDA #`DOS_FAT_SECTORS
                STA BIOS_BUFF_PTR+2

                JSL GETBLOCK                    ; Load the FAT entry
                BCS find_entry

                setas
                LDA #DOS_ERR_FAT
                BRA ret_failure

                ; X = (unsigned int) ((clusterNumber * 4) % bytesPerSector);
find_entry      setal
                LDA DOS_CLUS_ID
                ASL A
                ASL A                           ; * 4
                AND #$1FF                       ; DOS_CLUS_ID MOD 512
                TAX                             ; X should be the offset within the sector

ret_success     PLD
                PLB
                SEC                             ; return success
                RTL

ret_failure     PLD
                PLB
                CLC                             ; Return failure
                RTL
                .pend

;
; Find the next cluster in a file
;
; This subroutine calls the correct FAT code based on the file system type
;
; Inputs:
;   DOS_CLUS_ID = the current cluster of the file
;
; Outputs:
;   DOS_CLUS_ID = the next cluster for the file
;   C = set if there is a next cluster, clear if there isn't
;
NEXTCLUSTER     .proc
                PHP

                TRACE "NEXTCLUSTER"

                setas
                LDA @l FILE_SYSTEM              ; Get the file system code
                CMP #PART_TYPE_FAT12            ; Is it FAT12?
                BNE fat32                       ; No: assume it's FAT32

fat12           JSL NEXTCLUSTER12               ; Lookup the next cluster from FAT12
                BCC pass_failure                ; If there was an error, pass it up the chain
                BRA ret_success

fat32           JSL NEXTCLUSTER32               ; Lookup the next cluster from FAT32
                BCC pass_failure                ; If there was an error, pass it up the chain

ret_success     STZ DOS_STATUS
                PLP
                SEC
                RTL

pass_failure    PLP
                CLC
                RTL
                .pend    

;
; Find the next cluster in a file (FAT12)
;
; NOTE: assumes FAT12 with 512KB sectors
;
; Inputs:
;   DOS_CLUS_ID = the current cluster of the file
;
; Outputs:
;   DOS_CLUS_ID = the next cluster for the file
;   C = set if there is a next cluster, clear if there isn't
;
NEXTCLUSTER12       .proc
                    PHB
                    PHD
                    PHP

                    TRACE "NEXTCLUSTER12"

                    setdbr 0
                    setdp SDOS_VARIABLES

                    setaxl
                    JSL FATFORCLUSTER12             ; Attempt to load the FAT entries
                    BCS chk_clus_id
                    BRL pass_failure

chk_clus_id         LDA DOS_CLUS_ID                 ; Check the cluster ID...
                    BIT #1                          ; Is it odd?
                    BNE is_odd                      ; Yes: calculate the next cluster for odd

                    ; Handle even number clusters...

is_even             setal
                    LDA DOS_FAT_SECTORS,X           ; DOS_CLUS_ID := DOS_FAT_SECTORS[X] & $0FFF
                    AND #$0FFF
                    STA DOS_TEMP
                    BRA check_id

is_odd              setal
                    LDA DOS_FAT_SECTORS,X           ; DOS_CLUS_ID := DOS_FAT_SECTORS[X] >> 4
                    .rept 4
                    LSR A
                    .next
                    STA DOS_TEMP

check_id            setal
                    LDA DOS_TEMP                    ; Check the new cluster ID we got
                    AND #$0FF0                      ; Is it in the range $0FF0 -- $0FFF?
                    CMP #$0FF0
                    BEQ no_more                     ; Yes: return that we've reached the end of the chain

                    LDA DOS_TEMP                    ; Restore the "current" cluster ID
                    STA DOS_CLUS_ID
                    STZ DOS_CLUS_ID+2

ret_success         setas
                    STZ DOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

no_more             setas                           ; Return that there are no more clusters
                    LDA #DOS_ERR_NOCLUSTER
                    STA DOS_STATUS
pass_failure        PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend         

;
; Find the next cluster in a file
;
; NOTE: assumes FAT32 with 512KB sectors
;
; Inputs:
;   DOS_CLUS_ID = the current cluster of the file
;
; Outputs:
;   DOS_CLUS_ID = the next cluster for the file
;   C = set if there is a next cluster, clear if there isn't
;
NEXTCLUSTER32   .proc
                PHB
                PHD
                PHP

                TRACE "NEXTCLUSTER32"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl

                JSL FATFORCLUSTER32             ; Get the FAT entry for this cluster
                BCC ret_failure                 ; If it did not work, return the error

                LDA DOS_FAT_SECTORS,X           ; Get the entry and copy it to DOS_TEMP
                STA DOS_TEMP
                LDA DOS_FAT_SECTORS+2,X
                STA DOS_TEMP+2

                LDA DOS_TEMP                    ; Is DOS_TEMP = $FFFFFFFF?
                CMP #$FFFF
                BNE found_next
                LDA DOS_TEMP+2
                CMP #$0FFF
                BNE found_next                  ; No: return this cluster as the next
                LDA #DOS_ERR_NOCLUSTER          ; Yes: return that there are no more clusters
                BRA ret_failure

found_next      LDA DOS_TEMP                    ; No: return DOS_TEMP as the new DOS_CLUS_ID
                STA DOS_CLUS_ID
                LDA DOS_TEMP+2
                STA DOS_CLUS_ID+2

ret_success     setas
                STZ DOS_STATUS                  ; Record success
                
                PLP
                PLD
                PLB
                SEC
                RTL

ret_failure     STA DOS_STATUS                  ; Record the error condition
                PLP
                PLD
                PLB
                CLC
                RTL
                .pend

;
; Read the next cluster off a disk for the current file.
;
; Inputs:
;   DOS_CLUS_ID = the current cluster of the file being read
;   DOS_BUFF_PTR = pointer to the buffer to contain the first cluster of the file
;
; Outputs:
;   DOS_CLUS_ID = the next cluster of the file, if found
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
DOS_READNEXT    .proc
                PHP

                setaxl
                JSL NEXTCLUSTER                 ; Attempt to find the next cluster in the FAT
                BCC pass_failure                ; If nothing found: pass the failure up the chain
                JSL DOS_GETCLUSTER              ; Otherwise: attempt to read the cluster
                BCC pass_failure                ; If nothing read: pass the failure up the chain

ret_success     PLP
                SEC
                RTL

pass_failure    PLP
                CLC
                RTL
                .pend

;
; Find the next free cluster in the FAT, and flag it as used in the FAT (FAT32)
;
; Outputs:
;   DOS_CLUS_ID = the cluster found
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
DOS_FREECLUS    .proc
                PHP

                TRACE "DOS_FREECLUS"

                setdp SDOS_VARIABLES

                setas
                LDA @l FILE_SYSTEM              ; Get the file system code
                CMP #PART_TYPE_FAT12            ; Is it FAT12?
                BNE fat32                       ; No: assume it's FAT32

fat12           JSL DOS_FREECLUS12              ; Find the next free cluster from FAT12
                BCC pass_failure                ; If there was an error, pass it up the chain
                BRA ret_success

fat32           JSL DOS_FREECLUS32              ; Find the next free cluster from FAT32
                BCC pass_failure                ; If there was an error, pass it up the chain

ret_success     STZ DOS_STATUS
                PLP
                SEC
                RTL

pass_failure    PLP
                CLC
                RTL
                .pend

;
; Read two sectors of the FAT into the DOS FAT buffer
;
; Inputs:
;   DOS_FAT_LBA = the LBA of the first sector to read
;
; Returns:
;   BIOS_LBA = the LBA of the sector just read
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
FDC_READ2FAT12      .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp SDOS_VARIABLES
                    setaxl

                    LDA #<>DOS_FAT_SECTORS          ; Set the location to store the sector
                    STA BIOS_BUFF_PTR
                    LDA #`DOS_FAT_SECTORS
                    STA BIOS_BUFF_PTR+2

                    LDA DOS_FAT_LBA
                    STA BIOS_LBA
                    LDA DOS_FAT_LBA+2
                    STA BIOS_LBA+2

                    JSL GETBLOCK                    ; Read the first sector
                    BCS inc_sect2                   ; If success: start getting the second sector
                    setas                           ; If failed: return error
                    LDA #DOS_ERR_FAT
                    BRL ret_failure

inc_sect2           setal
                    INC BIOS_LBA                    ; Move to the next sector
                    BNE inc_buff_ptr
                    INC BIOS_LBA+2

                    ; Set the location to store the second sector
inc_buff_ptr        LDA #<>(DOS_FAT_SECTORS+DOS_SECTOR_SIZE)          
                    STA BIOS_BUFF_PTR
                    LDA #`(DOS_FAT_SECTORS+DOS_SECTOR_SIZE)
                    STA BIOS_BUFF_PTR+2

                    JSL GETBLOCK                    ; Read the second sector
                    BCS ret_success                 ; If success, return success
                    setas                           ; If failed: return error
                    LDA #DOS_ERR_FAT

ret_failure         setas
                    STA BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    CLC
                    RTL

ret_success         setas
                    STZ BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL
                    .pend

;
; Find the next free cluster in the FAT, and flag it as used in the FAT (FAT12)
;
; Outputs:
;   DOS_CLUS_ID = the cluster found
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
DOS_FREECLUS12  .proc
                PHX
                PHB
                PHD
                PHP

                TRACE "DOS_FREECLUS12"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl

                LDA #2                          ; Cluster ID is 2 to start with
                STA DOS_CLUS_ID
                LDA #0
                STA DOS_CLUS_ID+2

                JSL ENTRYFORCLUS12              ; Calculate the LBA and buffer offset for the cluster

                JSL FDC_READ2FAT12              ; Read the first two sectors of the FAT
                BCS start_of_fat                ; If success, move X to the start of the FAT
                setas                           ; If failed: return error
                LDA #DOS_ERR_FAT
                BRL ret_failure

start_of_fat    setaxl

                ; Get the cluster entry in the FAT
chk_cluster     LDA DOS_CLUS_ID                 ; Check to see if cluster number is even or odd
                BIT #1
                BNE is_odd

is_even         LDA DOS_FAT_SECTORS,X           ; Get the cluster status for an even numbered cluster
                AND #$0FFF
                BRA chk_available

is_odd          LDA DOS_FAT_SECTORS,X           ; Get the cluster status for an odd numbered cluster
                .rept 4
                LSR A
                .next

chk_available   TRACE "chk_available"
                STA DOS_TEMP

                CMP #0                          ; Is it available?
                BEQ chk_found
                BRL next_cluster                ; No: advance to the next cluster

                ; Yes... flag it as taken

chk_found       TXA
                STA DOS_TEMP+2

                LDA DOS_CLUS_ID                 ; Check to see if cluster number is even or odd
                BIT #1
                BNE is_odd2

is_even2        TRACE "is_even2"
                LDA DOS_FAT_SECTORS,X           ; Reserve the cluster in the FAT, even offset case
                ORA #$0FFF
                STA DOS_FAT_SECTORS,X
                BRA write_fat

is_odd2         TRACE "is_odd2"
                LDA DOS_FAT_SECTORS,X           ; Reserve the cluster in the FAT, odd offset case
                ORA #$FFF0
                STA DOS_FAT_SECTORS,X               

write_fat       JSL WRITEFAT12                  ; Write the two FAT sectors back to disk
                BCS ret_success                 ; If success: return success

                setas
                LDA #DOS_ERR_FATUPDATE          ; Flag an error trying to write the FAT back
                BRL ret_failure

ret_success     setas                           ; And return success
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                PLX
                SEC
                RTL

                ; Move to the next cluster in the FAT (may involve loading sectors)

next_cluster    TRACE "next_cluster"
                INC DOS_CLUS_ID                 ; And advance the cluster ID
                BNE calc_entry
                INC DOS_CLUS_ID+2

calc_entry      JSL ENTRYFORCLUS12              ; Calculate the LBA and offset into the buffer for the cluster

                CPX #0                          ; Did we wrap around?
                BEQ chk_end_of_fat
                BRL chk_cluster                 ; No: go back and check it too

chk_end_of_fat  TRACE "chk_end_of_fat"
                LDA DOS_FAT_LBA                 ; Are we at the end of the FAT?
                CMP FAT2_BEGIN_LBA              ; NOTE: we use the start sector of the second FAT as our sentinel
                BNE next_2
                LDA DOS_FAT_LBA+2
                CMP FAT2_BEGIN_LBA+2
                BNE next_2                      ; No: get the next to sectors

                setas
                LDA #DOS_ERR_MEDIAFULL          ; Yes: return media full
                BRL ret_failure

next_2          TRACE "read2fat12"
                JSL FDC_READ2FAT12              ; Read the next two sectors of the FAT
                BCC fat_fail                    ; If failed: return error

                LDX #0                          ; If success: Start scanning at the beginning of the sectors
                BRL chk_cluster                 ; And start checking from there

                ; Indicate that we failed to read or parst the FAT

fat_fail        setas
                LDA #DOS_ERR_FAT
                BRL ret_failure

ret_failure     setas
                STA DOS_STATUS
                PLP
                PLD
                PLB
                PLX
                CLC
                RTL
                .pend

;
; Find the next free cluster in the FAT, and flag it as used in the FAT (FAT32)
;
; Outputs:
;   DOS_CLUS_ID = the cluster found
;   DOS_STATUS = the status code for the operation
;   C set on success, clear on failure
;
DOS_FREECLUS32  .proc
                PHB
                PHD
                PHP

                TRACE "DOS_FREECLUS32"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl

                ; Get the first sector of the FAT

                LDA #<>DOS_SECTOR               ; Set the location to store the sector
                STA BIOS_BUFF_PTR
                LDA #`DOS_SECTOR
                STA BIOS_BUFF_PTR+2

                LDA FAT_BEGIN_LBA               ; Set the LBA to that of the first FAT sector
                STA BIOS_LBA
                LDA FAT_BEGIN_LBA+2
                STA BIOS_LBA+2

                JSL GETBLOCK                    ; Load the sector into memory
                BCS initial_entry               ; If OK: set the initial entry to check

                setas
                LDA #DOS_ERR_FAT                ; Return a NOFAT error
                BRL ret_failure

                ; Start at cluster #2

initial_entry   setal
                LDA #2                          ; Set DOS_CLUS_ID to 2
                STA DOS_CLUS_ID
                LDA #0
                STA DOS_CLUS_ID+2

                LDX #8                          ; Set the offset to DOS_CLUS_ID * 4

chk_entry       LDA DOS_SECTOR,X                ; Is the cluster entry == $00000000?
                BNE next_entry                  ; No: move to the next entry
                LDA DOS_SECTOR+2,X
                BEQ found_free                  ; Yes: go to allocate and return it

                ; No: move to next entry and update the cluster number

next_entry      INC DOS_CLUS_ID                 ; Move to the next cluster
                BNE inc_ptr
                INC DOS_CLUS_ID+2

inc_ptr         INX                             ; Update the index to the entry
                INX
                INX
                INX                
                CPX #DOS_SECTOR_SIZE            ; Are we outside the sector?
                BLT chk_entry                   ; No: check this entry
                
                ; Yes: load the next sector

                CLC                             ; Point to the next sector in the FAT
                LDA BIOS_LBA
                ADC #DOS_SECTOR_SIZE
                STA BIOS_LBA
                LDA BIOS_LBA+2
                ADC #0
                STA BIOS_LBA+2

                ; TODO: check for end of FAT

                JSL GETBLOCK                    ; Attempt to read the block
                BCS set_ptr                     ; If OK: set the pointer and check it

set_ptr         LDX #0                          ; Set index pointer to the first entry
                BRA chk_entry                   ; Check this entry

found_free      setal
                LDA #<>FAT_LAST_CLUSTER         ; Set the entry to $0FFFFFFF to make it the last entry in its chain
                STA DOS_SECTOR,X
                LDA #(FAT_LAST_CLUSTER >> 16)
                STA DOS_SECTOR+2,X

                JSL PUTBLOCK                    ; Write the sector back to the block device
                BCS ret_success                 ; If OK: return success

                setas
                LDA #DOS_ERR_FAT                ; Otherwise: return NOFAT error

ret_failure     setas
                STA DOS_STATUS
                PLP
                PLD
                PLB
                CLC
                RTL

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL
                .pend

;
; Delete a cluster by marking it as available for reallocation in the FAT
;
; Inputs:
;   DOS_CLUS_ID = the cluster to free
;
; Outputs:
;   DOS_STATUS = the status code for the operation
;   C = set if there is a next cluster, clear if there isn't
;
DELCLUSTER      .proc
                TRACE "DELCLUSTER"

                setas
                LDA @l FILE_SYSTEM              ; Get the file system code
                CMP #PART_TYPE_FAT12            ; Is it FAT12?
                BNE fat32                       ; No: assume it's FAT32

                ; Call the FAT12 version
fat12           JML DELCLUSTER12

                ; Call the FAT32 version
fat32           JMP DELCLUSTER32
                .pend

;
; Write FAT sectors back to the drive
;
; Inputs:
;   DOS_FAT_SECTORS = the two sectors worth of data to write
;   DOS_FAT_LBA = the LBA of the first sector to write on the disk
;
WRITEFAT12      .proc
                PHB
                PHD

                TRACE "WRITEFAT12"

                setdbr 0
                setdp SDOS_VARIABLES

                setaxl
                LDA #<>DOS_FAT_SECTORS          ; Point to the first FAT sector in memory
                STA BIOS_BUFF_PTR
                LDA #`DOS_FAT_SECTORS
                STA BIOS_BUFF_PTR+2

                LDA DOS_FAT_LBA                 ; Set the LBA to that of the first sector's
                STA BIOS_LBA
                LDA DOS_FAT_LBA+2
                STA BIOS_LBA+2

                JSL PUTBLOCK                    ; Write the first sector back to the block device
                BCC done

                ; Point to the second FAT sector in memory
                LDA #<>(DOS_FAT_SECTORS+DOS_SECTOR_SIZE)
                STA BIOS_BUFF_PTR
                LDA #`(DOS_FAT_SECTORS+DOS_SECTOR_SIZE)
                STA BIOS_BUFF_PTR+2

                INC BIOS_LBA                    ; Point to the next sector in the FAT
                BNE put_second
                INC BIOS_LBA+2

put_second      JSL PUTBLOCK                    ; Write the second sector back to the block device

done            PLD
                PLB
                RTL
                .pend

;
; Delete a cluster by marking it as available for reallocation in the FAT (FAT12)
;
; Inputs:
;   DOS_CLUS_ID = the cluster to free
;
; Outputs:
;   DOS_STATUS = the status code for the operation
;   C = set if there is a next cluster, clear if there isn't
;
DELCLUSTER12    .proc
                PHB
                PHD
                PHP
                TRACE "DELCLUSTER12"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                JSL FATFORCLUSTER12

                TXA                             ; Check to see if the index is odd or even
                BIT #1
                BNE is_odd

is_even         LDA DOS_FAT_SECTORS,X           ; Get the two bytes from the FAT
                AND #$F000                      ; Mask out the lower 12 bits
                BRA save_update

is_odd          LDA DOS_FAT_SECTORS,X           ; Get the two bytes from the FAT
                AND #$000F                      ; Mask out the upper 12 bits
                
save_update     STA DOS_FAT_SECTORS,X           ; And write it back

                JSL WRITEFAT12                  ; Write the two FAT12 sectors back to the drive
                BCS ret_success

ret_failure     TRACE "DELCLUSTER12 FAIL"
                setas
                LDA #DOS_ERR_FAT
                STA DOS_STATUS
                PLP
                PLD
                PLB
                CLC
                RTL

ret_success     TRACE "DELCLUSTER12 SUCCESS"
                setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL
                .pend

;
; Delete a cluster by marking it as available for reallocation in the FAT (FAT32)
;
; Inputs:
;   DOS_CLUS_ID = the cluster to free
;
; Outputs:
;   DOS_STATUS = the status code for the operation
;   C = set if there is a next cluster, clear if there isn't
;
DELCLUSTER32    .proc
                PHB
                PHD
                PHP
                setaxl

                TRACE "DELCLUSTER32"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                JSL FATFORCLUSTER32

                LDA #0
                STA DOS_FAT_SECTORS,X           ; Set the cluster entry to 0
                STA DOS_FAT_SECTORS+2,X

                JSL PUTBLOCK                    ; Write the sector back to the block device
                BCS ret_success

ret_failure     setas
                LDA #DOS_ERR_FAT
                STA DOS_STATUS
                PLP
                PLD
                PLB
                CLC
                RTL

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL
                .pend

;
; Append a cluster to the end of a file
;
; Inputs:
;   DOS_CLUS_ID = a cluster in the file (need not be the first)
;   DOS_BUFF_PTR = pointer to the data to add to the end of the file
;
; Outputs:
;   DOS_STATUS = the status code for the operation
;   C = set if there is a next cluster, clear if there isn't
;
DOS_APPENDCLUS  .proc
                PHB
                PHD
                PHP

                TRACE "DOS_APPENDCLUS"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                LDA DOS_CLUS_ID+2               ; Save the cluster number for later
                PHA
                LDA DOS_CLUS_ID
                PHA

                JSL DOS_FREECLUS                ; Find a free cluster on the block device
                BCS save_cluster                ; If we got a cluster, write the data to it

fail_cleanup    PLA                             ; Restore the cluster of the file
                STA DOS_CLUS_ID
                PLA
                STA DOS_CLUS_ID+2
                BRL pass_failure                ; Pass the failure back up the chain

                ; Save the ID of the new cluster
save_cluster    LDA DOS_CLUS_ID
                STA DOS_NEW_CLUSTER
                LDA DOS_CLUS_ID+2
                STA DOS_NEW_CLUSTER+2

                JSL DOS_PUTCLUSTER              ; Write the data to the free cluster
                BCC fail_cleanup                ; If failure: clean up stack and pass the failure up

                PLA                             ; Restore the cluster of the file
                STA DOS_CLUS_ID
                PLA
                STA DOS_CLUS_ID+2

                ; Walk to the end of the cluster chain for the file
walk_loop       JSL NEXTCLUSTER                 ; Try to get the next cluster in the chain
                BCS walk_loop                   ; If found a cluster, keep walking the chain

                setas
                LDA @l FILE_SYSTEM              ; Get the file system code
                CMP #PART_TYPE_FAT12            ; Is it FAT12?
                BNE fat32                       ; No: assume it's FAT32

                ; Update the cluster for FAT12

fat12           setal
                JSL ENTRYFORCLUS12              ; Make sure we have the right offset for the cluster
                LDA DOS_CLUS_ID                 ; Check to see if the last cluster ID is even or odd
                BIT #1
                BNE is_odd

is_even         LDA DOS_NEW_CLUSTER             ; Handle the even case (change the lower 12 bits)
                AND #$0FFF
                STA DOS_NEW_CLUSTER
                LDA DOS_FAT_SECTORS,X
                AND #$F000
                BRA update_fat12

is_odd          LDA DOS_NEW_CLUSTER             ; Handle the odd case (change the upper 12 bits)
                .rept 4
                ASL A
                .next
                STA DOS_NEW_CLUSTER
                LDA DOS_FAT_SECTORS,X
                AND #$000F

update_fat12    ORA DOS_NEW_CLUSTER
                STA DOS_FAT_SECTORS,X

                JSL WRITEFAT12                  ; Write the two FAT12 sectors back to the drive
                BCS ret_success
                BRL pass_failure

                ; Update the cluster for FAT32

fat32           setal
                LDA DOS_NEW_CLUSTER             ; Write the ID of the new cluster to the end of the chain
                STA DOS_FAT_SECTORS,X
                LDA DOS_NEW_CLUSTER+2
                STA DOS_FAT_SECTORS+2,X

                JSL PUTBLOCK                    ; Write the FAT sector back (assumes BIOS_LBA and BIOS_BUFF_PTR haven't changed)
                BCS ret_success

                setas
                LDA #DOS_ERR_FAT                ; Problem working with the FAT
                STA DOS_STATUS

pass_failure    PLP
                PLD
                PLB
                CLC
                RTL

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL
                .pend

;
; Convert the four digit BCD number in A to binary in A (16-bit)
;
BCD2BIN         .proc
                PHB
                PHD
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                ; Put the 1s digit into DOS_TEMP+2

                setaxl
                STA DOS_TEMP
                AND #$000F
                STA DOS_TEMP+2

                ; Add the 10s digit * 10 to DOS_TEMP+2

                LDA DOS_TEMP
                .rept 4
                LSR A
                .next
                STA DOS_TEMP

                AND #$000F
                STA @l UNSIGNED_MULT_A_LO
                LDA #10
                STA @l UNSIGNED_MULT_B_LO
                LDA @l UNSIGNED_MULT_AL_LO

                CLC
                ADC DOS_TEMP+2
                STA DOS_TEMP+2

                ; Add the 100s digit * 100 to DOS_TEMP+2

                LDA DOS_TEMP
                .rept 4
                LSR A
                .next
                STA DOS_TEMP

                AND #$000F
                STA @l UNSIGNED_MULT_A_LO
                LDA #100
                STA @l UNSIGNED_MULT_B_LO
                LDA @l UNSIGNED_MULT_AL_LO

                CLC
                ADC DOS_TEMP+2
                STA DOS_TEMP+2

                ; Add the 1000s digit * 1000 to A

                LDA DOS_TEMP
                .rept 4
                LSR A
                .next

                AND #$000F
                STA @l UNSIGNED_MULT_A_LO
                LDA #1000
                STA @l UNSIGNED_MULT_B_LO
                LDA @l UNSIGNED_MULT_AL_LO

                CLC
                ADC DOS_TEMP+2

                PLP
                PLD
                PLB
                RTL
                .pend

;
; Set the CREATION date-time of a file descriptor from the real time clock
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor to update
;
DOS_RTCCREATE   .proc
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setxl
                setas
                LDA @l RTC_CTRL             ; Turn off the updates to the clock 
                ORA #%00001000
                STA @l RTC_CTRL

                ;
                ; First... set the creation date
                ;

                ; Get the current year
                LDA @l RTC_CENTURY
                STA DOS_TEMP+1
                LDA @l RTC_YEAR             ; Get the year
                STA DOS_TEMP

                setal
                LDA DOS_TEMP
                JSL BCD2BIN                 ; Convert it to binary
                STA DOS_TEMP

                SEC                         ; Year is relative to 1980
                SBC #1980
                
                setal                
                .rept 9                     ; Move the year to bits 15 - 9
                ASL A
                .next
                AND #$FE00

                LDY #FILEDESC.CREATE_DATE   ; And save it to the creation date field
                STA [DOS_FD_PTR],Y

                ; Get the current month
                setas
                LDA @l RTC_MONTH            ; Get the month
                setal
                AND #$00FF
                JSL BCD2BIN                 ; Convert it to binary
                AND #$00FF                  ; Move the year to bits 15 - 9
                .rept 5
                ASL A
                .next
                AND #$01E0                  ; Make sure only the month is covered

                LDY #FILEDESC.CREATE_DATE   ; And save it to the creation date field
                ORA [DOS_FD_PTR],Y
                STA [DOS_FD_PTR],Y

                ; Get the current day
                setas
                LDA @l RTC_DAY              ; Get the day
                setal
                AND #$00FF
                JSL BCD2BIN                 ; Convert it to binary
                AND #$001F                  ; Make sure only the day is covered

                LDY #FILEDESC.CREATE_DATE   ; And save it to the creation date field
                ORA [DOS_FD_PTR],Y
                STA [DOS_FD_PTR],Y

                ;
                ; Next... set the creation time
                ;

                ; Get the current hour
                setas
                LDA @l RTC_HRS              ; Get the hour
                AND #$1F                    ; Trim AM/PM bit
                setal
                AND #$00FF
                JSL BCD2BIN                 ; Convert it to binary

                setal
                .rept 11                    ; Move the hour to bits 15 - 11
                ASL A
                .next
                AND #$F800

                LDY #FILEDESC.CREATE_TIME   ; And save it to the creation time field
                STA [DOS_FD_PTR],Y

                ; Get the current minute
                setas
                LDA @l RTC_MIN              ; Get the minute
                setal
                AND #$00FF
                JSL BCD2BIN                 ; Convert it to binary

                setal
                .rept 5                     ; Move the hour to bits 10 - 5
                ASL A
                .next
                AND #$07E0

                LDY #FILEDESC.CREATE_TIME   ; And save it to the creation time field
                ORA [DOS_FD_PTR],Y
                STA [DOS_FD_PTR],Y

                ; Get the current second
                setas
                LDA @l RTC_SEC              ; Get the second
                setal
                AND #$00FF
                JSL BCD2BIN                 ; Convert it to binary

                setal
                AND #$001F

                LDY #FILEDESC.CREATE_TIME   ; And save it to the creation time field
                ORA [DOS_FD_PTR],Y
                STA [DOS_FD_PTR],Y

                LDA @l RTC_CTRL             ; Turn on the updates again
                AND #%11110111
                STA @l RTC_CTRL

                PLP
                PLD
                PLB
                RTL
                .pend

;
; Create a file on the selected block device and write its first cluster
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor describing the file to create
;
; Outputs:
;   DOS_CLUS_ID = ID of the first cluster of the file
;   DOS_STATUS = the status code for the operation
;   C = set if there is a next cluster, clear if there isn't
;
DOS_CREATE      .proc
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                TRACE "DOS_CREATE"

                setaxl
                LDY #FILEDESC.PATH              ; DOS_TEMP := DOS_FD_PTR->PATH
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP+2

                setas
                LDY #0
                LDX #0
path_loop       LDA [DOS_TEMP],Y                ; Get a byte of the path
                STA DOS_PATH_BUFF,X             ; ... save it to the path buffer
                BEQ find_file                   ; If it's NULL, we're done
                INX
                INY
                BRA path_loop

                ; Attempt to find the file
find_file       JSL DOS_PARSE_PATH
                JSL DOS_FINDFILE
                BCC set_device

                setas
                LDA #DOS_ERR_FILEEXISTS
                BRL ret_failure

set_device      setas
                LDY #FILEDESC.DEV               ; Set the device in the file descriptor
                LDA BIOS_DEV
                STA [DOS_FD_PTR],Y

                ; Validate there is a file name

validate_name   ; Get the next free cluster
                JSL DOS_FREECLUS
                BCS save_data
                BRL pass_failure

                ; Save the data to the new cluster
save_data       setal
                LDY #FILEDESC.FIRST_CLUSTER
                LDA DOS_CLUS_ID             ; DOS_FD_PTR->FIRST_CLUSTER := DOS_CLUS_ID
                STA [DOS_FD_PTR],Y
                INY
                INY
                LDA DOS_CLUS_ID+2
                STA [DOS_FD_PTR],Y

                LDY #FILEDESC.BUFFER        ; DOS_BUFF_PTR := DOS_FD_PTR->BUFFER
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR+2

                JSL DOS_PUTCLUSTER
                BCS find_dir

                ; Get the next free entry in the directory
find_dir        setal
                ; TODO: pass in the appropriate directory
                JSL DOS_DIRFINDFREE
                BCS set_entry

                setal
                LDY #FILEDESC.FIRST_CLUSTER     ; Failed to get the directory entry...
                LDA [DOS_FD_PTR],Y              ; DOS_CLUS_ID := DOS_FD_PTR->FIRST_CLUSTER
                STA DOS_CLUS_ID
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_CLUS_ID+2
                JSL DELCLUSTER32                ; Delete the cluster
                
                setas
                LDA #DOS_ERR_NODIR              ; Return that we couldn't read the directory
                BRL ret_failure

                ; Set the directory information
set_entry       setas
                LDY #0
                LDA #0                          ; NULL
copy_dir_loop   STA [DOS_DIR_PTR],Y             ; Save it to the directory cluster
                INY
                CPY #SIZE(DIRENTRY)
                BNE copy_dir_loop

                LDY #0
name_loop       LDA DOS_SHORT_NAME,Y            ; Copy the name over
                STA [DOS_DIR_PTR],Y
                INY
                CPY #11
                BNE name_loop

                setal
                LDY #FILEDESC.FIRST_CLUSTER     ; DOS_DIR_PTR->CLUSTER_L := DOS_FD_PTR->FIRST_CLUSTER[15..0]
                LDA [DOS_FD_PTR],Y
                LDY #DIRENTRY.CLUSTER_L
                STA [DOS_DIR_PTR],Y

                LDY #FILEDESC.FIRST_CLUSTER+2   ; DOS_DIR_PTR->CLUSTER_H := DOS_FD_PTR->FIRST_CLUSTER[31..16]
                LDA [DOS_FD_PTR],Y
                LDY #DIRENTRY.CLUSTER_H
                STA [DOS_DIR_PTR],Y

                LDY #FILEDESC.SIZE              ; DOS_DIR_PTR->SIZE := DOS_FD_PTR->SIZE
                LDA [DOS_FD_PTR],Y
                LDY #DIRENTRY.SIZE
                STA [DOS_DIR_PTR],Y
                LDY #FILEDESC.SIZE+2
                LDA [DOS_FD_PTR],Y
                LDY #DIRENTRY.SIZE+2
                STA [DOS_DIR_PTR],Y

                JSL DOS_RTCCREATE               ; Pull the creation date-time from the RTC

                LDY #FILEDESC.CREATE_DATE       ; DOS_DIR_PTR->CREATE_DATE := DOS_FD_PTR->CREATE_DATE
                LDA [DOS_FD_PTR],Y
                LDY #DIRENTRY.CREATE_DATE
                STA [DOS_DIR_PTR],Y
                LDY #DIRENTRY.MODIFIED_DATE     ; And DOS_DIR_PTR->MODIFIED_DATE
                STA [DOS_DIR_PTR],Y

                LDY #FILEDESC.CREATE_TIME       ; DOS_DIR_PTR->CREATE_TIME := DOS_FD_PTR->CREATE_TIME
                LDA [DOS_FD_PTR],Y
                LDY #DIRENTRY.CREATE_TIME
                STA [DOS_DIR_PTR],Y
                LDY #DIRENTRY.MODIFIED_TIME     ; And DOS_DIR_PTR->MODIFIED_TIME
                STA [DOS_DIR_PTR],Y


                ; Save the directory cluster back to the block device
                setal

                JSL DOS_DIRWRITE
                BCS ret_success
                BRA pass_failure

ret_failure     setas
                STA DOS_STATUS
pass_failure    PLP
                PLD
                PLB
                CLC
                RTL

ret_success     setas
                STZ DOS_STATUS
                PLP
                PLD
                PLB
                SEC
                RTL
                .pend

;
; Copy the path from the current file descriptor to the DOS_PATH_BUFF
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;
DOS_COPYPATH    .proc
                PHX
                PHY
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                LDA #0                  ; Set the DOS_PATH_BUFF to all zeros
                LDX #0
clr_loop        STA DOS_PATH_BUFF,X
                INX
                INX
                CPX #256
                BNE clr_loop

                LDA DOS_FD_PTR          ; Is the DOS_FD_PTR null?
                BNE get_path            ; No: attempt to fetch the path
                LDA DOS_FD_PTR+2
                BEQ done                ; Yes: return an empty buffer

get_path        LDY #FILEDESC.PATH      ; Get the path buffer
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP+2

                LDA DOS_TEMP            ; Is the path pointer NULL?
                BNE start_copy          ; No: start copying it
                LDA DOS_TEMP+2
                BEQ done                ; Yes: return an empty buffer

start_copy      setas                   ; Copy the path into the path buffer
                LDX #0
                LDY #0
loop            LDA [DOS_TEMP],Y
                STA DOS_PATH_BUFF,X
                BEQ done
                INX
                INY
                BNE loop

done            PLP
                PLD
                PLB
                PLY
                PLX
                RTL
                .pend

.databank 0