;;
;; Base driver code for the text screens
;;
;; This code supports the built-in text screen for the U, U+, and FMX
;; as well as the second text screen provided by the EVID expansion card
;;

;
; Structures
;

S_ANSI_VARS         .struct
SCREENBEGIN         .long ?     ; Start of screen in video RAM. This is the upper-left corrner of the current video page being written to. This may not be what's being displayed by VICKY. Update this if you change VICKY's display page.
COLS_VISIBLE        .word ?     ; Columns visible per screen line. A virtual line can be longer than displayed, up to COLS_PER_LINE long. Default = 80
COLS_PER_LINE       .word ?     ; Columns in memory per screen line. A virtual line can be this long. Default=128
LINES_VISIBLE       .word ?     ; The number of rows visible on the screen. Default=25
LINES_MAX           .word ?     ; The number of rows in memory for the screen. Default=64
CURSORPOS           .long ?     ; The next character written to the screen will be written in this location.
CURSORX             .word ?     ; This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
CURSORY             .word ?     ; This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
CURCOLOR            .byte ?     ; Color of next character to be printed to the screen.
COLORPOS            .long ?     ; Address of cursor's position in the color matrix
COLORBEGIN          .long ?     ; Address of the first byte of the color matrix for this screen
TMPPTR1             .dword ?    ; Temporary pointer
STATE               .byte ?     ; State of the escape code parser
CONTROL             .byte ?     ; Control bit
ARGC                .byte ?     ; The number of arguments provided by the escape sequence (max 2)
ARG0                .byte ?     ; First ANSI code argument
ARG1                .byte ?     ; Second ANSI code argument
                    .ends

;
; Definitions
;

ST_INIT = 0             ; Starting state for the ANSI code parser. Most characters just print
ST_ESCAPE = 1           ; ESC has been seen
ST_CSI = 2              ; Full CSI has been seen "ESC ["

ANSI_MAX_ARG = 2        ; We'll limit ourselves to two arguments
ANSI_DEF_COLOR = $70    ; Default color (dim white on dim black)

CONTROL_INVERT = $80    ; Control bit: Colors are inverted
CONTROL_BOLD = $40      ; Control bit: Colors should be intense

;
; Code
;

;
; FAR: Initialize the screen kernel variables for the main screen and the EVID (if present)
;
ANSI_INIT           .proc
                    PHX
                    PHY
                    PHB
                    PHD
                    PHP

                    setaxl
                    LDY #0
                    JSR INIT_SCREEN_Y               ; Set up the main screen

                    ; Check to see if the EVID card is installed...

                    setas
                    LDA @l GABE_SYS_STAT            ; Let's check the Presence of an Expansion Card here
                    AND #GABE_SYS_STAT_EXP          ; When there is a Card the Value is 1
                    CMP #GABE_SYS_STAT_EXP
                    BNE no_evid

                    setal
                    LDA @l ESID_ID_CARD_ID_Lo       ; Load the Card ID and check for C100 or C200
                    CMP #$00C8                      ; Is it the EVID card?
                    BNE no_evid                     ; No: mark the EVID screen as not present
                    
                    setas
                    LDA #1                          ; Otherwise: Mark that there is an EVID present
                    STA @l EVID_PRESENT

                    LDY #1
                    JSR INIT_SCREEN_Y               ; Initialize the EVID screen variables
                    BRA done

no_evid             setas
                    LDA #0                          ; Mark that there is no EVID present
                    STA @l EVID_PRESENT

done                PLP
                    PLD
                    PLB
                    PLY
                    PLX
                    RTS
                    .pend

LUTRGB              .macro red, green, blue
                    .byte \blue, \green, \red, 0
                    .endm

;
; Set the foreground and background color LUTs to match ANSI colors
;
ANSI_INIT_LUTS      .proc
                    PHP

                    setaxs

                    ; Set the Vicky text foreground and background LUTs

                    LDX #0
vicky_loop          LDA ANSI_TEXT_LUT,X             ; Get the Xth LUT byte
                    STA @l FG_CHAR_LUT_PTR,X        ; Set the corresponding foreground color component on Vicky
                    STA @l BG_CHAR_LUT_PTR,X        ; Set the corresponding background color component on Vicky
                    INX
                    CPX #4*16
                    BNE vicky_loop

                    LDA @l EVID_PRESENT             ; Check to see if EVID is present
                    BEQ done                        ; If not, we're done

                    ; Set the EVID text foreground and background LUTs
                    
                    LDX #0
evid_loop           LDA ANSI_TEXT_LUT,X             ; Get the Xth LUT byte
                    STA @l EVID_FG_LUT,X            ; Set the corresponding foreground color component on the EVID card
                    STA @l EVID_BG_LUT,X            ; Set the corresponding background color component on the EVID card
                    INX
                    CPX #4*16
                    BNE evid_loop

done                PLP
                    RTS
                    .pend

ANSI_TEXT_LUT       LUTRGB 0, 0, 0          ; Black
                    LUTRGB 128, 0, 0        ; Red
                    LUTRGB 0, 128, 0        ; Green
                    LUTRGB 128, 128, 0      ; Yellow
                    LUTRGB 0, 0, 128        ; Blue
                    LUTRGB 128, 0, 128      ; Magenta
                    LUTRGB 0, 128, 128      ; Cyan
                    LUTRGB 192, 192, 192    ; White
                    LUTRGB 128, 128, 128    ; Bright Black (grey)
                    LUTRGB 255, 0, 0        ; Bright Red
                    LUTRGB 0, 255, 0        ; Bright Green
                    LUTRGB 255, 255, 0      ; Bright Yellow
                    LUTRGB 0, 0, 255        ; Bright Blue
                    LUTRGB 252, 127, 0      ; Bright Orange
                    LUTRGB 0, 255, 255      ; Bright Cyan
                    LUTRGB 255, 255, 255    ; Bright White
;
; Intialize the variables a screen
;
; Inputs:
;   Y = the number of the screen to initialize (0 = main screen, 1 = EVID)
;
INIT_SCREEN_Y       .proc
                    setaxl
                    CPY #0
                    BEQ setdp_0

setdp_1             LDA #<>EVID_SCREENBEGIN         ; Set DP to the EVID variable block
                    TCD
                    BRA set_addresses

setdp_0             LDA #<>SCREENBEGIN              ; Set DP to the main screen variable block
                    TCD

