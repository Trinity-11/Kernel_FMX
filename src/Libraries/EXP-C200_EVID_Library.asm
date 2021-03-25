;;;
;;; Definitions of important characters
;;;
; Please include page_00_inc.asm for the CPUA register
;CHAR_CTRL_A = $01   ; CTRL-A (move to start of line)
;CHAR_CTRL_C = $03   ; CTRL-C
;CHAR_CTRL_E = $05   ; CTRL-E (move to end of line)
;CHAR_BS = $08       ; Backspace (delete character to the left of the cursor)
;CHAR_TAB = $09      ; TAB (moves cursor to next tabulated column)
;CHAR_LF = $0A       ; Line feed
;CHAR_CR = $0D       ; Carriage return
;CHAR_INS = $0F      ; Insert a space at the cursor
;CHAR_UP = $11       ; Up arrow
;CHAR_RIGHT = $1D    ; Right arrow
;CHAR_SP = $20       ; Space
;CHAR_DOWN = $91     ; Down arrow
;CHAR_LEFT = $9D     ; Left arrow
;CHAR_DEL = $7F      ; Delete key (delete the character at the cursor)

;CHAR_F1 = $81       ; Function keys
;CHAR_F2 = $82
;CHAR_F3 = $83
;CHAR_F4 = $84
;CHAR_F5 = $85
;CHAR_F6 = $86
;CHAR_F7 = $87
;CHAR_F8 = $88
;CHAR_F9 = $89
;CHAR_F10 = $8A
;CHAR_F11 = $8B
;CHAR_F12 = $8C

EVID_SCREENBEGIN      = $000060 ;3 Bytes Start of screen in video RAM. This is the upper-left corrner of the current video page being written to. This may not be what's being displayed by VICKY. Update this if you change VICKY's display page.
EVID_COLS_VISIBLE     = $000064 ;2 Bytes Columns visible per screen line. A virtual line can be longer than displayed, up to COLS_PER_LINE long. Default = 80
EVID_COLS_PER_LINE    = $000066 ;2 Bytes Columns in memory per screen line. A virtual line can be this long. Default=128
EVID_LINES_VISIBLE    = $000068 ;2 Bytes The number of rows visible on the screen. Default=25
EVID_LINES_MAX        = $00006A ;2 Bytes The number of rows in memory for the screen. Default=64
EVID_CURSORPOS        = $00006C ;3 Bytes The next character written to the screen will be written in this location.
EVID_CURSORX          = $000070 ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
EVID_CURSORY          = $000072 ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
EVID_CURCOLOR         = $000074 ;1 Byte Color of next character to be printed to the screen.
EVID_COLORPOS         = $000075 ;3 Byte address of cursor's position in the color matrix
EVID_TMPPTR1          = $000076 ; 4 byte temporary pointer
EVID_SCREEN_PAGE      = $AE2000 ;8192 Bytes First page of display RAM. This is used at boot time to display the welcome screen and the BASIC or MONITOR command screens.
;
; EVID_IPRINT
; Print a string, followed by a carriage return
; DBR: bank containing string
; X: address of the string in data bank
; Modifies: X
;
EVID_IPRINT     .proc
                JSL EVID_IPUTS
                JSL EVID_IPRINTCR
                RTL
                .pend

; IPUTS
; Print a null terminated string
; DBR: bank containing string
; X: address of the string in data bank
; Modifies: X.
;  X will be set to the location of the byte following the string
;  So you can print multiple, contiguous strings by simply calling
;  IPUTS multiple times.
EVID_IPUTS .proc
                PHA
                PHP
                setas
                setxl
iputs1          LDA $0,b,x      ; read from the string
                BEQ iputs_done
iputs2          JSL EVID_IPUTC
iputs3          INX
                JMP iputs1
iputs_done      INX
                PLP
                PLA
                RTL
.pend

