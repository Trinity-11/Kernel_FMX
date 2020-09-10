;;;
;;; Front end for the SimpleDOS kernel functions.
;;;
;;; SimpleDOS provides basic FAT support on the SDC.
;;; Eventually, it will support the IDE and floppy drive interfaces
;;; as well as hierarchical file systems.
;;;
;;; The code is broken up into three blocks:
;;;     sdos.asm -- The kernel calls providing top level access
;;;     sdos_fat.asm -- The routines to work with the FAT file system
;;;     sdos_bios.asm -- "BIOS" type low level, sector based access routines
;;;
;;; F_OPEN -- open a file for reading/writing/creating
;;; F_CREATE -- create a new file
;;; F_CLOSE -- close a file (make sure last cluster is written)
;;; F_WRITE -- write the current cluster to the file
;;; F_READ -- read the next cluster from the file
;;; F_DELETE -- delete a file / directory
;;; F_RENAME -- rename a file
;;; F_DIROPEN -- open a directory and seek the first directory entry
;;; F_DIRNEXT -- seek to the next directory of an open directory
;;; F_LOAD -- load a binary file into memory, supports multiple file formats
;;; F_SAVE -- save a block of memory to a file on a block device
;;; F_COPY -- Copy a file (can be from one drive to another or the same drive)
;;;

.dpage SDOS_VARIABLES
.databank `DOS_HIGH_VARIABLES

.include "sdos_fat.asm"

DOS_TEST        .proc
                PHB
                PHD
                PHP

                TRACE "DOS_TEST"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES     

                setaxl
                LDA #<>src_file
                STA @l DOS_STR1_PTR
                LDA #`src_file
                STA @l DOS_STR1_PTR+2

                LDA #<>dst_file
                STA @l DOS_STR2_PTR
                LDA #`dst_file
                STA @l DOS_STR2_PTR+2

                JSL IF_COPY
                BCS done

                TRACE "Could not copy file."

done            PLP
                PLD
                PLB
                RTL
src_file        .null "@s:hello.bas"
dst_file        .null "@s:hello2.bas"
                .pend

;
; IF_OPEN
;
; Open a file for reading or editting (R&W) a file.
; Given a file path and a mode (read and/or write) in the file descriptor
; Set up the rest of the file descriptor for processing.
; For read and write, the first cluster will be loaded into the cluster buffer provided
;
; Inputs:
;     DOS_FD_PTR = pointer to the file descriptor
;
; Outputs:
;     DOS_FD_PTR = pointer to the file descriptor
;
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_OPEN         .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                TRACE "IF_OPEN"

                setas
                LDY #FILEDESC.STATUS            ; Get the status to make sure a open is ok
                LDA [DOS_FD_PTR],Y
                BIT #FD_STAT_OPEN
                BEQ ok_to_open
                LDA #DOS_ERR_OPEN               ; If already open: throw an error
                BRL IF_FAILURE

ok_to_open      JSL DOS_COPYPATH                ; Copy the path to the path buffer
                JSL DOS_FINDFILE                ; Attempt to find the file
                BCS is_found                    ; If OK: we found the file
                BRL IF_PASSFAILURE              ; Otherwise: pass the failure up the chain

is_found        setas
                LDY #FILEDESC.DEV               ; Set the device in the file descriptor
                LDA BIOS_DEV
                STA [DOS_FD_PTR],Y
                
                setal
                LDY #FILEDESC.BUFFER            ; Set the buffer point to the one provided in the file
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR+2

                JSL DOS_GETCLUSTER              ; Attempt to load the cluster
                BCS read_cluster
                BRL IF_PASSFAILURE

read_cluster    LDY #FILEDESC.FIRST_CLUSTER     ; Set the first cluster in the file descriptor
                LDA DOS_CLUS_ID
                STA [DOS_FD_PTR],Y
                INY
                INY
                LDA DOS_CLUS_ID+2
                STA [DOS_FD_PTR],Y

                LDY #FILEDESC.CLUSTER           ; Set the current cluster in the file descriptor
                LDA DOS_CLUS_ID
                STA [DOS_FD_PTR],Y
                INY
                INY
                LDA DOS_CLUS_ID+2
                STA [DOS_FD_PTR],Y

                LDY #DIRENTRY.SIZE              ; Copy the filesize from the directory entry to the file descriptor
                LDA [DOS_DIR_PTR],Y
                LDY #FILEDESC.SIZE
                STA [DOS_FD_PTR],Y
                LDY #DIRENTRY.SIZE+2
                LDA [DOS_DIR_PTR],Y
                LDY #FILEDESC.SIZE+2
                STA [DOS_FD_PTR],Y

                setas
                LDY #FILEDESC.STATUS            ; Mark file as open and readable
                LDA #FD_STAT_OPEN | FD_STAT_READ
                ORA [DOS_FD_PTR],Y
                STA [DOS_FD_PTR],Y

                BRL IF_SUCCESS
                .pend

