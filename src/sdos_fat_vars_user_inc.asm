;;
;; Data storage needed by the file system (internal variables user apps shouldn't need)
;;
;; NOTE: these locations are correct for the C256 Foenix User
;;

; Device information from master boot record and boot sector

DOS_HIGH_VARIABLES      = $38A000
DEVICE                  = $38A000       ; 1 byte - The number of the block device
FILE_SYSTEM             = $38A001       ; 1 byte - The type of filesystem (FAT12, FAT32, etc.)
PARTITION               = $38A002       ; 1 byte - The number of the partitions on the device
SECTORS_PER_CLUSTER     = $38A003       ; 1 byte - The number of sectors in a cluster
FIRSTSECTOR             = $38A004       ; 4 bytes - The LBA of the first sector on the volume
SECTORCOUNT             = $38A008       ; 4 bytes - The number of sectors in the volume
NUM_RSRV_SEC            = $38A00C       ; 2 bytes - The number of hidden or reserved sectors
CLUSTER_SIZE            = $38A00E       ; 2 bytes - The size of a cluster in bytes 
SEC_PER_FAT             = $38A010       ; 4 bytes - The number of sectors per FAT
FAT_BEGIN_LBA           = $38A014       ; 4 bytes - The LBA of the first sector of FAT #1
FAT2_BEGIN_LBA          = $38A018       ; 4 bytes - The LBA of the first sector of FAT #2
CLUSTER_BEGIN_LBA       = $38A01C       ; 4 bytes - The LBA of the first cluster in the storage area
ROOT_DIR_FIRST_CLUSTER  = $38A020       ; 4 bytes - The number of the first cluster in the root directory
ROOT_DIR_MAX_ENTRY      = $38A024       ; 2 bytes - The maximum number of entries in the root directory (0 = no limit)
VOLUME_ID               = $38A026       ; 4 bytes - The ID of the volume

; Other variables we don't need in bank 0

DOS_CURR_CLUS           = $38A02A       ; 4 bytes - The current cluster (for delete)
DOS_NEXT_CLUS           = $38A02E       ; 4 bytes - The next cluster in a file (for delete)
DOS_DIR_BLOCK_ID        = $38A032       ; 4 bytes - The ID of the current directory block
                                        ;   If DOS_DIR_TYPE = 0, this is a cluster ID
                                        ;   If DOS_DIR_TYPE = $80, this is a sector LBA
DOS_NEW_CLUSTER         = $38A036       ; 4 bytes - Space to store a newly written cluster ID
DOS_SHORT_NAME          = $38A03A       ; 11 bytes - The short name for a desired file
DOS_DIR_TYPE            = $38A045       ; 1 byte - a code indicating the type of the current directory (0 = cluster based, $80 = sector based)
DOS_CURR_DIR_ID         = $38A046       ; 4 byte - the ID of the first sector or cluster of the current directory
DOS_DEV_NAMES           = $38A04A       ; 4 byte - pointer to the linked list of device names
FDC_MOTOR_TIMER         = $38A04E       ; 2 bytes - count-down timer to automatically turn off the FDC spindle motor
DOS_MOUNT_DEV           = $38A050       ; 1 byte - the device code of the currently mounted device

; Larger buffers

DOS_DIR_CLUSTER         = $38A100       ; 512 bytes - A buffer for directory entries
DOS_DIR_CLUSTER_END     = $38A300       ; The byte just past the end of the directory cluster buffer
DOS_SECTOR              = $38A300       ; 512 bytes - A buffer for block device read/write
DOS_SECTOR_END          = $38A500       ; The byte just past the end of the cluster buffer
DOS_FAT_SECTORS         = $38A500       ; 1024 bytes - two sectors worth of the FAT
DOS_FAT_SECTORS_END     = $38A900       ; The byte just past the end of the FAT buffers
DOS_BOOT_SECTOR         = $38A900       ; A sector for holding the boot sector
DOS_BOOT_SECTOR_END     = $38AB00
DOS_SPARE_SECTOR        = $38AB00       ; A spare 512 byte buffer for loading sectors
DOS_SPARE_SECTOR_END    = $38AD00
DOS_SPARE_FD            = $38AD00       ; A spare file descriptor buffer
DOS_SPARE_FD_END        = DOS_SPARE_FD + SIZE(FILEDESC)

; Space for allocatable file descriptors (8 file descriptors of 32 bytes each)
DOS_FILE_DESCS          = DOS_SPARE_FD_END
DOS_FILE_DESCS_END      = DOS_FILE_DESCS + SIZE(FILEDESC) * DOS_FD_MAX

; Space for sector buffers for the file descriptors (8 buffers of 512 bytes each)
DOS_FILE_BUFFS          = $38B000
DOS_FILE_BUFFS_END      = DOS_FILE_BUFFS + DOS_SECTOR_SIZE * DOS_FD_MAX