set_addresses       TYA                             ; Compute offset to screen Y's addresses
                    ASL A
                    ASL A
                    TAX

                    LDA @l text_address,X
                    STA #S_ANSI_VARS.SCREENBEGIN,D  ; Set the address of the text matrix
                    STA #S_ANSI_VARS.CURSORPOS,D    ; And the cursor pointer
                    setas
                    LDA @l text_address+2,X
                    STA #S_ANSI_VARS.SCREENBEGIN+2,D
                    STA #S_ANSI_VARS.CURSORPOS+2,D

                    setal
                    LDA @l color_address,X
                    STA #S_ANSI_VARS.COLORBEGIN,D   ; Set the address of the color matrix
                    STA #S_ANSI_VARS.COLORPOS,D     ; And the color cursor pointer
                    setas
                    LDA @l color_address+2,X
                    STA #S_ANSI_VARS.COLORBEGIN+2,D
                    STA #S_ANSI_VARS.COLORPOS+2,D

                    setal
                    STZ #S_ANSI_VARS.CURSORX,D      ; Set the cursor position to 0, 0
                    STZ #S_ANSI_VARS.CURSORY,D

                    setas
                    STZ #S_ANSI_VARS.STATE,D        ; Set the state of the ANSI parser to S0
                    STZ #S_ANSI_VARS.CONTROL,D      ; Set the control bits to 0 (default)

                    LDA #ANSI_DEF_COLOR
                    STA #S_ANSI_VARS.CURCOLOR,D     ; Set the current color to the default

                    JSR ANSI_SETSIZE_Y              ; Set the size variables for the main screen

                    RTS
text_address        .dword CS_TEXT_MEM_PTR, EVID_TEXT_MEM
color_address       .dword CS_COLOR_MEM_PTR, EVID_COLOR_MEM
                    .pend

;
; Set the sizes of the text screens based on their Vicky and EVID (if installed) registers
;
ANSI_SETSIZES       .proc
                    PHD

                    setasx
                    LDA @l CHAN_OUT                 ; Save the current output channel
                    PHA

                    LDA #CHAN_CONSOLE               ; Set the sizes for the main screen
                    STA @l CHAN_OUT
                    JSR ANSI_SETDEVICE              ; Set the DP to the device's record
                    LDY #CHAN_CONSOLE
                    JSR ANSI_SETSIZE_Y              ; Set the sizes for that device

                    LDA #CHAN_EVID                  ; Set the sizes for the EVID screen
                    STA @l CHAN_OUT
                    JSR ANSI_SETDEVICE              ; Set the DP to the device's record
                    BCS done                        ; Not present, just return
                    LDY #CHAN_EVID
                    JSR ANSI_SETSIZE_Y              ; Set the sizes for that device

done                PLA
                    STA @l CHAN_OUT                 ; Restore the output channel

                    PLD
                    RTS
                    .pend

;
; Set the size of the currently selected screen based on the settings of the
; relevant hardware registers in either Vicky or the EVID card.
;
; Inputs:
;   DP = pointer to the kernel variable block for the selected screen
;   Y = screen number (0 for main screen, 1 for EVID)
;
ANSI_SETSIZE_Y      .proc
                    PHP

                    setaxs
                    CPY #0                              ; Is our target screen 0?
                    BEQ vky_master                      ; Yes: get the resolution from Vicky
                    LDA @l EVID_MSTR_CTRL_REG_H         ; No: get the resolution from EVID
                    BRA resolution
vky_master          LDA @l MASTER_CTRL_REG_H
resolution          AND #$03                            ; Mask off the resolution bits
                    ASL A
                    TAX                                 ; Index to the col/line count in X

                    setal
                    LDA cols_by_res,X                   ; Get the number of columns
                    STA #S_ANSI_VARS.COLS_PER_LINE,D    ; This is how many columns there are per line in the memory
                    STA #S_ANSI_VARS.COLS_VISIBLE,D     ; This is how many would be visible with no border

                    LDA lines_by_res,X                  ; Get the number of lines
                    STA #S_ANSI_VARS.LINES_MAX,D        ; This is the total number of lines in memory
                    STA #S_ANSI_VARS.LINES_VISIBLE,D    ; This is how many lines would be visible with no border

                    setas
                    CPY #0                              ; Is our target screen 0?
                    BEQ vky_border                      ; Yes: get the border from Vicky
                    LDA @l EVID_BORDER_CTRL_REG         ; No: Check EVID to see if we have a border
                    BRA border
vky_border          LDA @l BORDER_CTRL_REG              ; Check Vicky to see if we have a border
border              BIT #Border_Ctrl_Enable
                    BEQ done                            ; No border... the sizes are correct now

                    ; There is a border...adjust the column count down based on the border size

                    CPY #0                              ; Is our target screen 0?
                    BEQ vky_border_size                 ; Yes: get the border size from Vicky
                    LDA @l EVID_BORDER_X_SIZE           ; No: Get the horizontal border width from EVID
                    BRA border_size
vky_border_size     LDA @l BORDER_X_SIZE                ; Get the horizontal border width from Vicky
border_size         AND #$3F
                    BIT #$03                            ; Check the lower two bits... indicates a partial column is eaten
                    BNE frac_width

                    LSR A                               ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4
                    LSR A
                    BRA store_width

frac_width          LSR A                               ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4 + 1
                    LSR A                               ; because a column is partially hidden
                    INC A

store_width         STA #S_ANSI_VARS.TMPPTR1,D
                    STZ #S_ANSI_VARS.TMPPTR1+1,D

                    setas
                    CPY #1                              ; Are we setting the EVID?
                    BEQ adjust_width                    ; Yes: skip the pixel doubling check

                    LDA @l MASTER_CTRL_REG_H            ; Check Vucky if we're pixel doubling
                    BIT #Mstr_Ctrl_Video_Mode1
                    BEQ adjust_width                    ; No... just adjust the width of the screen

                    setal
                    LSR #S_ANSI_VARS.TMPPTR1,D          ; Yes... cut the adjustment in half

adjust_width        setal
                    SEC
                    LDA #S_ANSI_VARS.COLS_PER_LINE,D
                    SBC #S_ANSI_VARS.TMPPTR1,D
                    STA #S_ANSI_VARS.COLS_VISIBLE,D

                    CPY #0                              ; Is our target screen 0?
                    BEQ vky_border_y_size               ; Yes: get the border Y size from Vicky
                    LDA @l EVID_BORDER_X_SIZE           ; No: Get the vertical border width from EVID
                    BRA border_y_size
