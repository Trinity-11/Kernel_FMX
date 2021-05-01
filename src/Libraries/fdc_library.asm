;;;
;;; Low level routines for controlling the floppy drive
;;;

FDC_MOTOR_TIME = 4295454        ; Time to wait for the motor to come on: 300ms
FDC_SEEK_TIME = 2147727         ; Time to wait for a seek to happen: 150ms

FDC_MOTOR_ON_TIME = 60*15       ; Time (in SOF interrupt counts) for the motor to stay on: ~15s?
FDC_WAIT_TIME = 30              ; Time (in SOF interrupt counts) to allow for a waiting loop to continue

BPB_SECPERCLUS12_OFF = 13       ; Offset to sectors per cluster in a FAT12 boot sector
BPB_ROOT_MAX_ENTRY12_OFF = 17   ; Offset to the maximum number of entries in the root directory in FAT12 boot sector
BPB_SECPERFAT12_OFF = 22        ; Offset to sectors per FAT on a FAT12 boot sector

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

                    JSL CLRSCREEN
                    JSL CSRHOME

                    setaxl

                    JSL FDC_Init
                    BCS init_ok

                    TRACE "Could not initialize drive"
                    BRL motor_off

init_ok             JSL FDC_CHK_MEDIA
                    BCC no_media
                    BRL is_ok1

no_media            TRACE "No media was found."
                    BRL motor_off

is_ok1              JSL FDC_MOUNT
                    BCC mount_err
                    BRL is_ok2

mount_err           TRACE "Could not mount drive."
                    BRL motor_off

is_ok2              JSL FDC_TEST_PUTBLOCK
                    BCS all_ok

                    TRACE "Could not write cluster."
                    BRA motor_off

                    ; setaxl
                    ; LDA #<>BOOT_FILE
                    ; STA @l DOS_RUN_PTR
                    ; LDA #`BOOT_FILE
                    ; STA @l DOS_RUN_PTR+2
                    
                    ; JSL FDC_WRITEVBR
                    ; BCS all_ok

                    ; TRACE "Could not find a free cluster."
                    ; BRA motor_off

all_ok              TRACE "Everything worked OK!"

motor_off           JSL PRINTCR
                    JSL FDC_Motor_Off

                    PLP
                    PLD
                    PLB
                    RTL
                    .pend

FDC_TEST_PUTBLOCK   .proc
                    setas
                    LDA #0                          ; Initialize the data to write to the drive
                    LDX #0
init_loop           STA @l TEST_BUFFER,X
                    INC A
                    INX
                    CPX #512
                    BNE init_loop

                    setal
                    LDA #<>TEST_BUFFER              ; Set BIOS_BUFF_PTR
                    STA @l BIOS_BUFF_PTR
                    LDA #`TEST_BUFFER
                    STA @l BIOS_BUFF_PTR+2

                    LDA #100                        ; Set LBA = 100
                    STA @l BIOS_LBA
                    LDA #0
                    STA @l BIOS_LBA+2

                    JSL FDC_PUTBLOCK                ; Try to write the data

                    RTL
                    .pend


BOOT_FILE           .null "@F:SAMPLE.PGX Hello, world!"
TEST_LOCATION = $020000                     ; Location to try to load it
TEST_BUFFER = $030000                       ; Temporary location for a cluster buffer

;
; Wait for the FDC to be ready for a transfer from the CPU
;
; Bit[7] needs to be 1 in order to send a new command
;
; Outputs:
;   C is set on success, clear if there was a time out
;
FDC_Check_RQM       .proc
                    PHD
                    PHP

                    setdp FDC_DRIVE

                    setas
                    LDA #FDC_WAIT_TIME      ; Set a time out for the loop
                    JSL ISETTIMEOUT

loop                LDA @b BIOS_FLAGS       ; Check if there was a time out
                    BMI time_out            ; If so: signal a time out

                    LDA @l SIO_FDC_MSR
                    BIT #FDC_MSR_RQM
                    BEQ loop

                    LDA #0                  ; Clear the time out
                    JSL ISETTIMEOUT

                    PLP
                    PLD
                    SEC
                    RTS

time_out            PLP
                    PLD
                    CLC
                    RTS
                    .pend

;
; Wait while drive 0 is busy
;
;Bit[0] needs to be cleared before doing anything else (1 = Seeking)
;
FDC_Check_DRV0_BSY  .proc
                    PHD
                    PHP

                    setdp FDC_DRIVE

                    setas
                    LDA #FDC_WAIT_TIME      ; Set a time out for the loop
                    JSL ISETTIMEOUT

