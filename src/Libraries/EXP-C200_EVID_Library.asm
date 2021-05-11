;;;
;;; Driver for the EVID second video port
;;;


EVID_SCREEN_PAGE      = $AE2000 ;8192 Bytes First page of display RAM. This is used at boot time to display the welcome screen and the BASIC or MONITOR command screens.

;
; Initialize the EVID card registers
;
INIT_EVID_VID_MODE .proc
                setas
                LDA #EVID_800x600ModeEnable     ; 0 - 80x60, 1- 100x75
                STA @l EVID_MSTR_CTRL_REG_H

                LDA #EVID_Border_Ctrl_Enable    ; Enable the Border
                STA @l EVID_BORDER_CTRL_REG

                LDA #8                          ; Set the border to the standard 8 pixels
                STA @l EVID_BORDER_X_SIZE       ; Let's use maximum space
                STA @l EVID_BORDER_Y_SIZE

                ; Set the Border to dark Grey
                LDA #$20
                STA @l EVID_BORDER_COLOR_R      ; R
                LDA #$00
                STA @l EVID_BORDER_COLOR_G      ; G
                LDA #$20
                STA @l EVID_BORDER_COLOR_B      ; B 
                
                JSL INIT_EVID_LUT
                JSL INIT_EVID_FONTSET
                JSL INIT_EVID_CURSOR

                setaxl
                LDA #(100-2)    
                STA @l EVID_COLS_VISIBLE
                LDA #(75-2)
                STA @l EVID_LINES_VISIBLE
                LDA #100
                STA @l EVID_COLS_PER_LINE
                LDA #75
                STA @l EVID_LINES_MAX

                LDA #$70                        ; Set the default text color to light gray on dark gray 
                STA @l EVID_CURCOLOR

                setaxl
                LDA #<>EVID_TEXT_MEM            ; store the initial screen buffer location
                STA @l EVID_SCREENBEGIN
                STA @l EVID_CURSORPOS

                LDA #<>EVID_COLOR_MEM           ; Set the initial COLOR cursor position
                STA EVID_COLORPOS

                setas
                LDA #`EVID_TEXT_MEM
                STA @l EVID_SCREENBEGIN + 2
                STA @l EVID_CURSORPOS+2

                LDA #`EVID_COLOR_MEM            ; Set the initial COLOR cursor position
                STA @l EVID_COLORPOS + 2
               
                RTL
                .pend

EVID_DEV_RDY0   .text $1B, "[1m", $1B, "[31m", $0B, $0C, $1B, "[35m", $0B, $0C, $1B, "[33m", $0B, $0C, $1B
                .null "[32m", $0B, $0C, $1B, "[34m", $0B, $0C, $1B, "[0m", $20, "C256 Foenix EXP-C200-EVID", $0D 
EVID_DEV_RDY1   .null "Your Device is Ready..."

;
; Print the greeting on the EVID screen
;
EVID_GREET      .proc
                PHA
                PHX
                PHP

                setas
                LDA @l EVID_PRESENT             ; Check if the EVID screen is present
                BEQ done                        ; If not, skip this routine

                LDA #CHAN_EVID                  ; Switch to the EVID screen
                JSL SETOUT

                JSL CLRSCREEN                   ; Clear the screen

                setxl
                PHB                             ; Print the messages
                LDA #`EVID_DEV_RDY0
                PHA
                PLB
                LDX #<>EVID_DEV_RDY0
                JSL IPRINT

                LDX #<>EVID_DEV_RDY1
                JSL IPRINT
                PLB

                LDA #CHAN_CONSOLE               ; Go back to the main console
                JSL SETOUT

done            PLP
                PLX
                PLA
                RTL
                .pend

; INIT_EVID_FONTSET
; Author: Stefany
; Init the Text Modey
; Inputs:
;   None
; Affects:
;  Vicky's Internal FONT Memory
INIT_EVID_FONTSET .proc
                setas
                setxl
                LDX #$0000
initFontsetbranch0
                LDA @lFONT_4_BANK0,X    ; RAM Content
                STA @lEVID_FONT_MEM,X   ; Vicky FONT RAM Bank
                INX
                CPX #$0800
                BNE initFontsetbranch0
                NOP
                RTL
.pend

; INIT_EVID_LUT
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize VICKY's Character Color Look-Up Table;
; Inputs:
;   None
; Affects:
;   None
INIT_EVID_LUT   .proc
                setas
                setxs 					; Set 8bits

                ; Setup Foreground LUT First
                LDX	#$00
lutinitloop0	LDA @lfg_color_lut,x    ; get Local Data c64_character_Color_LUT_4_Txt
                STA @lEVID_FG_LUT,x	    ; Write in LUT Memory
                inx
                cpx #$40
                bne lutinitloop0

                ; Set Background LUT Second
                LDX	#$00
lutinitloop1	LDA @lbg_color_lut,x    ; get Local Data
                STA @lEVID_BG_LUT,x	    ; Write in LUT Memory
                INX
                CPX #$40
                bne lutinitloop1
                NOP
                RTL
.pend

; INIT_EVID_CURSOR
; Author: Stefany
; Init the Cursor Registers
; Verify that the Math Block Works
; Inputs:
; None
; Affects:
;  Vicky's Internal Cursor's Registers
INIT_EVID_CURSOR .proc
                PHP
                setas
                LDA #$B1                                            ; The Cursor Character will be a Fully Filled Block
                STA @lEVID_TXT_CURSOR_CHAR_REG
                LDA #(EVID_Cursor_Enable | EVID_Cursor_Flash_Rate0) ; Set Cursor Enable And Flash Rate @1Hz
                STA @lEVID_TXT_CURSOR_CTRL_REG

                setaxl                          ; Set Acc back to 16bits before setting the Cursor Position
                LDA #$0000;
                STA @lEVID_TXT_CURSOR_X_REG_L   ; Set the X to Position 1
                STA @lEVID_TXT_CURSOR_Y_REG_L   ; Set the Y to Position 6 (Below)

                PLP
                RTL
                .pend
;
; INIT_EVID_CLRSCREEN
; Clear the screen and set the background and foreground colors to the
; currently selected colors.
INIT_EVID_CLRSCREEN	   .proc
                PHP
                setas
                setxl 			        ; Set 16bits
                LDX #$0000		        ; Only Use One Pointer

                LDA #$20		        ; Fill the Entire Screen with Space
iclearloop0	    STA @l EVID_TEXT_MEM,X
                inx
                cpx #$2000
                bne iclearloop0

                ; Now Set the Colors so we can see the text
                
                LDX	#$0000		        ; Only Use One Pointer
                LDA #$F0		        ; Fill the Color Memory with Foreground: 75% Purple, Background 12.5% White
iclearloop1	    STA @l EVID_COLOR_MEM,X
                inx
                cpx #$2000
                bne iclearloop1

                PLP
                RTL
                .pend
