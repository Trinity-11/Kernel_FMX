;;;
;;; Registers for the floppy drive controller
;;;

SIO_FDC  = $AF13F0
SIO_FDC_SRA = $AF13F0 ; Read Only - Status Register A (not used in AT mode)

SIO_FDC_SRB = $AF13F1 ; Read Only - Status Register B (not used in AT mode)

SIO_FDC_DOR = $AF13F2 ; Read/Write - Digital Output Register
FDC_DOR_DSEL0 = $01     ; Drive 0 Select
FDC_DOR_DSEL1 = $02     ; Drive 1 Select
FDC_DOR_NRESET = $04    ; Reset the FDC
FDC_DOR_DMAEN = $08     ; Enable DMA
FDC_DOR_MOT0  = $10     ; Turn on motor 0
FDC_DOR_MOT1  = $20     ; Turn on motor 1
FDC_DOR_MOT2  = $40     ; Turn on motor 2
FDC_DOR_MOT3  = $80     ; Turn on motor 3

SIO_FDC_TSR = $AF13F3   ; Read/Write - Tape Drive Status (not used on the C256)

SIO_FDC_MSR = $AF13F4   ; Read - Main Status Register
FDC_MSR_DRV0BSY = $01   ; Indicates if drive 0 is busy
FDC_MSR_DRV1BSY = $02   ; Indicates if drive 1 is busy
FDC_MSR_CMDBSY = $10    ; Indicates if a command is in progress
FDC_MSR_NONDMA = $20    ; 
FDC_MSR_DIO = $40       ; Data direction: 1 = read, 0 = write
FDC_MSR_RQM = $80       ; 1 = host can transfer data, 0 = host must wait

SIO_FDC_DSR = $AF13F4   ; Write - Data Select Register
; Bit[0..1] = data rate
; Bit[2..4] = precompensation select
FDC_DSR_LOPWR = $40     ; Turn on low power mode
FDC_DSR_RESET = $80     ; Software reset of the FDC

SIO_FDC_DTA = $AF13F5   ; Read/Write - Data - FIFO

SIO_FDC_RSV = $AF13F6   ; Reserved

SIO_FDC_DIR = $AF13F7   ; Read - Digital Input Register
FDC_DIR_DSKCHG = $80    ; Indicates if the disk has changed

SIO_FDC_CCR = $AF13F7   ; Write - Configuration Control Register
; Bit[0..1] = Data rate

;
; Bank 0 Status Register Bitfields and Masks
;

; ST0
FDC_ST0_DRVSEL = $03    ; Mask for the current selected drive
FDC_ST0_HEAD = $04      ; Bit for the current selected head
FDC_ST0_EC = $08        ; Bit for EQUIPMENT CHECK, error in recalibrate or relative seek
FDC_ST0_SEEKEND = $10   ; The FDC completed a seek, relative seek, or recalibrate
FDC_ST0_INTCODE = $C0   ; Mask for interrupt code:
                        ;   00 = normal termination of command
                        ;   01 = Abnormal termination of command
                        ;   10 = Invalid command
                        ;   11 = Abnormal termination caused by polling

; ST1
FDC_ST1_MA = $01        ; Missing address mark
FDC_ST1_NW = $02        ; Not writable (disk is write protected)
FDC_ST1_ND = $04        ; No data
FDC_ST1_OR = $10        ; Overrun/underrun of the data
FDC_ST1_DE = $20        ; Data error... a CRC check failed
FDC_ST1_EN = $80        ; End of cylinder: tried to acess a sector not on the track

; ST2
FDC_ST2_MD = $01        ; Missing address mark: FDC cannot detect a data address mark
FDC_ST2_BC = $02        ; Bad cylinder
FDC_ST2_WC = $10        ; Wrong cylinder: track is not the same as expected
FDC_ST2_DD = $20        ; Data error in field: CRC error
FDC_ST2_CM = $40        ; Control mark

; ST3
FDC_ST3_DRVSEL = $03    ; Drive select mask
FDC_ST3_HEAD = $04      ; Head address bit
FDC_ST3_TRACK0 = $10    ; Track 0: Status of the TRK0 pin
FDC_ST3_WP = $40        ; Write Protect: status of the WP pin
    
;
;  FDC Commands
;

FDC_CMD_READ_TRACK          = 2
FDC_CMD_SPECIFY             = 3
FDC_CMD_SENSE_DRIVE_STATUS  = 4
FDC_CMD_WRITE_DATA          = 5
FDC_CMD_READ_DATA           = 6
FDC_CMD_RECALIBRATE         = 7
FDC_CMD_SENSE_INTERRUPT     = 8
FDC_CMD_WRITE_DELETED_DATA  = 9
FDC_CMD_READ_ID             = 10
FDC_CMD_READ_DELETED_DATA   = 12
FDC_CMD_FORMAT_TRACK        = 13
FDC_CMD_DUMPREG             = 14
FDC_CMD_SEEK                = 15
FDC_CMD_VERSION             = 16
FDC_CMD_SCAN_EQUAL          = 17
FDC_CMD_PERPENDICULAR_MODE  = 18
FDC_CMD_CONFIGURE           = 19
FDC_CMD_LOCK                = 20
FDC_CMD_VERIFY              = 22
FDC_CMD_SCAN_LOW_OR_EQUAL   = 25
FDC_CMD_SCAN_HIGH_OR_EQUAL  = 29

FDC_CMD_MT = $80                    ; Command bit to turn on multi-track
FDC_CMD_MFM = $40                   ; Command bit to operate in MFM format
FDC_CMD_SK = $20                    ; Command bit to skip deleted sectors
FDC_CMD_EIS = $40                   ; Command bit to turn on implied seek

;
; Floppy device command codes
;
FDC_DEVCMD_MOTOR_ON         = 1     ; Device code to turn the motor on
FDC_DEVCMD_MOTOR_OFF        = 2     ; Device code to turn the motor off
FDC_DEVCMD_RECAL            = 3     ; Device code to recalibrate the drive