;
; IF_CREATE
;
; Open a file for creating. The file must not already exist, and clusters can only be appended.
;
; Inputs:
;     DOS_FD_PTR = pointer to the file descriptor
;
; Outputs:
;     DOS_FD_PTR = pointer to the file descriptor
;
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_CREATE       .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                JSL DOS_CREATE                  ; Attempt to create the file
                BCC pass_failure                ; If it fails: pass the failure up the chain

                setaxl
                LDY #FILEDESC.CLUSTER           ; Sets the current cluster to 0 to make sure the next write appends
                LDA #0
                STA [DOS_FD_PTR],Y
                INY
                INY
                STA [DOS_FD_PTR],Y

                setas
                LDY #FILEDESC.STATUS
                LDA #FD_STAT_OPEN | FD_STAT_WRITE   ; Set the file to open and APPEND only

                BRL IF_SUCCESS

pass_failure    BRL IF_FAILURE
                .pend

;
; IF_CLOSE
;
; Close a file descriptor that is open. This doesn't do anything to
; a read only file, but for create/append/write files, this will ensure
; the current cluster is saved back to the block device
;
; Note: if the file descriptor was allocated, it will be flagged as deallocated
;
; Inputs:
;     DOS_FD_PTR = pointer to the file descriptor
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_CLOSE        .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setas
                LDY #FILEDESC.STATUS            ; Check to see if we were writing the file
                LDA [DOS_FD_PTR],Y
                BIT #FD_STAT_WRITE
                BEQ set_flag                    ; No, just mark it closed

                JSL IF_WRITE                    ; Attempt to write the cluster
                BCS set_flag
                BRL IF_PASSFAILURE              ; If there was a problem, pass it up the chain

set_flag        JSL IF_FREEFD                   ; Free the file descriptor as well

                BRL IF_SUCCESS
                .pend

;
; IF_READ
;
; Read the next cluster from a file. This should only be called
; on read or write files... not append or create.
;
; Inputs:
;     DOS_FD_PTR = pointer to the file descriptor
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_READ         .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                TRACE "IF_READ"

                setxl
                setas

;                 LDY #FILEDESC.STATUS            ; Get the status to make sure a read is ok
;                 LDA [DOS_FD_PTR],Y

;                 BIT #FD_STAT_OPEN               ; Make sure the file is open
;                 BNE chk_readable
;                 LDA #DOS_ERR_NOTOPEN            ; If not: throw a NOTOPEN error
;                 BRL IF_FAILURE
            
; chk_readable    TRACE "chk_readable"
;                 setas
;                 BIT #FD_STAT_READ               ; Make sure the file is readable
;                 BNE get_dev
;                 LDA #DOS_ERR_NOTREAD            ; If not: throw a NOTREAD error
;                 BRL IF_FAILURE

get_dev         setas
                LDY #FILEDESC.DEV               ; Get the device number from the file descriptor
                LDA [DOS_FD_PTR],Y
                STA BIOS_DEV

                JSL DOS_MOUNT                   ; Make sure the device is mounted (if needed)

                setal
                LDY #FILEDESC.CLUSTER           ; Get the file's current cluster
                LDA [DOS_FD_PTR],Y
                STA DOS_CLUS_ID
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_CLUS_ID+2

                JSL NEXTCLUSTER                 ; Find the next cluster of the file
                BCC pass_failure                ; If not OK: pass the failure up the chain

                LDY #FILEDESC.BUFFER            ; Get the pointer to the file's cluster buffer
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR+2
                
                JSL DOS_GETCLUSTER              ; Get the cluster
                BCS ret_success                 ; If ok: return success
pass_failure    TRACE "IF_READ FAIL"
                BRL IF_PASSFAILURE              ; Otherwise: bubble up the failure

ret_success     LDY #FILEDESC.CLUSTER           ; Save the new cluster as the file's current cluster
                LDA DOS_CLUS_ID
                STA [DOS_FD_PTR],Y
                INY
                INY
                LDA DOS_CLUS_ID+2
                STA [DOS_FD_PTR],Y
                
                BRL IF_SUCCESS
                .pend

;
; IF_WRITE
;
; Write the current cluster to the file.
;
; If the file is WRITE only, the cluster will be added to the end of the file.
; If the file is READ & WRITE, the will be appended only if the CLUSTER number is 0.
;
; Inputs:
;     DOS_FD_PTR = pointer to the file descriptor
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_WRITE        .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                TRACE "IF_WRITE"

                setxl
                setas

;                 LDY #FILEDESC.STATUS            ; Get the status to make sure a read is ok
;                 LDA [DOS_FD_PTR],Y

;                 BIT #FD_STAT_OPEN               ; Make sure the file is open
;                 BNE chk_writeable
;                 LDA #DOS_ERR_NOTOPEN            ; If not: throw a NOTOPEN error
;                 BRL IF_FAILURE
            
; chk_writeable   BIT #FD_STAT_WRITE              ; Make sure the file is WRITE
;                 BNE get_dev
;                 LDA #DOS_ERR_NOTWRITE           ; If not: throw a NOTWRITE error
;                 BRL IF_FAILURE

