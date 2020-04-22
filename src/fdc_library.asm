;;;
;;; Low level routines for controlling the floppy drive
;;;

FDC_MOTOR_TIME = 4295454        ; Time to wait for the motor to come on: 300ms
FDC_SEEK_TIME = 2147727         ; Time to wait for a seek to happen: 150ms

FDC_TEST            .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setaxl

                    LDA #'0'
                    JSL IPUTC

                    JSL FDC_Init

                    LDA #'1'
                    JSL IPUTC

                    JSL FDC_MOUNT
                    BCS is_ok

fail                LDA #'F'
                    JSL IPUTC
                    LDA #'A'
                    JSL IPUTC
                    LDA #'I'
                    JSL IPUTC
                    LDA #'L'
                    JSL IPUTC
                    BRA motor_off

is_ok               setas
                    LDA #'2'
                    JSL IPUTC
                    
                    setal
                    LDA @l ROOT_DIR_FIRST_CLUSTER           ; Try to read the first directory sector
                    STA BIOS_LBA
                    LDA @l ROOT_DIR_FIRST_CLUSTER
                    STA BIOS_LBA

                    LDA #<>DOS_DIR_CLUSTER
                    STA BIOS_BUFF_PTR
                    LDA #`DOS_DIR_CLUSTER
                    STA BIOS_BUFF_PTR+2

                    JSL FDC_GETBLOCK
                    BCC fail

                    setas
                    LDA #'2'
                    JSL IPUTC

;                     JSL FDC_Motor_On

;                     LDA #'2'
;                     JSL IPUTC

;                     LDX #<>FDC_MOTOR_TIME
;                     LDY #`FDC_MOTOR_TIME
;                     JSL IDELAY

;                     JSL FDC_Recalibrate_Command

;                     LDA #'3'
;                     JSL IPUTC

;                     LDX #<>FDC_SEEK_TIME
;                     LDY #`FDC_SEEK_TIME
;                     JSL IDELAY
                    
;                     JSL FDC_Sense_Int_Status
;                     JSL FDC_BRK_ON_ERR

;                     LDA #'4'
;                     JSL IPUTC
                    
;                     STZ FDC_CYLINDER
;                     JSL FDC_Seek_Track

;                     LDA #'5'
;                     JSL IPUTC

;                     LDX #<>FDC_SEEK_TIME
;                     LDY #`FDC_SEEK_TIME
;                     JSL IDELAY
                    
;                     JSL FDC_Sense_Int_Status
;                     JSL FDC_BRK_ON_ERR

;                     LDA FDC_PCN
;                     CMP #0
;                     BEQ step_6

;                     LDA #'@'
;                     JSL IPUTC
; lock1               NOP
;                     BRA lock1

; step_6              LDA #'6'
;                     JSL IPUTC
                    
;                     LDA #80
;                     STA FDC_CYLINDER
;                     JSL FDC_Seek_Track

;                     LDA #'7'
;                     JSL IPUTC

;                     LDX #<>FDC_SEEK_TIME
;                     LDY #`FDC_SEEK_TIME
;                     JSL IDELAY
                    
;                     JSL FDC_Sense_Int_Status
;                     JSL FDC_BRK_ON_ERR

;                     LDA FDC_PCN
;                     CMP #80
;                     BEQ step_8

;                     LDA #'@'
;                     JSL IPUTC
;                     BRA lock1

; step_8              LDA #'8'
;                     JSL IPUTC

;                     JSL FDC_DumpReg_Command

;                     ; LDX #32768     ; 400ms
;                     ; JSL ILOOP_MS

;                     JSL FDC_Read_ID_Command

;                     LDA #0
;                     STA FDC_CYLINDER
;                     JSL FDC_Seek_Track

;                     LDA #'9'
;                     JSL IPUTC

;                     LDX #<>FDC_SEEK_TIME
;                     LDY #`FDC_SEEK_TIME
;                     JSL IDELAY
                    
;                     JSL FDC_Sense_Int_Status
;                     JSL FDC_BRK_ON_ERR

;                     setal
;                     LDA #<>DOS_SECTOR           ; Point to DOS_SECTOR buffer
;                     STA BIOS_BUFF_PTR
;                     LDA #`DOS_SECTOR
;                     STA BIOS_BUFF_PTR+2
;                     setas

