DEF_NULL_CHAR           = $00
DEF_WILDCARD_CHAR       = $2A
DEF_SEPAR_CHAR1         = $5C
DEF_SEPAR_CHAR2         = $2F

; CH376S Commands
CH_CMD_CHECK_EXIST      = $06
;CH_CMD_RD_VAR8         = $0A     ; Read 8Bit Value
;CH_CMD_WR_VAR8         = $0B     ; Write 8Bit Value to controller
;CH_CMD_RD_VAR32        = $0C     ; Read 32Bit Value
CH_CMD_GET_FILE_SIZE    = $0C
;CH_CMD_WR_VAR32        = $0D
CH_CMD_SET_MODE         = $15     ; Set the Controller's mode, in our Case in SDCARD

CH_CMD_GET_STATUS       = $22     ; Get Interrupt Status
CH_CMD_RD_DATA0         = $27     ;
CH_CMD_WR_DATA          = $2C
CH_CMD_SET_FILENAME     = $2F     ;SET_FILE_NAME
CH_CMD_DISK_MOUNT       = $31     ;DISK_MOUNT
CH_CMD_FILE_OPEN        = $32     ;FILE_OPEN
CH_CMD_FILE_ENUM_GO     = $33
CH_CMD_FILE_CLOSE       = $36     ; To be Implemented
CH_CMD_BYTE_LOCATE      = $39
CH_CMD_BYTE_READ        = $3A
CH_CMD_BYTE_RD_GO       = $3B
CH_CMD_BYTE_WRITE       = $3C
CH_CMD_BYTE_WR_GO       = $3D

; Varial When Reading 8Bits or 32Bits Values From controller
CH_VAR_DISK_ROOT		= $44
CH_VAR_DSK_TOTAL_CLUS	= $48
CH_VAR_DSK_START_LBA	= $4C
CH_VAR_DSK_DAT_START	= $50
CH_VAR_LBA_BUFFER		= $54
CH_VAR_LBA_CURRENT		= $58
CH_VAR_FAT_DIR_LBA		= $5C
CH_VAR_START_CLUSTER	= $60
CH_VAR_CURRENT_CLUST	= $64
CH_VAR_FILE_SIZE		= $68
CH_VAR_CURRENT_OFFSET	= $6C


; Interruption state in SD card
CH376S_STAT_SUCCESS     = $14
CH376S_STAT_BUF_OVF     = $17
CH376S_STAT_DSK_RD      = $1D
CH376S_STAT_DSK_WR      = $1E
; File system notice code in SD card
CH376S_ERR_OPEN_DIR     = $41
CH376S_ERR_MISS_FIL     = $42
CH376S_ERR_FOUND_NAME   = $43
;File system error code in SD card
CH376S_ERR_DISK_DSC     = $82
CH376S_ERR_LRG_SEC      = $84
CH376S_ERR_PARTTION     = $92
CH376S_ERR_NOT_FORM     = $A1
CH376S_ERR_DSK_FULL     = $B1
CH376S_FDT_OVER         = $B2
CH376S_FILE_CLOSED      = $B4
                        
CH376S_CMD_RET_SUCCESS  = $51
CH376S_CMD_RET_ABORT    = $5F
                        
SDCARD_PRSNT_NO_CARD    = $00
SDCARD_PRSNT_CD         = $01
SDCARD_PRSNT_WP         = $02
SDCARD_PRSNT_MNTED      = $04  ; Card is present and Mounted1