get_dev         LDY #FILEDESC.DEV               ; Get the device number from the file descriptor
                LDA [DOS_FD_PTR],Y
                STA BIOS_DEV

                JSL DOS_MOUNT                   ; Make sure the device is mounted (if needed)

                setal
                LDY #FILEDESC.BUFFER            ; Get the pointer to the file's cluster buffer
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_BUFF_PTR+2

                LDY #FILEDESC.CLUSTER           ; Get the file's current cluster
                LDA [DOS_FD_PTR],Y
                STA DOS_CLUS_ID
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_CLUS_ID+2

                BNE rewrite_cluster             ; If the cluster ID <> 0, overwrite it
                LDA DOS_CLUS_ID
                BNE rewrite_cluster

                LDY #FILEDESC.FIRST_CLUSTER     ; Get the file's first cluster
                LDA [DOS_FD_PTR],Y
                STA DOS_CLUS_ID
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_CLUS_ID+2

                JSL DOS_APPENDCLUS              ; Append the cluster
                BCS ret_success                 ; If OK: return success
                BRL IF_PASSFAILURE              ; Otherwise: bubble up the failure
                
rewrite_cluster JSL DOS_PUTCLUSTER              ; Over-write the cluster
                BCS ret_success                 ; If ok: return success
pass_failure    BRL IF_PASSFAILURE              ; Otherwise: bubble up the failure

ret_success     BRL IF_SUCCESS
                .pend

;
; IF_DIROPEN
;
; Open a directory and seek the first entry.
;
; NOTE: at the moment, this only supports reading the root directory of the SDC.
;       Support for subdirectories and other block devices will come later.
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;
; Outputs:
;   DOS_FD_PTR = pointer to the file descriptor
;   DOS_DIR_PTR = pointer to the current directory entry
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_DIROPEN      .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                TRACE "IF_DIROPEN"

                setaxl
                JSL DOS_COPYPATH            ; Copy the path from the file descriptor to the path buffer
                JSL DOS_PARSE_PATH          ; Parse the path

                JSL DOS_MOUNT               ; Make sure we've mounted the SDC.
                BCS get_root_dir            ; If successful: get the root directory
                BRL IF_PASSFAILURE          ; Otherwise: pass the error up the chain

get_root_dir    setaxl
                JSL DOS_DIROPEN
                BCS success
                BRL IF_PASSFAILURE
success         BRL IF_SUCCESS
                .pend

;
; IF_DIRNEXT
;
; Get the next directory entry, reading the next cluster, if necessary.
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;   DOS_DIR_PTR = pointer to the current directory entry.
;
; Outputs:
;   DOS_FD_PTR = pointer to the file descriptor
;   DOS_DIR_PTR = pointer to the current directory entry
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_DIRNEXT      .proc
                JML DOS_DIRNEXT
                .pend

;
; IF_DELETE
;
; Delete a file from the block device.
;
; Inputs:
;   DOS_PATH_BUFF = a buffer containing the full path to the file (NULL terminated)
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_DELETE       .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                TRACE "IF_DELETE"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl

                ; Find the file on the block device
                JSL DOS_FINDFILE

                BCS get_first_clus
                BRL IF_PASSFAILURE

get_first_clus  ; Get the first cluster of the file
                LDY #DIRENTRY.CLUSTER_L
                LDA [DOS_DIR_PTR],Y
                STA DOS_CLUS_ID
                LDY #DIRENTRY.CLUSTER_H
                LDA [DOS_DIR_PTR],Y
                STA DOS_CLUS_ID+2

                ; Save the current cluster ID
                LDA DOS_CLUS_ID
                STA DOS_CURR_CLUS
                LDA DOS_CLUS_ID+2
                STA DOS_CURR_CLUS+2

                ; Get the next cluster ID
del_loop        JSL NEXTCLUSTER
                BCC del_one

                ; Save the next cluster ID
                LDA DOS_CLUS_ID
                STA DOS_NEXT_CLUS
                LDA DOS_CLUS_ID+2
                STA DOS_NEXT_CLUS+2

                ; Restore the current cluster ID
                LDA DOS_CURR_CLUS
                STA DOS_CLUS_ID
                LDA DOS_CURR_CLUS+2
                STA DOS_CLUS_ID+2

                ; Delete the current cluster
                JSL DELCLUSTER32
                BCS go_next
                BRL IF_PASSFAILURE

go_next         ; Restore the next cluster ID as the current cluster
                LDA DOS_NEXT_CLUS
                STA DOS_CLUS_ID
                STA DOS_CURR_CLUS
                LDA DOS_NEXT_CLUS+2
                STA DOS_CLUS_ID+2
                STA DOS_CURR_CLUS+2

                BRA del_loop

del_one         ; Restore the current cluster ID
                LDA DOS_CURR_CLUS
                STA DOS_CLUS_ID
                LDA DOS_CURR_CLUS+2
                STA DOS_CLUS_ID+2

                ; Delete the current cluster
                JSL DELCLUSTER
                BCS free_dir_entry
                BRL IF_PASSFAILURE

                ; Flag the directory entry as deleted
free_dir_entry  TRACE "free_dir_entry"
                setas
                LDY #DIRENTRY.SHORTNAME         ; Flag the directory entry as deleted
                LDA #DOS_DIR_ENT_UNUSED
                STA [DOS_DIR_PTR],Y

                JSL DOS_DIRWRITE                ; Write the directory entry back
                BCS ret_success
                BRL IF_PASSFAILURE