;
; EVID_IPUTC
; Print a single character to a channel.
; Handles terminal sequences, based on the selected text mode
; Modifies: none
;
EVID_IPUTC      .proc
                PHX
                PHY
                PHD
                PHB
                PHP                 ; stash the flags (we'll be changing M)

                setdp 0
                setdbr 0
                setas
                setxl

                CMP #CHAR_LF        ; Linefeed moves cursor down one line
                BEQ go_down
                CMP #$20
                BCC check_ctrl0     ; [$00..$1F]: check for arrows
                CMP #$7F
                BEQ do_del
                BCS check_A0        ; [$20..$7E]: print it
                BRA printc

check_A0        CMP #$A0
                BCC check_ctrl1
                BRA printc          ; [$A0..$FF]: print it

check_ctrl1     CMP #CHAR_DOWN      ; If the down arrow key was pressed
                BEQ go_down         ; ... move the cursor down one row
                CMP #CHAR_LEFT      ; If the left arrow key was pressed
                BEQ go_left         ; ... move the cursor left one column
                JMP done

check_ctrl0     CMP #CHAR_TAB       ; If it's a TAB...
                BEQ do_TAB          ; ... move to the next TAB stop
                CMP #CHAR_BS        ; If it's a backspace...
                BEQ backspace       ; ... move the cursor back and replace with a space
                CMP #CHAR_CR        ; If the carriage return was pressed
                BEQ do_cr           ; ... move cursor down and to the first column
                CMP #CHAR_UP        ; If the up arrow key was pressed
                BEQ go_up           ; ... move the cursor up one row
                CMP #CHAR_RIGHT     ; If the right arrow key was pressed
                BEQ go_right        ; ... move the cursor right one column
                CMP #CHAR_INS       ; If the insert key was pressed
                BEQ do_ins          ; ... insert a space
                CMP #CHAR_CTRL_A    ; Check for CTRL-A (start of line)
                BEQ go_sol          ; ... move the cursor to the start of the line
                CMP #CHAR_CTRL_E    ; Check for CTRL-E (end of line)
                BEQ go_eol          ; ... move the cursor to the end of the line

printc          STA [EVID_CURSORPOS]     ; Save the character on the screen

                LDA EVID_CURCOLOR        ; Set the color based on CURCOLOR
                STA [EVID_COLORPOS]

                JSL EVID_ICSRRIGHT       ; And advance the cursor

done            PLP
                PLB
                PLD
                PLY
                PLX
                RTL

do_del          JSL EVID_SCRSHIFTLL      ; Shift the current line left one space into the cursor
                BRA done

do_ins          JSL EVID_SCRSHIFTLR      ; Shift the current line right one space from the cursor
                BRA done

backspace       JSL EVID_ICSRLEFT  
                JSL EVID_SCRSHIFTLL      ; Shift the current line left one space into the cursor
                BRA done

do_cr           JSL EVID_IPRINTCR        ; Move the cursor to the beginning of the next line
                BRA done

go_down         JSL EVID_ICSRDOWN        ; Move the cursor down one row (might force a scroll)
                BRA done

go_up           JSL EVID_ICSRUP          ; Move the cursor up one line
                BRA done

go_right        JSL EVID_ICSRRIGHT       ; Move the cursor right one column
                BRA done

go_left         JSL EVID_ICSRLEFT        ; Move the cursor left one column
                BRA done

go_sol          setal               ; Move the cursor to the start of the line
                LDX #0
                LDY EVID_CURSORY
                BRA do_locate

do_TAB          setal
                LDA EVID_CURSORX         ; Get the current column
                AND #$FFF8          ; See which group of 8 it's in
                CLC
                ADC #$0008          ; And move it to the next one
                TAX
                LDY EVID_CURSORY
                setas

set_xy          CPX EVID_COLS_VISIBLE    ; Check if we're still on screen horizontally
                BCC check_row       ; Yes: check the row
                LDX #0              ; No: move to the first column...
                INY                 ; ... and the next row

check_row       CPY EVID_LINES_VISIBLE   ; Check if we're still on the screen vertically
                BCC do_locate       ; Yes: reposition the cursor

                JSL EVID_ISCROLLUP       ; No: scroll the screen
                DEY                 ; And set the row to the last one   

do_locate       JSL EVID_ILOCATE         ; Set the cursor position
                BRA done

; Move the cursor to be just to the right of the last non-white space character on the line
; If the line is full, move it to the right-most column
; If the line is empty, move it to the left-most column
go_eol          LDX EVID_COLS_VISIBLE    ; Move the cursor to the right most column
                DEX
                LDY EVID_CURSORY
                JSL EVID_ILOCATE

                setas
eol_loop        LDA [EVID_CURSORPOS]     ; Get the character under the cursor
                CMP #CHAR_SP        ; Is it blank?
                BNE eol_done        ; No: exit the loop

                JSL EVID_ICSRLEFT        ; Yes: move to the left

                LDX EVID_CURSORX         ; Are we at column 0?
                BNE eol_loop        ; No: try again
                BRL done            ; Yes: we're done

eol_done        LDX EVID_CURSORX         ; Check the column
                INX
                CPX EVID_COLS_VISIBLE    ; Is it the right most?
                BNE eol_right
                BRL done            ; Yes: we're done
                
eol_right       JSL EVID_ICSRRIGHT       ; No: move right one column
                BRL done
                .pend

;
; SCRSHIFTLL
; Shift all the characters on the current line left one cell, starting from the character to the right of the cursor
;
; Modifies: none
;
EVID_SCRSHIFTLL .proc
                PHX
                PHY
                PHA
                PHD
                PHP

                setdp 0

                setaxl
                LDA EVID_CURSORPOS       ; Get the current cursor position
                TAY                 ; Set it as the destination
                TAX
                INX                 ; And set the next cell as the source

                CLC                 ; Calculate the length of the block to move
                LDA EVID_COLS_VISIBLE    ; as columns visible - X
                SBC EVID_CURSORX

                MVN $AE, $AE        ; And move the block

                PLP
                PLD
                PLA
                PLY
                PLX
                RTL
                .pend

;
; SCRSHIFTLR
;
; Shift all the characters on the current line right one cell, starting from the character to the right of the cursor
; The character under the cursor should be replaced with a space.
;
; Modifies: none
;
EVID_SCRSHIFTLR .proc
                PHX
                PHA
                PHD
                PHP

                setdp 0

                setaxl
                LDA EVID_CURSORX         ; What column are we on
                INC A
                CMP EVID_COLS_VISIBLE    ; >= the # visible?
                BGE done            ; Yes: just skip the whole thing

                SEC                 ; Calculate the length of the block to move
                LDA EVID_COLS_VISIBLE
                SBC EVID_CURSORX
                INC A
                CLC
                ADC EVID_CURSORPOS       ; Add the current cursor position
                DEC A
                TAY                 ; Make it the destination
                DEC A               ; Move to the previous column
                TAX                 ; Make it the source              

                SEC                 ; Calculate the length of the block to move
                LDA EVID_COLS_VISIBLE    ; as columns visible - X
                SBC EVID_CURSORX

                MVP $AE, $AE        ; And move the block

                setas
                LDA #CHAR_SP        ; Put a blank space at the cursor position
                STA [EVID_CURSORPOS]

done            PLP
                PLD
                PLA
                PLX
                RTL
                .pend

;
;IPUTB
; Output a single byte to a channel.
; Does not handle terminal sequences.
; Modifies: none
;
EVID_IPUTB      .proc
                ;
                ; TODO: write to open channel
                ;
                RTL
.pend
;
; IPRINTCR
; Prints a carriage return.
; This moves the cursor to the beginning of the next line of text on the screen
; Modifies: Flags
;
EVID_IPRINTCR	.proc
                PHX
                PHY
                PHB
                PHD
                PHP

                setdbr 0
                setdp 0

                setas
                setxl

scr_printcr     LDX #0
                LDY EVID_CURSORY
                INY
                JSL EVID_ILOCATE

done            PLP
                PLD
                PLB
                PLY
                PLX
                RTL
                .pend

;
; ICSRHOME
; Move the cursor to the "home" position in the upper-left corner
;
EVID_ICSRHOME   .proc
                PHX
                PHY
                PHP

                LDX #0
                LDY #0
                JSL EVID_ILOCATE

                PLP
                PLY
                PLX
                RTL
                .pend

;
; ICSRRIGHT
; Move the cursor right one space
; Modifies: none
;
EVID_ICSRRIGHT  .proc
                PHX
                PHY
                PHA
                PHD
                PHP

                setal
                setxl
                setdp $0

                LDX EVID_CURSORX           ; Get the new column
                INX
                LDY EVID_CURSORY           ; Get the current row

                CPX EVID_COLS_VISIBLE      ; Are we off screen?
                BCC icsrright_nowrap  ; No: just set the position

                LDX #0                ; Yes: move to the first column
                INY                   ; And move to the next row
                CPY EVID_LINES_VISIBLE     ; Are we still off screen?
                BCC icsrright_nowrap  ; No: just set the position

                DEY                   ; Yes: lock to the last row
                JSL EVID_ISCROLLUP         ; But scroll the screen up

icsrright_nowrap
                JSL EVID_ILOCATE           ; Set the cursor position       

                PLP
                PLD
                PLA
                PLY
                PLX
                RTL
                .pend

;
; ICSRLEFT
; Move the cursor left one space
; Modifies: none
;
EVID_ICSRLEFT   .proc
                PHX
                PHY
                PHA
                PHD
                PHP

                setaxl
                setdp $0
                LDA EVID_CURSORX
                BEQ icsrleft_done_already_zero ; Check that we are not already @ Zero

                LDX EVID_CURSORX
                DEX
                STX EVID_CURSORX
                LDY EVID_CURSORY
                JSL EVID_ILOCATE

icsrleft_done_already_zero
                PLP
                PLD
                PLA
                PLY
                PLX
                RTL
                .pend

;ICSRUP
;Move the cursor up one space
; This routine doesn't wrap the cursor when it reaches the top, it just stays at the top
; Modifies: none
;
EVID_ICSRUP     .proc
                PHX
                PHY
                PHA
                PHD
                PHP

                setaxl
                setdp $0

                LDA EVID_CURSORY
                BEQ isrup_done_already_zero ; Check if we are not already @ Zero
                LDY EVID_CURSORY
                DEY
                STY EVID_CURSORY
                LDX EVID_CURSORX
                JSL EVID_ILOCATE

isrup_done_already_zero
                PLP
                PLD
                PLA
                PLY
                PLX
                RTL
                .pend
;
; ICSRDOWN
; Move the cursor down one space
; When it reaches the bottom. Every time it go over the limit, the screen is scrolled up. (Text + Color)
; It will replicate the Color of the last line before it is scrolled up.
; Modifies: none
;
EVID_ICSRDOWN   .proc
                PHX
                PHY
                PHD

                setaxl
                setdp $0

                LDX EVID_CURSORX                 ; Get the current column
                LDY EVID_CURSORY                 ; Get the new row
                INY
                CPY EVID_LINES_VISIBLE           ; Check to see if we're off screen
                BCC icsrdown_noscroll       ; No: go ahead and set the position

                DEY                         ; Yes: go back to the last row
                JSL EVID_ISCROLLUP               ; But scroll the screen up

icsrdown_noscroll
                JSL EVID_ILOCATE                 ; And set the cursor position

                PLD
                PLY
                PLX
                RTL
                .pend
;ILOCATE
;Sets the cursor X and Y positions to the X and Y registers
;Direct Page must be set to 0
;Input:
; X: column to set cursor
; Y: row to set cursor
;Modifies: none
EVID_ILOCATE    .proc
                PHA
                PHD
                PHP

                setdp 0
                setaxl

ilocate_scroll  ; If the cursor is below the bottom row of the screen
                ; scroll the screen up one line. Keep doing this until
                ; the cursor is visible.
                CPY EVID_LINES_VISIBLE
                BCC ilocate_scrolldone
                JSL EVID_ISCROLLUP
                DEY
                ; repeat until the cursor is visible again
                BRA ilocate_scroll

ilocate_scrolldone
                ; done scrolling store the resultant cursor positions.
                STX EVID_CURSORX
                STY EVID_CURSORY
                LDA EVID_SCREENBEGIN

ilocate_row     ; compute the row
                CPY #$0
                BEQ ilocate_right

                ; move down the number of rows in Y
ilocate_down    CLC
                ADC EVID_COLS_PER_LINE
                DEY
                BEQ ilocate_right
                BRA ilocate_down

                ; compute the column
ilocate_right   CLC
                ADC EVID_CURSORX             ; move the cursor right X columns
                STA EVID_CURSORPOS
                LDY EVID_CURSORY
                TYA
                STA @lEVID_TXT_CURSOR_Y_REG_L  ;Store in Vicky's registers
                TXA
                STA @lEVID_TXT_CURSOR_X_REG_L  ;Store in Vicky's register

                setal
                CLC
                LDA EVID_CURSORPOS
                ADC #<>(EVID_COLOR_MEM - EVID_TEXT_MEM)
                STA EVID_COLORPOS

ilocate_done    PLP
                PLD
                PLA
                RTL
                .pend
;
; ISCROLLUP
; Scroll the screen up one line
; Inputs:
;   None
; Affects:
;   None
EVID_ISCROLLUP  .proc    ; Scroll the screen up by one row
                ; Place an empty line at the bottom of the screen.
                ; TODO: use DMA to move the data
                PHA
                PHX
                PHY
                PHB
                PHD
                PHP

                setdp 0

                setaxl
                ; Calculate the number of bytes to move
                LDA EVID_COLS_PER_LINE
                STA @l UNSIGNED_MULT_A_LO

                LDA EVID_LINES_VISIBLE
                STA @l UNSIGNED_MULT_B_LO
                
                LDA @l UNSIGNED_MULT_AL_LO
                STA EVID_TMPPTR1

                ; Scroll Text Up
                CLC
                LDA #$2000
                TAY
                ADC EVID_COLS_PER_LINE
                TAX
                LDA EVID_TMPPTR1
                ; Move the data
                MVN $AE,$AE

                ; Scroll Color Up
                setaxl
                CLC
                LDA #$4000
                TAY
                ADC EVID_COLS_PER_LINE
                TAX
                ; for now, should be 8064 or $1f80 bytes
                LDA EVID_TMPPTR1
                ; Move the data
                MVN $AE,$AE

                ; Clear the last line of text on the screen
                LDA EVID_TMPPTR1
                PHA

                CLC
                ADC #<>EVID_TEXT_MEM
                STA EVID_TMPPTR1

                LDY #0
                LDA #' '
clr_text        STA [EVID_TMPPTR1],Y
                INY
                CPY EVID_COLS_VISIBLE
                BNE clr_text

                ; Set the last line of color on the screen to the current color
                PLA
                CLC
                ADC #<>EVID_COLOR_MEM
                STA EVID_TMPPTR1

                LDY #0
                LDA EVID_CURCOLOR
clr_color       STA [EVID_TMPPTR1],Y
                INY
                CPY EVID_COLS_VISIBLE
                BNE clr_color

                PLP
                PLD
                PLB
                PLY
                PLX
                PLA
                RTL
.pend

;
; IPRINTH
; Prints data from memory in hexadecimal format
; Inputs:
;   X: 16-bit address of the LAST BYTE of data to print.
;   Y: Length in bytes of data to print
; Modifies:
;   X,Y, results undefined
EVID_IPRINTH    .proc
                PHP
                PHA
iprinth1        setas
                LDA #0,b,x      ; Read the value to be printed
                LSR
                LSR
                LSR
                LSR
                JSL EVID_iprint_digit
                LDA #0,b,x
                JSL EVID_iprint_digit
                DEX
                DEY
                BNE iprinth1
                PLA
                PLP
                RTL
                .pend
;
; IPRINTAH
; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
;
; Inputs:
;   A: 8 or 16 bit value to print
;
EVID_IPRINTAH   .proc
                PHA
                PHP
                STA @lCPUA              ; Save A where we can use it multiple times

                PHP                     ; Get the processor status into A
                setas
                setxl
                PLA
                AND #%00100000          ; Is M = 1?
                CMP #%00100000
                BEQ eight_bit

                LDA @lCPUA+1            ; Get nibble [15..12]
                .rept 4
                LSR A
                .next
                JSL EVID_iprint_digit   ; And print it
                LDA @lCPUA+1            ; Get nibble [11..8]
                JSL EVID_iprint_digit   ; And print it

eight_bit       LDA @lCPUA              ; Get nibble [7..4]
                .rept 4
                LSR A
                .next
                JSL EVID_iprint_digit   ; And print it
                LDA @lCPUA              ; Get nibble [3..0]
                JSL EVID_iprint_digit   ; And print it

                PLP
                PLA
                RTL
                .pend

;
; iprint_digit
; This will print the low nibble in the A register.
; Inputs:
;   A: digit to print
;   x flag should be 0 (16-bit X)
; Affects:
;   P: m flag will be set to 0
EVID_iprint_digit    .proc
                PHX
                setal
                AND #$0F
                TAX
                ; Use the value in AL to
                .databank ?
                LDA hex_digits,X
                JSL EVID_IPUTC       ; Print the digit
                PLX
                RTL
.pend


;///////////////////////////////
;///////////////////////////////
INIT_EVID_VID_MODE .proc
                setas
                LDA #EVID_800x600ModeEnable          ; 0 - 80x60, 1- 100x75
                STA @l EVID_MSTR_CTRL_REG_H

                LDA #EVID_Border_Ctrl_Enable           ; Enable the Border
                STA EVID_BORDER_CTRL_REG

                LDA #8                           ; Set the border to the standard 8 pixels
                STA EVID_BORDER_X_SIZE          ; Let's use maximum space
                STA EVID_BORDER_Y_SIZE

                ; Set the Border to dark Grey
                LDA #$20
                STA EVID_BORDER_COLOR_R        ; R
                LDA #$00
                STA EVID_BORDER_COLOR_G        ; G
                LDA #$20
                STA EVID_BORDER_COLOR_B        ; B 
                
                JSL INIT_EVID_EVID_LUT
                JSL INIT_EVID_EVID_FONTSET
                JSL INIT_EVID_EVID_CURSOR

                setaxl
                LDX #(100-2)    
                STX EVID_COLS_VISIBLE
                LDY #(75-2)
                STY EVID_LINES_VISIBLE
                LDX #100
                STX EVID_COLS_PER_LINE
                LDY #75
                STY EVID_LINES_MAX

                LDA #$F0                  ; Set the default text color to light gray on dark gray 
                STA EVID_CURCOLOR

                setaxl
                LDA #<>EVID_TEXT_MEM      ; store the initial screen buffer location
                STA EVID_SCREENBEGIN
                STA EVID_CURSORPOS

                LDA #<>EVID_COLOR_MEM   ; Set the initial COLOR cursor position
                STA EVID_COLORPOS

                setas
                LDA #`EVID_TEXT_MEM
                STA SCREENBEGIN + 2
                STA EVID_CURSORPOS+2

                LDA #`EVID_COLOR_MEM    ; Set the initial COLOR cursor position
                STA EVID_COLORPOS + 2

                JSL INIT_EVID_EVID_CLRSCREEN
                setxl 
                PHD 
                setdbr `EVID_DEV_RDY0
                LDX #<>EVID_DEV_RDY0
                JSL EVID_IPRINT
                LDX #<>EVID_DEV_RDY1
                JSL EVID_IPRINT
                PLD 
                LDX #$0000
LifeIsFullOfColors:     ; Final Touch before I stop - Feb 08, 2021                
                LDA @l EVID_DEV_RDY0_CLR, X 
                STA @l EVID_COLOR_MEM, X 
                INX 
                CPX #10
                BNE LifeIsFullOfColors                
                RTL
.pend
EVID_DEV_RDY0  .null $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "C256 Foenix EXP-C200-EVID", $0D 
EVID_DEV_RDY0_CLR .text $1D, $1D, $8D, $8D, $4D, $4D, $2D, $2D, $5D, $5D
EVID_DEV_RDY1  .null "Your Device is Ready..."
TXTLINESIZE = 100
; IINITFONTSET
; Author: Stefany
; Init the Text Modey
; Inputs:
;   None
; Affects:
;  Vicky's Internal FONT Memory
INIT_EVID_EVID_FONTSET .proc
                setas
                setxl
                LDX #$0000
initFontsetbranch0
                LDA @lFONT_4_BANK0,X    ; RAM Content
                STA @lEVID_FONT_MEM,X ; Vicky FONT RAM Bank
                INX
                CPX #$0800
                BNE initFontsetbranch0
                NOP
                RTL
.pend

; IINITCHLUT
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize VICKY's Character Color Look-Up Table;
; Inputs:
;   None
; Affects:
;   None
INIT_EVID_EVID_LUT .proc
                setas
                setxs 					; Set 8bits
				        ; Setup Foreground LUT First
				        LDX	#$00

lutinitloop0	LDA @lfg_color_lut,x		; get Local Data c64_character_Color_LUT_4_Txt
                STA @lEVID_FG_LUT,x	; Write in LUT Memory
                inx
                cpx #$40
                bne lutinitloop0
                ; Set Background LUT Second
                LDX	#$00
lutinitloop1	LDA @lbg_color_lut,x		; get Local Data
                STA @lEVID_BG_LUT,x	; Write in LUT Memory
                INX
                CPX #$40
                bne lutinitloop1
                NOP
                RTL
.pend

; IINITCURSOR
; Author: Stefany
; Init the Cursor Registers
; Verify that the Math Block Works
; Inputs:
; None
; Affects:
;  Vicky's Internal Cursor's Registers
INIT_EVID_EVID_CURSOR .proc
                setas
                LDA #$B1      ;The Cursor Character will be a Fully Filled Block
                STA @lEVID_TXT_CURSOR_CHAR_REG
                LDA #(EVID_Cursor_Enable | EVID_Cursor_Flash_Rate0)      ;Set Cursor Enable And Flash Rate @1Hz
                STA @lEVID_TXT_CURSOR_CTRL_REG ;
                setaxl        ; Set Acc back to 16bits before setting the Cursor Position
                LDA #$0000;
                STA @lEVID_TXT_CURSOR_X_REG_L ;; // Set the X to Position 1
                STA @lEVID_TXT_CURSOR_Y_REG_L ; // Set the Y to Position 6 (Below)
                setas
                RTL
                .pend
;
; ICLRSCREEN
; Clear the screen and set the background and foreground colors to the
; currently selected colors.
INIT_EVID_EVID_CLRSCREEN	   .proc
                setas
                setxl 			; Set 16bits
                LDX #$0000		; Only Use One Pointer

                LDA #$20		; Fill the Entire Screen with Space
iclearloop0	    STA EVID_TEXT_MEM, x	;
                inx
                cpx #$2000
                bne iclearloop0
                ; Now Set the Colors so we can see the text
                LDX	#$0000		; Only Use One Pointer

                LDA #$F0		; Fill the Color Memory with Foreground: 75% Purple, Background 12.5% White
iclearloop1	    STA EVID_COLOR_MEM, x	;
                inx
                cpx #$2000
                bne iclearloop1
                RTL
.pend
