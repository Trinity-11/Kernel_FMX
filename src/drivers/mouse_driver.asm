;
; Code to support the PS/2 mouse
;

;
; IINIT_MOUSE
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize the Keyboard Controler (8042) in the SuperIO.
; Inputs:
;   None
; Affects:
;   Carry (c)
IINITMOUSE      PHA
                PHX
                PHD
                PHP

                setas				    ;Set A 8Bits
                setxl 			        ;Set XY 16Bits
                CLC
                LDX #$FFFF 

DO_CMD_A9_AGAIN
                JSR Poll_Inbuf
                LDA #$A9                ; Tests second PS2 Channel
                STA KBD_CMD_BUF
                JSR Poll_Outbuf_Mouse_TimeOut ;
                
				LDA KBD_OUT_BUF		    ; Clear the Output buffer
                CMP #$00
                BNE DO_CMD_A9_AGAIN
            
                LDA #$F6                ;Tell the mouse to use default settings
                JSR MOUSE_WRITE
                JSR MOUSE_READ

                ; Set the Mouse Resolution 1 Clicks for 1mm - For a 640 x 480, it needs to be the slowest
                LDA #$E8
                JSR MOUSE_WRITE
                JSR MOUSE_READ
                LDA #$00
                JSR MOUSE_WRITE
                JSR MOUSE_READ

                LDA #$F4                ; Enable the Mouse
                JSR MOUSE_WRITE
                JSR MOUSE_READ

                ; Let's Clear all the Variables Necessary to Computer the Absolute Position of the Mouse
                LDA #$00
                STA MOUSE_PTR

                LDA @lINT_PENDING_REG0  ; Read the Pending Register &
                AND #FNX0_INT07_MOUSE
                STA @lINT_PENDING_REG0  ; Writing it back will clear the Active Bit
                LDA @lINT_MASK_REG0
                AND #~FNX0_INT07_MOUSE
                STA @lINT_MASK_REG0
                setxl 					; Set 16bits
                LDX #<>Success_ms_init                 
                BRA InitMsSuccess

initms_loop_out LDX #<>Failed_ms_init
InitMsSuccess   ;JSL IPRINT             ; print Message                   
                setal 					; Set 16bits
                PLP
                PLD
                PLX
                PLA
                RTL

MOUSE_WRITE     setas
                PHA
                JSR Poll_Inbuf          ; Test bit $01 (if 2, Full)
                LDA #$D4
                STA KBD_CMD_BUF         ; KBD_CMD_BUF		= $AF1064
                JSR Poll_Inbuf
                PLA
                STA KBD_DATA_BUF        ; KBD_DATA_BUF	= $AF1060
                RTS

MOUSE_READ      setas
                JSR Poll_Outbuf_Mouse   ; Test bit $01 (if 1, Full)
                LDA KBD_INPT_BUF        ; KBD_INPT_BUF	= $AF1060
                RTS

Poll_Outbuf_Mouse
                setas
                LDA STATUS_PORT
                AND #OUT_BUF_FULL       ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL
                BNE Poll_Outbuf_Mouse
                RTS

Poll_Outbuf_Mouse_TimeOut
                setas
                LDA STATUS_PORT
                AND #OUT_BUF_FULL       ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL
                BEQ Poll_OutbufWeAreDone
                DEX 
                CPX #$0000
                BNE Poll_Outbuf_Mouse_TimeOut
                BRA initms_loop_out
Poll_OutbufWeAreDone:
                RTS

;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Mouse Interrupt
; /// Desc: Basically Assigning the 3Bytes Packet to Vicky's Registers
; ///       Vicky does the rest
; ///////////////////////////////////////////////////////////////////
MOUSE_INTERRUPT .proc
                PHP
                setasx

                LDA @l MOUSE_PTR                ; Get the # of the mouse byte to write
                CMP #3                          ; Check that mouse pointer is in bounds
                BLT mouse_ptr_ok                ; If it is: fetch the byte
                LDA #0                          ; If not, reset it
mouse_ptr_ok    TAX                             ; into X

                LDA @l KBD_INPT_BUF             ; Get the byte from the PS/2 interface
                STA @l MOUSE_PTR_BYTE0, X       ; Store it into the correct Vicky register

                INX                             ; Move to the next byte
                CPX #$03                        ; Have we written 3 bytes?
                BNE EXIT_FOR_NEXT_VALUE         ; No: return and wait for the next mouse interrupt

                ; Yes: use Vicky to get the absolute position from the relative count

                LDA @l MOUSE_PTR_X_POS_L
                STA @l MOUSE_POS_X_LO
                LDA @l MOUSE_PTR_X_POS_H
                STA @l MOUSE_POS_X_HI

                LDA @l MOUSE_PTR_Y_POS_L
                STA @l MOUSE_POS_Y_LO
                LDA @l MOUSE_PTR_Y_POS_H
                STA @l MOUSE_POS_Y_HI

                LDX #$00                        ; Reset our state machine to the beginning
EXIT_FOR_NEXT_VALUE
                TXA                             ; Save our next byte position (state)
                STA @l MOUSE_PTR

                PLP
                RTL
                .pend