ret_success     BRL IF_SUCCESS
                .pend

;
; IF_DIRREAD
;
; Find the directory entry for a given path
;
; Inputs:
;   DOS_PATH_BUFF = path to the directory entry desired
;
; Outputs:
;   DOS_DIR_PTR = pointer to the directory entry
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_DIRREAD      .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl

                JSL DOS_FINDFILE
                BCS success
                BRL IF_FAILURE

success         BRL IF_SUCCESS
                .pend

;
; IF_DIRWRITE
;
; Update the current directory entry
;
; NOT IMPLEMENTED
;
; Inputs:
;   DOS_DIR_PTR = pointer to the updated directory entry
;   DOS_DIR_CLUS = the cluster ID of the directory entry
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_DIRWRITE     .proc
                JML DOS_DIRWRITE
                .pend

; IF_LOAD
;
; Load a binary file into memory.
;
; Multiple binary formats are supported. For those file types including a load address,
; the address provided by the file itself will be used. If a destination address is provided
; that maps to system RAM, then file will load using that destination address. Otherwise,
; the source file must provide the destination address.
;
; Formats to be supported:
;   PGX -- First four bytes contain the loading address
;   FNX -- multi-segmented file format with multiple addresses
;   BIN -- Generic binary requiring a destination address
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;   DOS_DST_PTR = pointer to the location to load the file (if relevant)
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_LOAD         .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                TRACE "IF_LOAD"

                setaxl

                ; Open the file
                JSL IF_OPEN
                BCS setup                   ; If success: start setting things up
                BRL IF_PASSFAILURE          ; Otherwise: pass the failure up the chain

setup           setal
                LDY #FILEDESC.SIZE          ; Record the size of the file in DOS_FILE_SIZE
                LDA [DOS_FD_PTR],Y
                STA DOS_FILE_SIZE
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_FILE_SIZE+2

                LDY #FILEDESC.BUFFER        ; Set up the source pointer
                LDA [DOS_FD_PTR],Y
                STA DOS_SRC_PTR
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_SRC_PTR+2

                LDA DOS_DST_PTR+2           ; Is there a destination address in RAM?
                CMP #$0040
                BGE load_by_type            ; No: try to load it by type
                JML IF_LOADRAW              ; Otherwise, load it to the supplied destination

                ; Dispatch to correct loader based on file type

load_by_type    LDY #8                      ; Point to the first extension byte
                LDX #0                      ; and the first byte of the table

type_loop       setas
                LDA LOAD_TYPE_TABLE,X       ; Get 1st extension character of the entry
                BEQ no_match                ; If NULL... we didn't get a match
                CMP DOS_SHORT_NAME,Y        ; Get the character of the extension
                BNE next_entry              ; If they don't match, try the next entry

                LDA LOAD_TYPE_TABLE+1,X     ; Get 2nd extension character of the entry
                CMP DOS_SHORT_NAME+1,Y      ; Get the 2nd character of the extension
                BNE next_entry              ; If they don't match, try the next entry

                LDA LOAD_TYPE_TABLE+2,X     ; Get 3rd extension character of the entry
                CMP DOS_SHORT_NAME+2,Y      ; Get the 3rd character of the extension
                BNE next_entry              ; If they don't match, try the next entry

                setal
                LDA LOAD_TYPE_TABLE+3,X     ; Get the low word of the address
                STA DOS_TEMP                ; Save it to the jump vector
                setas
                LDA LOAD_TYPE_TABLE+5,X     ; Get the high byte of the address
                STA DOS_TEMP+2              ; Save it to the jump vector

                LDX #0
                JML [DOS_TEMP]              ; Jump to the loading routine

next_entry      setaxl                      ; Move to the next entry in the table
                TXA
                CLC
                ADC #6
                TAX
                BRA type_loop               ; And check it against the file

no_match        setas
                LDA #DOS_ERR_NOEXEC         ; Return an not-executable error
                BRL IF_FAILURE
                .pend