;                     LDY #0
;                     LDA #0
; zero_loop           STA [BIOS_BUFF_PTR],Y
;                     INY
;                     CPY #512
;                     BNE zero_loop

;                     setal
;                     LDA #0
;                     STA BIOS_LBA
;                     STA BIOS_LBA+2
;                     setas

;                     JSL FDC_GETBLOCK

;                     LDA #'a'
;                     JSL IPUTC

motor_off           JSL FDC_Motor_Off

                    LDA #'/'
                    JSL IPUTC

                    PLP
                    PLD
                    PLB
                    RTL
                    .pend

FDC_BRK_ON_ERR      .proc
                    PHP
                    setas

                    LDA @l FDC_ST0
                    AND #%11010000          ; Check only the error bits
                    BEQ done

                    LDA #'#'
                    JSL IPUTC

lock                NOP
                    BRA lock

done                PLP
                    RTL
                    .pend

;
; Wait for the FDC to be ready for a transfer from the CPU
;
; Bit[7] needs to be 1 in order to send a new command
;
FDC_Check_RQM       .proc
                    PHP
                    setas

fdc_mrqloop         LDA SIO_FDC_MSR
                    BIT #FDC_MSR_RQM
                    BEQ fdc_mrqloop

                    PLP
                    RTS
                    .pend

;
; Wait while drive 0 is busy
;
;Bit[0] needs to be cleared before doing anything else (1 = Seeking)
;
FDC_Check_DRV0_BSY  .proc
                    PHP
                    setas

fdc_drv0bsy_loop    LDA SIO_FDC_MSR
                    BIT #FDC_MSR_DRV0BSY
                    BNE fdc_drv0bsy_loop

                    PLP
                    RTS
                    .pend

;
; Wait while the FDC is busy with a command
;
;Bit[4] Command is in progress when 1
;
FDC_Check_CMD_BSY   .proc
                    PHP
                    setas

fdc_cmd_loop        LDA SIO_FDC_MSR
                    BIT #FDC_MSR_CMDBSY
                    BNE fdc_cmd_loop

                    PLP
                    RTS
                    .pend

;
; Wait until data is available for reading
;
FDC_Can_Read_Data   .proc
                    PHP
                    setas

                    LDA SIO_FDC_MSR
                    AND #FDC_MSR_DIO
                    CMP #FDC_MSR_DIO
                    BEQ FDC_Can_Read_Data

                    PLP
                    RTS
                    .pend

;
; Initialize the floppy drive controller
;
FDC_Init            .proc
                    PHP
                    setas

                    LDA #FDC_DOR_NRESET         ; Turn off the motor
                    STA SIO_FDC_DOR
                    NOP
                    NOP
                    NOP
                    NOP

                    LDA #$00                    ; Make sure the Speed and Compensation has been set
                    STA SIO_FDC_DSR             
                    LDA #$00                    ; Precompensation set to 0
                    STA SIO_FDC_CCR

                    LDX #32768                  ; 400ms
                    JSL ILOOP_MS
                    JSR FDC_Check_CMD_BSY

                    JSL FDC_Sense_Int_Status
                    JSL FDC_Sense_Int_Status
                    JSL FDC_Sense_Int_Status
                    JSL FDC_Sense_Int_Status

                    JSL FDC_Configure_Command

                    JSL FDC_Specify_Command

                    PLP
                    RTL
                    .pend

;
; Turn on the motor of the floppy drive
;
FDC_Motor_On        .proc
                    PHP
                    setas
                    ;JSR FDC_Check_DRV0_BSY ; Make sure the drive is not seeking
                    ;JSR FDC_Check_RQM ; Check if I can transfer data

                    ; Turn on the Motor - No DMA
                    LDA #FDC_DOR_MOT0 | FDC_DOR_NRESET
                    STA SIO_FDC_DOR
                    JSR FDC_Check_RQM           ; Make sure we can leave knowing that everything set properly

                    PLP
                    RTL
                    .pend

;
; Turn off the motor on the floppy drive
;
FDC_Motor_Off       .proc
                    PHP
                    setas

                    JSR FDC_Check_DRV0_BSY      ; Make sure the drive is not seeking
                    JSR FDC_Check_RQM           ; Check if I can transfer data

                     ; Turn OFF the Motor
                    LDA #FDC_DOR_NRESET
                    STA SIO_FDC_DOR

                    JSR FDC_Check_RQM           ; Make sure we can leave knowing that everything set properly

                    PLP
                    RTL
                    .pend

