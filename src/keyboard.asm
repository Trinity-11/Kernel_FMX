;;;
;;; Code to support keyboard entry from the PS/2 port
;;;

KBD_PROCESS_BYTE
                PHP
                JSR KEYBOARD_INTERRUPT
                PLP
                RTL

;
; IINITKEYBOARD
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize the Keyboard Controler (8042) in the SuperIO.
; Inputs:
;   None
; Affects:
;   Carry (c)
IINITKEYBOARD	PHD
		PHP
		PHA
		PHX

                setas				;just make sure we are in 8bit mode
                setxl 					; Set 8bits

				        ; Setup Foreground LUT First
                CLC

                JSR Poll_Inbuf ;
;; Test AA
		LDA #$AA			;Send self test command
		STA KBD_CMD_BUF
								;; Sent Self-Test Code and Waiting for Return value, it ought to be 0x55.
                JSR Poll_Outbuf ;

                LDA KBD_OUT_BUF		;Check self test result
                CMP #$55
                BEQ	passAAtest

                BRL initkb_loop_out

passAAtest
.if TEST_KEYBOARD
  LDX #<>pass_tst0xAAmsg
  JSL IPRINT      ; print Message
.endif
;; Test AB
		LDA #$AB			;Send test Interface command
                STA KBD_CMD_BUF
                JSR Poll_Outbuf ;
		LDA KBD_OUT_BUF		;Display Interface test results
		CMP #$00			;Should be 00
		BEQ	passABtest
                BRL initkb_loop_out

passABtest      
.if TEST_KEYBOARD
  LDX #<>pass_tst0xABmsg
  JSL IPRINT       ; print Message
.endif

;; Program the Keyboard & Enable Interrupt with Cmd 0x60
                LDA #$60            ; Send Command 0x60 so to Enable Interrupt
                STA KBD_CMD_BUF
                JSR Poll_Inbuf ;
;.if TARGET_SYS == SYS_C256_FMX
                ;LDA #%01100001      ; Enable Interrupt - Translation from CODE 2 to CODE 1 Scan code is enable
                LDA #%01000011      ; Enable Interrupt - Translation from CODE 2 to CODE 1 Scan code is enable                
;.else
                ;LDA #%00101001      ; Enable Interrupt
;.endif
                ;LDA #%01001011      ; Enable Interrupt for Mouse and Keyboard
                STA KBD_DATA_BUF
                JSR Poll_Inbuf ;
.if TEST_KEYBOARD                
                LDX #<>pass_cmd0x60msg
                JSL IPRINT       ; print Message
.endif
; Reset Keyboard
                LDA #$FF      ; Send Keyboard Reset command
                STA KBD_DATA_BUF
                ; Must wait here;
                LDX #$FFFF
DLY_LOOP1       DEX
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                CPX #$0000
                BNE DLY_LOOP1
                JSR Poll_Outbuf ;

                LDA KBD_OUT_BUF   ; Read Output Buffer

.if TEST_KEYBOARD
                LDX #<>pass_cmd0xFFmsg
                JSL IPRINT       ; print Message
.endif
DO_CMD_F4_AGAIN
                JSR Poll_Inbuf ;
				        LDA #$F4			; Enable the Keyboard
				        STA KBD_DATA_BUF
                JSR Poll_Outbuf ;

				        LDA KBD_OUT_BUF		; Clear the Output buffer
                CMP #$FA
                BNE DO_CMD_F4_AGAIN
                ; Till We Reach this point, the Keyboard is setup Properly


                ; Unmask the Keyboard interrupt
                ; Clear Any Pending Interrupt
                LDA @lINT_PENDING_REG1  ; Read the Pending Register &
                AND #FNX1_INT00_KBD
                STA @lINT_PENDING_REG1  ; Writing it back will clear the Active Bit
                ; Disable the Mask
                LDA @lINT_MASK_REG1
                AND #~FNX1_INT00_KBD
                STA @lINT_MASK_REG1

                LDX #<>Success_kb_init
                SEC
                BCS InitKbSuccess

initkb_loop_out ;LDX #<>Failed_kb_init
InitKbSuccess   JSL IPRINT       ; print Message
                setal 					; Set 16bits
                setxl 					; Set 16bits

                PLX
                PLA
				        PLP
				        PLD
                RTL

; Interrupt handler for the keyboard
KEYBOARD_INTERRUPT
                setdp KEY_BUFFER

                ldx #$0000
                setxs
                setas
                ; Clear the Pending Flag
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT00_KBD
                STA @lINT_PENDING_REG1

IRQ_HANDLER_FETCH
                LDA @lKBD_INPT_BUF      ; Get Scan Code from KeyBoard
                STA KEYBOARD_SC_TMP     ; Save Code Immediately

                LDA KEYBOARD_SC_FLG     ; Check to See if the Prefix was picked up before
                AND #$80
                CMP #$80
                BNE CHK_LSHIFT          ; No: do normal scan-code checks