; A table to map file extensions to the address of the routine to open it
; The routines should assume that the file has already been opened and the
; first cluster has been read.
; DOS_SRC_PTR will point to the cluster
; DOS_FD_PTR will point to the file descriptor.
;
; Table format: the three characters of the extension, followed by three bytes
; for the routine's address in low-endian order. Table is ended by a NULL
; instead of the first character
LOAD_TYPE_TABLE .text "PGX"                 ; "PGX" --> IF_LOADPGX
                .word <>IF_LOADPGX
                .byte `IF_LOADPGX
                .byte 0

; IF_LOADPGX
;
; Load a PGX file into memory.
;
; PGX is a simple binary file format with a targeted loading address:
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
; |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  | ... |  N  |
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
; | "P" | "G" | "X" | cpu |        ADDRESS        | DB0 + ... | DBn |
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor (already open)
;   DOS_SRC_PTR = pointer to the in-memory copy of the current cluster
;
; Outputs:
;   DOS_RUN_PTR = pointer to the first byte loaded
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_LOADPGX      .proc
                ; The usual PH* and other preamble instructions are handled by IF_LOAD

                setxl
                setas

                LDY #0

                ; Verify signature and CPU
                LDA [DOS_SRC_PTR],Y                 ; Check for "PGX" signature
                CMP #'P'
                BNE fail_sig                        ; If not found, fail

                INY
                LDA [DOS_SRC_PTR],Y
                CMP #'G'
                BNE fail_sig

                INY
                LDA [DOS_SRC_PTR],Y
                CMP #'X'
                BNE fail_sig

                INY                                 ; Check for CPU and version code ($01 for 65816)
                LDA [DOS_SRC_PTR],Y
                CMP #$01
                BEQ get_dest                        ; All passes: go to get the destination address

fail_sig        LDA #DOS_ERR_PGXSIG                 ; Fail with a PGXSIG error code
                JSL IF_FAILURE

adjust_size     setal
                SEC                                 ; Subtract the 8 bytes of the header from the file size
                LDA DOS_FILE_SIZE
                SBC #8
                STA DOS_FILE_SIZE
                LDA DOS_FILE_SIZE+2
                SBC #0
                STA DOS_FILE_SIZE+2

                ; Read destination address from the file
get_dest        setal
                INY
                LDA [DOS_SRC_PTR],Y                 ; Get low word of destination address
                STA DOS_DST_PTR                     ; And save it to the destination pointer
                STA DOS_RUN_PTR                     ; And save it to the RUN pointer
                INY
                INY
                LDA [DOS_SRC_PTR],Y                 ; Get high word of destination address
                STA DOS_DST_PTR+2
                STA DOS_RUN_PTR+2

                INY                                 ; Point to the first data byte
                INY

copy_loop       setas
                LDA [DOS_SRC_PTR],Y                 ; Read a byte from the file
                STA [DOS_DST_PTR]                   ; Write it to the destination
                
                setal
                INC DOS_DST_PTR                     ; Move to the next destination location
                BNE dec_file_size
                INC DOS_DST_PTR+2

dec_file_size   SEC                                 ; Count down the number of bytes to read
                LDA DOS_FILE_SIZE
                SBC #1
                STA DOS_FILE_SIZE
                LDA DOS_FILE_SIZE+2
                SBC #0
                STA DOS_FILE_SIZE+2

                LDA DOS_FILE_SIZE                   ; Are we at the end of the file?
                BNE next_byte
                LDA DOS_FILE_SIZE+2
                BEQ done                            ; Yes: we're done
                
next_byte       INY                                 ; Otherwise, move to the next source location
                CPY CLUSTER_SIZE                    ; Are we at the end of the cluster?
                BNE copy_loop                       ; No: keep copying

                JSL DOS_READNEXT                    ; Yes: Load the next cluster
                BCS next_cluster
                BRL IF_PASSFAILURE                  ; If failed: pass that up the chain

next_cluster    LDY #0
                BRA copy_loop                       ; Go back to copying

done            BRL IF_SUCCESS
                .pend

; IF_LOADRAW
;
; Load a binary file into memory at the specified location
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;   DOS_DST_PTR = pointer to the location to load the file (if relevant)
;   DOS_SRC_PTR = pointer to the cluster buffer for this file
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_LOADRAW      .proc
                ; The usual PH* and other preamble instructions are handled by IF_LOAD

                TRACE "IF_LOADRAW"

                setaxl

copy_cluster    LDY #0
copy_loop       setas
                LDA [DOS_SRC_PTR],Y         ; Copy byte from cluster to destination
                STA [DOS_DST_PTR],Y

                setal
                SEC                         ; Count down the number of bytes left
                LDA DOS_FILE_SIZE
                SBC #1
                STA DOS_FILE_SIZE
                LDA DOS_FILE_SIZE+2
                SBC #0
                STA DOS_FILE_SIZE+2

                ; Do we have more bytes to read?
                BNE continue
                LDA DOS_FILE_SIZE
                BEQ close_file              ; If not: we're done

continue        INY
                CPY CLUSTER_SIZE            ; Are we done with the cluster?
                BNE copy_loop               ; No: keep processing the bytes

                CLC                         ; Advance the destination pointer to the next chunk of memory
                LDA DOS_DST_PTR
                ADC CLUSTER_SIZE
                STA DOS_DST_PTR
                LDA DOS_DST_PTR+2
                ADC #0
                STA DOS_DST_PTR+2

                JSL IF_READ                 ; Yes: load the next cluster
                BCS copy_cluster            ; And start copying it

close_file      ; JSL IF_CLOSE                ; Close the file
                ; BCS ret_success             ; If success: we're done
                ; BRL IF_PASSFAILURE          ; Otherwise: pass the failure up the chain

ret_success     BRL IF_SUCCESS
                .pend

;
; Clear the buffer of the file descriptor
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;
IF_NULLBUFFER   .proc
                PHY
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                LDY #FILEDESC.BUFFER
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP+2

                LDY #0
                LDA #0
loop            STA [DOS_TEMP],Y
                INY
                INY
                CPY #DOS_SECTOR_SIZE
                BNE loop

                PLP
                PLD
                PLB
                PLY
                RTL
                .pend

;
; Copy at most 512 bytes from DOS_SRC_PTR to the buffer in DOS_FD_PTR
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;   DOS_SRC_PTR = pointer to the location to of the data to save
;   DOS_END_PTR = pointer to the last byte to send
;
IF_COPY2BUFF    .proc
                PHY
                PHB
                PHD
                PHP

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                LDY #FILEDESC.BUFFER
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP
                INY
                INY
                LDA [DOS_FD_PTR],Y
                STA DOS_TEMP+2

                LDY #0
copy_loop       setas
                LDA [DOS_SRC_PTR]           ; Copy a byte
                STA [DOS_TEMP],Y
                setal

                INC DOS_SRC_PTR             ; Advance the source pointer
                BNE adv_dest
                INC DOS_SRC_PTR+2

adv_dest        INY                         ; Count it
                CPY #DOS_SECTOR_SIZE        ; Have we reached the limit?
                BEQ done                    ; Yes: we're done

                LDA DOS_SRC_PTR             ; Check if we copied the last byte
                CMP DOS_END_PTR
                BNE copy_loop               ; No: keep copying
                LDA DOS_SRC_PTR+2
                CMP DOS_END_PTR+2
                BNE copy_loop

done            PLP
                PLD
                PLB
                PLY
                RTL
                .pend

; IF_SAVE
;
; Save a block of memory to a file.
;
; NOT IMPLEMENTED
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor
;   DOS_SRC_PTR = pointer to the location to of the data to save
;   DOS_END_PTR = pointer to the last byte to send
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_SAVE         .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                TRACE "IF_SAVE"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setaxl
                LDY #FILEDESC.SIZE      ; DOS_FD_PTR->SIZE := DOS_END_PTR - DOS_SRC_PTR
                SEC
                LDA DOS_END_PTR
                SBC DOS_SRC_PTR
                STA [DOS_FD_PTR],Y
                INY
                INY
                LDA DOS_END_PTR+2
                SBC DOS_SRC_PTR+2
                STA [DOS_FD_PTR],Y

                LDY #FILEDESC.SIZE      ; DOS_FD_PTR->SIZE++
                CLC
                LDA [DOS_FD_PTR],Y
                ADC #1
                STA [DOS_FD_PTR],Y
                BCC first_block
                INY
                INY
                LDA [DOS_FD_PTR],Y
                ADC #0
                STA [DOS_FD_PTR],Y

first_block     JSL IF_NULLBUFFER       ; Fill FD buffer with NULL
                JSL IF_COPY2BUFF        ; Copy first (at most) 512 bytes of data to FD buffer
                JSL IF_CREATE           ; Create file.
                BCS check_for_end
                BRL IF_PASSFAILURE      ; If we couldn't create the file, pass the failure up

check_for_end   LDA DOS_SRC_PTR         ; Check if we copied the last byte
                CMP DOS_END_PTR
                BNE next_block
                LDA DOS_SRC_PTR+2
                CMP DOS_END_PTR+2
                BEQ done                ; Yes: we're done

next_block      JSL IF_NULLBUFFER       ; Fill FD buffer with NULL
                JSL IF_COPY2BUFF        ; Copy next (at most) 512 bytes of data to FD buffer
          
                LDY #FILEDESC.CLUSTER   ; Make sure the CLUSTER is 0 to force an append
                LDA #0
                STA [DOS_FD_PTR],Y
                INY
                INY
                STA [DOS_FD_PTR],Y

                JSL IF_WRITE            ; Append to the file
                BCS check_for_end       ; And try again
                BRL IF_PASSFAILURE      ; If we couldn't update the file, pass the failure up

done            JML IF_SUCCESS
                .pend

;
; Return or pass FAILURE from the F_* functions
;
IF_FAILURE      setas
                STA DOS_STATUS
IF_PASSFAILURE  PLP
                CLC
                PLB
                PLD
                PLY
                PLX
                RTL 

;
; Return SUCCESS from the F_* functions
;
IF_SUCCESS      setas
                STZ BIOS_STATUS
                STZ DOS_STATUS
                PLP
                SEC
                PLB
                PLD
                PLY
                PLX
                RTL  

;
; Load and run an executable binary file
;
; Inputs:
;   DOS_RUN_PARAMS = pointer to the path an parameters to execute
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_RUN          .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                TRACE "IF_RUN"

                setdbr 0
                setdp SDOS_VARIABLES

                setas
                setxl
                LDA #0                                  ; Zero out the file descriptor
                LDX #0
clr_fd_loop     STA @l DOS_SPARE_FD,X
                INX
                CPX #SIZE(FILEDESC)
                BNE clr_fd_loop

                setal
                LDA #<>DOS_SPARE_SECTOR                 ; Set the buffer for the file descriptor
                STA @l DOS_SPARE_FD+FILEDESC.BUFFER
                LDA #`DOS_SPARE_SECTOR
                STA @l DOS_SPARE_FD+FILEDESC.BUFFER+2

                LDA DOS_RUN_PARAM                        ; Set the path for the file descriptor
                STA @l DOS_SPARE_FD+FILEDESC.PATH
                LDA DOS_RUN_PARAM+2
                STA @l DOS_SPARE_FD+FILEDESC.PATH+2

                LDA #0                                  ; Clear the run pointer
                STA DOS_RUN_PTR                         ; This is used to check that we loaded an executable binary
                STA DOS_RUN_PTR+2

                LDA #<>DOS_SPARE_FD
                STA DOS_FD_PTR
                LDA #`DOS_SPARE_FD
                STA DOS_FD_PTR+2

                LDA #$FFFF                              ; We want to load to the address provided by the file
                STA @l DOS_DST_PTR
                STA @l DOS_DST_PTR+2

                JSL F_LOAD                              ; Try to load the file
                BCS try_execute
                BRL IF_PASSFAILURE                      ; On error: pass failure up the chain