;
; Send the RECALIBRATE command
;
; Inputs:
;   FDC_DRIVE = the number of the drive to recalibrate
;
FDC_Recalibrate_Command
                    PHP

                    setas
                    JSR FDC_Check_CMD_BSY       ; Check I can send a command
                    JSR FDC_Check_RQM           ; Check if I can transfer data

                    LDA #FDC_CMD_RECALIBRATE    ; RECALIBRATE Command
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM           ; Check if I can transfer data

                    LDA #0                      ; Get the drive number
                    STA SIO_FDC_DTA

                    JSR FDC_Check_CMD_BSY       ; Check I can send a command

                    PLP
                    RTL

;
; Issue the SENSE INTERRUPT command;
;
; Inputs:
;   None
;
; Results:
;   FDC_ST0 = Status Register 0
;   FDC_PCN = Present cylinder number
;
FDC_Sense_Int_Status
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setas

                    STZ FDC_ST0                         ; Clear ST0
                    LDA #$FF
                    STA FDC_PCN                         ; Set PCN to some obviously bad value

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    JSR FDC_Check_CMD_BSY               ; Check I can send a command

                    LDA #FDC_CMD_SENSE_INTERRUPT        ; SENSE_INTERRUPT command
                    STA SIO_FDC_DTA
                    JSR FDC_Can_Read_Data

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST0                         ; Status register 0

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_PCN                         ; Present cylinder number

                    PLP
                    PLD
                    PLB
                    RTL


;
; Send the SPECIFY command
;
;	{ 2880,18,2,80,0,0x1B,0x00,0xCF,0x6C,"H1440" },	/*  7 1.44MB 3.5"   */
;
FDC_Specify_Command PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setas
                    JSR FDC_Check_CMD_BSY               ; Check I can send a command
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #FDC_CMD_SPECIFY                ; SPECIFY Command
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #$CF                            ; Set SRT = $C, HUT = $F
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #$01                            ; HLT = 0, 1 = Non-DMA
                    STA SIO_FDC_DTA

                    JSR FDC_Check_CMD_BSY               ; Check I can send a command

                    PLP
                    PLD
                    PLB
                    RTL

;
; Send the CONFIGURE command
;
FDC_Configure_Command
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setas
                    JSR FDC_Check_CMD_BSY               ; Check I can send a command
                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    
                    LDA #FDC_CMD_CONFIGURE              ; CONFIGURE Command
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #$00
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #$04                            ; FIFOTHR = 4 bytes
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #$00                            ; PRETRK = 00
                    STA SIO_FDC_DTA

                    JSR FDC_Check_CMD_BSY               ; Check I can send a command

                    PLP
                    PLD
                    PLB
                    RTL

;
; Send the READID command
;
; Inputs:
;   FDC_DRIVE = the number of the drive to access
; 
; Outputs:
;   FDC_ST0 = Status register 0
;   FDC_ST1 = Status register 1
;   FDC_ST2 = Status register 2
;   FDC_CYLINDER = the current cylinder
;   FDC_HEAD = the current HEAD
;   FDC_SECTOR = the current sector
;   FDC_SECTOR_SIZE = the sector size code
;
FDC_Read_ID_Command PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setas
                    JSR FDC_Check_CMD_BSY               ; Check I can send a command
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #FDC_CMD_READ_ID                ; READID Command
                    ORA #FDC_CMD_MFM                    ; Operate in MFM mode
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA FDC_DRIVE                       ; Send the drive
                    STA SIO_FDC_DTA

                    JSR FDC_Can_Read_Data

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST0                         ; Get ST0

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST1                         ; Get ST1

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST2                         ; Get ST2

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_CYLINDER                    ; Get the cylinder

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_HEAD                        ; Get the head

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_SECTOR                      ; Get the sector

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_SECTOR_SIZE                 ; Get the sector size code

                    PLP
                    PLD
                    PLB
                    RTL