vky_border_y_size   LDA @l BORDER_Y_SIZE                ; Get the vertical border width from Vicky
border_y_size       AND #$3F
                    BIT #$03                            ; Check the lower two bits... indicates a partial column is eaten
                    BNE frac_height

                    LSR A                               ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4
                    LSR A
                    BRA store_height

frac_height         LSR A                               ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4 + 1
                    LSR A                               ; because a column is partially hidden
                    INC A

store_height        STA #S_ANSI_VARS.TMPPTR1,D
                    STZ #S_ANSI_VARS.TMPPTR1+1,D

                    setas
                    CPY #1                              ; Are we setting the EVID?
                    BEQ adjust_height                   ; Yes: skip the pixel doubling check

                    LDA @l MASTER_CTRL_REG_H            ; Check if we're pixel doubling
                    BIT #Mstr_Ctrl_Video_Mode1
                    BEQ adjust_height                   ; No... just adjust the height of the screen

                    setal
                    LSR #S_ANSI_VARS.TMPPTR1,D          ; Yes... cut the adjustment in half

adjust_height       setal
                    SEC
                    LDA #S_ANSI_VARS.LINES_MAX,D
                    SBC #S_ANSI_VARS.TMPPTR1,D
                    STA #S_ANSI_VARS.LINES_VISIBLE,D

done                PLP
                    RTS
cols_by_res         .word 80,100,40,50
lines_by_res        .word 60,75,30,37
                    .pend

;
; Look at the current output device of the kernel and set the direct page
; based on whether we're trying to access the main screen or the EVID screen.
;
; Inputs:
;   CHAN_OUT = the current channel we're outputing to
;
; Outputs:
;   DP points to the kernel registers for that screen if successful
;   C is set if the current channel is not a screen, clear otherwise
;   
ANSI_SETDEVICE      .proc
                    PHA
                    PHP

                    setas
                    LDA @l CHAN_OUT                 ; Check the current output channel
                    CMP #CHAN_CONSOLE               ; Is it the console?
                    BEQ console                     ; Yes: point to the console

                    CMP #CHAN_EVID                  ; Is it the EVID?
                    BEQ evid                        ; Check to see if the EVID is present

bad_device          PLP
                    PLA
                    SEC
                    RTS

console             setal
                    LDA #<>SCREENBEGIN              ; Point to the the main screen's variables
                    BRA set_dp

evid                setas
                    LDA @l EVID_PRESENT             ; Is the EVID present?
                    BEQ bad_device                  ; No: return that the device is bad

                    setal
                    LDA #<>EVID_SCREENBEGIN         ; Yes: point to the EVID's variables

set_dp              TCD
                    PLP
                    PLA
                    CLC
                    RTS                   
                    .pend

;
; ANSI_PUTC
; Print a single character to a channel.
; Handles terminal sequences, based on the selected text mode
; Modifies: none
;
ANSI_PUTC           .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setaxs
                    JSR ANSI_SETDEVICE          ; Look at the current output channel and point
                                                ; Point to the correct control registers for it
                    BCC get_state               ; If valid, check the current state           
                    BRL done                    ; If invalid, just return

get_state           LDX #S_ANSI_VARS.STATE,D    ; Get the current state
                    BEQ do_st_init              ; Dispatch to the correct code for the state
                    CPX #ST_ESCAPE
                    BEQ do_st_escape
                    CPX #ST_CSI
                    BEQ do_st_csi

pr_and_reset        STZ #S_ANSI_VARS.STATE,D    ; If invalid, reset to 0 and print the character
                    BRA print_raw

                    ; Initial state

do_st_init          CMP #CHAR_ESC               ; Is it ESC?
                    BEQ go_escape               ; Yes, handle the ESC
                    BLT do_control              ; If less than, handle as a control code
print_raw           JSR ANSI_PUTRAWC            ; Otherwise: Just print the raw character 
                    BRA done

go_escape           LDA #ST_ESCAPE
                    STA #S_ANSI_VARS.STATE,D    ; Move to the ESCAPE state
                    BRA done

do_control          JSR ANSI_PR_CONTROL         ; Hand a single byte control code
                    BRA done

                    ; State: ESCAPE... we've seen an ESC character

do_st_escape        CMP #'['                    ; Have we gotten 'ESC['?
                    BNE pr_and_reset            ; No: print this and return to ST_INIT

                    STZ #S_ANSI_VARS.ARG0,D     ; Clear the arguments
                    STZ #S_ANSI_VARS.ARG1,D
                    STZ #S_ANSI_VARS.ARGC,D

                    LDA #ST_CSI
                    STA #S_ANSI_VARS.STATE,D    ; Move to the CSI state
                    BRA done

                    ; State: CSI... we've seen a CSI sequence, ESC[

do_st_csi           CMP #'0'                    ; Do we have a digit?
                    BLT csi_not_digit
                    CMP #'9'+1
                    BGE csi_not_digit

                    SEC                         ; Have digit... convert to a number
                    SBC #'0'
                    PHA                         ; Save it
                    
                    LDX #S_ANSI_VARS.ARGC,D
                    ASL #S_ANSI_VARS.ARG0,D,X   ; arg := arg * 2
                    LDA #S_ANSI_VARS.ARG0,D,X
                    ASL A                       ; A := arg * 4
                    ASL A                       ; A := arg * 8  
                    CLC
                    ADC #S_ANSI_VARS.ARG0,D,X   ; A := arg * 10
                    STA #S_ANSI_VARS.ARG0,D,X   ; arg := A
                    CLC
                    PLA                         ; Get the digit back
                    ADC #S_ANSI_VARS.ARG0,D,X   ; A := arg * 10 + digit
                    STA #S_ANSI_VARS.ARG0,D,X   ; arg := arg * 10 + digit
                    BRA done                    ; And we're done with this particular character

csi_not_digit       CMP #';'                    ; Is it an argument separator?
                    BNE csi_not_sep

                    LDA #S_ANSI_VARS.ARGC,D     ; Get the argument count
                    CMP #ANSI_MAX_ARG           ; Are we at the maximum argument count?
                    BNE csi_next_arg            ; No: move to the next argument
                    BRL pr_and_reset            ; Yes: print and reset state