loop                LDA @b BIOS_FLAGS       ; Check if there was a time out
                    BMI time_out            ; If so: signal a time out

                    LDA @l SIO_FDC_MSR
                    BIT #FDC_MSR_DRV0BSY
                    BNE loop

                    LDA #0                  ; Clear the time out
                    JSL ISETTIMEOUT

                    PLP
                    PLD
                    SEC
                    RTS

time_out            PLP
                    PLD
                    CLC
                    RTS
                    .pend

;
; Wait while the FDC is busy with a command
;
;Bit[4] Command is in progress when 1
;
FDC_Check_CMD_BSY   .proc
                    PHD
                    PHP

                    setdp FDC_DRIVE

                    setas
                    LDA #FDC_WAIT_TIME      ; Set a time out for the loop
                    JSL ISETTIMEOUT

loop                LDA @b BIOS_FLAGS       ; Check if there was a time out
                    BMI time_out            ; If so: signal a time out

                    LDA @l SIO_FDC_MSR
                    BIT #FDC_MSR_CMDBSY
                    BNE loop

                    LDA #0                  ; Clear the time out
                    JSL ISETTIMEOUT

                    PLP
                    PLD
                    SEC
                    RTS

time_out            PLP
                    PLD
                    CLC
                    RTS
                    .pend

;
; Wait until data is available for reading
;
FDC_Can_Read_Data   .proc
                    PHD
                    PHP

                    setdp FDC_DRIVE

                    setas
                    LDA #FDC_WAIT_TIME      ; Set a time out for the loop
                    JSL ISETTIMEOUT

loop                LDA @b BIOS_FLAGS       ; Check if there was a time out
                    BMI time_out            ; If so: signal a time out

                    LDA @l SIO_FDC_MSR
                    AND #FDC_MSR_DIO
                    CMP #FDC_MSR_DIO
                    BNE loop

                    LDA #0                  ; Clear the time out
                    JSL ISETTIMEOUT

                    PLP
                    PLD
                    SEC
                    RTS

time_out            PLP
                    PLD
                    CLC
                    RTS
                    .pend

;
; Wait until the FDC is clear to receive a byte
;
FDC_CAN_WRITE       .proc
                    PHD
                    PHP

                    setdp FDC_DRIVE

                    setas
                    LDA #FDC_WAIT_TIME      ; Set a time out for the loop
                    JSL ISETTIMEOUT

loop                LDA @b BIOS_FLAGS       ; Check if there was a time out
                    BMI time_out            ; If so: signal a time out

                    LDA @l SIO_FDC_MSR
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM
                    BNE loop

                    LDA #0                  ; Clear the time out
                    JSL ISETTIMEOUT

                    PLP
                    PLD
                    SEC
                    RTS

time_out            PLP
                    PLD
                    CLC
                    RTS
                    .pend

;
; A delay loop that should be around 10ms
;
FDC_DELAY_10MS      .proc
                    PHX
                    PHP

                    setxl
                    LDX #16000          ; Wait for around 10ms
loop                NOP                 ; Each iteration should take 9 cycles
                    DEX
                    CPX #0
                    BNE loop

                    PLP
                    PLX
                    RTL
                    .pend

;
; Execute a command on the floppy disk controller.
;
; Inputs:
;   FDC_PARAMETERS = buffer containing the bytes to send to start the command
;   FDC_PARAM_NUM = The number of parameter bytes to send to the FDC (including command)
;   FDC_RESULT_NUM = The number of result bytes expected ()
;   FDC_EXPECT_DAT = 0: the command expects no data,
;                   >0: the command expects to read data from the drive
;                   <0: the command expects to write data to the drive
;   BIOS_BUFF_PTR = pointer to the buffer to store data
;
; Outputs:
;   FDC_RESULTS = Buffer for results of FDC commands
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
FDC_COMMAND         .proc
                    PHX
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE

                    TRACE "FDC_COMMAND"

                    JSL FDC_DELAY_10MS                      ; Wait around 10ms

                    setaxs
                    LDX #0
                    LDA #0
clr_results         STA FDC_RESULTS,X                       ; Clear the result buffer
                    INX
                    CPX #16
                    BNE clr_results

                    LDA @l SIO_FDC_MSR                      ; Validate we can send a command
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM
                    BEQ start_send                          ; If so, start sending