;
; Send the DUMPREG command
;
; Inputs:
;   None
;
; Result Block:
;   PCN0
;   PCN1
;   PCN2
;   PCN3
;   SRT | HRT
;   HLT
;   SC/EOT
;   LOCK, ...
;   EIS, ...
;   PRETRK
;
FDC_DumpReg_Command .proc
                    PHX
                    PHP

                    setxl
                    setas
                    JSR FDC_Check_CMD_BSY               ; Check I can send a command
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #FDC_CMD_DUMPREG                ; DUMPREG Command
                    STA SIO_FDC_DTA

                    JSR FDC_Can_Read_Data

                    LDX #0
result_loop         JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA                     ; Get the result byte
                    STA FDC_RESULTS,X                   ; Save it to the results buffer
                    INX
                    CPX #10                             ; We expect 10 result bytes
                    BNE result_loop                     ; Loop until we get there
                    
                    JSR FDC_Check_CMD_BSY

                    PLP
                    PLX
                    RTL
                    .pend

;
; Seek to a track
;
; Inputs:
;   FDC_DRIVE = the number of the drive to use
;   FDC_HEAD = the number of the head to use
;   FDC_CYLINDER = the number of the cylinder to seek
;
; Result Block:
;   None
;
FDC_Seek_Track      PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setas
                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    JSR FDC_Check_CMD_BSY               ; Check I can send a command

                    LDA #FDC_CMD_SEEK                   ; Seek Command
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA FDC_HEAD                        ; Get the head
                    ASL A
                    ASL A
                    ORA FDC_DRIVE                       ; And the drive number
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA FDC_CYLINDER
                    STA SIO_FDC_DTA
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    PLP
                    PLD
                    PLB
                    RTL

;
; Read a sector into a buffer provided by the caller
;
; Inputs;
;   BIOS_BUFF_PTR = pointer to the destination to write the sector
;   FDC_DRIVE = the number of the drive to access
;   FDC_HEAD = the head to access (0/1)
;   FDC_CYLINDER = the cylinder or track to access
;   FDC_SECTOR = the sector to access (1..?)
;
; Outputs:
;   FDC_ST0 = Status register 0
;   FDC_ST1 = Status register 1
;   FDC_ST2 = Status register 2
;   FDC_CYLINDER = the current cylinder
;   FDC_HEAD = the current HEAD
;   FDC_SECTOR = the current sector
;   FDC_SECTOR_SIZE = the sector size code
;
FDC_Read_Sector     .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE
                    setas

                    JSR FDC_Check_CMD_BSY               ; Check I can send a command
                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    LDA #FDC_CMD_READ_DATA              ; The READ_DATA command
                    ORA #FDC_CMD_MFM                    ; Turn on MFM mode
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA FDC_HEAD                        ; Get the HEAD number
                    AND #$01
                    ASL A
                    ASL A
                    ORA FDC_DRIVE                       ; Get the drive number
                    STA SIO_FDC_DTA                     ; Set that for the command

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA FDC_CYLINDER                    ; Send the cylinder number
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA FDC_HEAD                        ; Send the head number
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA FDC_SECTOR                      ; Send the sector number
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA #$02                            ; --- N ---- Sector Size (2 = 512Bytes)
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA #18                             ; --- EOT ---- End of Track
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA #$1B                            ; --- GPL ---- End of Track
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA #$FF                            ; --- DTL ---- End of Track
                    STA SIO_FDC_DTA

; wait4data2bready    LDA SIO_FDC_MSR
;                     and #FDC_MSR_RQM | FDC_MSR_DIO
;                     cmp #FDC_MSR_RQM | FDC_MSR_DIO
;                     bne wait4data2bready

;                     LDA SIO_FDC_MSR;                  ; Skip if DMA?
;                     AND #FDC_MSR_NONDMA
;                     CMP #FDC_MSR_NONDMA
;                     BEQ fdc_Dump

                    LDY #$0000
copy_loop           LDA SIO_FDC_MSR                     ; Wait for data to be available to read
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM | FDC_MSR_DIO
                    BNE copy_loop
                    
                    LDA SIO_FDC_DTA                     ; Get the byte
                    STA [BIOS_BUFF_PTR],Y               ; Save it to the destination
                    STY CPUY
                    INY                                 ; And move to the next byte
                    CPY #512
                    BNE copy_loop                       ; Until we've read 512 bytes