csi_next_arg        INC A
                    STA #S_ANSI_VARS.ARGC,D     ; Set the new argument count
                    BRA done                    ; And we're done with this character

csi_not_sep         CMP #'A'
                    BLT csi_not_upper
                    CMP #'Z'+1
                    BGE csi_not_upper

                    JSR ANSI_ANSI_UPPER         ; Process an ANSI upper case code
                    BRA done

csi_not_upper       CMP #'a'
                    BLT csi_not_lower
                    CMP #'z'+1
                    BGE csi_not_lower

                    JSR ANSI_ANSI_LOWER         ; Process an ANSI lower case code
                    BRA done

csi_not_lower       BRL pr_and_reset            ; Invalid sequence: print it and reset

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; Handle an invalid ANSI sequence: print the current character and reset state
;
; Inputs:
;   DP = pointer to the current screen variables
;   A = the character to process (within 'A' .. 'Z')
;
ANSI_INVALID        .proc
                    PHP
                    setas
                    STZ #S_ANSI_VARS.STATE,D    ; If invalid, reset to 0 and print the character
                    JSR ANSI_PUTRAWC            ; Print the character
                    PLP
                    RTS
                    .pend

;
; Process upper case ANSI codes
;
; Inputs:
;   DP = pointer to the current screen variables
;   A = the character to process (within '@' .. 'Z')
;
ANSI_ANSI_UPPER     .proc
                    PHP

                    setaxs
                    STZ #S_ANSI_VARS.STATE,D    ; We'll always reset to the initial state

                    SEC
                    SBC #'@'
                    ASL A
                    TAX
                    JSR (ansi_table,X)
                    PLP
                    RTS

                    ; Table mapping character to operations 
ansi_table          .word <>ANSI_INVALID    ; '@' -- ICH -- Insert Character
                    .word <>ANSI_CUU        ; 'A' -- CUU -- Cursor Up
                    .word <>ANSI_CUD        ; 'B' -- CUD -- Cursor Down
                    .word <>ANSI_CUF        ; 'C' -- CUF -- Cursor Forward
                    .word <>ANSI_CUB        ; 'D' -- CUB -- Cursor Back
                    .word <>ANSI_INVALID    ; 'E' -- CNL -- Cursor Next Line
                    .word <>ANSI_INVALID    ; 'F' -- CPL -- Cursor Previous Line
                    .word <>ANSI_INVALID    ; 'G' -- CHA -- Cursor Horizontal Absolute
                    .word <>ANSI_CUP        ; 'H' -- CUP -- Cursor Position
                    .word <>ANSI_INVALID    ; 'I'
                    .word <>ANSI_ED         ; 'J' -- ED -- Erase In Display
                    .word <>ANSI_EL         ; 'K' -- EL -- Erase In Line
                    .word <>ANSI_INVALID    ; 'L'
                    .word <>ANSI_INVALID    ; 'M'
                    .word <>ANSI_INVALID    ; 'N'
                    .word <>ANSI_INVALID    ; 'O'
                    .word <>ANSI_INVALID    ; 'P' -- DCH -- Delete Character
                    .word <>ANSI_INVALID    ; 'Q'
                    .word <>ANSI_INVALID    ; 'R'
                    .word <>ANSI_INVALID    ; 'S' -- SU -- Scroll Up
                    .word <>ANSI_INVALID    ; 'T' -- SD -- Scroll Down
                    .word <>ANSI_INVALID    ; 'U' 
                    .word <>ANSI_INVALID    ; 'V'
                    .word <>ANSI_INVALID    ; 'W'
                    .word <>ANSI_INVALID    ; 'X'
                    .word <>ANSI_INVALID    ; 'Y'
                    .word <>ANSI_INVALID    ; 'Z'
                    .pend

;
; Process lower case ANSI codes
;
; Inputs:
;   DP = pointer to the current screen variables
;   A = the character to process (within 'a' .. 'z')
;
ANSI_ANSI_LOWER     .proc
                    PHP

                    setaxs
                    STZ #S_ANSI_VARS.STATE,D    ; We'll always reset to the initial state

                    SEC
                    SBC #'a'
                    ASL A
                    TAX
                    JSR (ansi_table,X)
                    PLP
                    RTS

                    ; Table mapping character to operations
ansi_table          .word <>ANSI_INVALID    ; 'a'
                    .word <>ANSI_INVALID    ; 'b'
                    .word <>ANSI_INVALID    ; 'c'
                    .word <>ANSI_INVALID    ; 'd'
                    .word <>ANSI_INVALID    ; 'e'
                    .word <>ANSI_INVALID    ; 'f' -- HVP -- Horizontal Vertical Position
                    .word <>ANSI_INVALID    ; 'g'
                    .word <>ANSI_INVALID    ; 'h'
                    .word <>ANSI_INVALID    ; 'i'
                    .word <>ANSI_INVALID    ; 'j'
                    .word <>ANSI_INVALID    ; 'k'
                    .word <>ANSI_INVALID    ; 'l'
                    .word <>ANSI_SGR        ; 'm' -- SGR -- Select Graphics Rendition
                    .word <>ANSI_INVALID    ; 'n'
                    .word <>ANSI_INVALID    ; 'o'
                    .word <>ANSI_INVALID    ; 'p'
                    .word <>ANSI_INVALID    ; 'q'
                    .word <>ANSI_INVALID    ; 'r'
                    .word <>ANSI_INVALID    ; 's'
                    .word <>ANSI_INVALID    ; 't'
                    .word <>ANSI_INVALID    ; 'u'
                    .word <>ANSI_INVALID    ; 'v'
                    .word <>ANSI_INVALID    ; 'w'
                    .word <>ANSI_INVALID    ; 'x'
                    .word <>ANSI_INVALID    ; 'y'
                    .word <>ANSI_INVALID    ; 'z'
                    .pend

;
; Handle a single byte control code
;
; Inputs:
;   A = character to print (single byte)
;
ANSI_PR_CONTROL     .proc
                    PHP
                    setas
                    setxl

                    CMP #CHAR_CR                ; Handle carriage return
                    BEQ do_cr
                    CMP #CHAR_LF                ; Handle line feed
                    BEQ do_lf
                    CMP #CHAR_BS                ; Handle back space
                    BEQ do_bs
                    CMP #CHAR_TAB               ; Handle TAB
                    BEQ do_tab

                    JSR ANSI_PUTRAWC            ; Otherwise, just print it raw and wriggling!
                    BRA done
                                        
