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
                BNE SERVICE_NEXT_IRQ6
                STA @lINT_PENDING_REG0
                ; Start of Frame Interrupt
                JSR SOF_INTERRUPT
                ;BRA EXIT_IRQ_HANDLE

                ;IRQ1 - Not Implemented Yet
                ;IRQ2 - Not Implemented Yet
                ;IRQ3 - Not Implemented Yet
                ;IRQ4 - Not Implemented Yet
                ;IRQ5 - Not Tested Yet
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
;                BRA EXIT_IRQ_HANDLE
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
                ;BRA EXIT_IRQ_HANDLE

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

KEYBOARD_INTERRUPT
                ldx #$0000
                setxs
                setas
                ; Clear the Pending Flag
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT00_KBD
                STA @lINT_PENDING_REG1

IRQ_HANDLER_FETCH
                LDA KBD_INPT_BUF        ; Get Scan Code from KeyBoard
                STA KEYBOARD_SC_TMP     ; Save Code Immediately
                ; Check for Shift Press or Unpressed
                CMP #$2A                ; Left Shift Pressed
                BNE NOT_KB_SET_SHIFT
                BRL KB_SET_SHIFT
NOT_KB_SET_SHIFT
                CMP #$AA                ; Left Shift Unpressed
                BNE NOT_KB_CLR_SHIFT
                BRL KB_CLR_SHIFT
NOT_KB_CLR_SHIFT
                ; Check for CTRL Press or Unpressed
                CMP #$1D                ; Left CTRL pressed
                BNE NOT_KB_SET_CTRL
                BRL KB_SET_CTRL
NOT_KB_SET_CTRL
                CMP #$9D                ; Left CTRL Unpressed
                BNE NOT_KB_CLR_CTRL
                BRL KB_CLR_CTRL

NOT_KB_CLR_CTRL
                CMP #$38                ; Left ALT Pressed
                BNE NOT_KB_SET_ALT
                BRL KB_SET_ALT
NOT_KB_SET_ALT
                CMP #$B8                ; Left ALT Unpressed
                BNE KB_UNPRESSED
                BRL KB_CLR_ALT


KB_UNPRESSED    AND #$80                ; See if the Scan Code is press or Depressed
                CMP #$80                ; Depress Status - We will not do anything at this point
                BNE KB_NORM_SC
                BRL KB_CHECK_B_DONE

KB_NORM_SC      LDA KEYBOARD_SC_TMP       ;
                TAX
                LDA KEYBOARD_SC_FLG     ; Check to See if the SHIFT Key is being Pushed
                AND #$10
                CMP #$10
                BEQ SHIFT_KEY_ON

                LDA KEYBOARD_SC_FLG     ; Check to See if the CTRL Key is being Pushed
                AND #$20
                CMP #$20
                BEQ CTRL_KEY_ON

                LDA KEYBOARD_SC_FLG     ; Check to See if the ALT Key is being Pushed
                AND #$40
                CMP #$40
                BEQ ALT_KEY_ON
                ; Pick and Choose the Right Bank of Character depending if the Shift/Ctrl/Alt or none are chosen
                LDA @lScanCode_Press_Set1, x
                BRL KB_WR_2_SCREEN
SHIFT_KEY_ON    LDA @lScanCode_Shift_Set1, x
                BRL KB_WR_2_SCREEN
CTRL_KEY_ON     LDA @lScanCode_Ctrl_Set1, x
                BRL KB_WR_2_SCREEN
ALT_KEY_ON      LDA @lScanCode_Alt_Set1, x

                ; Write Character to Screen (Later in the buffer)
KB_WR_2_SCREEN
                PHA
                setxl
                JSL SAVECHAR2CMDLINE
                setas
                PLA
                JSL PUTC
                JMP KB_CHECK_B_DONE

KB_SET_SHIFT    LDA KEYBOARD_SC_FLG
                ORA #$10
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_CLR_SHIFT    LDA KEYBOARD_SC_FLG
                AND #$EF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_CTRL    LDA KEYBOARD_SC_FLG
                ORA #$20
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_CLR_CTRL    LDA KEYBOARD_SC_FLG
                AND #$DF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_ALT      LDA KEYBOARD_SC_FLG
                ORA #$40
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_CLR_ALT     LDA KEYBOARD_SC_FLG
                AND #$BF
                STA KEYBOARD_SC_FLG

KB_CHECK_B_DONE .as
                LDA STATUS_PORT
                AND #OUT_BUF_FULL ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL ; if Still Byte in the Buffer, fetch it out
                BNE KB_DONE
                JMP IRQ_HANDLER_FETCH

KB_DONE
                setaxl
                RTS
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
;; PUT YOUR CODE HERE
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
