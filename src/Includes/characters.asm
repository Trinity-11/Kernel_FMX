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
CHAR_RIGHT = $1D    ; Right arrow
CHAR_SP = $20       ; Space
CHAR_DOWN = $91     ; Down arrow
CHAR_LEFT = $9D     ; Left arrow
CHAR_DEL = $7F      ; Delete key (delete the character at the cursor)

CHAR_F1 = $81       ; Function keys
CHAR_F2 = $82
CHAR_F3 = $83
CHAR_F4 = $84
CHAR_F5 = $85
CHAR_F6 = $86
CHAR_F7 = $87
CHAR_F8 = $88
CHAR_F9 = $89
CHAR_F10 = $8A
CHAR_F11 = $8B
CHAR_F12 = $8C