fdc_reset           JSL FDC_INIT                            ; Reset the FDC

                    ; Command and parameter write phase

start_send          setxs
                    LDX #0
send_loop           JSR FDC_Check_RQM                       ; Wait until we can write
                    BCS send_param
                    BRL time_out                            ; If there was a timeout, flag the time out

send_param          LDA FDC_PARAMETERS,X                    ; Get the parameter/command byte to write
                    STA @l SIO_FDC_DTA                      ; Send it

                    JSL FDC_DELAY_10MS                      ; Wait around 10ms for things to settle
                    
                    INX                                     ; Advance to the next byte
                    CPX FDC_PARAM_NUM
                    BNE send_loop                           ; Keep sending until we've sent them all

                    LDA FDC_EXPECT_DAT                      ; Check the data expectation byte
                    BNE chk_data_dir
                    BRL result_phase                        ; If 0: we just want a result
chk_data_dir        BPL rd_data                             ; If >0: we want to read data

                    ; Write data...

wr_data             ; JSR FDC_CAN_WRITE

wr_data_rdy         LDA FDC_STATUS                          ; Check that the motor is still spinning
                    BMI wr_chk_rqm
                    BRL time_out                            ; If not, raise an error
                    
wr_chk_rqm          LDA @l SIO_FDC_MSR                      ; Wait for ready to write
                    BIT #FDC_MSR_RQM
                    BEQ wr_data_rdy

                    BIT #FDC_MSR_NONDMA                     ; Check if in execution mode
                    BNE wr_data_phase                       ; If so: transfer the data

                    BRL result_phase                          ; If not: it's an error

                    ; Data write phase

wr_data_phase       setxl
                    LDY #0

wr_data_loop        LDA FDC_STATUS                          ; Check that the motor is still spinning
                    BMI wr_chk_nondma
                    BRL time_out                            ; If not, raise an error
                    
wr_chk_nondma       LDA @l SIO_FDC_MSR                      ; Check to see if the FDC is in execution phase
                    BIT #FDC_MSR_NONDMA
                    BEQ result_phase                        ; If not: break out to result phase

                    BIT #FDC_MSR_RQM                        ; Check if we can read data
                    BEQ wr_data_loop                        ; No: keep waiting

                    LDA [BIOS_BUFF_PTR],Y                   ; Get the data byte
                    STA @l SIO_FDC_DTA                      ; And save it to the buffer

                    INY                                     ; Move to the next position
                    CPY #512                                ; TODO: set this from the parameters?
                    BNE wr_data_loop                        ; If not at the end, keep fetching
                    BRA result_phase                        ; ready for the result phase

                    ; Read data

rd_data             JSR FDC_Can_Read_Data

rd_data_rdy         LDA FDC_STATUS                          ; Check that the motor is still spinning
                    BMI chk_rd_rdy                          ; If so, check to see if the data is ready

time_out            setas
                    LDA #BIOS_ERR_TIMEOUT                   ; Otherwise: throw a BIOS_ERR_TIMEOUT error
                    BRL pass_error

chk_rd_rdy          LDA @l SIO_FDC_MSR                      ; Wait for data to be ready
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM | FDC_MSR_DIO
                    BNE rd_data_rdy

                    LDA @l SIO_FDC_MSR                      ; Check to see if the FDC is in execution phase
                    BIT #FDC_MSR_NONDMA
                    BNE rd_data_phase                       ; If so: transfer the data
                    BRL error                               ; If not: it's an error

                    ; Data read phase

rd_data_phase       setxl
                    LDY #0
rd_data_loop        LDA FDC_STATUS                          ; Check that the motor is still spinning
                    BPL time_out                            ; If not: throw a timeout error
                    
                    LDA @l SIO_FDC_MSR                      ; Wait for the next byte to be ready
                    AND #FDC_MSR_RQM | FDC_MSR_DIO
                    CMP #FDC_MSR_RQM | FDC_MSR_DIO
                    BNE rd_data_loop

                    LDA @l SIO_FDC_DTA                      ; Get the data byte
                    STA [BIOS_BUFF_PTR],Y                   ; And save it to the buffer

                    INY                                     ; Move to the next position
                    CPY #512                                ; TODO: set this from the parameters?
                    BNE rd_data_loop                        ; If not at the end, keep fetching

                    ; Result read phase