chk_execute     setal
                LDA DOS_RUN_PTR                         ; Check to see if we got a startup address back
                BNE try_execute                         ; If so: call it
                LDA DOS_RUN_PTR+2
                BNE try_execute

                setas
                LDA #DOS_ERR_NOEXEC                     ; If not: return an error that it's not executable
                BRL IF_FAILURE

try_execute     setas
                LDA #$5C                                ; Write a JML opcode
                STA DOS_RUN_PTR-1

                JSL DOS_RUN_PTR-1                       ; And call to it
                BRL IF_SUCCESS                          ; Return success
                .pend

;
; Allocate a file descriptor for a program to use from the pool of file descriptors
;
; Outputs:
;   DOS_FD_PTR = pointer to the allocated file descriptor
;   DOS_STATUS = the status code for the operation
;   C = set if there is a next cluster, clear if there isn't
;
IF_ALLOCFD      .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                TRACE "IF_ALLOCFD"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setxl
                LDX #0                              ; Point to the first file descriptor

chk_fd          setas
                LDA @w DOS_FILE_DESCS,X             ; Check the file descriptor's status
                BIT #FD_STAT_ALLOC                  ; Is the file descriptor allocated?
                BEQ found                           ; No: flag and return the found descriptor
                
next_fd         setal
                TXA                                 ; Yes: Move to the next file descriptor
                CLC
                ADC #SIZE(FILEDESC)
                TAX
                CPX #SIZE(FILEDESC) * DOS_FD_MAX    ; Are we out of file descriptors?
                BLT chk_fd                          ; No: check this new file descriptor

                setas
                LDA #DOS_ERR_NOFD                   ; Yes: Return failure (no file descriptors available)
                BRL IF_FAILURE

