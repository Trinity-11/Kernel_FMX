;;;
;;; Low level routines for controlling the floppy drive
;;;

FDC_MOTOR_TIME = 4295454        ; Time to wait for the motor to come on: 300ms
FDC_SEEK_TIME = 2147727         ; Time to wait for a seek to happen: 150ms

FDC_MOTOR_ON_TIME = 60 * 30     ; Time (in SOF interrupt counts) for the motor to stay on: ~30s?

FDC_TEST            .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_TEST"

                    setas
                    LDA #$F0
                    STA @w CURCOLOR

                    JSL ICLRSCREEN
                    JSL ICSRHOME

                    setaxl

                    JSL FDC_Init
                    BCS init_ok

                    TRACE "Error: FDC_Init failed"
                    BRL motor_off

init_ok             JSL FDC_MOUNT
                    BCS is_ok

mount_err           TRACE "Error: FDC_MOUNT failed"
                    BRL motor_off

is_ok               setas
                    LDX #0
                    LDA #0
fd_clr_loop         STA TEST_FD,X
                    INX
                    CPX #size(FILEDESC)
                    BNE fd_clr_loop

                    LDX #0
buff_clr_loop       STA TEST_LOCATION,X
                    INX
                    CPX #1024
                    BNE buff_clr_loop

                    setal
                    LDA #<>TEST_FILE
                    STA TEST_FD.PATH
                    LDA #`TEST_FILE
                    STA TEST_FD.PATH+2

                    LDA #<>TEST_BUFFER
                    STA TEST_FD.BUFFER
                    LDA #`TEST_BUFFER
                    STA TEST_FD.BUFFER+2

                    LDA #<>TEST_FD
                    STA DOS_FD_PTR
                    LDA #`TEST_FD
                    STA DOS_FD_PTR+2

                    LDA #<>TEST_LOCATION
                    STA DOS_DST_PTR
                    LDA #`TEST_LOCATION
                    STA DOS_DST_PTR+2

                    JSL IF_LOAD
                    BCS is_ok3

                    TRACE "Could not load CYBERIAD.TXT"
                    BRA motor_off

is_ok3              TRACE "OK"

motor_off           JSL FDC_Motor_Off

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

TEST_FD             .dstruct FILEDESC
TEST_FILE           .null "cyberiad.txt"    ; Path to file to try to load
TEST_LOCATION = $020000                     ; Location to try to load it
TEST_BUFFER = $030000                       ; Temporary location for a cluster buffer

;
; Wait for the FDC to be ready for a transfer from the CPU
;
; Bit[7] needs to be 1 in order to send a new command
;
FDC_Check_RQM       .proc
                    PHP
                    setas

loop                LDA SIO_FDC_MSR
                    BIT #FDC_MSR_RQM
                    BEQ loop

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

fdc_cmd_loop        LDA @l SIO_FDC_MSR
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

loop                LDA @l SIO_FDC_MSR
                    AND #FDC_MSR_DIO
                    CMP #FDC_MSR_DIO
                    BNE loop

                    PLP
                    RTS
                    .pend

;
; Wait until the FDC is clear to receive a byte
;
FDC_CAN_WRITE       .proc
                    PHP
                    setas

loop                LDA @l SIO_FDC_MSR
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM
                    BNE loop

                    PLP
                    RTS
                    .pend

;
; Execute a command on the floppy disk controller.
;
; Inputs:
;   FDC_PARAMETERS = buffer containing the bytes to send to start the command
;   FDC_PARAM_NUM = The number of parameter bytes to send to the FDC (including command)
;   FDC_RESULT_NUM = The number of result bytes expected ()
;   FDC_EXPECT_DAT = 0: the command expects no data, otherwise command will read data from the FDC
;   BIOS_BUFF_PTR = pointer to the buffer to store data
;
; Outputs:
;   FDC_RESULTS = Buffer for results of FDC commands
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
FDC_COMMAND         .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_COMMAND"

                    setaxs
                    LDX #0
                    LDA #0