result_phase        LDA FDC_RESULT_NUM                      ; If no results are expected...
                    BEQ chk_busy                            ; Then we're done
                    
                    setxs
                    LDX #0
                    LDA #FDC_WAIT_TIME                      ; Set the watchdog timer
                    JSL ISETTIMEOUT

result_loop         JSR FDC_Can_Read_Data                   ; Wait until we can read
                    BCC time_out                            ; If there was a time out, raise an error

                    LDA @l SIO_FDC_DTA                      ; Yes: get the data
                    JSR FDC_Can_Read_Data                   ; Wait until we can read
                    BCC time_out                            ; If there was a time out, raise an error

read_result         LDA @l SIO_FDC_DTA                      ; Yes: get the data
                    STA FDC_RESULTS,X                       ; Save it to the result buffer

                    JSR FDC_Check_RQM
                    BCC time_out                            ; If there was a time out, flag the error

rd_chk_1            LDA @l SIO_FDC_MSR
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
                    BCS get_result_byte
                    BRL time_out                            ; If there was a time out, flag the error

get_result_byte     LDA @l SIO_FDC_DTA                      ; Read the data
                    STA FDC_RESULTS,X
                    INX
                    BRA chk_busy                            ; And keep checking

done                TRACE "done"
                    STZ BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    PLX
                    SEC
                    RTL

error               setas
                    LDA #BIOS_ERR_CMD
pass_error          STA BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    PLX
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
                    STA @l SIO_FDC_DSR             
                    LDA #$00                    ; Precompensation set to 0
                    STA @l SIO_FDC_CCR

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

                    JSL FDC_Motor_On

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
                    LDA @l INT_MASK_REG0
                    AND #~FNX0_INT00_SOF        ; Enable the SOF interrupt
                    STA @l INT_MASK_REG0
                    
                    PLP
                    RTL
                    .pend

;
; Turn on the motor of the floppy drive
;
; Outputs:
;   C is set on success, clear if there was a timeout
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
                    BCC time_out

                    LDX #<>FDC_MOTOR_TIME       ; Wait a suitable time for the motor to spin up
                    LDY #`FDC_MOTOR_TIME
                    JSL IDELAY

                    LDA @l FDC_STATUS
                    ORA #$80                    ; Flag that the motor should be on
                    STA @l FDC_STATUS

done                PLP
                    SEC
                    RTL

time_out            PLP                         ; Return a timeout error
                    CLC
                    RTL
                    .pend

;
; Turn off the motor on the floppy drive
;
FDC_Motor_Off       .proc
                    PHP
                    setas

                    ; JSR FDC_Check_DRV0_BSY      ; Make sure the drive is not seeking
                    ; JSR FDC_Check_RQM           ; Check if I can transfer data

                    ; Turn OFF the Motor
                    LDA #FDC_DOR_NRESET
                    STA @L SIO_FDC_DOR

                    ; JSR FDC_Check_RQM           ; Make sure we can leave knowing that everything set properly

                    setal
                    SEI                         ; Turn off interrupts
                    LDA #0                      ; Set FDC motor timeout counter to 0 to disable it
                    STA @l FDC_MOTOR_TIMER

                    setas
                    LDA @l INT_MASK_REG0
                    ORA #FNX0_INT00_SOF         ; Disable the SOF interrupt
                    STA @l INT_MASK_REG0

                    LDA @l FDC_STATUS
                    AND #$7F                    ; Flag that the motor should be off
                    STA @l FDC_STATUS

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
;   BIOS_STATUS = status code describing any error
;   C is set on success, clear on failure
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

                    setaxl
                    LDX #10                            ; Wait for 10ms
                    JSL ILOOP_MS

                    setas
                    STZ FDC_ST0                         ; Clear ST0
                    LDA #$FF
                    STA FDC_PCN                         ; Set PCN to some obviously bad value

                    JSR FDC_Check_CMD_BSY               ; Check I can send a command
                    BCC time_out                        ; If there was a time out, raise an error

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    BCC time_out                        ; If there was a time out, raise an error
                    LDA #FDC_CMD_SENSE_INTERRUPT
                    STA @l SIO_FDC_DTA

                    JSR FDC_Can_Read_Data
                    BCC time_out                        ; If there was a time out, raise an error

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    BCC time_out                        ; If there was a time out, raise an error
                    LDA @l SIO_FDC_DTA
                    STA FDC_ST0                         ; --- ST0 ---

                    JSR FDC_Check_RQM                   ; Check if I can transfer data
                    BCC time_out                        ; If there was a time out, raise an error
                    LDA @l SIO_FDC_DTA
                    STA FDC_PCN                         ; --- Cylinder ---

                    setas
                    STZ @w BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

time_out            setas
                    LDA #BIOS_ERR_TIMEOUT               ; Return a time out error
                    STA @w BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    CLC
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

                    setaxl
                    LDX #10                 ; Wait for 10ms
                    JSL ILOOP_MS

                    setas
                    JSR FDC_Check_CMD_BSY   ; Check I can send a command
                    BCC time_out            ; If there was a time out, raise an error

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    BCC time_out            ; If there was a time out, raise an error
                    LDA #FDC_CMD_SPECIFY    ; Specify Command
                    STA @l SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    BCC time_out            ; If there was a time out, raise an error
                    LDA #$CF
                    STA @l SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    BCC time_out            ; If there was a time out, raise an error
                    LDA #$01                ; 1 = Non-DMA
                    STA @l SIO_FDC_DTA

                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

time_out            setas
                    LDA #BIOS_ERR_TIMEOUT   ; Return a time out error
                    STA @w BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    CLC
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

                    setaxl
                    LDX #10                 ; Wait for 10ms
                    JSL ILOOP_MS

                    setas
                    JSR FDC_Check_CMD_BSY   ; Check I can send a command
                    BCC time_out            ; If there was a time out, raise an error

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    BCC time_out            ; If there was a time out, raise an error
                    LDA #FDC_CMD_CONFIGURE  ; Specify Command
                    STA @l SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    BCC time_out            ; If there was a time out, raise an error
                    LDA #$00
                    STA @l SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    BCC time_out            ; If there was a time out, raise an error
                    LDA #$44                ; Implied Seek, FIFOTHR = 4 byte
                    STA @l SIO_FDC_DTA

                    JSR FDC_Check_RQM       ; Check if I can transfer data
                    BCC time_out            ; If there was a time out, raise an error
                    LDA #$00
                    STA @l SIO_FDC_DTA

                    JSR FDC_Check_CMD_BSY   ; Check I can send a command
                    BCC time_out            ; If there was a time out, raise an error

                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

time_out            setas
                    LDA #BIOS_ERR_TIMEOUT   ; Return a time out error
                    STA @w BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    CLC
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
                    STA FDC_PCN                         ; Get the sector

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

                    JSL FDC_MOTOR_NEEDED                ; Reset the spindle motor timeout clock

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
                    STA FDC_PCN                      ; --- R ---

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

                    setas
                    JSL FDC_MOTOR_NEEDED                ; Reset the spindle motor timeout clock
                  
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

                    LDA #$FF
                    STA FDC_EXPECT_DAT                  ; Expect to write data

                    LDA #7
                    STA FDC_RESULT_NUM                  ; 7 results

command             JSL FDC_COMMAND                     ; Issue the command
                    PHP

get_results         LDA FDC_RESULTS
                    STA FDC_ST0                         ; --- ST0 ---

                    LDA FDC_RESULTS+1
                    STA FDC_ST1                         ; --- ST1 ---

                    LDA FDC_RESULTS+2
                    STA FDC_ST2                         ; --- ST2 ---

                    LDA FDC_RESULTS+3
                    STA FDC_CYLINDER                    ; --- C ---

                    LDA FDC_RESULTS+4
                    STA FDC_HEAD                        ; --- H ---

                    LDA FDC_RESULTS+5
                    STA FDC_PCN                      ; --- R ---

                    LDA FDC_RESULTS+6
                    STA FDC_SECTOR_SIZE                 ; --- N ---

check_status        PLP
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
                    STA DIVIDEND
                    LDA BIOS_LBA+2
                    STA DIVIDEND+2

                    LDA #36
                    STA DIVISOR
                    STZ DIVISOR+2

                    JSR DIVIDE32

                    setas
                    LDA DIVIDEND
                    STA FDC_CYLINDER
                    setal

                    ; HEAD = (LBA % (HPC * SPT)) / SPT
                    LDA REMAINDER
                    STA DIVIDEND
                    LDA REMAINDER+2
                    STA DIVIDEND+2

                    LDA #18
                    STA DIVISOR
                    STZ DIVISOR+2

                    JSR DIVIDE32

                    setas
                    LDA DIVIDEND
                    AND #$01
                    STA FDC_HEAD
                    
                    ; SECT = (LBA % (HPC * SPT)) % SPT + 1 
                    LDA REMAINDER
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

                    setas
                    LDA #3                      ; We can retry 3 times
                    STA FDC_CMD_RETRY

                    setaxl                   
                    JSL LBA2CHS                 ; Convert the LBA to CHS

                    setas
                    LDA FDC_SECTOR              ; Just make sure the sector is ok
                    BEQ read_failure
                    
try_read            setal
                    JSL FDC_Read_Sector         ; Read the sector
                    BCC retry

                    setas
                    LDA FDC_ST0
                    AND #%11010000              ; Check the error bits
                    BNE read_failure

                    ; LDA FDC_ST1               ; TODO: figure out why the status registers sometimes come back as jibberish
                    ; AND #%00110101
                    ; BNE read_failure

ret_success         setas
                    LDA #0
                    STA @w BIOS_STATUS
                    
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

retry               setas                       ; Check to see if we can try again
                    DEC FDC_CMD_RETRY           ; Decrement the retry counter
                    BMI pass_failure            ; If it's gone negative, we should quit with an error

                    JSL FDC_INIT                ; Otherwise, reinitialize the FDC
                    BRA try_read                ; And try the read again

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
; Write a 512 byte block to the floppy disk from memory
;
; Inputs:
;   BIOS_LBA = the 32-bit block address to write
;   BIOS_BUFF_PTR = pointer to the location containing the data to write
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
FDC_PUTBLOCK        .proc
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE
                    
                    TRACE "FDC_PUTBLOCK"

                    setas
                    LDA #3                      ; Set the number of retries we're willing to do
                    STA @w FDC_CMD_RETRY

                    setaxl                   
                    JSL LBA2CHS                 ; Convert the LBA to CHS

retry               JSL FDC_Write_Sector        ; Write the sector
                    BCS chk_st0
                    BRL attempt_retry

chk_st0             setas
                    LDA FDC_ST0
                    AND #%11010000              ; Check the error bits
                    BNE write_failure

ret_success         TRACE "FDC_PUTBLOCK SUCCESS"
                    setas
                    LDA #0
                    STA @w BIOS_STATUS
                    
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

write_failure       setas
                    LDA FDC_ST1                         ; Check ST1 for write protect
                    BIT #FDC_ST1_NW
                    BEQ generic_err     
                    LDA #BIOS_ERR_WRITEPROT             ; Yes: return a write-protect error
                    BRA ret_failure

generic_err         BIT #FDC_ST1_OR                     ; TODO: properly handle over/under run errors
                    BNE ret_success

                    BIT #FDC_ST1_EN                     ; TODO: properly handle end-of-track
                    BNE ret_success

attempt_retry       setas
                    DEC @w FDC_CMD_RETRY                ; Count down the retries
                    BNE retry                           ; And retry unless we have none left

                    LDA #BIOS_ERR_WRITE                 ; Otherwise: return a generic write error
                    BRA ret_failure

seek_failure        setas
                    LDA #BIOS_ERR_TRACK

ret_failure         TRACE "FDC_PUTBLOCK SUCCESS"

                    STA @w BIOS_STATUS
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

                    JSL FDC_INIT

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
                    LDA DOS_SECTOR+BPB_SECPERCLUS12_OFF     ; Get the # of sectors per cluster (usually 1)
                    STA @l SECTORS_PER_CLUSTER

                    setal
                    LDA #0                                  ; First sector of the "partition" is 0
                    STA @l FIRSTSECTOR
                    STA @l FIRSTSECTOR+2

                    LDA DOS_SECTOR+BPB_SECPERFAT12_OFF      ; Get the number of sectors per FAT
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

                    LDA DOS_SECTOR+BPB_ROOT_MAX_ENTRY12_OFF ; Get the maximum number of directory entries for the root dir
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
                    BRA no_volume_id                        ; No: there is no volume ID

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
                    PHB
                    PHD
                    PHP

                    setdbr 0
                    setdp FDC_DRIVE
                    setaxs

                    CPX #FDC_DEVCMD_MOTOR_ON
                    BEQ motor_on
                    
                    CPX #FDC_DEVCMD_MOTOR_OFF
                    BEQ motor_off

                    CPX #FDC_DEVCMD_RECAL
                    BEQ recalibrate