PREFIX_ON       LDA KEYBOARD_SC_FLG     ; Otherwise: clear prefix
                AND #$7F
                STA KEYBOARD_SC_FLG

                LDA KEYBOARD_SC_TMP     ; Get the prefixed scan-code's character
                TAX
                LDA @lScanCode_Prefix_Set1, x
                JMP KB_WR_2_SCREEN      ; And save it

                ; Check for Shift Press or Unpressed
CHK_LSHIFT      LDA KEYBOARD_SC_TMP
                CMP #$2A                ; Left Shift Pressed
                BNE NOT_KB_SET_LSHIFT
                BRL KB_SET_SHIFT
NOT_KB_SET_LSHIFT
                CMP #$AA                ; Left Shift Unpressed
                BNE NOT_KB_CLR_LSHIFT
                BRL KB_CLR_SHIFT
NOT_KB_CLR_LSHIFT
                ; Check for right Shift Press or Unpressed
                CMP #$36                ; Right Shift Pressed
                BNE NOT_KB_SET_RSHIFT
                BRL KB_SET_SHIFT
NOT_KB_SET_RSHIFT
                CMP #$B6                ; Right Shift Unpressed
                BNE NOT_KB_CLR_RSHIFT
                BRL KB_CLR_SHIFT
NOT_KB_CLR_RSHIFT
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
                BNE NOT_KB_CLR_ALT
                BRL KB_CLR_ALT

NOT_KB_CLR_ALT  CMP #$E0                ; Prefixed scan code
                BNE NOT_PREFIXED
                BRL KB_SET_PREFIX

NOT_PREFIXED    CMP #$45                ; Numlock Pressed
                BNE NOT_KB_SET_NUM
                BRL KB_TOG_NUMLOCK

NOT_KB_SET_NUM  CMP #$46                ; Scroll Lock Pressed
                BNE NOT_KB_SET_SCR
                BRL KB_TOG_SCRLOCK

NOT_KB_SET_SCR  CMP #$3A                ; Caps Lock Pressed
                BNE NOT_KB_CAPSLOCK
                BRL KB_TOG_CAPLOCK

NOT_KB_CAPSLOCK CMP #$58                ; F12 Pressed
                BNE KB_UNPRESSED
                LDA #KB_CREDITS         ; Yes: flag that the CREDITS key has been pressed
                STA @lKEYFLAG
                BRL KB_CHECK_B_DONE

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
                BRL KB_WR_2_SCREEN

                ; Write Character to Screen (Later in the buffer)
KB_WR_2_SCREEN  CMP #$18                ; Is it SysRq?
                BNE savechar
                JMP programmerKey       ; Yes: trigger the programmer key

savechar        PHA
                setxl
                JSR SAVEKEY
                setas
                PLA
                JMP KB_CHECK_B_DONE

KB_SET_SHIFT    LDA KEYBOARD_SC_FLG
                ORA #$10
                STA KEYBOARD_SC_FLG

                JMP KB_CHECK_B_DONE

KB_CLR_SHIFT    LDA KEYBOARD_SC_FLG
                AND #$EF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_CTRL     LDA KEYBOARD_SC_FLG
                ORA #$20
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_CLR_CTRL     LDA KEYBOARD_SC_FLG
                AND #$DF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_ALT      LDA KEYBOARD_SC_FLG
                ORA #$40
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_CLR_ALT      LDA KEYBOARD_SC_FLG
                AND #$BF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_PREFIX   LDA KEYBOARD_SC_FLG
                ORA #$80
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_TOG_SCRLOCK  LDA KEYBOARD_LOCKS
                EOR #KB_SCROLL_LOCK         ; toggle the Scroll Lock flag
                STA KEYBOARD_LOCKS
                JMP KB_CHECK_B_DONE

KB_TOG_NUMLOCK  LDA KEYBOARD_SC_FLG         ; Check flags...
                AND #$60                    ; ... is control-alt pressed?
                CMP #$60
                BNE KB_TOG_NUMLOC2
                BRL KB_NORM_SC              ; No: treat as a BREAK key

KB_TOG_NUMLOC2  LDA KEYBOARD_LOCKS
                EOR #KB_NUM_LOCK            ; toggle the Num Lock flag
                STA KEYBOARD_LOCKS
                JMP KB_CHECK_B_DONE

KB_TOG_CAPLOCK  LDA KEYBOARD_LOCKS
                EOR #KB_CAPS_LOCK           ; toggle the Caps Lock flag
                STA KEYBOARD_LOCKS

KB_CHECK_B_DONE .as
                LDA STATUS_PORT
                AND #OUT_BUF_FULL           ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL           ; if Still Byte in the Buffer, fetch it out
                BNE SET_LED
                JMP IRQ_HANDLER_FETCH

SET_LED         ; LDA #$ED                    ; Command to set LEDs
;                 STA KBD_CMD_BUF             ; Send the command
;                 JSR Poll_Inbuf              ; Wait for the keyboard to be ready
;                 LDA KEYBOARD_LOCKS          ; Get the current lock status
;                 STA KBD_DATA_BUF            ; And send it to the keyboard
;                 JSR Poll_Inbuf              ; Wait for the keyboard to be ready