clr_results         STA FDC_RESULTS,X                       ; Clear the result buffer
                    INX
                    CPX #16
                    BNE clr_results

                    LDA #3                                  ; Default to 3 retries
                    STA FDC_CMD_RETRY

                    LDA @l SIO_FDC_MSR                      ; Validate we can send a command
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM
                    BEQ start_send                          ; If so, start sending

fdc_reset           JSL FDC_INIT                            ; Reset the FDC

                    ; Command and parameter write phase

start_send          setxs
                    LDX #0
send_loop           JSR FDC_Check_RQM                       ; Wait until we can write
                    LDA FDC_PARAMETERS,X                    ; Get the parameter/command byte to write
                    STA @l SIO_FDC_DTA                      ; Send it
                    INX                                     ; Advance to the next byte
                    CPX FDC_PARAM_NUM
                    BNE send_loop                           ; Keep sending until we've sent them all

                    LDA FDC_EXPECT_DAT
                    BEQ result_phase

                    JSR FDC_Can_Read_Data

wait_for_data_rdy   LDA @l SIO_FDC_MSR                      ; Wait for data to be ready
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM | FDC_MSR_DIO
                    BNE wait_for_data_rdy

                    LDA @l SIO_FDC_MSR                      ; Check to see if the FDC is in execution phase
                    BIT #FDC_MSR_NONDMA
                    BNE data_phase                          ; If so: transfer the data
                    BRL error                               ; If not: it's an error

                    ; Data read phase

data_phase          setxl
                    LDY #0
data_loop           LDA @l SIO_FDC_MSR                      ; Wait for the next byte to be ready
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM | FDC_MSR_DIO
                    BNE data_loop

                    LDA @l SIO_FDC_DTA                      ; Get the data byte
                    STA [BIOS_BUFF_PTR],Y                   ; And save it to the buffer

                    INY                                     ; Move to the next position
                    CPY #512                                ; TODO: set this from the parameters?
                    BNE data_loop                           ; If not at the end, keep fetching

                    ; Result read phase

result_phase        LDA FDC_RESULT_NUM                      ; If no results are expected...
                    BEQ chk_busy                                ; Then we're done
                    
                    setxs
                    LDX #0
result_loop         JSR FDC_Can_Read_Data                   ; Wait until we can read
                    LDA @l SIO_FDC_DTA                      ; Yes: get the data
                    JSR FDC_Can_Read_Data                   ; Wait until we can read

read_result         LDA @l SIO_FDC_DTA                      ; Yes: get the data
                    STA FDC_RESULTS,X                       ; Save it to the result buffer

                    JSR FDC_Check_RQM
                    LDA @l SIO_FDC_MSR
                    AND #FDC_MSR_DIO | FDC_MSR_CMDBSY
                    CMP #FDC_MSR_DIO | FDC_MSR_CMDBSY
                    BNE chk_busy

                    INX                                     ; Move to the next result positions
                    CPX FDC_RESULT_NUM
                    BNE read_result                         ; And keep looping until we've read all

chk_busy            setxl
                    LDX #10                                 ; Wait 10ms (I guess?)
                    JSL ILOOP_MS
                    
                    LDA @l SIO_FDC_MSR                      ; Check the command busy bit
                    BIT #FDC_MSR_CMDBSY
                    BEQ done                                ; If not set: we're done

                    JSR FDC_Can_Read_Data                   ; Wait until we can read
                    LDA @l SIO_FDC_DTA                      ; Read the data
                    STA FDC_RESULTS,X
                    INX
                    BRA chk_busy                            ; And keep checking

done                STZ BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

retry               setas
                    DEC FDC_CMD_RETRY                       ; Decrement the retry counter
                    BMI error                               ; If it's negative, we've failed
                    BRL fdc_reset                           ; Otherwise, try to reset and try again

error               setas
                    LDA #BIOS_ERR_CMD
                    STA BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend

;
; Initialize the floppy drive controller
;
FDC_Init            .proc
                    PHP

                    setxl
                    setas

                    TRACE "FDC_Init"

                    LDA #0
                    STA @l SIO_FDC_DOR
                    
                    LDX #1000                   ; Wait
                    LDY #0
                    JSL IDELAY

                    LDA #FDC_DOR_NRESET         ; Reset the FDC
                    STA @l SIO_FDC_DOR
                    NOP
                    NOP
                    NOP
                    NOP

                    LDA #$00                    ; Make sure the Speed and Compensation has been set
                    STA SIO_FDC_DSR             
                    LDA #$00                    ; Precompensation set to 0
                    STA SIO_FDC_CCR

                    LDX #<>FDC_SEEK_TIME
                    LDY #`FDC_SEEK_TIME
                    JSL IDELAY


                    JSL FDC_Sense_Int_Status
                    BCC pass_failure
                    JSL FDC_Sense_Int_Status
                    BCC pass_failure
                    JSL FDC_Sense_Int_Status
                    BCC pass_failure
                    JSL FDC_Sense_Int_Status
                    BCC pass_failure

                    JSL FDC_Configure_Command
                    BCC pass_failure

                    JSL FDC_Specify_Command
                    BCC pass_failure

                    PLP
                    SEC
                    RTL

pass_failure        PLP
                    CLC
                    RTL
                    .pend

;
; Reset the FDC motor timeout counter
;
; If there is no disk activity for a set number of seconds, the motor should shut off in the SOF interrupt.
; This routine will reset the timeout to keep the motor spinning while a program is using the disk.
;
FDC_MOTOR_NEEDED    .proc
                    PHP

                    setal
                    SEI                         ; Turn off interrupts
                    LDA #FDC_MOTOR_ON_TIME      ; Reset the FDC timeout clock
                    STA @l FDC_MOTOR_TIMER

                    setas
                    LDA @lINT_MASK_REG0
                    AND #~FNX0_INT00_SOF        ; Enable the SOF interrupt
                    STA @lINT_MASK_REG0
                    
                    PLP
                    RTL
                    .pend

;
; Turn on the motor of the floppy drive
;
FDC_Motor_On        .proc
                    PHP

                    TRACE "FDC_Motor_On"

                    JSL FDC_MOTOR_NEEDED        ; Reset the spindle motor timeout clock

                    setas
                    LDA @l SIO_FDC_DOR          ; Check to see if the motor is already on
                    BIT #FDC_DOR_MOT0
                    BNE done                    ; If so: skip

                    ; Turn on the Motor - No DMA
                    LDA #FDC_DOR_MOT0 | FDC_DOR_NRESET
                    STA @l SIO_FDC_DOR
                    JSR FDC_Check_RQM           ; Make sure we can leave knowing that everything set properly

                    LDX #<>FDC_MOTOR_TIME       ; Wait a suitable time for the motor to spin up
                    LDY #`FDC_MOTOR_TIME
                    JSL IDELAY

done                PLP
                    RTL
                    .pend

;
; Turn off the motor on the floppy drive
;
FDC_Motor_Off       .proc
                    PHP
                    setas

                    TRACE "FDC_Motor_Off"

                    JSR FDC_Check_DRV0_BSY      ; Make sure the drive is not seeking
                    JSR FDC_Check_RQM           ; Check if I can transfer data

                    ; Turn OFF the Motor
                    LDA #FDC_DOR_NRESET
                    STA SIO_FDC_DOR

                    JSR FDC_Check_RQM           ; Make sure we can leave knowing that everything set properly

                    setal
                    SEI                         ; Turn off interrupts
                    LDA #0                      ; Set FDC motor timeout counter to 0 to disable it
                    STA @l FDC_MOTOR_TIMER

                    setas
                    LDA @lINT_MASK_REG0
                    ORA #FNX0_INT00_SOF         ; Disable the SOF interrupt
                    STA @lINT_MASK_REG0

                    PLP
                    RTL
                    .pend

;
; Send the RECALIBRATE command
;
; Inputs:
;   FDC_DRIVE = the number of the drive to recalibrate
;
FDC_Recalibrate_Command .proc
                    PHD
                    PHP

                    setdp FDC_DRIVE

                    TRACE "FDC_Recalibrate_Command"

                    JSL FDC_MOTOR_NEEDED        ; Reset the spindle motor timeout clock

                    setas
                    LDA #FDC_CMD_RECALIBRATE    ; RECALIBRATE Command
                    STA FDC_PARAMETERS

                    LDA FDC_DRIVE
                    STA FDC_PARAMETERS+1

                    LDA #2
                    STA FDC_PARAM_NUM           ; 2 parameters
                    STZ FDC_EXPECT_DAT          ; 0 data
                    STZ FDC_RESULT_NUM          ; 0 results

                    JSL FDC_COMMAND             ; Issue the command
                    BCC pass_failure            ; If failure, pass the failure up

                    PLP
                    PLD
                    SEC
                    RTL