found           ORA #FD_STAT_ALLOC                  ; No: Set the ALLOC bit
                STA @w DOS_FILE_DESCS,X             ; And store it in the file descriptor's status

                setal
                TXA
                CLC
                ADC #<>DOS_FILE_DESCS
                STA @b DOS_FD_PTR
                LDA #`DOS_FILE_DESCS
                ADC #0
                STA @b DOS_FD_PTR+2

                BRL IF_SUCCESS                      ; Return this file descriptor
                .pend

;
; Deallocate a file descriptor
;
; Inputs:
;   DOS_FD_PTR = pointer to the file descriptor to return to the pool
;
IF_FREEFD       .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                TRACE "IF_FREEFD"

                setdbr `DOS_HIGH_VARIABLES
                setdp SDOS_VARIABLES

                setas
                setxl

                LDA #0
                STA [DOS_FD_PTR]

                BRL IF_SUCCESS
                .pend

;
; Copy the bytes from the source file descriptor's sector to the destination descriptor's sector buffer
;
; Note: this routine assumes that both sector buffers are in the DOS_FILE_BUFFS block
;
; Inputs:
;   DOS_SRC_PTR = the pointer to the source file descriptor
;   DOS_DST_PTR = the pointer to the destination file descriptor
;
DOS_SRC2DST     .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                TRACE "DOS_SRC2DST"

                setdp SDOS_VARIABLES
                setaxl

                LDY #FILEDESC.BUFFER
                LDA [DOS_SRC_PTR],Y
                TAX                                     ; X := source buffer address

                LDA [DOS_DST_PTR],Y
                TAY                                     ; Y := destination buffer address

                LDA #DOS_SECTOR_SIZE                    ; A := the size of the buffers
                MVN #`DOS_FILE_BUFFS,#`DOS_FILE_BUFFS   ; Copy the sector data

                PLP
                PLB
                PLD
                PLY
                PLX
                RTL
                .pend

;
; Copy a file (can be from one drive to another or the same drive)
;
; NOTE: It is an error if the destination file already exists.
;
; Inputs:
;   DOS_STR1_PTR = pointer to the ASCIIZ path of the existing file (source)
;   DOS_STR2_PTR = pointer to the ASCIIZ path for the new file (destination)
;
; Outputs:
;   DOS_STATUS = status code for any DOS-related errors (0 = fine)
;   BIOS_STATUS = status code for any BIOS-related errors (0 = fine)
;   C = set if success, clear on error
;
IF_COPY         .proc
                PHX
                PHY
                PHD
                PHB
                PHP

                TRACE "IF_COPY"

                setdbr 0
                setdp SDOS_VARIABLES

                JSL IF_ALLOCFD                  ; Allocate an FD for the source
                BCS set_src_path
                BRL IF_PASSFAILURE              ; If failed: pass the failure up the chain

