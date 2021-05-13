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
IINITMOUSE      .proc
                PHA
                PHX
                PHD
                PHP

                setdp 0

                SEI

                setas				    ;Set A 8Bits
                setxl 			        ;Set XY 16Bits
                CLC
                LDX #$FFFF 

DO_CMD_A9_AGAIN JSR Poll_Inbuf_Mouse_TimeOut
                BCS mouse_init_fail

                LDA #$A9                        ; Tests second PS2 Channel
                STA @l KBD_CMD_BUF

                JSR Poll_Outbuf_Mouse_TimeOut
                BCC mouse_found

                ; Got no response in time

mouse_init_fail LDA #0                          ; Disable the mouse pointer
                STA @l MOUSE_PTR_CTRL_REG_L

                LDA @lINT_MASK_REG0             ; Make sure the mouse interrupt is disabled
                ORA #FNX0_INT07_MOUSE
                STA @lINT_MASK_REG0

                ; The mouse not being present triggers a spurious keyboard interrupt
                ; So we clear it here as well as any pending mouse interrupts

                LDA @l INT_PENDING_REG1     ; Read the Pending Register &
                AND #FNX1_INT00_KBD
                STA @l INT_PENDING_REG1     ; Writing it back will clear the Active Bit

                LDA @lINT_PENDING_REG0          ; Read the Pending Register &
                AND #FNX0_INT07_MOUSE
                STA @lINT_PENDING_REG0          ; Writing it back will clear the Active Bit

                PLP                             ; Return failure
                PLD
                PLX
                PLA
                SEC
                RTL

mouse_found     LDA KBD_OUT_BUF		            ; Clear the Output buffer
                CMP #$00
                BNE DO_CMD_A9_AGAIN
            
                LDA #$F6                        ;Tell the mouse to use default settings
                JSR MOUSE_WRITE
                JSR MOUSE_READ
                BCS mouse_init_fail


                ; Set the Mouse Resolution 1 Clicks for 1mm - For a 640 x 480, it needs to be the slowest

                LDA #$E8
                JSR MOUSE_WRITE
                JSR MOUSE_READ
                BCS mouse_init_fail
                LDA #$00
                JSR MOUSE_WRITE
                JSR MOUSE_READ
                BCS mouse_init_fail

                LDA #$F4                        ; Enable the Mouse
                JSR MOUSE_WRITE
                JSR MOUSE_READ
                BCS mouse_init_fail

                ; Let's Clear all the Variables Necessary to Computer the Absolute Position of the Mouse

                LDA #$00
                STA MOUSE_PTR

                LDA @lINT_PENDING_REG0          ; Read the Pending Register &
                AND #FNX0_INT07_MOUSE
                STA @lINT_PENDING_REG0          ; Writing it back will clear the Active Bit

                LDA @lINT_MASK_REG0             ; Enable the mouse interrupt
                AND #~FNX0_INT07_MOUSE
                STA @lINT_MASK_REG0

mouse_init_ok   PLP
                PLD
                PLX
                PLA
                CLC
                RTL
                .pend

MOUSE_WRITE     setas
                PHA
                JSR Poll_Inbuf          ; Test bit $01 (if 2, Full)
                LDA #$D4
                STA KBD_CMD_BUF         ; KBD_CMD_BUF		= $AF1064
                JSR Poll_Inbuf
                PLA
                STA KBD_DATA_BUF        ; KBD_DATA_BUF	= $AF1060
                RTS

MOUSE_READ      .proc
                setas
                JSR Poll_Outbuf_Mouse_TimeOut   ; Test bit $01 (if 1, Full)
                BCS done
                LDA KBD_INPT_BUF        ; KBD_INPT_BUF	= $AF1060
done            RTS
                .pend

;
; Wait for the PS/2 output buffer to be clear
; 
Poll_Outbuf_Mouse   .proc
                setas

wait            LDA STATUS_PORT
                AND #OUT_BUF_FULL       ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL
                BNE wait
                RTS
                .pend

;
; Wait for the PS/2 output buffer to be clear (timeout if it never clears)
; 
; Returns:
;   C is clear on success, set on timeout error
; 
Poll_Outbuf_Mouse_TimeOut   .proc
                setas
                setxl

                LDX #$FFFF

wait            LDA STATUS_PORT
                AND #OUT_BUF_FULL       ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL
                BEQ ret_success
                DEX 
                CPX #$0000
                BNE wait

                SEC                     ; Return timeout error
                RTS

ret_success     CLC                     ; Return success
                RTS
                .pend

;
; Wait for the PS/2 input buffer to be clear
; 
Poll_Inbuf	    .proc
                setas
wait            LDA STATUS_PORT         ; Load Status Byte
                AND	#<INPT_BUF_FULL     ; Test bit $02 (if 0, Empty)
                CMP #<INPT_BUF_FULL
                BEQ wait
                RTS
                .pend

;
; Wait for the PS/2 input buffer to have data (timeout if it never clears)
; 
; Returns:
;   C is clear on success, set on timeout error
; 
Poll_Inbuf_Mouse_TimeOut   .proc
                setas
                setxl

                LDX #$FFFF

wait            LDA STATUS_PORT
                AND	#<INPT_BUF_FULL     ; Test bit $02 (if 0, Empty)
                CMP #<INPT_BUF_FULL
                BNE ret_success
                DEX 
                CPX #$0000
                BNE wait

                SEC                     ; Return timeout error
                RTS

ret_success     CLC                     ; Return success
                RTS
                .pend

;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Mouse Interrupt
; /// Desc: Basically Assigning the 3Bytes Packet to Vicky's Registers
; ///       Vicky does the rest
; ///////////////////////////////////////////////////////////////////
MOUSE_INTERRUPT .proc
                PHD
                PHP
                setasx

                SEI

                setdp 0

                LDX @b MOUSE_PTR                ; Get the # of the mouse byte to write
                LDA @l KBD_INPT_BUF             ; Get the byte from the PS/2 interface
                STA @l MOUSE_PTR_BYTE0,X        ; Store it into the correct Vicky register

                INX                             ; Move to the next byte
                CPX #$03                        ; Have we written 3 bytes?
                BNE save_ptr                    ; No: return and wait for the next mouse interrupt

                ; Yes: use Vicky to get the absolute position from the relative count

                LDA @l MOUSE_PTR_X_POS_L
                STA @b MOUSE_POS_X_LO
                LDA @l MOUSE_PTR_X_POS_H
                STA @b MOUSE_POS_X_HI

                LDA @l MOUSE_PTR_Y_POS_L
                STA @b MOUSE_POS_Y_LO
                LDA @l MOUSE_PTR_Y_POS_H
                STA @b MOUSE_POS_Y_HI

                LDX #0                          ; Reset our state machine to the beginning
save_ptr        STX @b MOUSE_PTR                ; Save our next byte position (state)

                PLP
                PLD
                RTL
                .pend

