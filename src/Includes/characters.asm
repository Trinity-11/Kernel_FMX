;;;
;;; Definitions of important characters
;;;

CHAR_CTRL_A = $01   ; CTRL-A (move to start of line)
CHAR_CTRL_C = $03   ; CTRL-C
CHAR_CTRL_E = $05   ; CTRL-E (move to end of line)
CHAR_BS = $08       ; Backspace (delete character to the left of the cursor)
CHAR_TAB = $09      ; TAB (moves cursor to next tabulated column)
CHAR_LF = $0A       ; Line feed
CHAR_CR = $0D       ; Carriage return
CHAR_INS = $0F      ; Insert a space at the cursor
CHAR_UP = $11       ; Up arrow
CHAR_ESC = $1B      ; ESC
CHAR_RIGHT = $1D    ; Right arrow
CHAR_SP = $20       ; Space
CHAR_DOWN = $91     ; Down arrow
CHAR_LEFT = $9D     ; Left arrow
CHAR_DEL = $7F      ; Delete key (delete the character at the cursor)

CHAR_F1 = $3B       ; Function key scan codes
CHAR_F2 = $3C
CHAR_F3 = $3D
CHAR_F4 = $3E
CHAR_F5 = $3F
CHAR_F6 = $40
CHAR_F7 = $41
CHAR_F8 = $42
CHAR_F9 = $43
CHAR_F10 = $44
CHAR_F11 = $57
CHAR_F12 = $58
SCAN_SP = $39
SCAN_CR = $1C