KB_DONE         setaxl
                RTS

;
; The user has pressed the "programmer's key" which should bring up the monitor
;
programmerKey   setaxl
                PLA                     ; Get and throw-away the return address to the interrupt handler
                PLD                     ; Restore the registers that were present when the handler was invoked
                PLB
                PLY
                PLX
                PLA
                JML BREAK               ; And go to the BRK handler directly to open the monitor

; Save the character retrieved from the keyboard to the keyboard input buffer
SAVEKEY         .proc
                setas

                PHA                     ; Save the character
                LDA KEYBOARD_LOCKS      ; Check the keyboard lock flags
                AND #KB_CAPS_LOCK       ; Is CAPS lock on?
                BEQ no_caps             ; No... just use the character as-is

                PLA                     ; Get the character back
                CMP #'a'                ; Is it < 'a'
                BLT check_break         ; Yes: just use as-is
                CMP #'z'+1              ; Is it > 'z'
                BGE check_break         ; Yes: just us as-is

                AND #%11011111          ; Conver to upper case
                BRA check_break

no_caps         PLA                     ; Restore the character

check_break     CMP #0
                BEQ done
                CMP #CHAR_CTRL_C        ; Is it CTRL-C?
                BEQ flag_break          ; Yes: flag a break

no_break        LDX KEY_BUFFER_WPOS     ; So the Receive Character is saved in the Buffer

                ; Save the Character in the Buffer
                CPX #KEY_BUFFER_SIZE    ; Make sure we haven't been overboard.
                BCS done                ; Stop storing - An error should ensue here...

                STA @lKEY_BUFFER,X
                INX
                STX KEY_BUFFER_WPOS
                
                LDA #$00
                STA @lKEY_BUFFER, X       ; Store a EOL in the following location for good measure

done            RTS

flag_break      setas
                LDA #KB_CTRL_C          ; Flag that an interrupt key has been pressed
                STA KEYFLAG             ; The interpreter should see this soon and throw a BREAK
                RTS
                .pend

;
; KBD_GETCW
; Waits until a key is available in the KEY_BUFFER and returns the key
;
; Outputs:
;   A = the ASCII code of the key pressed
;
KBD_GETCW       .proc
                PHX
                PHD
                PHP

                setdp KEY_BUFFER

                setas
                setxl

                CLI                     ; Make sure interrupts can happen

get_wait        LDA @lKEYFLAG           ; Check the keyboard control flag
                AND #KB_CREDITS         ; Are the credits flagged?
                CMP #KB_CREDITS
                BNE check_buffer        ; No: check the key buffer

                LDA #0                  ; Yes: clear the flags
                STA @lKEYFLAG

                JSL SHOW_CREDITS        ; Then show the credits screen and wait for a key press

check_buffer    LDX KEY_BUFFER_RPOS     ; Is KEY_BUFFER_RPOS < KEY_BUFFER_WPOS
                CPX KEY_BUFFER_WPOS
                BCC read_buff           ; Yes: a key is present, read it
                BRA get_wait            ; Otherwise, keep waiting

read_buff       SEI                     ; Don't interrupt me!

                LDA KEY_BUFFER,X        ; Get the key

                INX                     ; And move to the next key
                CPX KEY_BUFFER_WPOS     ; Did we just read the last key?
                BEQ reset_indexes       ; Yes: return to 0 position

                STX KEY_BUFFER_RPOS     ; Otherwise: Update the read index

                CLI

done            PLP                     ; Restore status and interrupts
                PLD
                PLX
                RTL

reset_indexes   STZ KEY_BUFFER_RPOS     ; Reset read index to the beginning
                STZ KEY_BUFFER_WPOS     ; Reset the write index to the beginning
                BRA done
                .pend

;
; KBD_GETCW
; Returns a key from the KEY_BUFFER buffer if there is one. No waiting.
;
; Outputs:
;   A = the ASCII code of the key pressed
;
KBD_GETC        .proc 
                PHX
                PHD
                PHP

                setdp KEY_BUFFER

                setas
                setxl

                CLI                     ; Make sure interrupts can happen

check_buffer    LDX KEY_BUFFER_RPOS     ; Is KEY_BUFFER_RPOS < KEY_BUFFER_WPOS
                CPX KEY_BUFFER_WPOS
                BCC read_buff           ; Yes: a key is present, read it

                LDA #0                  ; If no key, return zero and set carry bit
                SEC
                BRA done

read_buff       SEI                     ; Don't interrupt me!

                LDA KEY_BUFFER,X        ; Get the key

                INX                     ; And move to the next key
                CPX KEY_BUFFER_WPOS     ; Did we just read the last key?
                BEQ reset_indexes       ; Yes: return to 0 position

                STX KEY_BUFFER_RPOS     ; Otherwise: Update the read index

                CLI

done            PLP                     ; Restore status and interrupts
                PLD
                PLX
                RTL

reset_indexes   STZ KEY_BUFFER_RPOS     ; Reset read index to the beginning
                STZ KEY_BUFFER_WPOS     ; Reset the write index to the beginning
                BRA done
                .pend
