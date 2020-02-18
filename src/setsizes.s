;
; ISETSIZES
;
; Author: PJW
;
; Sets the kernel variables tracking the size of the text screen based on the current
; screen resolution and border size. This routine should be called whenever the screen
; resolution or border are changed, if the caller needs to use the kernel screen routines.
;
; Inputs:
;   None
;
; Outputs:
;   None
;
; Affects:
;   COLS_PER_LINE, COLS_VISIBLE, LINES_MAX, LINES_VISIBLE
;
ISETSIZES       ;.proc
;                 PHA
;                 PHX
;                 PHD
;                 PHP

;                 ;setdp <>BANK0_BEGIN

;                 setaxs
;                 LDA @l MASTER_CTRL_REG_H
;                 AND #$03                    ; Mask off the resolution bits
;                 ASL A
;                 TAX                         ; Index to the col/line count in X

;                 setal
;                 LDA cols_by_res,X           ; Get the number of columns
;                 STA COLS_PER_LINE           ; This is how many columns there are per line in the memory
;                 STA COLS_VISIBLE            ; This is how many would be visible with no border

;                 LDA lines_by_res,X          ; Get the number of lines
;                 STA LINES_MAX               ; This is the total number of lines in memory
;                 STA LINES_VISIBLE           ; This is how many lines would be visible with no border

;                 setas
;                 LDA @l BORDER_CTRL_REG      ; Check to see if we have a border
;                 BIT #Border_Ctrl_Enable
;                 BEQ done                    ; No border... the sizes are correct now

;                 ; There is a border...adjust the column count down based on the border size
;                 LDA @l BORDER_X_SIZE        ; Get the horizontal border width
;                 AND #$3F
;                 BIT #$03                    ; Check the lower two bits... indicates a partial column is eaten
;                 BNE frac_width

;                 LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4
;                 LSR A
;                 BRA store_width

; frac_width      LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4 + 1
;                 LSR A                       ; because a column is partially hidden
;                 INC A

; store_width     STA TMPPTR1
;                 STZ TMPPTR1+1

;                 setal
;                 SEC
;                 LDA COLS_PER_LINE
;                 SBC TMPPTR1
;                 STA COLS_VISIBLE

;                 LDA @l BORDER_Y_SIZE        ; Get the horizontal border width
;                 AND #$3F
;                 BIT #$03                    ; Check the lower two bits... indicates a partial column is eaten
;                 BNE frac_height

;                 LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4
;                 LSR A
;                 BRA store_height

; frac_height     LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4 + 1
;                 LSR A                       ; because a column is partially hidden
;                 INC A

; store_height    STA TMPPTR1
;                 STZ TMPPTR1+1

;                 setal
;                 SEC
;                 LDA LINES_MAX
;                 SBC TMPPTR1
;                 STA LINES_VISIBLE

;                 setaxl

; done            PLP
;                 PLD
;                 PLX
;                 PLA
                RTL