pass_failure        PLP
                    PLD
                    CLC
                    RTL
                    .pend

;
; Issue the SENSE INTERRUPT command
;
; Inputs:
;   None
;
; Results:
;   FDC_ST0 = Status Register 0
;   FDC_PCN = Present cylinder number
;
FDC_Sense_Int_Status .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_Sense_Int_Status"

                    setas
                    STZ FDC_ST0                         ; Clear ST0
                    LDA #$FF
                    STA FDC_PCN                         ; Set PCN to some obviously bad value

                    JSR FDC_Check_CMD_BSY               ; Check I can send a command

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA #FDC_CMD_SENSE_INTERRUPT
                    STA SIO_FDC_DTA

                    JSR FDC_Can_Read_Data

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_ST0                         ; --- ST0 ---

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    LDA SIO_FDC_DTA
                    STA FDC_PCN                         ; --- Cylinder ---

                    PLP
                    PLD
                    PLB
                    SEC
                    RTL
                    .pend


;
; Send the SPECIFY command
;
;	{ 2880,18,2,80,0,0x1B,0x00,0xCF,0x6C,"H1440" },	/*  7 1.44MB 3.5"   */
;
FDC_Specify_Command .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_Specify_Command"

                    setas
                    JSR FDC_Check_CMD_BSY   ; Check I can send a command

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    LDA #FDC_CMD_SPECIFY    ; Specify Command
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    LDA #$CF
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    LDA #$01                ; 1 = Non-DMA
                    STA SIO_FDC_DTA

                    PLP
                    PLD
                    PLB
                    SEC
                    RTL
                    .pend

;
; Send the CONFIGURE command
;
FDC_Configure_Command .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_Configure_Command"

                    setas
                    JSR FDC_Check_CMD_BSY   ; Check I can send a command

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    LDA #FDC_CMD_CONFIGURE  ; Specify Command
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    LDA #$00
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    LDA #$44                ; Implied Seek, FIFOTHR = 4 byte
                    STA SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    LDA #$00
                    STA SIO_FDC_DTA

                    JSR FDC_Check_CMD_BSY   ; Check I can send a command

                    PLP
                    PLD
                    PLB
                    SEC
                    RTL
                    .pend

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
FDC_Read_ID_Command .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_Read_ID_Command"

                    setas
                    LDA #FDC_CMD_READ_ID                ; READID Command
                    STA FDC_PARAMETERS

                    LDA #1
                    STA FDC_PARAM_NUM                   ; 4 parameter (the command)
                    STZ FDC_EXPECT_DAT                  ; 0 data
                    LDA #7
                    STA FDC_RESULT_NUM                  ; 7 results

                    JSL FDC_COMMAND                     ; Issue the command
                    BCC pass_failure

                    LDA FDC_RESULTS
                    STA FDC_ST0                         ; Get ST0

                    LDA FDC_RESULTS+1
                    STA FDC_ST1                         ; Get ST1

                    LDA FDC_RESULTS+2
                    STA FDC_ST2                         ; Get ST2

                    LDA FDC_RESULTS+3
                    STA FDC_CYLINDER                    ; Get the cylinder

                    LDA FDC_RESULTS+4
                    STA FDC_HEAD                        ; Get the head

                    LDA FDC_RESULTS+5
                    STA FDC_SECTOR                      ; Get the sector

                    LDA FDC_RESULTS+6
                    STA FDC_SECTOR_SIZE                 ; Get the sector size code

                    PLP
                    PLD
                    PLB
                    RTL