get_results         JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST0                         ; --- ST0 ----

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST1                         ; --- ST1 ----

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST2                         ; --- ST2 ----

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_CYLINDER                    ; -- C ---

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_HEAD                        ; --- H ---

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_SECTOR                      ; --- R ---

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_SECTOR_SIZE                 ; --- N ---

                    JSR FDC_Check_RQM                   ; Check if I can transfer data

                    PLP
                    PLD
                    PLB
                    RTL
                    .pend

;
; DIVIDE32 -- do 32-bit division
;
; NOTE: modified from https://codebase64.org/doku.php?id=base:16bit_division_16-bit_result
;
; Inputs:
;   DIVIDEND = 32-bit dividend
;   DIVISOR = 32-bit divisor
;
; Outputs:
;   DIVIDENT = 32-bit result
;   REMAINDER = 32-bit remainder
;
DIVIDE32            .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setdp DIVIDEND
                    setaxl

                    STZ REMAINDER           ; Initialize the remainder
                    STZ REMAINDER+2

                    LDX #32                 ; Set the number of bits to process

loop                ASL DIVIDEND
                    ROL DIVIDEND+2
                    ROL REMAINDER
                    ROL REMAINDER+2

                    LDA REMAINDER
                    SEC
                    SBC DIVISOR
                    TAY
                    LDA REMAINDER+2
                    SBC DIVISOR+2
                    BCC skip

                    STA REMAINDER+2
                    STY REMAINDER
                    INC DIVIDEND

skip                DEX
                    BNE loop 

                    PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; LBA2CHS -- Convert logical block address to CHS for the floppy drive
;
; Inputs:
;   BIOS_LBA = the logical block address to convert
;
; Outputs:
;   FDC_CYLINDER = the track for that LBA
;   FDC_HEAD = the head for that LBA
;   FDC_SECTOR = the sector for that LBA
;
LBA2CHS             .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setaxl       

                    ; CYL = LBA / (HPC * SPT)
                    LDA BIOS_LBA
                    STA @w DIVIDEND
                    LDA BIOS_LBA+2
                    STA @w DIVIDEND+2

                    LDA #36
                    STA @w DIVISOR
                    STZ @w DIVISOR+2

                    JSR DIVIDE32

                    setas
                    LDA DIVIDEND
                    STA FDC_CYLINDER
                    setal

                    ; HEAD = (LBA % (HPC * SPT)) / SPT
                    LDA @w REMAINDER
                    STA @w DIVIDEND
                    LDA @w REMAINDER+2
                    STA @w DIVIDEND+2

                    LDA #18
                    STA @w DIVISOR
                    STZ @w DIVISOR+2

                    JSR DIVIDE32

                    setas
                    LDA @w DIVIDEND
                    AND #$01
                    STA FDC_HEAD
                    
                    ; SECT = (LBA % (HPC * SPT)) % SPT + 1 
                    LDA @w REMAINDER
                    INC A
                    STA FDC_SECTOR

                    PLP
                    PLD
                    PLB
                    RTL
                    .pend

;
; Read a 512 byte block from the floppy disk into memory
;
; Inputs:
;   BIOS_LBA = the 32-bit block address to read
;   BIOS_BUFF_PTR = pointer to the location to store the block
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
FDC_GETBLOCK        .proc
                    PHP

                    JSL LBA2CHS                 ; Convert the LBA to CHS

                    JSL FDC_Seek_Track          ; Try to move to that track

                    LDX #<>FDC_SEEK_TIME
                    LDY #`FDC_SEEK_TIME
                    JSL IDELAY
                    
                    JSL FDC_Sense_Int_Status

                    ; TODO: error checking

                    JSL FDC_Read_Sector         ; Read the sector

                    ; TODO: error checking

ret_success         PLP
                    SEC
                    RTL
                    .pend

;
FDC_Read_Track
            setas

            RTL


FDC_Write_Sector
            RTL