set_src_path    setaxl
                LDY #FILEDESC.PATH              ; Set the source path
                LDA @b DOS_STR1_PTR
                STA [DOS_FD_PTR],Y
                INY
                INY
                LDA @b DOS_STR1_PTR+2
                STA [DOS_FD_PTR],Y

alloc_dest      setaxl
                LDA @b DOS_FD_PTR               ; set DOS_SRC_PTR to the file descriptor pointer
                STA @b DOS_SRC_PTR
                LDA @b DOS_FD_PTR+2
                STA @b DOS_SRC_PTR+2

                JSL IF_ALLOCFD                  ; Allocate an FD for the destination
                BCS set_paths                   ; If everything is ok... start setting the paths

err_free_src_fd LDA @b DOS_SRC_PTR              ; Get the source file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_SRC_PTR+2
                STA @b DOS_FD_PTR+2
                JSL IF_FREEFD                   ; And free it
                BRL IF_PASSFAILURE              ; Pass the failure up the chain

set_paths       setaxl
                LDA @b DOS_FD_PTR               ; Set DOS_DST_PTR to the file descriptor pointer for the destination
                STA @b DOS_DST_PTR
                LDA @b DOS_FD_PTR+2
                STA @b DOS_DST_PTR+2

                LDY #FILEDESC.PATH              ; Set the destination path
                LDA @b DOS_STR2_PTR
                STA [DOS_DST_PTR],Y
                INY
                INY
                LDA @b DOS_STR2_PTR+2
                STA [DOS_DST_PTR],Y

                LDA @b DOS_SRC_PTR              ; Get the source file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_SRC_PTR+2
                STA @b DOS_FD_PTR+2
                JSL F_OPEN                      ; Try to open the file
                BCS src_open                    ; If success, work with the openned file

err_free_dst_fd LDA @b DOS_DST_PTR              ; Get the destination file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_DST_PTR+2
                STA @b DOS_FD_PTR+2
                JSL IF_FREEFD                   ; And free it
                BRL err_free_src_fd             ; Free the source file descriptor

src_open        LDY #FILEDESC.SIZE              ; destination file size := source file size
                LDA [DOS_SRC_PTR],Y
                STA [DOS_DST_PTR],Y
                INY
                INY
                LDA [DOS_SRC_PTR],Y
                STA [DOS_DST_PTR],Y

                JSL DOS_SRC2DST                 ; Copy the first sector's worth of data

                LDA @b DOS_DST_PTR              ; Get the destination file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_DST_PTR+2
                STA @b DOS_FD_PTR+2 
                JSL F_CREATE                    ; Attempt to create the file
                BCS read_next                   ; If sucessful, try to get the next cluster

err_src_close   LDA @b DOS_SRC_PTR              ; Get the source file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_SRC_PTR+2
                STA @b DOS_FD_PTR+2
                JSL F_CLOSE                     ; Close the source file (maybe not really necessary)
                BRL err_free_dst_fd             ; Free the file descriptors and return an error

read_next       TRACE "read_next"
                LDA @b DOS_SRC_PTR              ; Get the source file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_SRC_PTR+2
                STA @b DOS_FD_PTR+2
                JSL F_READ                      ; Attempt to read the next sector of the source
                BCS copy2dest                   ; If successful, copy the sector

                setas
                LDA @b DOS_STATUS
                CMP #DOS_ERR_NOCLUSTER          ; Are there no more clusters in the source file?
                BEQ file_copied                 ; Yes: we're done copying

err_dest_close  setal                           ; Otherwise: there was an error
                LDA @b DOS_DST_PTR              ; Get the destination file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_DST_PTR+2
                STA @b DOS_FD_PTR+2 
                JSL F_CLOSE                     ; Attempt to close the destination
                BRL err_src_close               ; Close the source and throw an error

copy2dest       TRACE "copy2dest"
                JSL DOS_SRC2DST                 ; Copy the source sector to the destination sector

                LDY #FILEDESC.CLUSTER           ; destination sector cluster ID := 0 to append
                LDA #0
                STA [DOS_DST_PTR],Y
                INY
                INY
                STA [DOS_DST_PTR],Y

                LDA @b DOS_DST_PTR              ; Get the destination file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_DST_PTR+2
                STA @b DOS_FD_PTR+2 
                JSL F_WRITE                     ; Attempt to write the destionation sector to the disk
                BCC err_dest_close              ; If error: close all files and throw the error
                BRL read_next                   ; Otherwise: repeat the loop

file_copied     TRACE "file_copied"
                setal
                LDA @b DOS_DST_PTR              ; Get the destination file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_DST_PTR+2
                STA @b DOS_FD_PTR+2
                JSL F_CLOSE                     ; Close the destination

                LDA @b DOS_SRC_PTR              ; Get the source file descriptor pointer
                STA @b DOS_FD_PTR
                LDA @b DOS_SRC_PTR+2
                STA @b DOS_FD_PTR+2
                JSL F_CLOSE                     ; Close the source

                BRL IF_SUCCESS
                .pend

.databank 0