pass_failure        PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend

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
                    PHD
                    PHP

                    TRACE "FDC_DumpReg_Command"

                    setas                  
                    LDA #FDC_CMD_DUMPREG                ; DUMPREG Command
                    STA FDC_PARAMETERS

                    LDA #1
                    STA FDC_PARAM_NUM                   ; 4 parameter (the command)
                    STZ FDC_EXPECT_DAT                  ; 0 data
                    LDA #10
                    STA FDC_RESULT_NUM                  ; 10 results

                    JSL FDC_COMMAND                     ; Issue the command
                    BCC pass_failure

                    PLP
                    PLD
                    RTL

pass_failure        PLP
                    PLD
                    CLC
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
FDC_Seek_Track      .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_Seek_Track"

                    JSL FDC_MOTOR_NEEDED        ; Reset the spindle motor timeout clock

                    setas                  
                    LDA #FDC_CMD_SEEK                   ; Seek Command
                    STA FDC_PARAMETERS

                    LDA FDC_HEAD                        ; Get the head
                    AND #$01
                    ASL A
                    ASL A
                    ORA FDC_DRIVE                       ; And the drive number
                    STA FDC_PARAMETERS+1

                    LDA FDC_CYLINDER                    ; And the track
                    STA FDC_PARAMETERS+2

                    LDA #3
                    STA FDC_PARAM_NUM                   ; 3 parameter (the command)
                    STZ FDC_EXPECT_DAT                  ; 0 data
                    STZ FDC_RESULT_NUM                  ; 0 results

                    JSL FDC_COMMAND                     ; Issue the command
                    BCC pass_failure

                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

pass_failure        PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend

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

                    TRACE "FDC_Read_Sector"

                    JSL FDC_MOTOR_NEEDED                ; Reset the spindle motor timeout clock

                    setas                  
                    LDA #FDC_CMD_READ_DATA              ; The READ_DATA command
                    ORA #FDC_CMD_MFM                    ; Turn on MFM mode
                    STA FDC_PARAMETERS

                    LDA FDC_HEAD                        ; Get the head
                    AND #$01
                    ASL A
                    ASL A
                    ORA FDC_DRIVE                       ; And the drive number
                    STA FDC_PARAMETERS+1

                    LDA FDC_CYLINDER                    ; Send the cylinder number
                    STA FDC_PARAMETERS+2

                    LDA FDC_HEAD                        ; Send the head number
                    STA FDC_PARAMETERS+3

                    LDA FDC_SECTOR                      ; Send the sector number
                    STA FDC_PARAMETERS+4

                    LDA #$02                            ; --- N ---- Sector Size (2 = 512Bytes)
                    STA FDC_PARAMETERS+5

                    LDA #18                             ; --- EOT ---- End of Track
                    STA FDC_PARAMETERS+6

                    LDA #$1B                            ; --- GPL ---- End of Track
                    STA FDC_PARAMETERS+7

                    LDA #$FF                            ; --- DTL ---- Special sector size
                    STA FDC_PARAMETERS+8

                    LDA #9
                    STA FDC_PARAM_NUM                   ; 9 parameter (the command)

                    LDA #1
                    STA FDC_EXPECT_DAT                  ; Expect data

                    LDA #7
                    STA FDC_RESULT_NUM                  ; 7 results

command             JSL FDC_COMMAND                     ; Issue the command
                    PHP

get_results         LDA FDC_RESULTS
                    STA FDC_ST0                         ; --- ST0 ----

                    LDA FDC_RESULTS+1
                    STA FDC_ST1                         ; --- ST1 ----

                    LDA FDC_RESULTS+2
                    STA FDC_ST2                         ; --- ST2 ----

                    LDA FDC_RESULTS+3
                    STA FDC_CYLINDER                    ; -- C ---

                    LDA FDC_RESULTS+4
                    STA FDC_HEAD                        ; --- H ---

                    LDA FDC_RESULTS+5
                    STA FDC_SECTOR                      ; --- R ---

                    LDA FDC_RESULTS+6
                    STA FDC_SECTOR_SIZE                 ; --- N ---

                    PLP
                    BCC pass_failure

done                PLP
                    PLD
                    PLB
                    RTL

pass_failure        PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend

;
; Write a sector from a buffer provided by the caller
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
FDC_Write_Sector    .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_Write_Sector"

                    JSL FDC_MOTOR_NEEDED                ; Reset the spindle motor timeout clock

                    setas                  
                    LDA #FDC_CMD_WRITE_DATA             ; The WRITE_DATA command
                    ORA #FDC_CMD_MFM                    ; Turn on MFM mode
                    STA FDC_PARAMETERS

                    LDA FDC_HEAD                        ; Get the head
                    AND #$01
                    ASL A
                    ASL A
                    ORA FDC_DRIVE                       ; And the drive number
                    STA FDC_PARAMETERS+1

                    LDA FDC_CYLINDER                    ; Send the cylinder number
                    STA FDC_PARAMETERS+2

                    LDA FDC_HEAD                        ; Send the head number
                    STA FDC_PARAMETERS+3

                    LDA FDC_SECTOR                      ; Send the sector number
                    STA FDC_PARAMETERS+4

                    LDA #$02                            ; --- N ---- Sector Size (2 = 512Bytes)
                    STA FDC_PARAMETERS+5

                    LDA #18                             ; --- EOT ---- End of Track
                    STA FDC_PARAMETERS+6

                    LDA #$1B                            ; --- GPL ---- End of Track
                    STA FDC_PARAMETERS+7

                    LDA #$FF                            ; --- DTL ---- Special sector size
                    STA FDC_PARAMETERS+8

                    LDA #9
                    STA FDC_PARAM_NUM                   ; 9 parameter (the command)

                    LDA #1
                    STA FDC_EXPECT_DAT                  ; Expect data

                    LDA #7
                    STA FDC_RESULT_NUM                  ; 7 results

command             JSL FDC_COMMAND                     ; Issue the command
                    PHP

get_results         LDA FDC_RESULTS
                    STA FDC_ST0                         ; --- ST0 ----

                    LDA FDC_RESULTS+1
                    STA FDC_ST1                         ; --- ST1 ----

                    LDA FDC_RESULTS+2
                    STA FDC_ST2                         ; --- ST2 ----

                    LDA FDC_RESULTS+3
                    STA FDC_CYLINDER                    ; -- C ---

                    LDA FDC_RESULTS+4
                    STA FDC_HEAD                        ; --- H ---

                    LDA FDC_RESULTS+5
                    STA FDC_SECTOR                      ; --- R ---

                    LDA FDC_RESULTS+6
                    STA FDC_SECTOR_SIZE                 ; --- N ---

                    PLP
                    BCC pass_failure

done                PLP
                    PLD
                    PLB
                    RTL

pass_failure        PLP
                    PLD
                    PLB
                    CLC
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
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE
                    
                    TRACE "FDC_GETBLOCK"

                    setaxl                   
                    JSL LBA2CHS                 ; Convert the LBA to CHS

                    JSL FDC_Read_Sector         ; Read the sector
                    BCC pass_failure

                    setas
                    LDA FDC_ST0
                    AND #%11010000              ; Check the error bits
                    BNE read_failure

ret_success         setas
                    LDA #0
                    STA @w BIOS_STATUS
                    
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

read_failure        setas
                    LDA #BIOS_ERR_READ
                    BRA ret_failure

seek_failure        setas
                    LDA #BIOS_ERR_TRACK

ret_failure         STA @w BIOS_STATUS
pass_failure        PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend

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

                    TRACE "FDC_MOUNT"

                    setas
                    setxl
                    LDA #0
                    LDX #0
zero_loop           STA DOS_SECTOR,X
                    INX
                    CPX #512
                    BNE zero_loop

                    LDA #0                                  ; We only support drive 0
                    STA FDC_DRIVE
                    JSL FDC_Motor_On                        ; Turn the motor on

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

                    LDA #DOS_SECTOR_SIZE                    ; Set the size of a FAT12 cluster
                    STA @l CLUSTER_SIZE

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
                    LDA #0
                    STA BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