;
; Attempt to mount a floppy disk
; Read the floppy's boot record and process settings
;
; NOTE: we assume that FDC_INIT has been called previously.
;
; Inputs:
;   None
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
FDC_MOUNT           .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    setas
                    LDA #0                                  ; We only support drive 0
                    STA FDC_DRIVE
                    JSL FDC_Motor_On                        ; Turn the motor on

                    LDA #'a'
                    JSL IPUTC

                    setaxl
                    LDA #0                                  ; We want sector 0
                    STA BIOS_LBA
                    STA BIOS_LBA+2

                    LDA #<>DOS_SECTOR                       ; And load it into DOS_SECTOR
                    STA BIOS_BUFF_PTR
                    LDA #`DOS_SECTOR
                    STA BIOS_BUFF_PTR+2

                    JSL FDC_GETBLOCK                        ; Attempt to read the data
                    BCS parse_boot                          ; If ok: start parsing the boot record
                    BRL pass_failure                        ; Pass the error up the chain

                    ; Got the boot record... start parsing it for the disk's characteristics

parse_boot          setas
                    LDA #'b'
                    JSL IPUTC

                    LDA #PART_TYPE_FAT12                    ; Set the file system to FAT12
                    STA @l FILE_SYSTEM

                    LDA #0                                  ; There are no partitions on the disk
                    STA @l PARTITION

                    setas
                    LDA DOS_SECTOR+BPB_SECPERCLUS_OFF       ; Get the # of sectors per cluster (usually 1)
                    STA @l SECTORS_PER_CLUSTER

                    setal
                    LDA #0                                  ; First sector of the "partition" is 0
                    STA @l FIRSTSECTOR
                    STA @l FIRSTSECTOR+2

                    LDA DOS_SECTOR+BPB_SECPERFAT_OFF        ; Get the number of sectors per FAT
                    STA @l SEC_PER_FAT
                    LDA #0
                    STA @l SEC_PER_FAT+2

                    LDA #1                                  ; FAT#1 begins at sector 1
                    STA @l FAT_BEGIN_LBA
                    CLC
                    ADC @l SEC_PER_FAT
                    STA @l FAT2_BEGIN_LBA                   ; FAT#2 begins SEC_PER_FAT sectors later
                    LDA #0
                    STA @l FAT_BEGIN_LBA+2
                    STA @L FAT2_BEGIN_LBA+2

                    CLC                                     ; Calculate the root directory's starting sector
                    LDA @l FAT2_BEGIN_LBA
                    ADC @l SEC_PER_FAT
                    STA @l ROOT_DIR_FIRST_CLUSTER           ; ROOT_DIR_FIRST_CLUSTER will be a sector LBA for FAT12!
                    LDA #0
                    STA @l ROOT_DIR_FIRST_CLUSTER+2

                    LDA DOS_SECTOR+BPB_ROOT_MAX_ENTRY_OFF   ; Get the maximum number of directory entries for the root dir
                    STA @l ROOT_DIR_MAX_ENTRY

                    LSR A                                   ; 16 entries per sector
                    LSR A
                    LSR A
                    LSR A                                   ; So now A is the number of sectors in the root directory

                    CLC
                    ADC @L ROOT_DIR_FIRST_CLUSTER           ; Add that to the first sector LBA for the root directory
                    STA @l CLUSTER_BEGIN_LBA                ; And that is the LBA for the first cluster
                    LDA #0
                    STA @l CLUSTER_BEGIN_LBA+2

                    LDA DOS_SECTOR+BPB_TOTAL_SECTORS        ; Set the sector limit
                    STA @l SECTORCOUNT
                    LDA #0
                    STA @l SECTORCOUNT+2

                    LDA DOS_SECTOR+BPB_RSRVCLUS_OFF         ; Get the number of reserved clusters
                    STA @l NUM_RSRV_SEC

                    ; Check for an extended boot record with a volume label

                    setas
                    LDA DOS_SECTOR+BPB_SIGNATUREB           ; Is signature B $29?
                    CMP #BPB_EXTENDED_RECORD
                    BNE no_volume_id                        ; No: there is no volume ID

is_extended         setal
                    LDA DOS_SECTOR+BPB_VOLUMEID             ; Yes: set the volume ID
                    STA @l VOLUME_ID
                    LDA DOS_SECTOR+BPB_VOLUMEID+2
                    STA @l VOLUME_ID+2
                    BRA ret_success

no_volume_id        setal
                    LDA #0                                  ; No: blank the Volume ID
                    STA @l VOLUME_ID
                    STA @L VOLUME_ID+2

ret_success         setas
                    LDA #'/'
                    JSL IPUTC
                    
                    LDA #0
                    STA BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

pass_failure        setas
                    LDA #'!'
                    JSL IPUTC
                    
                    LDA #1
                    STA BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend