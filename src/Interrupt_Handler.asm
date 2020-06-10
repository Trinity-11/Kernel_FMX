;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
; Interrupt Handler
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
IRQ_HANDLER
;                LDX #<>irq_Msg
;                JSL IPRINT       ; print the Init
                setas 					; Set 8bits
                ; Go Service the Start of Frame Interrupt Interrupt
                ; IRQ0
                ; Start of Frame Interrupt
                LDA @lINT_PENDING_REG0
                CMP #$00
                BEQ CHECK_PENDING_REG1

                LDA @lINT_PENDING_REG0
                AND #FNX0_INT00_SOF
                CMP #FNX0_INT00_SOF
                BNE SERVICE_NEXT_IRQ2
                STA @lINT_PENDING_REG0
                ; Start of Frame Interrupt
                JSR SOF_INTERRUPT

                ;IRQ1 - Not Implemented Yet
                ;IRQ3 - Not Implemented Yet
                ;IRQ5 - Not Tested Yet
                ;IRQ6
                setas

SERVICE_NEXT_IRQ2
                ; Timer0 Interrupt
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT02_TMR0
                CMP #FNX0_INT02_TMR0
                BNE SERVICE_NEXT_IRQ6
                STA @lINT_PENDING_REG0
                ; Timer 0
                JSR TIMER0_INTERRUPT

                ;IRQ6
                setas
SERVICE_NEXT_IRQ6 ; FDC Interrupt
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT06_FDC
                CMP #FNX0_INT06_FDC
                BNE SERVICE_NEXT_IRQ7
                STA @lINT_PENDING_REG0
                ; Floppy Disk Controller
                JSR FDC_INTERRUPT

                ;IRQ7
                setas
SERVICE_NEXT_IRQ7 ; Mouse IRQ
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT07_MOUSE
                CMP #FNX0_INT07_MOUSE
                BNE CHECK_PENDING_REG1
                STA @lINT_PENDING_REG0
                ; Mouse Interrupt
                JSR MOUSE_INTERRUPT

; Second Block of 8 Interrupts
                ;IRQ8
CHECK_PENDING_REG1
                setas
                LDA @lINT_PENDING_REG1
                CMP #$00
                BEQ EXIT_IRQ_HANDLE


SERVICE_NEXT_IRQ8 ; Keyboard Interrupt
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT00_KBD
                CMP #FNX1_INT00_KBD
                BNE SERVICE_NEXT_IRQ11
                STA @lINT_PENDING_REG1
                ; Keyboard Interrupt
                JSR KEYBOARD_INTERRUPT
                ;BRA EXIT_IRQ_HANDLE
                ;IRQ9 - Not Implemented Yet
                ;IRQ10 - Not Implemented Yet
                ;IRQ11
                setas
SERVICE_NEXT_IRQ11
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT03_COM2
                CMP #FNX1_INT03_COM2
                BNE SERVICE_NEXT_IRQ12
                STA @lINT_PENDING_REG1
                ; Serial Port Com2 Interrupt
                JSR COM2_INTERRUPT
                ;BRA EXIT_IRQ_HANDLE
                ;IRQ12
                setas
SERVICE_NEXT_IRQ12
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT04_COM1
                CMP #FNX1_INT04_COM1
                BNE SERVICE_NEXT_IRQ13
                STA @lINT_PENDING_REG1
                ; Serial Port Com1 Interrupt
                JSR COM1_INTERRUPT
                ;BRA EXIT_IRQ_HANDLE
                ;IRQ13
                setas
SERVICE_NEXT_IRQ13
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT05_MPU401
                CMP #FNX1_INT05_MPU401
                BNE SERVICE_NEXT_IRQ14
                STA @lINT_PENDING_REG1
                ; Serial Port Com1 Interrupt
                JSR MPU401_INTERRUPT
                ;BRA EXIT_IRQ_HANDLE
                ;IRQ14
                setas
SERVICE_NEXT_IRQ14
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT06_LPT
                CMP #FNX1_INT06_LPT
                BNE EXIT_IRQ_HANDLE
                STA @lINT_PENDING_REG1
                ; Serial Port Com1 Interrupt
                JSR LPT1_INTERRUPT
EXIT_IRQ_HANDLE
                ; Exit Interrupt Handler
                setaxl
                RTL
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Start of Frame Interrupt
; /// 60Hz, 16ms Cyclical Interrupt
; ///
; ///////////////////////////////////////////////////////////////////
SOF_INTERRUPT
                .as
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT00_SOF
                STA @lINT_PENDING_REG0

                setal
                LDA @l FDC_MOTOR_TIMER          ; Check the FDC motor count-down timer
                BEQ sof_timeout                 ; If it's zero, check for the watchdog timeout

                DEC A                           ; Otherwise, decrement it...
                STA @l FDC_MOTOR_TIMER
                BNE sof_timeout                 ; If it's not zero, check for the watchdog timeout

                JSL FDC_Motor_Off               ; Otherwise, turn off the motor

sof_timeout     setas
                LDA @l BIOS_TIMER               ; Check the BIOS_TIMER
                BEQ sof_int_done                ; If it's 0, we don't do anything

                DEC A                           ; Count down one tick
                STA @l BIOS_TIMER
                BNE sof_int_done                ; If not 0, we're done

                LDA @l BIOS_FLAGS               ; Otherwise: flag a time out event
                ORA #BIOS_TIMEOUT
                STA @l BIOS_FLAGS

sof_int_done    RTS

; ///////////////////////////////////////////////////////////////////
; ///
; /// Timer 0 Interrupt
; ///
; ///////////////////////////////////////////////////////////////////
TIMER0_INTERRUPT
                setas

                LDA @l TIMERFLAGS               ; Flag that the interrupt has happened
                ORA #TIMER0TRIGGER
                STA @l TIMERFLAGS

                RTS

; ///////////////////////////////////////////////////////////////////
; ///
; /// Timer 2 Interrupt
; ///
; ///////////////////////////////////////////////////////////////////
TIMER2_INTERRUPT
                setas

                LDA @l TIMERFLAGS               ; Flag that the interrupt has happened
                ORA #TIMER2TRIGGER
                STA @l TIMERFLAGS

                RTS

;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Mouse Interrupt
; /// Desc: Basically Assigning the 3Bytes Packet to Vicky's Registers
; ///       Vicky does the rest
; ///////////////////////////////////////////////////////////////////
MOUSE_INTERRUPT .as
                setas
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT07_MOUSE
                STA @lINT_PENDING_REG0
                LDA KBD_INPT_BUF
                LDX #$0000
                setxs
                LDX MOUSE_PTR
                STA @lMOUSE_PTR_BYTE0, X
                INX
                CPX #$03
                BNE EXIT_FOR_NEXT_VALUE
                ; Create Absolute Count from Relative Input
                LDA @lMOUSE_PTR_X_POS_L
                STA MOUSE_POS_X_LO
                LDA @lMOUSE_PTR_X_POS_H
                STA MOUSE_POS_X_HI

                LDA @lMOUSE_PTR_Y_POS_L
                STA MOUSE_POS_Y_LO
                LDA @lMOUSE_PTR_Y_POS_H
                STA MOUSE_POS_Y_HI

                setas
                LDX #$00
EXIT_FOR_NEXT_VALUE
                STX MOUSE_PTR

                setxl
                RTS
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Floppy Controller
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
FDC_INTERRUPT   .as
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT06_FDC
                STA @lINT_PENDING_REG0
;; PUT YOUR CODE HERE
                RTS
;
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Serial Port COM2
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
COM2_INTERRUPT  .as
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT03_COM2
                STA @lINT_PENDING_REG1
;; PUT YOUR CODE HERE
                RTS
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Serial Port COM1
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
COM1_INTERRUPT  .as
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT04_COM1
                STA @lINT_PENDING_REG1
;; PUT YOUR CODE HERE
                RTS
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// MPU-401 (MIDI)
; /// Desc: Interrupt for Data Rx/Tx
; ///
; ///////////////////////////////////////////////////////////////////
MPU401_INTERRUPT  .as
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT05_MPU401
                STA @lINT_PENDING_REG1
;; PUT YOUR CODE HERE
                RTS
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Parallel Port LPT1
; /// Desc: Interrupt for Data Rx/Tx or Process Commencement or Termination
; ///
; ///////////////////////////////////////////////////////////////////
LPT1_INTERRUPT  .as
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT06_LPT
                STA @lINT_PENDING_REG1
;; PUT YOUR CODE HERE
                RTS

NMI_HANDLER
                RTL
