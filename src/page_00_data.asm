; page_00.asm
; Initialization Code
;

* = START_OF_FLASH
;                .fill 12,0          ; unused_0000, 12 bytes, unused
;* = SCREENBEGIN
                .long $AFA000       ; SCREENBEGIN, 3 bytes, Start of screen in video RAM. This is the upper-left corrner of the current video page being written to. This may not be what's being displayed by VICKY. Update this if you change VICKY's display page.
                .word 76            ; COLS_VISIBLE, 2 bytes, Columns visible per screen line. A virtual line can be longer than displayed, up to COLS_PER_LINE long. Default = 80
                .word 100           ; COLS_PER_LINE, 2 bytes, Columns in memory per screen line. A virtual line can be this long. Default=128
                .word 56            ; LINES_VISIBLE, 2 bytes, The number of rows visible on the screen. Default=25
                .word 64            ; LINES_MAX, 2 bytes, The number of rows in memory for the screen. Default=64
                .long $AFA000       ; CURSORPOS, 3 bytes, The next character written to the screen will be written in this location.
                .word 0             ; CURSORX, 2 bytes, This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
                .word 0             ; CURSORY, 2 bytes, This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
                .byte $0F           ; CURCOLOR, 2 bytes, Color of next character to be printed to the screen.
                .byte $00           ; CURATTR, 2 bytes, Attribute of next character to be printed to the screen.
                .word STACK_BEGIN   ; STACKBOT, 2 bytes, Lowest location the stack should be allowed to write to. If SP falls below this value, the runtime should generate STACK OVERFLOW error and abort.
                .word STACK_END     ; STACKTOP, 2 bytes, Highest location the stack can occupy. If SP goes above this value, the runtime should generate STACK OVERFLOW error and abort.