do_cr               LDX #0                      ; Move to the beginning of the next line
                    LDY #S_ANSI_VARS.CURSORY,D
                    INY
                    JSR ANSI_LOCATE
                    BRA done

do_lf               JSR ANSI_CSRDOWN            ; Move the cursor down a line
                    BRA done

do_bs               JSR ANSI_CSRLEFT            ; Move the cursor to the left (TODO: delete to the left?)
                    BRA done

do_tab              setal
                    LDA #S_ANSI_VARS.CURSORX,D  ; Move to the next power 8th column
                    AND #$FFF7
                    CLC
                    ADC #$0008
                    TAX
                    setas

                    LDY #S_ANSI_VARS.CURSORY,D
                    JSR ANSI_LOCATE

done                PLP
                    RTS
                    .pend

;
; ANSI_PUTRAWC
; Print a single character to a channel.
; Characters are written as-is with no escape sequence processing
; Modifies: none
;
ANSI_PUTRAWC        .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setas
                    JSR ANSI_SETDEVICE              ; Look at the current output channel and point
                                                    ; Point to the correct control registers for it
                    BCS done                        ; If invalid, just return

                    STA [#S_ANSI_VARS.CURSORPOS,D]  ; Save the character on the screen

                    LDA #S_ANSI_VARS.CURCOLOR,D     ; Set the color based on CURCOLOR
                    STA [#S_ANSI_VARS.COLORPOS,D]

                    JSR ANSI_CSRRIGHT              ; And advance the cursor

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; Handle the ANSI CUU operation
;
ANSI_CUU            .proc
                    PHP

                    setas
                    LDA #S_ANSI_VARS.ARG0,D         ; Get the first argument
                    INC A

default             LDA #1                          ; Otherwise: treat it as 1

loop                PHA                             ; Save the count
                    JSR ANSI_CSRUP                  ; Cursor Up
                    PLA                             ; Restore the count

                    DEC A                           ; Count down and repeat if not done
                    BNE loop

                    PLP
                    RTS
                    .pend

;
; Handle the ANSI CUD operation
;
ANSI_CUD            .proc
                    PHP

                    setas
                    LDA #S_ANSI_VARS.ARG0,D         ; Get the first argument
                    INC A

loop                PHA                             ; Save the count
                    JSR ANSI_CSRDOWN                ; Cursor Down
                    PLA                             ; Restore the count

                    DEC A                           ; Count down and repeat if not done
                    BNE loop

                    PLP
                    RTS
                    .pend

;
; Handle the ANSI CUF operation
;
ANSI_CUF            .proc
                    PHP

                    setas
                    LDA #S_ANSI_VARS.ARG0,D         ; Get the first argument
                    INC A

loop                PHA                             ; Save the count
                    JSR ANSI_CSRRIGHT               ; Cursor right
                    PLA                             ; Restore the count

                    DEC A                           ; Count down and repeat if not done
                    BNE loop

                    PLP
                    RTS
                    .pend

;
; Handle the ANSI CUB operation
;
ANSI_CUB            .proc
                    PHP

                    setas
                    LDA #S_ANSI_VARS.ARG0,D         ; Get the first argument
                    INC A

loop                PHA                             ; Save the count
                    JSR ANSI_CSRLEFT                ; Cursor left
                    PLA                             ; Restore the count

                    DEC A                           ; Count down and repeat if not done
                    BNE loop

                    PLP
                    RTS
                    .pend

;
; Handle the ANSI CUP operation
;
ANSI_CUP            .proc
                    PHP

                    setaxs
                    LDX #S_ANSI_VARS.ARG0,D         ; Get the first argument
                    BNE get_row
                    LDX #1                          ; Default to 1

get_row             LDY #S_ANSI_VARS.ARG1,D         ; Get the second argument
                    BNE adjust_coords
                    LDY #1                          ; Default to 1

adjust_coords       DEX                             ; Translate from base 1 to base 0 coordinates
                    DEY

                    setaxl
                    JSR ANSI_LOCATE                 ; Set the cursor position

                    PLP
                    RTS
                    .pend

;
; Handle the ANSI SGR operation
;
ANSI_SGR            .proc
                    PHP

                    setaxs
                    LDA #S_ANSI_VARS.ARG0,D         ; Get the first argument
                    BNE chk_1

                    ; 0 ==> Reset to the defaults

                    LDA #ANSI_DEF_COLOR             ; 0 ==> Return to the default colors
                    STA #S_ANSI_VARS.CURCOLOR,D

                    LDA #S_ANSI_VARS.CONTROL,D      ; Switch off inversion
                    AND #~(CONTROL_INVERT | CONTROL_BOLD)
                    STA #S_ANSI_VARS.CONTROL,D
                    BRL done

chk_1               CMP #1
                    BNE chk_2

                    ; 1 ==> Set the foreground to high intensity

                    LDA #S_ANSI_VARS.CURCOLOR,D     ; Make the current color bold
                    ORA #$80
                    STA #S_ANSI_VARS.CURCOLOR,D

                    LDA #S_ANSI_VARS.CONTROL,D      ; Flag that text should be bold
                    ORA #CONTROL_BOLD
                    STA #S_ANSI_VARS.CONTROL,D
                    BRL done

chk_2               CMP #2
                    BEQ normal_intensity
chk_22              CMP #22
                    BNE chk_7

                    ; 2|22 ==> go back to normal intensity 

normal_intensity    LDA #S_ANSI_VARS.CURCOLOR,D     ; 2 ==> Set the foreground to normal intensity
                    AND #~$80
                    STA #S_ANSI_VARS.CURCOLOR,D

                    LDA #S_ANSI_VARS.CONTROL,D      ; Flag that text should be normal
                    AND #~CONTROL_BOLD
                    STA #S_ANSI_VARS.CONTROL,D
                    BRL done

chk_7               CMP #7
                    BNE chk_27

                    ; 7 ==> Enable reversed text

                    LDA #S_ANSI_VARS.CONTROL,D      ; Are the colors already inverted?
                    BIT #CONTROL_INVERT
                    BEQ invert_on
                    BRL done                        ; Yes: just finish

invert_on           ORA #CONTROL_INVERT             ; No: Mark that the colors are inverted
                    STA #S_ANSI_VARS.CONTROL,D

swap_colors         LDA #S_ANSI_VARS.CURCOLOR,D     ; Exchange the upper and lower nibbles
                    ASL  A
                    ADC  #$80
                    ROL  A
                    ASL  A
                    ADC  #$80
                    ROL  A
                    AND #%11110111                  ; Make sure the background is not bolded
                    STA #S_ANSI_VARS.CURCOLOR,D

                    LDA #S_ANSI_VARS.CONTROL,D      ; Should the color be bold?
                    BIT #CONTROL_BOLD
                    BNE bold_on
                    BRL done                        ; No: we're done

bold_on             LDA #S_ANSI_VARS.CURCOLOR,D     ; Yes: make the foreground bold
                    ORA #$80
                    STA #S_ANSI_VARS.CURCOLOR,D
                    BRA done

chk_27              CMP #27
                    BNE chk_39
                    
                    ; 27 ==> stop inverting the colors

                    LDA #S_ANSI_VARS.CONTROL,D      ; Are the colors inverted?
                    BIT #CONTROL_INVERT
                    BEQ done                        ; No: just finish

                    AND #~CONTROL_INVERT            ; Yes: Mark that the colors are back to normal
                    STA #S_ANSI_VARS.CONTROL,D
                    BRA swap_colors                 ; And go swap the colors

chk_39              CMP #39
                    BNE chk_49

                    ; 39 ==> ; Restore the default foreground color

                    LDA #S_ANSI_VARS.CURCOLOR,D     
                    AND #$0F
                    STA #S_ANSI_VARS.CURCOLOR,D

                    LDA #ANSI_DEF_COLOR             
                    AND #$F0
                    ORA #S_ANSI_VARS.CURCOLOR,D
                    STA #S_ANSI_VARS.CURCOLOR,D
                    BRA done
                    
chk_49              CMP #49
                    BNE chk_foreground

                    ; 49 ==> Restore the default background color

                    LDA #S_ANSI_VARS.CURCOLOR,D
                    AND #$F0
                    STA #S_ANSI_VARS.CURCOLOR,D

                    LDA #ANSI_DEF_COLOR             
                    AND #$0F
                    ORA #S_ANSI_VARS.CURCOLOR,D
                    STA #S_ANSI_VARS.CURCOLOR,D
                    BRA done

                    
chk_foreground      CMP #30                         ; If [30..37], set the foreground color
                    BLT chk_background
                    CMP #38
                    BGE chk_background

                    ; 30..37 ==> Set the foreground color

                    LDA #S_ANSI_VARS.CURCOLOR,D
                    AND #$0F
                    STA #S_ANSI_VARS.CURCOLOR,D
                    
                    LDA #S_ANSI_VARS.ARG0,D
                    SEC
                    SBC #30
                    ASL A
                    ASL A
                    ASL A
                    ASL A
                    ORA #S_ANSI_VARS.CURCOLOR,D
                    STA #S_ANSI_VARS.CURCOLOR,D

                    LDA #S_ANSI_VARS.CONTROL,D      ; Should the color be bold?
                    BIT #CONTROL_BOLD
                    BNE bold_fore                   ; No: we're done
                    BRL done

bold_fore           LDA #S_ANSI_VARS.CURCOLOR,D     ; Yes: make the foreground bold
                    ORA #$80
                    STA #S_ANSI_VARS.CURCOLOR,D
                    BRL done

chk_background      CMP #40                         ; If [40..47], set the background color
                    BLT done
                    CMP #48
                    BGE done

                    ; 40..47 ==> Set the background color

                    LDA #S_ANSI_VARS.CURCOLOR,D
                    AND #$F0
                    STA #S_ANSI_VARS.CURCOLOR,D
                    
                    LDA #S_ANSI_VARS.ARG0,D
                    SEC
                    SBC #40
                    ORA #S_ANSI_VARS.CURCOLOR,D
                    STA #S_ANSI_VARS.CURCOLOR,D

done                PLP
                    RTS
                    .pend

;
; Handle the ANSI ED operation
;
ANSI_ED             .proc
                    PHY
                    PHP

                    setas
                    setxl
                    LDA #S_ANSI_VARS.ARG0,D         ; Get the first argument

                    BNE not_0                       ; Is the code 0?

code_0              ; 0 --> Erase from the cursor to the end of the screen
                    LDA #' '
                    LDY #CURSORPOS,D                ; Start with the cursor's position
code_0_loop         STA [#SCREENBEGIN,D],Y          ; Clear the text cell
                    INY                             ; Go to the next position
                    CPY #$2000                      ; Have we reached the end?
                    BNE code_0_loop                 ; No: keep going
                    BRL done

not_0               CMP #1                          ; Is the code 1?
                    BNE not_1

code_1              ; 1 --> Erase from beginning of screen to cursor
                    LDA #' '
                    LDY #CURSORPOS,D                ; Start with the cursor's position
code_1_loop         STA [#SCREENBEGIN,D],Y          ; Clear the text cell
                    DEY                             ; Go to the previous position
                    BNE code_1_loop
                    STA [#SCREENBEGIN,D],Y          ; Clear the first cell
                    BRL done

not_1               CMP #2                          ; Is the code 2 or 3?
                    BEQ code_2_3
                    CMP #3
                    BNE done                        ; No: just ignore the sequence

code_2_3            ; 2|3 --> Clear the entire screen
                    LDA #' '
                    LDY #0                          ; Start with the cursor's position
code_2_3_loop       STA [#SCREENBEGIN,D],Y          ; Clear the text cell
                    INY                             ; Go to the next position
                    CPY #$2000                      ; Have we reached the end?
                    BNE code_0_loop                 ; No: keep going

done                PLP
                    PLY
                    RTS
                    .pend

;
; Handle the ANSI EL operation
;
ANSI_EL             .proc
                    PHX
                    PHY
                    PHP

                    setaxl
                    SEC
                    LDA #S_ANSI_VARS.CURSORPOS,D        ; Compute the address of the first character of the line
                    SBC #S_ANSI_VARS.CURSORX,D
                    STA #S_ANSI_VARS.TMPPTR1,D
                    setas
                    LDA #S_ANSI_VARS.SCREENBEGIN+2,D    ; Get the bank of the screen
                    STA #S_ANSI_VARS.TMPPTR1+2,D        ; And put it in the TMPPTR1

                    LDA #S_ANSI_VARS.ARG0,D             ; Get the first argument
                    BNE not_0                           ; Is the code 0?

code_0              ; 0 --> Erase from the cursor to the end of the line
                    LDA #' '
                    LDY #S_ANSI_VARS.CURSORX,D          ; Start at the cursor position
code_0_loop         STA [#S_ANSI_VARS.TMPPTR1,D],Y      ; Clear the text cell
                    INY
                    CPY #S_ANSI_VARS.COLS_PER_LINE,D    ; Have we reached the end of the line?
                    BNE code_0_loop                     ; No: keep looping
                    BRL done

not_0               CMP #1                              ; Is the code 1?
                    BNE not_1

code_1              ; 1 --> Erase from beginning of line to cursor
                    LDA #' '
                    LDY #0
code_1_loop         STA [#S_ANSI_VARS.TMPPTR1,D],Y      ; Clear the text cell
                    INY
                    CPY #S_ANSI_VARS.CURSORX,D          ; Have we reached the cursor?
                    BNE code_1_loop                     ; No: keep looping
                    STA [#S_ANSI_VARS.TMPPTR1,D],Y      ; And clear under the cursor
                    BRL done

not_1               CMP #2                              ; Is the code 2 or 3?
                    BEQ code_2_3
                    CMP #3
                    BNE done                            ; No: just ignore the sequence

code_2_3            ; 2|3 --> Clear the entire line
                    LDA #' '
                    LDY #0
code_2_3_loop       STA [#S_ANSI_VARS.TMPPTR1,D],Y      ; Clear the text cell
                    INY
                    CPY #S_ANSI_VARS.COLS_PER_LINE,D    ; Have we reached the end of the line?
                    BNE code_2_3_loop                   ; No: keep looping

done                PLP
                    PLY
                    PLX
                    RTS
                    .pend

;
; ICSRRIGHT
; Move the cursor right one space
; Modifies: none
;
ANSI_CSRRIGHT       .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setaxl

                    JSR ANSI_SETDEVICE                  ; Look at the current output channel and point
                                                        ; Point to the correct control registers for it
                    BCS done                            ; If invalid, just return

                    LDX #S_ANSI_VARS.CURSORX,D          ; Get the new column
                    INX
                    LDY #S_ANSI_VARS.CURSORY,D          ; Get the current row

                    CPX #S_ANSI_VARS.COLS_VISIBLE,D     ; Are we off screen?
                    BCC nowrap                          ; No: just set the position

                    LDX #0                              ; Yes: move to the first column
                    INY                                 ; And move to the next row
                    CPY #S_ANSI_VARS.LINES_VISIBLE,D    ; Are we still off screen?
                    BCC nowrap                          ; No: just set the position

                    DEY                                 ; Yes: lock to the last row
                    JSR ANSI_SCROLLUP                   ; But scroll the screen up

nowrap              JSR ANSI_LOCATE                     ; Set the cursor position     

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; ANSI_CSRLEFT
; Move the cursor left one space
; Modifies: none
;
ANSI_CSRLEFT        .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setaxl

                    JSR ANSI_SETDEVICE          ; Look at the current output channel and point
                                                ; Point to the correct control registers for it
                    BCS done                    ; If invalid, just return

                    LDX #S_ANSI_VARS.CURSORX,D  ; Check that we are not already @ Zero
                    BEQ done                    ; If so, just ignore this call

                    DEX
                    STX #S_ANSI_VARS.CURSORX,D
                    LDY #S_ANSI_VARS.CURSORY,D
                    JSR ANSI_LOCATE

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; ANSI_CSRUP
; Move the cursor up one space
; This routine doesn't wrap the cursor when it reaches the top, it just stays at the top
; Modifies: none
;
ANSI_CSRUP          .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setaxl
                    JSR ANSI_SETDEVICE          ; Look at the current output channel and point
                                                ; Point to the correct control registers for it
                    BCS done                    ; If invalid, just return

                    LDY #S_ANSI_VARS.CURSORY,D  ; Check if we are not already @ Zero
                    BEQ done                    ; If we are, just ignore the call
                    DEY
                    STY #S_ANSI_VARS.CURSORY,D
                    LDX #S_ANSI_VARS.CURSORX,D
                    JSR ANSI_LOCATE

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; ANSI_CSRDOWN
; Move the cursor down one space
; When it reaches the bottom. Every time it go over the limit, the screen is scrolled up. (Text + Color)
; It will replicate the Color of the last line before it is scrolled up.
; Modifies: none
;
ANSI_CSRDOWN        .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setaxl
                    JSR ANSI_SETDEVICE                  ; Look at the current output channel and point
                                                        ; Point to the correct control registers for it
                    BCS done                            ; If invalid, just return

                    LDX #S_ANSI_VARS.CURSORX,D          ; Get the current column
                    LDY #S_ANSI_VARS.CURSORY,D          ; Get the new row
                    INY
                    CPY #S_ANSI_VARS.LINES_VISIBLE,D    ; Check to see if we're off screen
                    BCC noscroll                        ; No: go ahead and set the position

                    DEY                                 ; Yes: go back to the last row
                    JSR ANSI_SCROLLUP                   ; But scroll the screen up

noscroll            JSR ANSI_LOCATE                     ; And set the cursor position

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; ANSI_LOCATE
; Sets the cursor X and Y positions to the X and Y registers
;
; Input:
;   X: column to set cursor
;   Y: row to set cursor
; Modifies: none
;
ANSI_LOCATE         .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    JSR ANSI_SETDEVICE          ; Look at the current output channel and point
                                                ; Point to the correct control registers for it
                    BCS done                    ; If invalid, just return

                    setaxl
locate_scroll       ; If the cursor is below the bottom row of the screen
                    ; scroll the screen up one line. Keep doing this until
                    ; the cursor is visible.
                    CPY #S_ANSI_VARS.LINES_VISIBLE,D
                    BCC locate_scrolldone
                    JSR ANSI_SCROLLUP
                    DEY
                    ; repeat until the cursor is visible again
                    BRA locate_scroll

locate_scrolldone
                    ; done scrolling store the resultant cursor positions.
                    STX #S_ANSI_VARS.CURSORX,D
                    STY #S_ANSI_VARS.CURSORY,D
                    LDA #S_ANSI_VARS.SCREENBEGIN,D

locate_row          ; compute the row
                    CPY #$0
                    BEQ locate_right

                    ; move down the number of rows in Y
locate_down         CLC
                    ADC #S_ANSI_VARS.COLS_PER_LINE,D
                    DEY
                    BEQ locate_right
                    BRA locate_down

                    ; compute the column
locate_right        CLC
                    ADC #S_ANSI_VARS.CURSORX,D      ; move the cursor right X columns
                    STA #S_ANSI_VARS.CURSORPOS,D
                    LDY #S_ANSI_VARS.CURSORY,D
                    
                    setas
                    LDA @l CHAN_OUT
                    CMP #CHAN_EVID
                    beq locate_evid

                    setal                       ; Set the Vicky cursor registers (main screen)
                    TYA
                    STA @l VKY_TXT_CURSOR_Y_REG_L
                    TXA
                    STA @l VKY_TXT_CURSOR_X_REG_L
                    BRA update_colorpos

locate_evid         setal                       ; Set the EVID cursor registers (secondary screen)
                    TYA
                    STA @l EVID_TXT_CURSOR_Y_REG_L
                    TXA
                    STA @l EVID_TXT_CURSOR_X_REG_L

update_colorpos     setal
                    CLC
                    LDA #S_ANSI_VARS.CURSORPOS,D
                    ADC #<>(CS_COLOR_MEM_PTR - CS_TEXT_MEM_PTR)
                    STA #S_ANSI_VARS.COLORPOS,D

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend

;
; ANSI_SCROLLUP
; Scroll the screen up one line
; Inputs:
;   None
; Affects:
;   None
ANSI_SCROLLUP       .proc
                    PHX
                    PHY
                    PHB
                    PHD
                    PHP

                    JSR ANSI_SETDEVICE          ; Look at the current output channel and point
                                                ; Point to the correct control registers for it
                    BCC calc_size
                    BRL done                    ; If invalid, just return

calc_size           setaxl
                    ; Calculate the number of bytes to move
                    LDA #S_ANSI_VARS.COLS_PER_LINE,D
                    STA @l UNSIGNED_MULT_A_LO

                    LDA #S_ANSI_VARS.LINES_VISIBLE,D
                    STA @l UNSIGNED_MULT_B_LO
                    
                    LDA @l UNSIGNED_MULT_AL_LO
                    STA #S_ANSI_VARS.TMPPTR1,D

                    ; Scroll Text Up
                    CLC
                    LDA #S_ANSI_VARS.SCREENBEGIN,D
                    TAY
                    ADC #S_ANSI_VARS.COLS_PER_LINE,D
                    TAX

                    setas
                    LDA @l CHAN_OUT                             ; Are we scrolling the EVID
                    CMP #CHAN_EVID
                    BEQ move_text_1                             ; Yes: do the move on the EVID memory

move_text_0         setal
                    LDA #S_ANSI_VARS.TMPPTR1,D
                    MVN `CS_TEXT_MEM_PTR,`CS_TEXT_MEM_PTR       ; Move the data on the main screen
                    BRA scroll_color

move_text_1         setal
                    LDA #S_ANSI_VARS.TMPPTR1,D
                    MVN `EVID_TEXT_MEM,`EVID_TEXT_MEM           ; Move the data on the EVID screen

                    ; Scroll Color Up
scroll_color        setaxl
                    CLC
                    LDA #S_ANSI_VARS.COLORBEGIN,D
                    TAY
                    ADC #S_ANSI_VARS.COLS_PER_LINE,D
                    TAX

                    setas
                    LDA @l CHAN_OUT                             ; Are we scrolling the EVID?
                    CMP #CHAN_EVID
                    BEQ move_color_1                            ; Yes: scroll the EVID color matrix

move_color_0        setal
                    LDA #S_ANSI_VARS.TMPPTR1,D
                    MVN `CS_COLOR_MEM_PTR,`CS_COLOR_MEM_PTR     ; Move the data on the main screen
                    BRA vicky_lastline

move_color_1         setal
                    LDA #S_ANSI_VARS.TMPPTR1,D
                    MVN `EVID_COLOR_MEM,`EVID_COLOR_MEM         ; Move the data on the EVID screen

                    ; Clear the last line of text on the screen
                    
vicky_lastline      setal
                    LDA #S_ANSI_VARS.TMPPTR1,D
                    PHA
                    CLC
                    ADC #S_ANSI_VARS.SCREENBEGIN,D
                    STA #S_ANSI_VARS.TMPPTR1,D

start_clear         LDY #0
                    LDA #' '
clr_text            STA [#S_ANSI_VARS.TMPPTR1,D],Y
                    INY
                    CPY #COLS_VISIBLE,D
                    BNE clr_text

                    ; Set the last line of color on the screen to the current color

vicky_lastcolor     PLA
                    CLC
                    ADC #S_ANSI_VARS.COLORBEGIN,D
                    STA #S_ANSI_VARS.TMPPTR1,D

start_color         LDY #0
                    LDA #S_ANSI_VARS.CURCOLOR,D
clr_color           STA [#S_ANSI_VARS.TMPPTR1,D],Y
                    INY
                    CPY #S_ANSI_VARS.COLS_PER_LINE,D
                    BNE clr_color

done                PLP
                    PLD
                    PLB
                    PLY
                    PLX
                    RTS
                    .pend

;
; ANSI_CLRSCREEN
; Clear the screen and set the background and foreground colors to the
; currently selected colors.
;
ANSI_CLRSCREEN      .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    JSR ANSI_SETDEVICE          ; Look at the current output channel and point
                                                ; Point to the correct control registers for it
                    BCS done                    ; If invalid, just return

                    setas
                    setxl

                    LDY #0
                    LDA #$20		            ; Fill the Entire Screen with Space
iclearloop0	        STA [#S_ANSI_VARS.SCREENBEGIN,D],Y
                    INY
                    CPY #$2000
                    BNE iclearloop0

                    ; Now Set the Colors so we can see the text
                    LDY	#0
                    LDA #CURCOLOR,D             ; Fill the current color
evid_clearloop1     STA [#S_ANSI_VARS.COLORBEGIN,D],Y
                    INY
                    CPY #$2000
                    BNE evid_clearloop1

done                PLP
                    PLD
                    PLY
                    PLX
                    RTS
                    .pend