ret_success         STZ BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL

motor_on            JSL FDC_Motor_On
                    BRA ret_success

motor_off           JSL FDC_Motor_Off
                    BRA ret_success

recalibrate         JSL FDC_Recalibrate_Command
                    BCS ret_success

pass_failure        PLP
                    PLD
                    PLB
                    CLC
                    RTL
                    .pend

;
; Validate that a disk is in the drive.
;
; Outputs:
;   C is set, if there is a disk, clear otherwise
;
FDC_CHK_MEDIA       .proc
                    PHD
                    PHP

                    TRACE "FDC_CHK_MEDIA"

                    setdp FDC_DRIVE

                    JSL FDC_Motor_On                ; Turn on the motor

                    setas
                    LDA @l SIO_FDC_DIR              ; Check if the DSKCHG bit is set
                    BIT #FDC_DIR_DSKCHG
                    BEQ ret_true                    ; If not: assume the disk is present

                    LDA #0
                    STA FDC_DRIVE

                    LDA #0
                    STA FDC_HEAD

                    LDA #80
                    STA FDC_CYLINDER

                    JSL FDC_Seek_Track              ; Attempt to seek to track 80
                    BCC ret_false                   ; If fail: return false

                    setxl

                    LDX #<>FDC_MOTOR_TIME       ; Wait a suitable time for the motor to spin up
                    LDY #`FDC_MOTOR_TIME
                    JSL IDELAY

                    JSL FDC_Sense_Int_Status
                    LDA FDC_ST0
                    AND #%11010000
                    BNE ret_false

                    JSL FDC_Recalibrate_Command     ; Attempt to recalibrate
                    BCC ret_false                   ; If fail: return false

                    LDX #<>FDC_MOTOR_TIME       ; Wait a suitable time for the motor to spin up
                    LDY #`FDC_MOTOR_TIME
                    JSL IDELAY

                    JSL FDC_Sense_Int_Status
                    LDA FDC_ST0
                    AND #%11010000
                    BNE ret_false

ret_true            TRACE "DISK PRESENT"
                    PLP
                    PLD
                    SEC
                    RTL

ret_false           TRACE "NO MEDIA"
                    PLP
                    PLD
                    CLC
                    RTL
                    .pend

;
; Write a volume block record to the floppy drive
;
; Inputs:
;   DOS_RUN_PTR = pointer to the path to the binary to execute (0 for non-booting)
;
FDC_WRITEVBR        .proc
                    PHB
                    PHD
                    PHP

                    TRACE "FDC_WRITEVBR"

                    setdbr 0
                    setdp SDOS_VARIABLES

                    JSL FDC_MOUNT               ; Mount the floppy disk

                    setaxl
                    LDA #0                      ; Clear the sector buffer
                    LDX #0
clr_loop            STA DOS_SECTOR,X
                    INX
                    INX
                    CPX #512
                    BNE clr_loop

                    setas
                    LDX #0                      ; Copy the prototype VBR to the sector buffer
copy_loop           LDA FDC_VBR_BEGIN,X
                    STA DOS_SECTOR,X
                    INX
                    CPX #<>(FDC_VBR_END - FDC_VBR_BEGIN + 1)
                    BNE copy_loop

                    LDY #0                      ; Copy the boot binary path to the VBR
                    LDX #FDC_VBR_PATH
path_copy_loop      LDA [DOS_RUN_PTR],Y
                    STA DOS_SECTOR,X
                    BEQ path_copy_done
                    INX
                    INY
                    CPY #128
                    BNE path_copy_loop

path_copy_done      setal
                    LDA #$AA55                  ; Set the VBR signature bytes at the end
                    STA DOS_SECTOR+BPB_SIGNATURE

                    setal
                    LDA #<>DOS_SECTOR           ; Point to the BIOS buffer
                    STA BIOS_BUFF_PTR
                    LDA #`DOS_SECTOR
                    STA BIOS_BUFF_PTR+2

                    LDA #0                      ; Set the sector to #0 (boot record)
                    STA BIOS_LBA
                    STA BIOS_LBA+2

                    setas
                    LDA #BIOS_DEV_FDC
                    STA BIOS_DEV

                    JSL PUTBLOCK                ; Attempt to write the boot record
                    BCS ret_success

                    JSL FDC_Motor_Off

                    PLP                         ; Return the failure
                    PLD
                    PLB
                    CLC
                    RTL

ret_success         JSL FDC_Motor_Off

                    setas                       ; Return success
                    LDA #0
                    STA BIOS_STATUS
                    PLP
                    PLD
                    PLB
                    SEC
                    RTL
                    .pend

;
; Interrupt handler for the SOF interrupt to update the FDC timeout counter
;
FDC_TIME_HANDLE     .proc
                    PHP

                    ; TODO: seeing odd behavior with the timer

                    setas                           ; Switching to 8 bit counting... for now.
                    LDA @l FDC_MOTOR_TIMER          ; Check the FDC motor count-down timer
                    BNE dec_motor                   ; If not zero: decrement the timer
                    LDA @l FDC_MOTOR_TIMER+1        ; Check the high byte
                    BEQ sof_timeout                 ; If zero: move on to the next timer

dec_motor           LDA @l FDC_MOTOR_TIMER          ; Decrement the low byte
                    DEC A
                    STA @l FDC_MOTOR_TIMER
                    CMP #$FF                        ; Did it roll over?
                    BNE chk_motor_end               ; No: check to see if we're a the end

                    LDA @l FDC_MOTOR_TIMER+1        ; Decrement the high byte
                    DEC A
                    STA @l FDC_MOTOR_TIMER+1
                    BRA sof_timeout                 ; And move on to the next timer

chk_motor_end       LDA @l FDC_MOTOR_TIMER          ; Check timer
                    BNE sof_timeout                 ; if it's <>0, move on to the next timer
                    LDA @l FDC_MOTOR_TIMER+1
                    BNE sof_timeout

                    JSL FDC_Motor_Off               ; Otherwise, turn off the motor

sof_timeout         setas
                    LDA @l BIOS_TIMER               ; Check the BIOS_TIMER
                    BEQ sof_int_done                ; If it's 0, we don't do anything

                    DEC A                           ; Count down one tick
                    STA @l BIOS_TIMER
                    BNE sof_int_done                ; If not 0, we're done

                    LDA @l BIOS_FLAGS               ; Otherwise: flag a time out event
                    ORA #BIOS_TIMEOUT
                    STA @l BIOS_FLAGS

sof_int_done        PLP
                    RTL
                    .pend

FDC_BOOT_START = 62                         ; Entry point to the boot code
FDC_VBR_PATH = 64                           ; Offset to the path in the VBR
FDC_VBR_BEGIN       .block
start               .byte $EB, $00, $90     ; Entry point
magic               .text "C256DOS "        ; OEM name / magic text for booting
bytes_per_sec       .word 512               ; How many bytes per sector
sec_per_cluster     .byte 1                 ; How many sectors per cluster
rsrv_sectors        .word 1                 ; Number of reserved sectors
num_fat             .byte 2                 ; Number of FATs
max_dir_entry       .word (32-18)*16        ; Total number of root dir entries
total_sectors       .word 2880              ; Total sectors
media_descriptor    .byte $F0               ; 3.5" 1.44 MB floppy 80 tracks, 18 tracks per sector
sec_per_fat         .word 9                 ; Sectors per FAT
sec_per_track       .word 18                ; Sectors per track
num_head            .word 2                 ; Number of heads
ignore2             .dword 0
fat32_sector        .dword 0                ; # of sectors in FAT32
ignore3             .word 0
boot_signature      .byte $29
volume_id           .dword $12345678        ; Replaced by code
volume_name         .text "UNTITLED   "     ; Replace by code
fs_type             .text "FAT12   "

; Boot code (assumes we are in native mode)
                    
                    BRA vbr_start

file_path           .fill 64                ; Reserve 64 bytes for a path and any options

vbr_start           setal
                    LDA #<>(DOS_SECTOR + (file_path - FDC_VBR_BEGIN))
                    STA @l DOS_RUN_PARAM
                    LDA #`(DOS_SECTOR + (file_path - FDC_VBR_BEGIN))
                    STA @l DOS_RUN_PARAM+2
                    
                    JSL F_RUN               ; And try to execute the binary file
                    BCS lock                ; If it returned success... lock up... I guess?

error               setas
                    PHK                     ; Otherwise, print an error message
                    PLB
                    PER message
                    PLX
                    JSL PUTS

lock                NOP                     ; And lock up
                    BRA lock

message             .null "Could not find a bootable binary.",13
                    .bend
FDC_VBR_END