pass_failure        PLP
                    PLD
                    PLB
                    CLC
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
                setdp FDC_DRIVE

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

                LDA DOS_TEMP
                STA BIOS_LBA
                LDA DOS_TEMP+2
                STA BIOS_LBA+2

                .rept 9
                LSR BIOS_LBA+2                  ; BIOS_LBA := DOS_TEMP / 512
                ROR BIOS_LBA
                .next

                CLC                             ; BIOS_LBA should be the LBA of the first FAT sector we need
                LDA FAT_BEGIN_LBA
                ADC BIOS_LBA
                STA BIOS_LBA
                STA DOS_FAT_LBA                 ; With a copy of the LBA in DOS_FAT_LBA
                LDA FAT_BEGIN_LBA+2
                ADC BIOS_LBA+2
                STA BIOS_LBA+2
                STA DOS_FAT_LBA+2

                LDA #<>DOS_FAT_SECTORS          ; Point to the first 512 bytes of the FAT buffer
                STA BIOS_BUFF_PTR
                LDA #`DOS_FAT_SECTORS
                STA BIOS_BUFF_PTR+2

                JSL FDC_GETBLOCK                ; Attempt to load the first FAT sector
                BCC error

                INC BIOS_LBA                    ; Move to the next sector

                LDA #<>DOS_FAT_SECTORS+512      ; And point to the second 512 bytes of teh FAT buffer
                STA BIOS_BUFF_PTR
                LDA #`DOS_FAT_SECTORS
                STA BIOS_BUFF_PTR+2

                JSL FDC_GETBLOCK                ; Attempt to load the first FAT sector
                BCC error

                LDA DOS_TEMP                    ; Get the offset to the cluster's entry in the FAT
                AND #$03FFF                     ; And mask it so it's an offset to the FAT buffer
                TAX                             ; And move that to X

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
                    setdp FDC_DRIVE

                    setaxl

                    JSL FATFORCLUSTER12             ; Attempt to load the FAT entries
                    BCS chk_clus_id
                    BRL pass_failure

chk_clus_id         LDA DOS_CLUS_ID                 ; Check the cluster ID...
                    BIT #1                          ; Is it odd?
                    BNE is_odd                      ; Yes: calculate the next cluster for odd

                    ; Handle even number clusters...

is_even             TRACE "is_even"
                    setal
                    LDA DOS_FAT_SECTORS,X           ; DOS_CLUS_ID := DOS_FAT_SECTORS[X] & $0FFF
                    AND #$0FFF
                    STA DOS_CLUS_ID
                    STZ DOS_CLUS_ID+2
                    BRA check_id

is_odd              TRACE "is_odd"
                    setal
                    LDA DOS_FAT_SECTORS,X           ; DOS_CLUS_ID := DOS_FAT_SECTORS[X] >> 4
                    .rept 4
                    LSR A
                    .next
                    STA DOS_CLUS_ID
                    STZ DOS_CLUS_ID+2

check_id            setal
                    LDA DOS_CLUS_ID                 ; Check the new cluster ID we got
                    AND #$0FF0                      ; Is it in the range $0FF0 -- $0FFF?
                    CMP #$0FF0
                    BEQ no_more                     ; Yes: return that we've reached the end of the chain

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
; Send a special command code to the floppy drive controller
;
; Inputs:
;   A = the block device number
;   X = the command # to send:
;       1 = Turn on the spindle motor
;       2 = Turn off the spindle motor
;       3 = Recalibrate the drive
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
FDC_CMDBLOCK        .proc
                    PHP

                    setaxs

                    CPX #FDC_DEVCMD_MOTOR_ON
                    BEQ motor_on
                    
                    CPX #FDC_DEVCMD_MOTOR_OFF
                    BEQ motor_off

                    CPX #FDC_DEVCMD_RECAL
                    BEQ recalibrate

ret_success         STZ BIOS_STATUS
                    PLP
                    SEC
                    RTL

motor_on            JSL FDC_Motor_On
                    BRA ret_success

motor_off           JSL FDC_Motor_Off
                    BRA ret_success

recalibrate         JSL FDC_Recalibrate_Command
                    BCS ret_success

pass_failure        PLP
                    CLC
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
                PHP

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
                CLC
                RTL

ret_success     setas
                STZ DOS_STATUS
                PLP
                SEC
                RTL
                .pend