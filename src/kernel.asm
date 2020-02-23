.cpu "65816"

TARGET_FLASH = 1              ; The code is being assembled for Flash
TARGET_RAM = 2                ; The code is being assembled for RAM

.include "macros_inc.asm"
.include "characters.asm"     ; Definition of special ASCII control codes
.include "simulator_inc.asm"
.include "page_00_inc.asm"
.include "page_00_data.asm"
.include "page_00_code.asm"
.include "Math_def.asm"                     ; Math Co_processor Definition
.include "interrupt_def.asm"                ; Interrupr Controller Registers Definitions
.include "dram_inc.asm"                     ; old Definition file that was supposed to be a Memory map
.include "vicky_def.asm"                    ; VICKY's registers Definitions
.include "super_io_def.asm"                 ; SuperIO Registers Definitions
.include "keyboard_def.asm"                 ; Keyboard 8042 Controller (in SuperIO) bit Field definitions
.include "SID_def.asm"                      ; SID, but not the latest - Deprecated for now.
.include "RTC_def.asm"                      ; Real-Time Clock Register Definition (BQ4802)
.include "io_def.asm"                       ; CODEC, SDCard Controller Registers
.include "Trinity_CFP9301_def.asm"          ; Definitions for Trinity chip: Joystick, DipSwitch
.include "Unity_CFP9307_def.asm"            ; Definitions for Unity chip (IDE)
.include "GABE_Control_Registers_def.asm"   ; Definitions for GABE registers

.include "basic_inc.asm"      ; Pointers into BASIC and the machine language monitor
;.include "OPL2_Rad_Player.asm"

; C256 Foenix Kernel
; The Kernel is located in flash @ F8:0000 but not accessible by CPU
; Kernel Transfered by GAVIN @ Cold Reset to $18:0000 - $1F:FFFF

; Loads to $38:0000

.include "kernel_jumptable.asm"

.include "Interrupt_Handler.asm" ; Interrupt Handler Routines
.include "SDOS.asm"           ; Code Library for SD Card Controller (Working, needs a lot improvement and completion)
.include "OPL2_Library.asm"   ; Library code to drive the OPL2 (right now, only in mono (both side from the same data))
.include "ide_library.asm"
;.include "YM26XX.asm"
.include "keyboard.asm"       ; Include the keyboard reading code
.include "uart.asm"           ; The code to handle the UART
.include "joystick.asm"       ; Code for the joysticks and gamepads

* = $390400

IBOOT           ; boot the system
                CLC               ; clear the carry flag
                XCE               ; move carry to emulation flag.

                SEI               ; Disable interrupts

                setaxl
                LDA #STACK_END    ; initialize stack pointer
                TAS

                LDX #<>BOOT       ; Copy the kernel jump table to bank 0
                LDY #<>BOOT       ; Ordinarily, this is done by GAVIN, but
                LDA #$0100        ; this is ensures it can be reloaded in case of errors
                MVN `BOOT,$00     ; Or during soft loading of the kernel from the debug port

                setdp 0
                setas
                LDX #$0000
                LDA #$00
CLEAR_MEM_LOOP
                STA $0000, X
                INX
                CPX #$0100
                BNE CLEAR_MEM_LOOP
                NOP

                ; Setup the Interrupt Controller
                ; For Now all Interrupt are Falling Edge Detection (IRQ)
                LDA #$FF
                STA @lINT_EDGE_REG0
                STA @lINT_EDGE_REG1
                STA @lINT_EDGE_REG2
                STA @lINT_EDGE_REG3
                ; Mask all Interrupt @ This Point
                STA @lINT_MASK_REG0
                STA @lINT_MASK_REG1
                STA @lINT_MASK_REG2
                STA @lINT_MASK_REG3

                setaxl
                LDA #<>SCREEN_PAGE0      ; store the initial screen buffer location
                STA SCREENBEGIN
                STA CURSORPOS

                LDA #<>CS_COLOR_MEM_PTR   ; Set the initial COLOR cursor position
                STA COLORPOS

                setas
                LDA #`SCREEN_PAGE0
                STA SCREENBEGIN+2
                STA CURSORPOS+2

                LDA #`CS_COLOR_MEM_PTR    ; Set the initial COLOR cursor position
                STA COLORPOS+2
                
                setas
                LDA #$00
                STA KEYBOARD_SC_FLG     ; Clear the Keyboard Flag
                ; Shutdown the SN76489 before the CODEC enables all the channels
                LDA #$9F ; Channel Two - No Atteniation
                STA $AFF100
                LDA #$BF ; Channel Two - No Atteniation
                STA $AFF100
                LDA #$DF ; Channel Two - No Atteniation
                STA $AFF100
                LDA #$FF ; Channel Two - No Atteniation
                STA $AFF100

                ;LDA #$04                ; This is to make sure the RTC will keep working after unit is turn-off
                ;STA @lRTC_CTRL
                ; Set screen dimensions. There more columns in memory than
                ; are visible. A virtual line is 128 bytes, but 80 columns will be
                ; visible on screen.
                setaxl
                LDX #72
                STX COLS_VISIBLE
                LDY #52
                STY LINES_VISIBLE
                LDX #128
                STX COLS_PER_LINE
                LDY #64
                STY LINES_MAX

                LDA #$ED                  ; Set the default text color to light gray on dark gray 
                STA CURCOLOR

                ; Init CODEC
                JSL INITCODEC
                ; Init Suprt IO (Keyboard/Floppy/Etc...)
                JSL INITSUPERIO
                ; Init GAMMA Table
                JSL INITGAMMATABLE
                ; Init All the Graphic Mode Look-up Table (by default they are all Zero)
                JSL INITALLLUT
                ; Initialize the Character Color Foreground/Background LUT First
                JSL INITCHLUT

                JSL INITMOUSEPOINTER
                ; Go Enable and Setup the Cursor's Position
                JSL INITCURSOR
                ; Init the Vicky Text MODE
                JSL INITVKYTXTMODE
                ; Load The FONT Memory with local FONT in Flash (or RAM)
                JSL IINITFONTSET
                ; Now, clear the screen and Setup Foreground/Background Bytes, so we can see the Text on screen
                JSL ICLRSCREEN  ; Clear Screen and Set a standard color in Color Memory
                ; Init Globacl Look-up Table

                ; Initialize the UARTs
                LDA #CHAN_COM1    ; Initialize COM1
                JSL UART_SELECT
                JSL UART_INIT
                LDA #CHAN_COM2    ; Initialize COM2
                JSL UART_SELECT
                JSL UART_INIT

                ; Set the default I/O devices to the screen and keyboard
                LDA #0
                JSL SETIN
                JSL SETOUT

                setal

                LDX #0
                LDY #0
                JSL ILOCATE

                setaxl
                ; Write the Greeting Message Here, after Screen Cleared and Colored
greet           setdbr `greet_msg       ;Set data bank to ROM
                LDX #<>greet_msg
                JSL IPRINT       ; print the first line

                ; Go set the Color Text Memory so we can have color for the LOGO
                JSL ICOLORFLAG  ; This is to set the Color Memory for the Logo

                setdp 0
                ; Init the Keyboard
                JSL INITKEYBOARD ;

                setas
                setxl
                LDA #$9F ; Channel Two - No Atteniation
                STA $AFF100
                LDA #$BF ; Channel Two - No Atteniation
                STA $AFF100
                LDA #$DF ; Channel Two - No Atteniation
                STA $AFF100
                LDA #$FF ; Channel Two - No Atteniation
                STA $AFF100
                LDA #$83 ; Channel Zero - No Atteniation
                STA $AFF100
                LDA #$12 ; Channel Zero - No Atteniation
                STA $AFF100
                LDA #$90 ; Channel One - No Atteniation
                STA $AFF100
                LDX #16384      ; 400ms
          		 	JSL ILOOP_MS
                LDA #$9F ; Channel Two - No Atteniation
                STA $AFF100

                ; ;setaxl
                ; JSL YM2151_test
                ; ;JSL YM2151_test_2_from_Chibisound
                ; JSL YM2612_test_piano
                ; JSL YM2612_test_piano

                ; ;JSL OPL2_TONE_TEST
                ; ;JSL OPL2_INIT_PLAYER

                CLI                   ; Make sure no Interrupt will come and fuck up Init before this point.

                setas
                setxl
                setdbr `greet_msg     ;set data bank to 39 (Kernel Variables)

                ;
                ; Determine the boot mode on the DIP switches and complete booting as specified
                ;

                LDA @lDIP_BOOTMODE    ; {HD_INSTALLED, 5'b0_0000, BOOT_MODE[1], BOOT_MODE[0]}
                AND #%00000011        ; Look at the mode bits
                CMP #DIP_BOOT_IDE     ; DIP set for IDE?
                BEQ BOOTIDE           ; Yes: Boot from the IDE

                CMP #DIP_BOOT_SDCARD  ; DIP set for SD card?
                BEQ BOOTSDC           ; Yes: try to boot from the SD card
                
                CMP #DIP_BOOT_FLOPPY  ; DIP set for floppy?
                BEQ BOOTFLOPPY        ; Yes: try to boot from the floppy

BOOTBASIC       JML BASIC             ; Cold start of the BASIC interpreter (or its replacement)

CREDIT_LOCK     NOP
                BRA CREDIT_LOCK

BOOTSDC         ; TODO: implement boot from SD card

                LDX #<>sdcard_notimpl ; Print a message saying SD card booting is not implemented
                BRA PR_BOOT_ERROR

BOOTIDE         ; TODO: implement boot from IDE

                LDX #<>ide_notimpl    ; Print a message saying SD card booting is not implemented
                BRA PR_BOOT_ERROR

BOOTFLOPPY      ; TODO: implement boot from floppy

                LDX #<>floppy_notimpl ; Print a message saying SD card booting is not implemented
PR_BOOT_ERROR   JSL IPRINT
LOOP_FOREVER    NOP
                BRA LOOP_FOREVER

;
; IBREAK
; ROM Break handler. This pulls the registers out of the stack
; and saves them in the "CPU" direct page locations
IBREAK          setdp 0
                PLA             ; Pull .Y and stuff it in the CPUY variable
                STA CPUY
                PLA             ; Pull .X and stuff it in the CPUY variable
                STA CPUX
                PLA             ; Pull .A and stuff it in the CPUY variable
                STA CPUA
                PLA
                STA CPUDP       ; Pull Direct page
                setas
                PLA             ; Pull Data Bank (8 bits)
                STA CPUDBR
                PLA             ; Pull Flags (8 bits)
                STA CPUFLAGS
                setal
                PLA             ; Pull Program Counter (16 bits)
                STA CPUPC
                setas
                PLA             ; Pull Program Bank (8 bits)
                STA CPUPBR
                setal
                TSA             ; Get the stack
                STA CPUSTACK    ; Store the stack at immediately before the interrupt was asserted
                LDA #<>STACK_END   ; initialize stack pointer back to the bootup value
                                ;<> is "lower word"
                TAS
                JML MONITOR

IREADY          setdbr `ready_msg
                setas
                LDX #<>ready_msg
                JSL IPRINT
;
; IREADYWAIT*
;  Wait for a keypress and display it on the screen. When the RETURN key is pressed,
;  call the RETURN event handler to process the command. Since RETURN can change, use
;  the vector in Direct Page to invoke the handler.
;
;  *Does not return. Execution in your program should continue via the RETURN direct page
;  vector.
IREADYWAIT      ; Check the keyboard buffer.
                JSL IGETCHE
                BRA IREADYWAIT

IKEYDOWN        STP             ; Keyboard key pressed
IRETURN         STP

;
; ISETIN
; Sets the channel to use for input (e.g. GETCH)
;
; Inputs:
;   A = the number of the channel to use (1-byte)
;       0 = Keyboard
;       1 = COM1
;       2 = COM2
;       3 = N/A
;
ISETIN          PHP
                setas
                STA @lCHAN_IN   ; Save the channel number
                PLP
                RTL

;
; ISETOUT
; Sets the channel to use for output (e.g. PUTC)
;
; Inputs:
;   A = the number of the channel to use (1-byte)
;       0 = Text Screen
;       1 = COM1
;       2 = COM2
;       3 = LPT
;
ISETOUT         PHP
                setas
                STA @lCHAN_OUT  ; Save the channel number
                PLP
                RTL

;
;IGETCHE
; Get a character from the current input chnannel and echo it to screen.
; Waits for a character to be read.
; Return:
; A: Character read
; Carry: 1 if no valid data
;
IGETCHE         JSL IGETCHW
                JSL IPUTC
                RTL

;
;IGETCHW
; Get a character from the current input chnannel.
; Waits for a character to be read.
; Return:
; A: Character read
; Carry: 1 if no valid data
;
IGETCHW         .proc
                PHP

                setas
                LDA @lCHAN_IN       ; Get the current input channel
                BEQ getc_keyboard   ; If it's keyboard, read from the key buffer

                CMP #CHAN_COM1      ; Check to see if it's the COM1 port
                BEQ getc_uart       ; Yes: handle reading from the UART
                CMP #CHAN_COM2      ; Check to see if it's the COM2 port
                BEQ getc_uart       ; Yes: handle reading from the UART                

                ; TODO: handle other devices

                LDA #0              ; Return 0 if no valid device
                PLP
                SEC                 ; And return carry set
                RTL

getc_uart       JSL UART_SELECT     ; Select the correct COM port
                JSL UART_GETC       ; Get the charater from the COM port
                BRA done            

getc_keyboard   JSL KBD_GETC        ; Get the character from the keyboard
done            PLP
                CLC                 ; Return carry clear for valid data
                RTL
                .pend
;
; IPRINT
; Print a string, followed by a carriage return
; DBR: bank containing string
; X: address of the string in data bank
; Modifies: X
;
IPRINT          JSL IPUTS
                JSL IPRINTCR
                RTL

; IPUTS
; Print a null terminated string
; DBR: bank containing string
; X: address of the string in data bank
; Modifies: X.
;  X will be set to the location of the byte following the string
;  So you can print multiple, contiguous strings by simply calling
;  IPUTS multiple times.
IPUTS           PHA
                PHP
                setas
                setxl
iputs1          LDA $0,b,x      ; read from the string
                BEQ iputs_done
iputs2          JSL IPUTC
iputs3          INX
                JMP iputs1
iputs_done      INX
                PLP
                PLA
                RTL

;
; IPUTC
; Print a single character to a channel.
; Handles terminal sequences, based on the selected text mode
; Modifies: none
;
IPUTC           .proc
                PHX
                PHY
                PHD
                PHB
                PHP                 ; stash the flags (we'll be changing M)

                setdp 0
                setdbr 0
                setas
                setxl

                PHA                 ; Save the character to print
                LDA @lCHAN_OUT      ; Check the output channel #
                BEQ putc_screen     ; If it's 0: print to the screen

                CMP #CHAN_COM1      ; Check to see if it's the COM1 port
                BEQ putc_uart       ; Yes: handle printing to the UART
                CMP #CHAN_COM2      ; Check to see if it's the COM2 port
                BEQ putc_uart       ; Yes: handle printing to the UART

                ; TODO: handle other output channels

                PLA                 ; Otherwise, just exit
                BRA done

putc_uart       JSL UART_SELECT     ; Point to the correct UART

                PLA                 ; Recover the character to send
                JSL UART_PUTC       ; Send the character
                BRA done

putc_screen     PLA                 ; Get the character to print
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

printc          STA [CURSORPOS]     ; Save the character on the screen

                LDA CURCOLOR        ; Set the color based on CURCOLOR
                STA [COLORPOS]

                JSL ICSRRIGHT       ; And advance the cursor

done            PLP
                PLB
                PLD
                PLY
                PLX
                RTL

do_del          JSL SCRSHIFTLL      ; Shift the current line left one space into the cursor
                BRA done

do_ins          JSL SCRSHIFTLR      ; Shift the current line right one space from the cursor
                BRA done

backspace       JSL ICSRLEFT  
                JSL SCRSHIFTLL      ; Shift the current line left one space into the cursor
                BRA done

do_cr           JSL IPRINTCR        ; Move the cursor to the beginning of the next line
                BRA done

go_down         JSL ICSRDOWN        ; Move the cursor down one row (might force a scroll)
                BRA done

go_up           JSL ICSRUP          ; Move the cursor up one line
                BRA done

go_right        JSL ICSRRIGHT       ; Move the cursor right one column
                BRA done

go_left         JSL ICSRLEFT        ; Move the cursor left one column
                BRA done

do_TAB          setal
                LDA CURSORX         ; Get the current column
                AND #$FFF8          ; See which group of 8 it's in
                CLC
                ADC #$0008          ; And move it to the next one
                TAX
                LDY CURSORY
                setas

set_xy          CPX COLS_VISIBLE    ; Check if we're still on screen horizontally
                BCC check_row       ; Yes: check the row
                LDX #0              ; No: move to the first column...
                INY                 ; ... and the next row

check_row       CPY LINES_VISIBLE   ; Check if we're still on the screen vertically
                BCC do_locate       ; Yes: reposition the cursor

                JSL ISCROLLUP       ; No: scroll the screen
                DEY                 ; And set the row to the last one   

do_locate       JSL ILOCATE         ; Set the cursor position
                BRA done
                .pend

;
; SCRSHIFTLL
; Shift all the characters on the current line left one cell, starting from the character to the right of the cursor
;
; Modifies: none
;
SCRSHIFTLL      PHX
                PHY
                PHA
                PHD
                PHP

                setdp 0

                setaxl
                LDA CURSORPOS       ; Get the current cursor position
                TAY                 ; Set it as the destination
                TAX
                INX                 ; And set the next cell as the source

                SEC                 ; Calculate the length of the block to move
                LDA COLS_VISIBLE    ; as columns visible - X
                SBC CURSORX

                MVN $AF, $AF        ; And move the block

                PLP
                PLD
                PLA
                PLY
                PLX
                RTL

;
; SCRSHIFTLR
;
; Shift all the characters on the current line right one cell, starting from the character to the right of the cursor
; The character under the cursor should be replaced with a space.
;
; Modifies: none
;
SCRSHIFTLR      PHX
                PHA
                PHD
                PHP

                setdp 0

                setaxl
                LDA CURSORPOS       ; Get the current cursor position
                AND #$FF80          ; Mask off the column bits
                ORA #$007F          ; And compute the address of the last cell
                TAY                 ; And set that as the destination address
                DEC A               ; Compute the address of the character to the left
                TAX                 ; And make it the source

                SEC                 ; Calculate the length of the block to move
                LDA COLS_VISIBLE    ; as columns visible - X
                SBC CURSORX

                MVP $AF, $AF        ; And move the block

                setas
                LDA #CHAR_SP        ; Put a blank space at the cursor position
                STA [CURSORPOS]

                PLP
                PLD
                PLA
                PLX
                RTL

;
;IPUTB
; Output a single byte to a channel.
; Does not handle terminal sequences.
; Modifies: none
;
IPUTB
                ;
                ; TODO: write to open channel
                ;
                RTL

;
; IPRINTCR
; Prints a carriage return.
; This moves the cursor to the beginning of the next line of text on the screen
; Modifies: Flags
;
IPRINTCR	      .proc
                PHX
                PHY
                PHP

                setas
                LDA @lCHAN_OUT
                BEQ scr_printcr

                CMP #CHAN_COM1      ; Check to see if it's the COM1 port
                BEQ uart_printcr    ; Yes: handle printing to the UART
                CMP #CHAN_COM2      ; Check to see if it's the COM2 port
                BEQ uart_printcr    ; Yes: handle printing to the UART

                ; TODO: handle other devices

                BRA done

uart_printcr    JSL UART_SELECT
                LDA #CHAR_CR
                JSL IPUTC
                LDA #CHAR_LF
                JSL IPUTC
                BRA done

scr_printcr     LDX #0
                LDY CURSORY
                INY
                JSL ILOCATE

done            PLP
                PLY
                PLX
                RTL
                .pend

;
; ICSRHOME
; Move the cursor to the "home" position in the upper-left corner
;
ICSRHOME        PHX
                PHY
                PHP

                LDX #0
                LDY #0
                JSL ILOCATE

                PLP
                PLY
                PLX
                RTL

;
; ICSRRIGHT
; Move the cursor right one space
; Modifies: none
;
ICSRRIGHT       PHX
                PHY
                PHA
                PHD
                PHP

                setal
                setxl
                setdp $0

                LDX CURSORX           ; Get the new column
                INX
                LDY CURSORY           ; Get the current row

                CPX COLS_VISIBLE      ; Are we off screen?
                BCC icsrright_nowrap  ; No: just set the position

                LDX #0                ; Yes: move to the first column
                INY                   ; And move to the next row
                CPY LINES_VISIBLE     ; Are we still off screen?
                BCC icsrright_nowrap  ; No: just set the position

                DEY                   ; Yes: lock to the last row
                JSL ISCROLLUP         ; But scroll the screen up

icsrright_nowrap
                JSL ILOCATE           ; Set the cursor position       

                PLP
                PLD
                PLA
                PLY
                PLX
                RTL

;
; ICSRLEFT
; Move the cursor left one space
; Modifies: none
;
ICSRLEFT
                PHX
                PHY
                PHA
                PHD
                PHP

                setaxl
                setdp $0
                LDA CURSORX
                BEQ icsrleft_done_already_zero ; Check that we are not already @ Zero

                LDX CURSORX
                DEX
                STX CURSORX
                LDY CURSORY
                JSL ILOCATE

icsrleft_done_already_zero
                PLP
                PLD
                PLA
                PLY
                PLX
                RTL

;ICSRUP
;Move the cursor up one space
; This routine doesn't wrap the cursor when it reaches the top, it just stays at the top
; Modifies: none
;
ICSRUP
                PHX
                PHY
                PHA
                PHD
                PHP

                setaxl
                setdp $0

                LDA CURSORY
                BEQ isrup_done_already_zero ; Check if we are not already @ Zero
                LDY CURSORY
                DEY
                STY CURSORY
                LDX CURSORX
                JSL ILOCATE

isrup_done_already_zero
                PLP
                PLD
                PLA
                PLY
                PLX
                RTL

;
; ICSRDOWN
; Move the cursor down one space
; When it reaches the bottom. Every time it go over the limit, the screen is scrolled up. (Text + Color)
; It will replicate the Color of the last line before it is scrolled up.
; Modifies: none
;
ICSRDOWN        PHX
                PHY
                PHD

                setaxl
                setdp $0

                LDX CURSORX                 ; Get the current column
                LDY CURSORY                 ; Get the new row
                INY
                CPY LINES_VISIBLE           ; Check to see if we're off screen
                BCC icsrdown_noscroll       ; No: go ahead and set the position

                DEY                         ; Yes: go back to the last row
                JSL ISCROLLUP               ; But scroll the screen up

icsrdown_noscroll
                JSL ILOCATE                 ; And set the cursor position

                PLD
                PLY
                PLX
                RTL

;ILOCATE
;Sets the cursor X and Y positions to the X and Y registers
;Direct Page must be set to 0
;Input:
; X: column to set cursor
; Y: row to set cursor
;Modifies: none
ILOCATE         PHA
                PHD
                PHP

                setdp 0
                setaxl

ilocate_scroll  ; If the cursor is below the bottom row of the screen
                ; scroll the screen up one line. Keep doing this until
                ; the cursor is visible.
                CPY LINES_VISIBLE
                BCC ilocate_scrolldone
                JSL ISCROLLUP
                DEY
                ; repeat until the cursor is visible again
                BRA ilocate_scroll

ilocate_scrolldone
                ; done scrolling store the resultant cursor positions.
                STX CURSORX
                STY CURSORY
                LDA SCREENBEGIN

ilocate_row     ; compute the row
                CPY #$0
                BEQ ilocate_right

                ; move down the number of rows in Y
ilocate_down    CLC
                ADC COLS_PER_LINE
                DEY
                BEQ ilocate_right
                BRA ilocate_down

                ; compute the column
ilocate_right   CLC
                ADC CURSORX             ; move the cursor right X columns
                STA CURSORPOS
                LDY CURSORY
                TYA
                STA @lVKY_TXT_CURSOR_Y_REG_L  ;Store in Vicky's registers
                TXA
                STA @lVKY_TXT_CURSOR_X_REG_L  ;Store in Vicky's register

                setal
                CLC
                LDA CURSORPOS
                ADC #<>(CS_COLOR_MEM_PTR - CS_TEXT_MEM_PTR)
                STA COLORPOS

ilocate_done    PLP
                PLD
                PLA
                RTL
;
; ISCROLLUP
; Scroll the screen up one line
; Inputs:
;   None
; Affects:
;   None
ISCROLLUP       ; Scroll the screen up by one row
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
                LDA COLS_PER_LINE
                STA @lM0_OPERAND_A
                LDA LINES_VISIBLE
                STA @lM0_OPERAND_B
                LDA @lM0_RESULT
                STA TMPPTR1

                ; Scroll Text Up
                CLC
                LDA #$A000
                TAY
                ADC COLS_PER_LINE
                TAX
                LDA TMPPTR1
                ; Move the data
                MVN $AF,$AF

                ; Scroll Color Up
                setaxl
                CLC
                LDA #$C000
                TAY
                ADC COLS_PER_LINE
                TAX
                ; for now, should be 8064 or $1f80 bytes
                LDA TMPPTR1
                ; Move the data
                MVN $AF,$AF

                ; Clear the last line of text on the screen
                LDA TMPPTR1
                PHA

                CLC
                ADC #<>CS_TEXT_MEM_PTR
                STA TMPPTR1

                LDY #0
                LDA #' '
clr_text        STA [TMPPTR1],Y
                INY
                CPY COLS_VISIBLE
                BNE clr_text

                ; Set the last line of color on the screen to the current color
                PLA

                CLC
                ADC #<>CS_COLOR_MEM_PTR
                STA TMPPTR1

                LDY #0
                LDA CURCOLOR
clr_color       STA [TMPPTR1],Y
                INY
                CPY COLS_VISIBLE
                BNE clr_color

                PLP
                PLD
                PLB
                PLY
                PLX
                PLA
                RTL


;
; IPRINTH
; Prints data from memory in hexadecimal format
; Inputs:
;   X: 16-bit address of the LAST BYTE of data to print.
;   Y: Length in bytes of data to print
; Modifies:
;   X,Y, results undefined
IPRINTH         PHP
                PHA
iprinth1        setas
                LDA #0,b,x      ; Read the value to be printed
                LSR
                LSR
                LSR
                LSR
                JSL iprint_digit
                LDA #0,b,x
                JSL iprint_digit
                DEX
                DEY
                BNE iprinth1
                PLA
                PLP
                RTL
              
;
; IPRINTAH
; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
;
; Inputs:
;   A: 8 or 16 bit value to print
;
IPRINTAH        .proc
                PHA
                PHP
                STA @lCPUA            ; Save A where we can use it multiple times

                PHP                   ; Get the processor status into A
                setas
                setxl
                PLA
                AND #%00100000        ; Is M = 1?
                CMP #%00100000
                BEQ eight_bit

                LDA @lCPUA+2          ; Get nibble [15..12]
                .rept 4
                LSR A
                .next
                JSL iprint_digit      ; And print it
                LDA @lCPUA+2          ; Get nibble [11..8]
                JSL iprint_digit      ; And print it

eight_bit       LDA @lCPUA            ; Get nibble [7..4]
                .rept 4
                LSR A
                .next
                JSL iprint_digit      ; And print it
                LDA @lCPUA            ; Get nibble [3..0]
                JSL iprint_digit      ; And print it

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
iprint_digit    PHX
                setal
                AND #$0F
                TAX
                ; Use the value in AL to
                .databank ?
                LDA hex_digits,X
                JSL IPUTC       ; Print the digit
                PLX
                RTL
;
; ICLRSCREEN
; Clear the screen and set the background and foreground colors to the
; currently selected colors.
ICLRSCREEN	    PHA
                PHX
                PHP

                setas
                setxl 			            ; Set 16bits

                LDX #$0000		          ; Only Use One Pointer
                LDA #$20		            ; Fill the Entire Screen with Space
iclearloop0	    STA CS_TEXT_MEM_PTR, x	;
                inx
                cpx #$2000
                bne iclearloop0

                ; Now Set the Colors so we can see the text
                LDX	#$0000		          ; Only Use One Pointer
                LDA @lCURCOLOR          ; Fill the Color Memory with the current color
iclearloop1	    STA CS_COLOR_MEM_PTR, x	;
                inx
                cpx #$2000
                bne iclearloop1

                PLP
                PLX
                PLA
                RTL

;
; Copy 42 Bytes
;
; Inputs:
;   TMPPTR1 = pointer to the source
;   TMPPTR2 = pointer to the destination
;
COPYBYTES42     .proc
                PHP
                PHD

                setdp TMPPTR1

                setas
                setxl
                LDY #0
copy_loop       LDA [TMPPTR1],Y
                STA [TMPPTR2],Y
                INY
                CPY #42
                BNE copy_loop

                PLD
                PLP
                RTS
                .pend

;
; ICOLORFLAG
; Set the colors of the flag on the welcome screen
;
ICOLORFLAG      .proc
                PHA
                PHX
                PHY
                PHP
                PHB
                PHD

                setdp 0

                setaxl
                LDA #<>CS_COLOR_MEM_PTR
                STA TMPPTR2
                LDA #`CS_COLOR_MEM_PTR
                STA TMPPTR2+2

                LDA #<>greet_clr_line1
                STA TMPPTR1
                LDA #`greet_clr_line1
                STA TMPPTR1+2

                JSR COPYBYTES42

                CLC
                LDA TMPPTR2
                ADC COLS_PER_LINE
                STA TMPPTR2

                LDA #<>greet_clr_line2
                STA TMPPTR1
                LDA #`greet_clr_line2
                STA TMPPTR1+2

                JSR COPYBYTES42

                CLC
                LDA TMPPTR2
                ADC COLS_PER_LINE
                STA TMPPTR2

                LDA #<>greet_clr_line3
                STA TMPPTR1
                LDA #`greet_clr_line3
                STA TMPPTR1+2

                JSR COPYBYTES42

                CLC
                LDA TMPPTR2
                ADC COLS_PER_LINE
                STA TMPPTR2

                LDA #<>greet_clr_line4
                STA TMPPTR1
                LDA #`greet_clr_line4
                STA TMPPTR1+2

                JSR COPYBYTES42

                CLC
                LDA TMPPTR2
                ADC COLS_PER_LINE
                STA TMPPTR2

                LDA #<>greet_clr_line5
                STA TMPPTR1
                LDA #`greet_clr_line5
                STA TMPPTR1+2

                JSR COPYBYTES42

                PLD
                PLB
                PLP
                PLY
                PLX
                PLA
                RTL
                .pend
;
; IINITCHLUT
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize VICKY's Character Color Look-Up Table;
; Inputs:
;   None
; Affects:
;   None
IINITCHLUT		  PHD
                PHP
                PHA
                PHX
                setas
                setxs 					; Set 8bits
				        ; Setup Foreground LUT First
				        LDX	#$00
lutinitloop0	  LDA @lfg_color_lut,x		; get Local Data
                STA FG_CHAR_LUT_PTR,x	; Write in LUT Memory
                inx
                cpx #$40
                bne lutinitloop0
                ; Set Background LUT Second
                LDX	#$00
lutinitloop1	  LDA @lbg_color_lut,x		; get Local Data
                STA BG_CHAR_LUT_PTR,x	; Write in LUT Memory
                INX
                CPX #$40
                bne lutinitloop1

                setal
                setxl 					; Set 8bits
                PLX
                PLA
                PLP
                PLD
                RTL

; IINITGAMMATABLE
; Author: Stefany
; Init the GAMMA Table for each R, G, B Channels
; Dec 15th, 2018 - Just Load the Gamma Table with linear Value.
; Inputs:
;   None
; Affects:
;  VICKY GAMMA TABLES
IINITGAMMATABLE setas 		; Set 8bits
                setxl     ; Set Accumulator to 8bits
                ldx #$0000
initgammaloop   LDA GAMMA_1_8_Tbl, x
                STA GAMMA_B_LUT_PTR, x
                STA GAMMA_G_LUT_PTR, x
                STA GAMMA_R_LUT_PTR, x
                inx
                cpx #$0100
                bne initgammaloop
                setaxl        ; Set Acc back to 16bits before setting the Cursor Position
                RTL

; IINITALLLUT
; Author: Stefany
;Init the Different Look-Up Table for the Graphic Mode
; The LUT are loaded with Equal Values, so the End Results will be Gray Shades
; Inputs:
;   None
; Affects:
;  VICKY INTERNAL LOOK-UP TAbles
IINITALLLUT     PHA
                PHX
                LDX #$0000
                setas
                LDA #$00
                STA $0A     ; Temp Location
iinit_lut_loop  ;
                ; Red Channel
                STX $02
                LDX $0A
                LDA GAMMA_2_2_Tbl, x
                EOR  #$55
                LDX $02
                STA @lGRPH_LUT0_PTR, x
                STA @lGRPH_LUT1_PTR, x
                STA @lGRPH_LUT2_PTR, x
                STA @lGRPH_LUT3_PTR, x
                STA @lGRPH_LUT4_PTR, x
                STA @lGRPH_LUT5_PTR, x
                STA @lGRPH_LUT6_PTR, x
                STA @lGRPH_LUT7_PTR, x
                inx
                ; Green Channel  RANDOM_LUT_Tbl
                STX $02
                LDX $0A
                LDA RANDOM_LUT_Tbl, x
                LDX $02
                STA @lGRPH_LUT0_PTR, x
                STA @lGRPH_LUT1_PTR, x
                STA @lGRPH_LUT2_PTR, x
                STA @lGRPH_LUT3_PTR, x
                STA @lGRPH_LUT4_PTR, x
                STA @lGRPH_LUT5_PTR, x
                STA @lGRPH_LUT6_PTR, x
                STA @lGRPH_LUT7_PTR, x
                inx
                STX $02
                LDX $0A
                LDA GAMMA_1_8_Tbl, x
                EOR  #$AA
                LDX $02
                STA @lGRPH_LUT0_PTR, x
                STA @lGRPH_LUT1_PTR, x
                STA @lGRPH_LUT2_PTR, x
                STA @lGRPH_LUT3_PTR, x
                STA @lGRPH_LUT4_PTR, x
                STA @lGRPH_LUT5_PTR, x
                STA @lGRPH_LUT6_PTR, x
                STA @lGRPH_LUT7_PTR, x
                inx
                ; Alpha Channel
                LDA #$FF
                STA @lGRPH_LUT0_PTR, x
                STA @lGRPH_LUT1_PTR, x
                STA @lGRPH_LUT2_PTR, x
                STA @lGRPH_LUT3_PTR, x
                STA @lGRPH_LUT4_PTR, x
                STA @lGRPH_LUT5_PTR, x
                STA @lGRPH_LUT6_PTR, x
                STA @lGRPH_LUT7_PTR, x
                inc $0A
                inx
                cpx #$0400
                beq iinit_lut_exit
                brl iinit_lut_loop
iinit_lut_exit
                setaxl        ; Set Acc back to 16bits before setting the Cursor Position
                PLX
                PLA
                RTL

; IINITVKYTXTMODE
; Author: Stefany
;Init the Text Mode
; Inputs:
;   None
; Affects:
;  Vicky's Internal Registers
IINITVKYTXTMODE PHA
                PHP

                setas
                LDA #Mstr_Ctrl_Text_Mode_En       ; Okay, this Enables the Text Mode (Video Display)
                STA MASTER_CTRL_REG_L

                LDA #0                            ; 640x480 mode (80 columns max)
                STA @lMASTER_CTRL_REG_H


                ; Set the Border Color
                LDA #$20
                STA BORDER_COLOR_B
                STA BORDER_COLOR_R
                LDA #$00
                STA BORDER_COLOR_G

                LDA #Border_Ctrl_Enable           ; Enable the Border
                STA BORDER_CTRL_REG

                LDA #32                           ; Set the border to the standard 32 pixels
                STA BORDER_X_SIZE
                STA BORDER_Y_SIZE

                setaxl                            ; Set Acc back to 16bits before setting the Cursor Position

                JSL ISETSIZES                     ; Calculate the size of the text screen

                PLP
                PLA
                RTL

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
ISETSIZES       .proc
                PHA
                PHX
                PHY
                PHB
                PHD
                PHP

                setdp <>BANK0_BEGIN
                setdbr 0

                setaxs
                LDA @l MASTER_CTRL_REG_H
                AND #$03                    ; Mask off the resolution bits
                ASL A
                TAX                         ; Index to the col/line count in X

                setal
                LDA cols_by_res,X           ; Get the number of columns
                STA COLS_PER_LINE           ; This is how many columns there are per line in the memory
                STA COLS_VISIBLE            ; This is how many would be visible with no border

                LDA lines_by_res,X          ; Get the number of lines
                STA LINES_MAX               ; This is the total number of lines in memory
                STA LINES_VISIBLE           ; This is how many lines would be visible with no border

                setas
                LDA @l BORDER_CTRL_REG      ; Check to see if we have a border
                BIT #Border_Ctrl_Enable
                BEQ done                    ; No border... the sizes are correct now

                ; There is a border...adjust the column count down based on the border size
                LDA @l BORDER_X_SIZE        ; Get the horizontal border width
                AND #$3F
                BIT #$03                    ; Check the lower two bits... indicates a partial column is eaten
                BNE frac_width

                LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4
                LSR A
                BRA store_width

frac_width      LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4 + 1
                LSR A                       ; because a column is partially hidden
                INC A

store_width     STA TMPPTR1
                STZ TMPPTR1+1

                setas
                LDA @l MASTER_CTRL_REG_H    ; Check if we're pixel doubling
                BIT #Mstt_Ctrl_Video_Mode1
                BEQ adjust_width            ; No... just adjust the width of the screen

                setal
                LSR TMPPTR1                 ; Yes... cut the adjustment in half

adjust_width    setal
                SEC
                LDA COLS_PER_LINE
                SBC TMPPTR1
                STA COLS_VISIBLE

                LDA @l BORDER_Y_SIZE        ; Get the horizontal border width
                AND #$3F
                BIT #$03                    ; Check the lower two bits... indicates a partial column is eaten
                BNE frac_height

                LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4
                LSR A
                BRA store_height

frac_height     LSR A                       ; COLUMNS_HIDDEN := BORDER_X_SIZE / 4 + 1
                LSR A                       ; because a column is partially hidden
                INC A

store_height    STA TMPPTR1
                STZ TMPPTR1+1

                setas
                LDA @l MASTER_CTRL_REG_H    ; Check if we're pixel doubling
                BIT #Mstt_Ctrl_Video_Mode1
                BEQ adjust_height           ; No... just adjust the height of the screen

                setal
                LSR TMPPTR1                 ; Yes... cut the adjustment in half

adjust_height   setal
                SEC
                LDA LINES_MAX
                SBC TMPPTR1
                STA LINES_VISIBLE

                setaxl

done            PLP
                PLD
                PLB
                PLY
                PLX
                PLA
                RTL
cols_by_res     .word 80,100,40,50
lines_by_res    .word 60,75,30,37
                .pend

; IINITVKYTXTMODE
; Author: Stefany
;Init the Text Mode
; Inputs:
;   None
; Affects:
;  Vicky's Internal Registers
IINITVKYGRPMODE
                PHA
                setas
                LDA #$00          ; Enable Bit-Map and uses LUT0
                STA @lBM_CONTROL_REG
                ; Set the BitMap Start Address to $00C0000 ($B0C000)
                LDA #$00          ;; (L)Load Base Address of where Bitmap begins
                STA @lBM_START_ADDY_L
                LDA #$C0
                STA @lBM_START_ADDY_M
                LDA #$00
                STA @lBM_START_ADDY_H ; This address is always base from
                                      ; of starting of FRAME Buffer $B00000
                LDA #$80
                STA BM_X_SIZE_L
                LDA #$02
                STA BM_X_SIZE_H         ; $0280 = 640
                LDA #$E0
                STA BM_Y_SIZE_L
                LDA #$01
                STA BM_Y_SIZE_H         ; $01E0 = 480
                setaxl        ; Set Acc back to 16bits before setting the Cursor Position
                PLA
                RTL

IINITTILEMODE

                RTL

IINITSPRITE     PHA
                setas
                LDA #$03    ; Enable 17 Sprites
                STA SP00_CONTROL_REG
                STA SP01_CONTROL_REG
                STA SP02_CONTROL_REG
                STA SP03_CONTROL_REG
                STA SP04_CONTROL_REG
                STA SP05_CONTROL_REG
                STA SP06_CONTROL_REG
                STA SP07_CONTROL_REG
                STA SP08_CONTROL_REG
                STA SP09_CONTROL_REG
                STA SP10_CONTROL_REG
                STA SP11_CONTROL_REG
                STA SP12_CONTROL_REG
                STA SP13_CONTROL_REG
                STA SP14_CONTROL_REG
                STA SP15_CONTROL_REG
                STA SP16_CONTROL_REG
                ; Set the Pointer for the Graphic
                LDA #$09
                STA SP00_ADDY_PTR_H
                STA SP01_ADDY_PTR_H
                STA SP02_ADDY_PTR_H
                STA SP03_ADDY_PTR_H
                STA SP04_ADDY_PTR_H
                STA SP05_ADDY_PTR_H
                STA SP06_ADDY_PTR_H
                STA SP07_ADDY_PTR_H
                STA SP08_ADDY_PTR_H
                STA SP09_ADDY_PTR_H
                STA SP10_ADDY_PTR_H
                STA SP11_ADDY_PTR_H
                STA SP12_ADDY_PTR_H
                STA SP13_ADDY_PTR_H
                STA SP14_ADDY_PTR_H
                STA SP15_ADDY_PTR_H
                STA SP16_ADDY_PTR_H

                LDA #$00
                STA SP00_ADDY_PTR_M
                LDA #$04
                STA SP01_ADDY_PTR_M
                LDA #$08
                STA SP02_ADDY_PTR_M
                LDA #$0C
                STA SP03_ADDY_PTR_M
                LDA #$10
                STA SP04_ADDY_PTR_M
                LDA #$14
                STA SP05_ADDY_PTR_M
                LDA #$18
                STA SP06_ADDY_PTR_M
                LDA #$1C
                STA SP07_ADDY_PTR_M
                LDA #$20
                STA SP08_ADDY_PTR_M
                LDA #$24
                STA SP09_ADDY_PTR_M
                LDA #$28
                STA SP10_ADDY_PTR_M
                LDA #$2C
                STA SP11_ADDY_PTR_M
                LDA #$30
                STA SP12_ADDY_PTR_M
                LDA #$34
                STA SP13_ADDY_PTR_M
                LDA #$38
                STA SP14_ADDY_PTR_M
                LDA #$3C
                STA SP15_ADDY_PTR_M
                LDA #$40
                STA SP16_ADDY_PTR_M

                LDA #$00
                STA SP00_ADDY_PTR_L
                STA SP01_ADDY_PTR_L
                STA SP02_ADDY_PTR_L
                STA SP03_ADDY_PTR_L
                STA SP04_ADDY_PTR_L
                STA SP05_ADDY_PTR_L
                STA SP06_ADDY_PTR_L
                STA SP07_ADDY_PTR_L
                STA SP08_ADDY_PTR_L
                STA SP09_ADDY_PTR_L
                STA SP10_ADDY_PTR_L
                STA SP11_ADDY_PTR_L
                STA SP12_ADDY_PTR_L
                STA SP13_ADDY_PTR_L
                STA SP14_ADDY_PTR_L
                STA SP15_ADDY_PTR_L
                STA SP16_ADDY_PTR_L
                PLA
                RTL


; IINITFONTSET
; Author: Stefany
; Init the Text Mode
; Inputs:
;   None
; Affects:
;  Vicky's Internal FONT Memory
IINITFONTSET
                setas
                setxl
                LDX #$0000
initFontsetbranch0
                LDA @lFONT_4_BANK0,X    ; RAM Content
                STA @lFONT_MEMORY_BANK0,X ; Vicky FONT RAM Bank
                INX
                CPX #$0800
                BNE initFontsetbranch0
                NOP
                LDX #$0000
initFontsetbranch1
                LDA @lFONT_4_BANK1,X
                STA @lFONT_MEMORY_BANK1,X ; Vicky FONT RAM Bank
                INX
                CPX #$0800
                BNE initFontsetbranch1
                NOP
                setaxl
                RTL

;
;
;INITMOUSEPOINTER
INITMOUSEPOINTER
                setas
                setxl
                LDX #$0000
FILL_MOUSE_MARKER
                LDA @lMOUSE_POINTER_PTR,X
                STA @lMOUSE_PTR_GRAP0_START, X
                INX
                CPX #$0100
                BNE FILL_MOUSE_MARKER
                nop

                LDA #$01
                STA @lMOUSE_PTR_CTRL_REG_L  ; Enable Mouse, Mouse Pointer Graphic Bank 0
                setaxl
                RTL




;
; IINITCURSOR
; Author: Stefany
; Init the Cursor Registers
; Verify that the Math Block Works
; Inputs:
; None
; Affects:
;  Vicky's Internal Cursor's Registers
IINITCURSOR     PHA
                setas
                LDA #$B1      ;The Cursor Character will be a Fully Filled Block
                STA VKY_TXT_CURSOR_CHAR_REG
                LDA #$03      ;Set Cursor Enable And Flash Rate @1Hz
                STA VKY_TXT_CURSOR_CTRL_REG ;
                setaxl        ; Set Acc back to 16bits before setting the Cursor Position
                LDA #$0000;
                STA VKY_TXT_CURSOR_X_REG_L; // Set the X to Position 1
                LDA #$0006;
                STA VKY_TXT_CURSOR_Y_REG_L; // Set the Y to Position 6 (Below)
                PLA
                RTL

;
; IINITSUPERIO
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize SuperIO PME Registers
; Inputs:
;   None
; Affects:
;   None
IINITSUPERIO	  PHD
                PHP
                PHA
                setas			;just make sure we are in 8bit mode

                LDA #$01		;Default Value - C256 Doesn't use this IO Pin
                STA GP10_REG
                LDA GP10_REG
                LDA #$01		;Default Value - C256 Doesn't use this IO Pin
                STA GP11_REG
                LDA #$01		;Default Value - C256 Doesn't use this IO Pin
                STA GP12_REG
        				LDA #$01		;Default Value - C256 Doesn't use this IO Pin
        				STA GP13_REG
        				LDA #$05		;(C256 - POT A Analog BX) Bit[0] = 1, Bit[2] = 1
        				STA GP14_REG
        				LDA #$05		;(C256 - POT A Analog BY) Bit[0] = 1, Bit[2] = 1
        				STA GP15_REG
        				LDA #$05		;(C256 - POT B Analog BX) Bit[0] = 1, Bit[2] = 1
        				STA GP16_REG
        				LDA #$05		;(C256 - POT B Analog BY) Bit[0] = 1, Bit[2] = 1
        				STA GP17_REG
        				LDA #$00		;(C256 - HEADPHONE MUTE) - Output GPIO - Push-Pull (1 - Headphone On, 0 - HeadPhone Off)
        				STA GP20_REG

                ;LDA #$00		;(C256 - FLOPPY - DS1) - TBD Later, Floppy Stuff (JIM DREW)
				        ;STA GP21_REG
				        ;LDA #$00		;(C256 - FLOPPY - DMTR1) - TBD Later, Floppy Stuff (JIM DREW)
				        ;STA GP22_REG

				        LDA #$01		;Default Value - C256 Doesn't use this IO Pin
				        STA GP24_REG
				        LDA #$05		;(C256 - MIDI IN) Bit[0] = 1, Bit[2] = 1 (Page 132 Manual)
				        STA GP25_REG
			        	LDA #$84		;(C256 - MIDI OUT) Bit[2] = 1, Bit[7] = 1 (Open Drain - To be Checked)
				        STA GP26_REG

				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 1) Setup as GPIO Input for now
				        STA GP30_REG
				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 4) Setup as GPIO Input for now
				        STA GP31_REG
				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 3) Setup as GPIO Input for now
				        STA GP32_REG
				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 6) Setup as GPIO Input for now
				        STA GP33_REG
				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 5) Setup as GPIO Input for now
				        STA GP34_REG
				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 8) Setup as GPIO Input for now
				        STA GP35_REG
				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 7) Setup as GPIO Input for now
				        STA GP36_REG
				        LDA #$01		;Default Value - (C256 - JP1 Fanout Pin 10) Setup as GPIO Input for now
				        STA GP37_REG

				        ;LDA #$01		;(C256 - FLOPPY - DRVDEN0) - TBD Later, Floppy Stuff (JIM DREW)
				        ;STA GP40_REG
				        ;LDA #$01		;(C256 - FLOPPY - DRVDEN1) - TBD Later, Floppy Stuff (JIM DREW)
				        ;STA GP41_REG
				        LDA #$01		;Default Value - C256 Doesn't use this IO Pin
				        STA GP42_REG
			          LDA #$01		;(C256 - INPUT PLL CLK INTERRUPT) Default Value - Will keep it as an input for now, no real usage for now
				        STA GP43_REG
				        LDA #$05		;(C256 - UART2 - RI2) - Input - Set Secondary Function
				        STA GP50_REG
				        LDA #$05		;(C256 - UART2 - DCD2) - Input - Set Secondary Function
				        STA GP51_REG
				        LDA #$05		;(C256 - UART2 - RXD2) - Input - Set Secondary Function
				        STA GP52_REG
				        LDA #$04		;(C256 - UART2 - TXD2) - Output - Set Secondary Function
				        STA GP53_REG
				        LDA #$05		;(C256 - UART2 - DSR2) - Input - Set Secondary Function
				        STA GP54_REG
				        LDA #$04		;(C256 - UART2 - RTS2) - Output - Set Secondary Function
				        STA GP55_REG
				        LDA #$05		;(C256 - UART2 - CTS2) - Input - Set Secondary Function
				        STA GP56_REG
				        LDA #$04		;(C256 - UART2 - DTR2) - Output - Set Secondary Function
				        STA GP57_REG
				        LDA #$84		;(C256 - LED1) - Open Drain - Output
				        STA GP60_REG
				        LDA #$84		;(C256 - LED2) - Open Drain - Output
				        STA GP61_REG
			        	LDA #$00		;GPIO Data Register (GP10..GP17) - Not Used
				        STA GP1_REG
				        LDA #$01		;GPIO Data Register (GP20..GP27) - Bit[0] - Headphone Mute (Enabling it)
				        STA GP2_REG
				        LDA #$00		;GPIO Data Register (GP30..GP37) - Since it is in Output mode, nothing to write here.
				        STA GP3_REG
				        LDA #$00		;GPIO Data Register (GP40..GP47)  - Not Used
				        STA GP4_REG
				        LDA #$00		;GPIO Data Register (GP50..GP57)  - Not Used
				        STA GP5_REG
				        LDA #$00		;GPIO Data Register (GP60..GP61)  - Not Used
				        STA GP6_REG

				        LDA #$01		;LED1 Output - Already setup by Vicky Init Phase, for now, I will leave it alone
				        STA LED1_REG
				        LDA #$02		;LED2 Output - However, I will setup this one, to make sure the Code works (Full On, when Code was ran)
				        STA LED2_REG
				        setal
                PLA
				        PLP
			        	PLD
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
IINITKEYBOARD	  PHD
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

passAAtest      ;LDX #<>pass_tst0xAAmsg
                ;JSL IPRINT      ; print Message
;; Test AB
				        LDA #$AB			;Send test Interface command
				        STA KBD_CMD_BUF

                JSR Poll_Outbuf ;

				        LDA KBD_OUT_BUF		;Display Interface test results
				        CMP #$00			;Should be 00
				        BEQ	passABtest

                BRL initkb_loop_out

passABtest      ;LDX #<>pass_tst0xABmsg
;                JSL IPRINT       ; print Message

                ;LDA #$A8        ; Enable Second PS2 Port
                ;STA KBD_DATA_BUF
                ;JSR Poll_Outbuf ;

;; Program the Keyboard & Enable Interrupt with Cmd 0x60
                LDA #$60            ; Send Command 0x60 so to Enable Interrupt
                STA KBD_CMD_BUF
                JSR Poll_Inbuf ;
                LDA #%01101001      ; Enable Interrupt
                ;LDA #%01001011      ; Enable Interrupt for Mouse and Keyboard
                STA KBD_DATA_BUF
                JSR Poll_Inbuf ;
                ;LDX #<>pass_cmd0x60msg
                ;JSL IPRINT       ; print Message
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

;                LDX #<>pass_cmd0xFFmsg
;                JSL IPRINT       ; print Message
DO_CMD_F4_AGAIN
                JSR Poll_Inbuf ;
				        LDA #$F4			; Enable the Keyboard
				        STA KBD_DATA_BUF
                JSR Poll_Outbuf ;

				        LDA KBD_OUT_BUF		; Clear the Output buffer
                CMP #$FA
                BNE DO_CMD_F4_AGAIN
                ; Till We Reach this point, the Keyboard is setup Properly
                JSR INIT_MOUSE

                ; Unmask the Keyboard interrupt
                ; Clear Any Pending Interrupt
                LDA @lINT_PENDING_REG0  ; Read the Pending Register &
                AND #FNX0_INT07_MOUSE
                STA @lINT_PENDING_REG0  ; Writing it back will clear the Active Bit

                LDA @lINT_PENDING_REG1  ; Read the Pending Register &
                AND #FNX1_INT00_KBD
                STA @lINT_PENDING_REG1  ; Writing it back will clear the Active Bit
                ; Disable the Mask
                LDA @lINT_MASK_REG1
                AND #~FNX1_INT00_KBD
                STA @lINT_MASK_REG1

                LDA @lINT_MASK_REG0
                AND #~FNX0_INT07_MOUSE
                STA @lINT_MASK_REG0


                LDX #<>Success_kb_init
                SEC
                BCS InitSuccess

initkb_loop_out LDX #<>Failed_kb_init
InitSuccess     JSL IPRINT       ; print Message
                setal 					; Set 16bits
                setxl 					; Set 16bits

                PLX
                PLA
				        PLP
				        PLD
                RTL

Poll_Inbuf	    .as
                LDA STATUS_PORT		; Load Status Byte
				        AND	#<INPT_BUF_FULL	; Test bit $02 (if 0, Empty)
				        CMP #<INPT_BUF_FULL
				        BEQ Poll_Inbuf
                RTS

Poll_Outbuf	    .as
                LDA STATUS_PORT
                AND #OUT_BUF_FULL ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL
                BNE Poll_Outbuf
                RTS

INIT_MOUSE      .as

                JSR Poll_Inbuf
                LDA #$A8          ; Enable the second PS2 Channel
                STA KBD_CMD_BUF

;                LDX #$4000
;DLY_MOUSE_LOOP  DEX
                ;CPX #$0000
                ;BNE DLY_MOUSE_LOOP
DO_CMD_A9_AGAIN
                JSR Poll_Inbuf
                LDA #$A9          ; Tests second PS2 Channel
                STA KBD_CMD_BUF
                JSR Poll_Outbuf ;
				        LDA KBD_OUT_BUF		; Clear the Output buffer
                CMP #$00
                BNE DO_CMD_A9_AGAIN
                ; IF we pass this point, the Channel is OKAY, Let's move on

                JSR Poll_Inbuf
                LDA #$20
                STA KBD_CMD_BUF
                JSR Poll_Outbuf ;

                LDA KBD_OUT_BUF
                ORA #$02
                PHA
                JSR Poll_Inbuf
                LDA #$60
                STA KBD_CMD_BUF
                JSR Poll_Inbuf ;
                PLA
                STA KBD_DATA_BUF

                LDA #$F6        ;Tell the mouse to use default settings
                JSR MOUSE_WRITE
                JSR MOUSE_READ

                ; Set the Mouse Resolution 1 Clicks for 1mm - For a 640 x 480, it needs to be the slowest
                LDA #$E8
                JSR MOUSE_WRITE
                JSR MOUSE_READ
                LDA #$00
                JSR MOUSE_WRITE
                JSR MOUSE_READ

                ; Set the Refresh Rate to 60
;                LDA #$F2
;                JSR MOUSE_WRITE
;                JSR MOUSE_READ
;                LDA #60
;                JSR MOUSE_WRITE
;                JSR MOUSE_READ


                LDA #$F4        ; Enable the Mouse
                JSR MOUSE_WRITE
                JSR MOUSE_READ
                ; Let's Clear all the Variables Necessary to Computer the Absolute Position of the Mouse
                LDA #$00
                STA MOUSE_PTR
                RTS

MOUSE_WRITE     .as
                PHA
                JSR Poll_Inbuf
                LDA #$D4
                STA KBD_CMD_BUF
                JSR Poll_Inbuf
                PLA
                STA KBD_DATA_BUF
                RTS

MOUSE_READ      .as
                JSR Poll_Outbuf ;
                LDA KBD_INPT_BUF
                RTS


; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize the Real Time Clock
; Inputs:
;   None
                ; Affects:
                ;   None

INITRTC         PHA
                setas				    ;just make sure we are in 8bit mode
                LDA @lRTC_CTRL
                BRK

                setal 					; Set 16bits
                PLA
                RTL
;
; ITESTSID
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize the Real Time Clock
; Inputs:
; None
ITESTSID
                ; Set the Volume to Max
                LDA #$0F
                STA SID0_MODE_VOL
                ; Left SID
                ; Voice
                LDA #$BE
                STA SID0_V1_ATCK_DECY
                LDA #$F8
                STA SID0_V1_SSTN_RLSE

                LDA #$11
                STA SID0_V1_FREQ_HI
                LDA #$25
                STA SID0_V1_FREQ_LO

                LDA #$11
                STA SID0_V1_CTRL


                LDA #$08
                STA SID0_V1_PW_HI   ;G1
                LDA #$00
                STA SID0_V1_FREQ_HI

                LDA #$C6
                STA SID0_V1_SSTN_RLSE

                LDA #$08
                STA SID0_V2_PW_HI   ;G1
                LDA #$00
                STA SID0_V2_FREQ_HI
                LDA #$08
                STA SID0_V2_ATCK_DECY
                LDA #$C6
                STA SID0_V2_SSTN_RLSE

                LDA #$08
                STA SID0_V3_PW_HI   ;G1
                LDA #$00
                STA SID0_V3_FREQ_HI
                LDA #$08
                STA SID0_V3_ATCK_DECY
                LDA #$C6
                STA SID0_V3_SSTN_RLSE


                LDA #$36              ;Left Side (Rev A of Board)
                STA SID0_V1_FREQ_LO
                LDA #$01
                STA SID0_V1_FREQ_HI   ;G1
                LDA #$00              ;Left Side (Rev A of Board)
                STA SID0_V1_PW_LO
                LDA #$08
                STA SID0_V1_PW_HI   ;G1
                LDA #$08
                STA SID0_V1_CTRL    ; Reset
                ; Voice 2
                LDA #$0C
                STA SID0_V2_FREQ_LO
                LDA #$04
                STA SID0_V2_FREQ_HI   ;B1
                LDA #$00              ;Left Side (Rev A of Board)
                STA SID0_V2_PW_LO
                LDA #$08
                STA SID0_V2_PW_HI   ;G1
                LDA #$08
                STA SID0_V2_CTRL    ; Reset
                ; Voice 3
                LDA #$00
                STA SID0_V3_FREQ_LO
                LDA #$08
                STA SID0_V3_FREQ_HI   ;D
                LDA #$00              ;Left Side (Rev A of Board)
                STA SID0_V3_PW_LO
                LDA #$08
                STA SID0_V3_PW_HI   ;G1
                LDA #$08
                STA SID0_V3_CTRL    ; Reset

                ; Enable each Voices with Triangle Wave
                LDA #$10
                STA SID0_V1_CTRL    ; Triangle
                STA SID0_V2_CTRL    ; Triangle
                STA SID0_V3_CTRL    ; Triangle
                RTL
; IINITCODEC
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Verify that the Math Block Works
; Inputs:
; None
IINITCODEC      PHA
                setal
                LDA #%0001101000000000     ;R13 - Turn On Headphones
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED
                ;
                LDA #%0010101000001111       ;R21 - Enable All the Analog In
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED

                LDA #%0010001100000001      ;R17 - Enable All the Analog In
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED

                LDA #%0010110000000111      ;R22 - Enable all Analog Out
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED

                ; Adjust the DAC For 16bits @ 32Khz Sampling for the I2S Interface
                LDA #%0001010000000010      ;R10 - DAC Interface Control
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED
                ; Adjust the ADC For 16bits @ 32Khz Sampling for the I2S Interface
                LDA #%0001011000000010      ;R11 - ADC Interface Control
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED
                ; Master Control
                LDA #%0001100111010101      ;R12 - Master Mode Control
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED
                PLA
                RTL

IRESETCODEC     setal
                LDA #$2E00      ;R22 - Enable all Analog Out
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED
                RTL

CODEC_TRF_FINISHED
                setas
; This is about waiting for the Serial Transfer to CODEC to be finished
CODEC_LOOP      LDA CODEC_WR_CTRL
                AND #$01
                CMP #$01
                BEQ CODEC_LOOP
                setal
                RTS

; Clear Bitmap Screen
; This is Done with Software for Now, will be done by DMA later

IBM_FILL_SCREEN  setaxl
                LDA #$0000
                LDX #$0000
BM_FILL_SCREEN_LOOPY
                LDY #$0000
                setas
BM_FILL_SCREEN_LOOPX
                STA [BMP_PRSE_DST_PTR],Y    ; This is where the Pixel Go, Video Memory
                INY
                CPY BM_CLEAR_SCRN_X              ; Transfer the First line
                BNE BM_FILL_SCREEN_LOOPX
                JSR BM_FILL_COMPUTE_Y_DST
                INX
                CPX BM_CLEAR_SCRN_Y
                BNE BM_FILL_SCREEN_LOOPY
                setaxl
                RTL
; BMP_PRSE_SRC_PTR = BMP_PRSE_SRC_PTR + BMP_X_SIZE
BM_FILL_COMPUTE_Y_DST
                setal
                ; So just load the Actual Value so it can be substracted again from BMP_X_SIZE
                LDA BMP_PRSE_DST_PTR        ; Right now it is set @ $020000 (128K) + File Size
                STA @lADDER32_A_LL
                LDA BMP_PRSE_DST_PTR+2      ; Right now it is set @ $020000 (128K)
                STA @lADDER32_A_HL
                LDA #$280        ; Right now it is set @ $020000 (128K) + File Size
                STA @lADDER32_B_LL
                LDA #$0000
                STA @lADDER32_B_HL
                LDA @lADDER32_R_LL
                STA BMP_PRSE_DST_PTR
                LDA @lADDER32_R_HL
                STA BMP_PRSE_DST_PTR+2
                LDA #$0000
                RTS





;
; IBMP_PARSER  (indexed File Only)
; Go Parse and Update LUT and Transfer Data to Video Memory (Active Memory)
; Author: Stefany
;
; Verify that the Math Block Works
; Inputs:
; None
IBMP_PARSER     setaxl
                ; First Check the BMP Signature
                LDY #$0000
                LDA [BMP_PRSE_SRC_PTR],Y
                CMP #$4D42
                BEQ IBMP_PARSER_CONT
                BRL BMP_PARSER_END_WITH_ERROR
IBMP_PARSER_CONT
                LDY #$0002
                LDA [BMP_PRSE_SRC_PTR],Y    ; File Size Low Short
                STA @lADDER32_A_LL          ; Store in 32Bit Adder (A)
                ; File Size
                LDY #$0004
                LDA [BMP_PRSE_SRC_PTR],Y    ; File Size High Short
                STA @lADDER32_A_HL          ; Store in 32Bit Adder (A)
                LDA #$FFFF                  ; Store -1 in Adder (B)
                STA @lADDER32_B_LL
                STA @lADDER32_B_HL
                ; File Size - 1
                CLC
                LDA @lADDER32_R_LL
                STA BMP_FILE_SIZE
                LDA @lADDER32_R_HL
                STA BMP_FILE_SIZE+2
                ; If the signature is valid, Save the Size of the Image
                LDY #$0012
                LDA [BMP_PRSE_SRC_PTR],Y    ; The X SIze is 32bits in BMP, but 16bits will suffice
                STA BMP_X_SIZE
                ; Y Size
                LDY #$0016
                LDA [BMP_PRSE_SRC_PTR],Y    ; The X SIze is 32bits in BMP, but 16bits will suffice
                STA BMP_Y_SIZE
                ; Number of Indexed Color in the Image (number of colors in the LUT)
                LDY #$002E
                LDA [BMP_PRSE_SRC_PTR],Y    ; The X SIze is 32bits in BMP, but 16bits will suffice
                ;INC A; Add 1
                ASL A; Multiply by 2
                ASL A; Multiply by 2
                STA BMP_COLOR_PALET         ;
                CPX #$0000
                BNE BMP_LUT1_PICK
                JSR BMP_PARSER_UPDATE_LUT0   ; Go Upload the LUT0
                BRA DONE_TRANSFER_LUT;
  BMP_LUT1_PICK
                CPX #$0001
                BNE BMP_LUT2_PICK
                JSR BMP_PARSER_UPDATE_LUT1   ; Go Upload the LUT1
  BMP_LUT2_PICK
               ; Let's Compute the Pointer for the BITMAP (The Destination)
               ; Let's use the Internal Mutliplier to Find the Destination Address
               ; Let's Compute the Hight First
               ; Y x Stride + X
  DONE_TRANSFER_LUT
                LDA BMP_POSITION_Y
                STA @lM0_OPERAND_A
                LDA SCRN_X_STRIDE
                STA @lM0_OPERAND_B
                LDA @lM0_RESULT
                STA @lADDER32_A_LL          ; Store in 32Bit Adder (A)
                LDA @lM0_RESULT+2
                STA @lADDER32_A_HL          ; Store in 32Bit Adder (A)
                LDA BMP_POSITION_X
                STA @lADDER32_B_LL          ; Put the X Position Adder (B)
                LDA #$0000
                STA @lADDER32_B_HL
                LDA @lADDER32_R_LL          ; Put the Results in TEMP
                STA USER_TEMP
                LDA @lADDER32_R_HL          ; Put the Results in TEMP
                STA USER_TEMP+2
                ; Let's Add the X,Y Memory Point to the Actual Address where the bitmap begins
                LDA BMP_PRSE_DST_PTR
                STA @lADDER32_A_LL          ; Store in 32Bit Adder (A)
                LDA BMP_PRSE_DST_PTR+2
                STA @lADDER32_A_HL          ; Store in 32Bit Adder (A)
                LDA USER_TEMP
                STA @lADDER32_B_LL          ; Store in 32Bit Adder (B)
                LDA USER_TEMP+2
                STA @lADDER32_B_HL          ; Store in 32Bit Adder (B)
                ; Results of Requested Position (Y x Stride + X) + Start Address
                LDA @lADDER32_R_LL          ; Put the Results in BMP_PRSE_DST_PTR
                STA BMP_PRSE_DST_PTR
                LDA @lADDER32_R_HL          ; Put the Results in BMP_PRSE_DST_PTR
                STA BMP_PRSE_DST_PTR+2
                ; Let's Compute the Pointer for the FILE (The Source)
                ; My GOD I love this 32Bits ADDER ;o) Makes my life so simple...
                ; Imagine when we are going to need the 16Bit Multiplier, hum... it is going to be fun
                ; Load Absolute Location in Adder32 Bit Reg A
                LDA BMP_PRSE_SRC_PTR        ; Right now it is set @ $020000 (128K)
                STA @lADDER32_A_LL
                LDA BMP_PRSE_SRC_PTR+2        ; Right now it is set @ $020000 (128K)
                STA @lADDER32_A_HL
                ; Load File Size in Adder32bits Reg B
                LDA BMP_FILE_SIZE
                STA @lADDER32_B_LL
                LDA BMP_FILE_SIZE+2
                STA @lADDER32_B_HL
                ; Spit the Answer Back into the SRC Pointer (this should Point to last Pixel in memory)
                LDA @lADDER32_R_LL
                STA BMP_PRSE_SRC_PTR
                LDA @lADDER32_R_HL
                STA BMP_PRSE_SRC_PTR+2
                ; Now Take the Last Results and put it in Register A of ADDER32
                LDA BMP_PRSE_SRC_PTR        ; Right now it is set @ $020000 (128K) + File Size
                STA @lADDER32_A_LL
                LDA BMP_PRSE_SRC_PTR+2      ; Right now it is set @ $020000 (128K)
                STA @lADDER32_A_HL
                CLC
                LDA BMP_X_SIZE              ; Load The Size in X of the image and Make it negative
                EOR #$FFFF                  ; Inverse all bit
                ADC #$0001                  ; Add 0 ()
                STA @lADDER32_B_LL          ; Store the Results in reg B of ADDER32
                LDA #$FFFF
                STA @lADDER32_B_HL          ; Store in the Reminder of the 32Bits B Register
                                            ; We are now ready to go transfer the Image
                LDA @lADDER32_R_LL
                STA BMP_PRSE_SRC_PTR
                LDA @lADDER32_R_HL
                STA BMP_PRSE_SRC_PTR+2
                                            ; The Starting Pointer is in Results of the ADDER32
                ; Here The Pointer "BMP_PRSE_SRC_PTR" ought to point to the graphic itself (0,0)
                JSR BMP_PARSER_DMA_SHIT_OUT  ; We are going to start with the slow method
                LDX #<>bmp_parser_msg0
                BRA BMP_PARSER_END_NO_ERROR

BMP_PARSER_END_WITH_ERROR
                LDX #<>bmp_parser_err0

BMP_PARSER_END_NO_ERROR
                JSL IPRINT       ; print the first line
                RTL

; This transfer the Palette Directly
; Will have to be improved, so it can load the LUT Data in any specific LUT - TBC
BMP_PARSER_UPDATE_LUT0
                SEC
                   ; And this is offset to where the Color Palette Begins
                LDY #$007A
                LDX #$0000
                setas
BMP_PARSER_UPDATE_LOOP
                ; RED Pixel
                LDA [BMP_PRSE_SRC_PTR],Y    ; First Pixel is Red
                STA @lGRPH_LUT0_PTR+0, X      ; The look-up Table point to a pixel Blue
                INY
                ; Green Pixel
                LDA [BMP_PRSE_SRC_PTR],Y    ; Second Pixel is Green
                STA @lGRPH_LUT0_PTR+1, X      ; The look-up Table point to a pixel Blue
                INY
                ; Blue Pixel
                LDA [BMP_PRSE_SRC_PTR],Y    ; Third Pixel is Blue
                STA @lGRPH_LUT0_PTR+2, X      ; The look-up Table point to a pixel Blue
                INY
                LDA #$80
                STA @lGRPH_LUT0_PTR+3, X      ; The look-up Table point to a pixel Blue
                INY ; For the Alpha Value, nobody cares
                INX
                INX
                INX
                INX
                CPX BMP_COLOR_PALET         ; Apparently sometime there is less than 256 Values in the lookup
                BNE BMP_PARSER_UPDATE_LOOP
                setal
                RTS


;
; This transfer the Palette Directly
; Will have to be improved, so it can load the LUT Data in any specific LUT - TBC
BMP_PARSER_UPDATE_LUT1
                SEC
                   ; And this is offset to where the Color Palette Begins
                LDY #$0036
                LDX #$0000
                setas
PALETTE_LUT1_LOOP
                ; RED Pixel
                LDA [BMP_PRSE_SRC_PTR],Y    ; First Pixel is Red
                STA @lGRPH_LUT1_PTR+0, X      ; The look-up Table point to a pixel Blue
                INY
                ; Green Pixel
                LDA [BMP_PRSE_SRC_PTR],Y    ; Second Pixel is Green
                STA @lGRPH_LUT1_PTR+1, X      ; The look-up Table point to a pixel Blue
                INY
                ; Blue Pixel
                LDA [BMP_PRSE_SRC_PTR],Y    ; Third Pixel is Blue
                STA @lGRPH_LUT1_PTR+2, X      ; The look-up Table point to a pixel Blue
                INY
                LDA #$80
                STA @lGRPH_LUT1_PTR+3, X      ; The look-up Table point to a pixel Blue
                INY ; For the Alpha Value, nobody cares
                INX
                INX
                INX
                INX
                CPX BMP_COLOR_PALET         ; Apparently sometime there is less than 256 Values in the lookup
                BNE PALETTE_LUT1_LOOP
                setal
                RTS

; Let's do it the easy way first, then we will implement a DMA Controller
BMP_PARSER_DMA_SHIT_OUT
                LDX #$0000
BMP_PARSER_LOOPY
                LDY #$0000
                setas
BMP_PARSER_LOOPX
                LDA [BMP_PRSE_SRC_PTR],Y    ; Load First Pixel Y (will be linear)
                STA [BMP_PRSE_DST_PTR],Y    ; This is where the Pixel Go, Video Memory
                INY
                CPY BMP_X_SIZE              ; Transfer the First line
                BNE BMP_PARSER_LOOPX
                JSR BMP_PARSER_COMPUTE_Y_SRC
                JSR BMP_PARSER_COMPUTE_Y_DST
                INX
                CPX BMP_Y_SIZE
                BNE BMP_PARSER_LOOPY
                RTS
; BMP_PRSE_SRC_PTR = BMP_PRSE_SRC_PTR + BMP_X_SIZE
BMP_PARSER_COMPUTE_Y_SRC
                setal
                ; The 32Bit ADDER is already Setup with Reg B with -(BMP_X_SIZE)
                ; So just load the Actual Value so it can be substracted again from BMP_X_SIZE
                LDA BMP_PRSE_SRC_PTR        ; Right now it is set @ $020000 (128K) + File Size
                STA @lADDER32_A_LL
                LDA BMP_PRSE_SRC_PTR+2      ; Right now it is set @ $020000 (128K)
                STA @lADDER32_A_HL
                ; And Zooom... The new Value is calculated... Yeah, Fuck I love the 32Bit Adder
                LDA @lADDER32_R_LL
                STA BMP_PRSE_SRC_PTR
                LDA @lADDER32_R_HL
                STA BMP_PRSE_SRC_PTR+2
                RTS
;BMP_PRSE_DST_PTR = BMP_PRSE_DST_PTR + Screen_Stride
BMP_PARSER_COMPUTE_Y_DST
                setal
                CLC
                LDA BMP_PRSE_DST_PTR
                ADC SCRN_X_STRIDE        ; In Normal Circumstances, it is 640
                STA BMP_PRSE_DST_PTR
                LDA BMP_PRSE_DST_PTR+2
                ADC #$0000
                STA BMP_PRSE_DST_PTR+2
                RTS

ILOOP           NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                RTL

ILOOP_1         JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                RTL

ILOOP_1MS       JSL ILOOP_1
                RTL

; A delay loop
ILOOP_MS        CPX #0
                BEQ LOOP_MS_END
                JSL ILOOP_1MS
                DEX
                BRA ILOOP_MS
LOOP_MS_END     RTL

;
; Show the credits screen
;
SHOW_CREDITS    .proc
                PHA
                PHX
                PHY
                PHP

                setas
                setxl

                LDA @lVKY_TXT_CURSOR_CTRL_REG   ; Disable the cursor
                AND #~Vky_Cursor_Enable
                STA @lVKY_TXT_CURSOR_CTRL_REG

                LDX #0

credit_loop     LDA @lCREDITS_TEXT,X            ; Copy a byte of text
                STA @lCS_TEXT_MEM_PTR,X

                LDA @lCREDITS_COLOR,X           ; Copy a byte of color
                STA @lCS_COLOR_MEM_PTR,X

                INX
                CPX #128 * 64
                BNE credit_loop

                JSL IGETCHW                     ; Wait for a keypress
                JSL ICLRSCREEN                  ; Then clear the screen and return
                JSL ICSRHOME                    ; Move cursor to the home position

                LDA @lVKY_TXT_CURSOR_CTRL_REG   ; Enable the cursor
                ORA #Vky_Cursor_Enable
                STA @lVKY_TXT_CURSOR_CTRL_REG

                PLP
                PLY
                PLX
                PLA
                RTL
                .pend

;
;Not-implemented routines
;
IRESTORE        BRK ; Warm boot routine
ISCINIT         BRK ;
IIOINIT         BRK ;
IPUTBLOCK       BRK ; Ouput a binary block to the currently selected channel
ISETLFS         BRK ; Obsolete (done in OPEN)
ISETNAM         BRK ; Obsolete (done in OPEN)
IOPEN           BRK ; Open a channel for reading and/or writing. Use SETLFS and SETNAM to set the channels and filename first.
ICLOSE          BRK ; Close a channel
IGETB           BRK ; Get a byte from input channel. Return 0 if no input. Carry is set if no input.
IGETBLOCK       BRK ; Get a X byes from input channel. If Carry is set, wait. If Carry is clear, do not wait.
IGETCH          BRK ; Get a character from the input channel. A=0 and Carry=1 if no data is wating
IGETS           BRK ; Get a string from the input channel. NULL terminates
IGETLINE        BRK ; Get a line of text from input channel. CR or NULL terminates.
IGETFIELD       BRK ; Get a field from the input channel. Value in A, CR, or NULL terminates
ITRIM           BRK ; Removes spaces at beginning and end of string.
IPRINTC         BRK ; Print character to screen. Handles terminal commands
IPRINTS         BRK ; Print string to screen. Handles terminal commands
IPRINTF         BRK ; Print a float value
IPRINTI         BRK ; Prints integer value in TEMP
IPRINTAI        BRK ; Prints integer value in A
IPUSHKEY        BRK ;
IPUSHKEYS       BRK ;
ISCRREADLINE    BRK ; Loads the MCMDADDR/BCMDADDR variable with the address of the current line on the screen. This is called when the RETURN key is pressed and is the first step in processing an immediate mode command.
ISCRGETWORD     BRK ; Read a current word on the screen. A word ends with a space, punctuation (except _), or any control character (value < 32). Loads the address into CMPTEXT_VAL and length into CMPTEXT_LEN variables.

;
; Greeting message and other kernel boot data
;
KERNEL_DATA
greet_msg       .text $20, $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, " FFFFFFF MMMMMMMM XX    XXX " ,$0D
                .text $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FF      MM MM MM   XX XXX   ",$0D
                .text $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FFFFF   MM MM MM    XXX      ",$0D
                .text $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FF      MM MM MM  XXX  XX     ",$0D
                .text $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FF      MM MM MM XXX     XX    ",$0D
                .text $0D, "C256 FOENIX FMX -- 3,670,016 Bytes Free", $0D
                .text "www.c256foenix.com - Kernel Date: "
                .include "version.asm"
                .text $0D,$00

old_pc_style_stat
;                .text $D6, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C2
;                .text      $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $B7, $0D
;                .text $BA, " Main Processor     : 65C816      ",$B3," Base Memory Size     : 2048K     ",$BA, $0D
;                .text $BA, " Numeric Processor  : CFP9519     ",$B3," Video Memory Size    : 4096K     ",$BA, $0D
;                .text $BA, " Floppy Driver A:   : Yes         ",$B3," Hard Disk C: Type    : None      ",$BA, $0D
;                .text $BA, " SDCard Card Reader : Yes         ",$B3," Serial Port(s)       : $AF:13F8, ",$BA, $0D
;                .text $BA, " Display Type       : VGA         ",$B3,"                        $AF:12F8  ",$BA, $0D
;                .text $BA, " Foenix Kernel Date : 081819      ",$B3," Parallel Ports(s)    : $AF:1378  ",$BA, $0D
;                .text $BA, " Keyboard Type      : PS2         ",$B3," Sound Chip Installed : OPL2(2)   ",$BA, $0D
;                .text $D3, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C1
;                .text      $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $C4, $BD, $00


greet_clr_line1 .text $1D, $1D, $1D, $1D, $1D, $1D, $8D, $8D, $4D, $4D, $2D, $2D, $5D, $5D, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD
greet_clr_line2 .text $1D, $1D, $1D, $1D, $1D, $8D, $8D, $4D, $4D, $2D, $2D, $5D, $5D, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD
greet_clr_line3 .text $1D, $1D, $1D, $1D, $8D, $8D, $4D, $4D, $2D, $2D, $5D, $5D, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD
greet_clr_line4 .text $1D, $1D, $1D, $8D, $8D, $4D, $4D, $2D, $2D, $5D, $5D, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD
greet_clr_line5 .text $1D, $1D, $8D, $8D, $4D, $4D, $2D, $2D, $5D, $5D, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD, $FD

fg_color_lut	  .text $00, $00, $00, $FF
                .text $00, $00, $80, $FF
                .text $00, $80, $00, $FF
                .text $80, $00, $00, $FF
                .text $00, $80, $80, $FF
                .text $80, $80, $00, $FF
                .text $80, $00, $80, $FF
                .text $80, $80, $80, $FF
                .text $00, $45, $FF, $FF
                .text $13, $45, $8B, $FF
                .text $00, $00, $20, $FF
                .text $00, $20, $00, $FF
                .text $20, $00, $00, $FF
                .text $20, $20, $20, $FF
                .text $40, $40, $40, $FF
                .text $FF, $FF, $FF, $FF

bg_color_lut	  .text $00, $00, $00, $FF
                .text $00, $00, $80, $FF
                .text $00, $80, $00, $FF
                .text $80, $00, $00, $FF
                .text $00, $20, $20, $FF
                .text $20, $20, $00, $FF
                .text $20, $00, $20, $FF
                .text $20, $20, $20, $FF
                .text $1E, $69, $D2, $FF
                .text $13, $45, $8B, $FF
                .text $00, $00, $20, $FF
                .text $00, $20, $00, $FF
                .text $40, $00, $00, $FF
                .text $10, $10, $10, $FF
                .text $40, $40, $40, $FF
                .text $FF, $FF, $FF, $FF

pass_tst0xAAmsg .text "Cmd 0xAA Test passed...", $0D, $00
pass_tst0xABmsg .text "Cmd 0xAB Test passed...", $0D, $00
pass_cmd0x60msg .text "Cmd 0x60 Executed.", $0D, $00
pass_cmd0xFFmsg .text "Cmd 0xFF (Reset) Done.", $0D, $00
pass_cmd0xEEmsg .text "Cmd 0xEE Echo Test passed...", $0D, $00
Success_kb_init .text "Keyboard Present", $0D, $00
Failed_kb_init  .text "No Keyboard Attached or Failed Init...", $0D, $00
bmp_parser_err0 .text "NO SIGNATURE FOUND.", $00
bmp_parser_msg0 .text "BMP LOADED.", $00
bmp_parser_msg1 .text "EXECUTING BMP PARSER", $00
IDE_HDD_Present_msg0 .text "IDE HDD Present:", $00

boot_invalid    .text "Boot DIP switch settings are invalid", $00
sdcard_notimpl  .text "Booting from SD card is not yet implemented.", $00
ide_notimpl     .text "Booting from IDE drive is not yet implemented.", $00
floppy_notimpl  .text "Booting from floppy drive is not yet implemented.", $00

ready_msg       .null $0D,"READY."


error_01        .null "ABORT ERROR"
hex_digits      .text "0123456789ABCDEF",0

; Keyboard scan code -> ASCII conversion tables
.align 256
ScanCode_Press_Set1   .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $11, $00, $00, $9D, $00, $1D, $00, $00    ; $40
                      .text $91, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Shift_Set1   .text $00, $00, $21, $40, $23, $24, $25, $5E, $26, $2A, $28, $29, $5F, $2B, $08, $09    ; $00
                      .text $51, $57, $45, $52, $54, $59, $55, $49, $4F, $50, $7B, $7D, $0D, $00, $41, $53    ; $10
                      .text $44, $46, $47, $48, $4A, $4B, $4C, $3A, $22, $7E, $00, $5C, $5A, $58, $43, $56    ; $20
                      .text $42, $4E, $4D, $3C, $3E, $3F, $00, $18, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Ctrl_Set1    .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $03, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Alt_Set1     .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_NumLock_Set1 .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Prefix_Set1  .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $00
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $10
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $20
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $11, $00, $00, $9D, $00, $1D, $00, $00    ; $40
                      .text $91, $00, $0F, $7F, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

; Gamma Table 2.2
.align 256
GAMMA_2_2_Tbl         .text  $00, $14, $1c, $21, $26, $2a, $2e, $31, $34, $37, $3a, $3d, $3f, $41, $44, $46
                      .text  $48, $4a, $4c, $4e, $50, $51, $53, $55, $57, $58, $5a, $5b, $5d, $5e, $60, $61
                      .text  $63, $64, $66, $67, $68, $6a, $6b, $6c, $6d, $6f, $70, $71, $72, $73, $75, $76
                      .text  $77, $78, $79, $7a, $7b, $7c, $7d, $7e, $80, $81, $82, $83, $84, $85, $86, $87
                      .text  $88, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f, $90, $91, $92, $93, $93, $94, $95
                      .text  $96, $97, $98, $99, $99, $9a, $9b, $9c, $9d, $9e, $9e, $9f, $a0, $a1, $a2, $a2
                      .text  $a3, $a4, $a5, $a5, $a6, $a7, $a8, $a8, $a9, $aa, $ab, $ab, $ac, $ad, $ae, $ae
                      .text  $AF, $b0, $b0, $b1, $b2, $b2, $b3, $b4, $b5, $b5, $b6, $b7, $b7, $b8, $b9, $b9
                      .text  $ba, $bb, $bb, $bc, $bd, $bd, $be, $be, $bf, $c0, $c0, $c1, $c2, $c2, $c3, $c4
                      .text  $c4, $c5, $c5, $c6, $c7, $c7, $c8, $c8, $c9, $ca, $ca, $cb, $cb, $cc, $cd, $cd
                      .text  $ce, $ce, $cf, $d0, $d0, $d1, $d1, $d2, $d2, $d3, $d4, $d4, $d5, $d5, $d6, $d6
                      .text  $d7, $d8, $d8, $d9, $d9, $da, $da, $db, $db, $dc, $dc, $dd, $de, $de, $df, $df
                      .text  $e0, $e0, $e1, $e1, $e2, $e2, $e3, $e3, $e4, $e4, $e5, $e5, $e6, $e6, $e7, $e7
                      .text  $e8, $e8, $e9, $e9, $ea, $ea, $eb, $eb, $ec, $ec, $ed, $ed, $ee, $ee, $ef, $ef
                      .text  $f0, $f0, $f1, $f1, $f2, $f2, $f3, $f3, $f4, $f4, $f5, $f5, $f6, $f6, $f7, $f7
                      .text  $f8, $f8, $f9, $f9, $f9, $fa, $fa, $fb, $fb, $fc, $fc, $fd, $fd, $fe, $fe, $ff
.align 256
GAMMA_1_8_Tbl         .text  $00, $0b, $11, $15, $19, $1c, $1f, $22, $25, $27, $2a, $2c, $2e, $30, $32, $34
                      .text  $36, $38, $3a, $3c, $3d, $3f, $41, $43, $44, $46, $47, $49, $4a, $4c, $4d, $4f
                      .text  $50, $51, $53, $54, $55, $57, $58, $59, $5b, $5c, $5d, $5e, $60, $61, $62, $63
                      .text  $64, $65, $67, $68, $69, $6a, $6b, $6c, $6d, $6e, $70, $71, $72, $73, $74, $75
                      .text  $76, $77, $78, $79, $7a, $7b, $7c, $7d, $7e, $7f, $80, $81, $82, $83, $84, $84
                      .text  $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8e, $8f, $90, $91, $92, $93
                      .text  $94, $95, $95, $96, $97, $98, $99, $9a, $9a, $9b, $9c, $9d, $9e, $9f, $9f, $a0
                      .text  $a1, $a2, $a3, $a3, $a4, $a5, $a6, $a6, $a7, $a8, $a9, $aa, $aa, $ab, $ac, $ad
                      .text  $ad, $ae, $af, $b0, $b0, $b1, $b2, $b3, $b3, $b4, $b5, $b6, $b6, $b7, $b8, $b8
                      .text  $b9, $ba, $bb, $bb, $bc, $bd, $bd, $be, $bf, $bf, $c0, $c1, $c2, $c2, $c3, $c4
                      .text  $c4, $c5, $c6, $c6, $c7, $c8, $c8, $c9, $ca, $ca, $cb, $cc, $cc, $cd, $ce, $ce
                      .text  $cf, $d0, $d0, $d1, $d2, $d2, $d3, $d4, $d4, $d5, $d6, $d6, $d7, $d7, $d8, $d9
                      .text  $d9, $da, $db, $db, $dc, $dc, $dd, $de, $de, $df, $e0, $e0, $e1, $e1, $e2, $e3
                      .text  $e3, $e4, $e4, $e5, $e6, $e6, $e7, $e7, $e8, $e9, $e9, $ea, $ea, $eb, $ec, $ec
                      .text  $ed, $ed, $ee, $ef, $ef, $f0, $f0, $f1, $f1, $f2, $f3, $f3, $f4, $f4, $f5, $f5
                      .text  $f6, $f7, $f7, $f8, $f8, $f9, $f9, $fa, $fb, $fb, $fc, $fc, $fd, $fd, $fe, $ff
.align 256
RANDOM_LUT_Tbl		    .text  $1d, $c8, $a7, $ac, $10, $d6, $52, $7c, $83, $dd, $ce, $39, $cd, $c5, $3b, $15
				              .text  $22, $55, $3b, $94, $e0, $33, $1f, $38, $87, $12, $31, $65, $89, $27, $88, $42
				              .text  $b2, $32, $72, $84, $b2, $b2, $31, $52, $94, $ce, $56, $ec, $fe, $da, $58, $c9
				              .text  $c8, $5b, $53, $2a, $08, $3b, $19, $c1, $d0, $10, $2c, $b2, $4b, $ea, $32, $61
				              .text  $da, $34, $33, $8f, $2b, $da, $49, $89, $a1, $e6, $ca, $2d, $b3, $ce, $b0, $79
				              .text  $44, $aa, $32, $82, $91, $e9, $29, $16, $5f, $e3, $fb, $bd, $15, $2e, $be, $f5
				              .text  $e9, $4a, $e4, $2e, $60, $24, $94, $35, $8d, $8f, $2c, $80, $0a, $5e, $99, $36
				              .text  $ac, $ab, $21, $26, $42, $7c, $5e, $bc, $13, $52, $44, $2f, $e3, $ef, $44, $a2
				              .text  $86, $c1, $9c, $47, $5f, $36, $6d, $02, $be, $23, $02, $58, $0a, $52, $5e, $b4
				              .text  $9f, $06, $08, $c9, $97, $cb, $9e, $dd, $d5, $cf, $3e, $df, $c4, $9e, $da, $bb
				              .text  $9b, $5d, $c9, $f5, $d9, $c3, $7e, $87, $77, $7d, $b1, $3b, $4a, $68, $35, $6e
				              .text  $ee, $47, $ad, $8f, $fd, $73, $2e, $46, $b5, $8f, $44, $63, $55, $6f, $e1, $50
				              .text  $f4, $b6, $a3, $4f, $68, $c4, $a5, $a4, $57, $74, $b9, $bd, $05, $14, $50, $eb
				              .text  $a5, $5c, $57, $2f, $99, $dc, $2e, $8a, $44, $bc, $ec, $db, $22, $58, $fc, $be
				              .text  $5f, $3f, $50, $bd, $2a, $36, $ab, $ae, $24, $aa, $82, $11, $5c, $9f, $43, $4d
				              .text  $8f, $0c, $20, $00, $91, $b6, $45, $9e, $3e, $3d, $66, $7e, $0a, $1c, $6b, $74

.align 16

MOUSE_POINTER_PTR     .text $00,$01,$01,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00
                      .text $01,$FF,$FF,$01,$00,$00,$01,$01,$FF,$FF,$FF,$01,$00,$00,$00,$00
                      .text $01,$FF,$FF,$FF,$01,$01,$55,$FF,$01,$55,$FF,$FF,$01,$00,$00,$00
                      .text $01,$55,$FF,$FF,$FF,$FF,$01,$55,$FF,$FF,$FF,$FF,$01,$00,$00,$00
                      .text $00,$01,$55,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$FF,$FF,$01,$00,$00
                      .text $00,$00,$01,$55,$FF,$FF,$FF,$FF,$01,$FF,$FF,$01,$FF,$01,$00,$00
                      .text $00,$00,$01,$01,$55,$FF,$FF,$FF,$FF,$01,$FF,$FF,$FF,$01,$00,$00
                      .text $00,$00,$01,$55,$01,$55,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$01,$00
                      .text $00,$00,$01,$55,$55,$55,$FF,$FF,$FF,$FF,$FF,$FF,$01,$FF,$FF,$01
                      .text $00,$00,$00,$01,$55,$55,$55,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01
                      .text $00,$00,$00,$00,$01,$55,$55,$55,$55,$55,$01,$FF,$FF,$55,$01,$00
                      .text $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$55,$FF,$55,$01,$00,$00
                      .text $00,$00,$00,$00,$00,$00,$00,$00,$01,$55,$55,$55,$01,$00,$00,$00
                      .text $00,$00,$00,$00,$00,$00,$00,$00,$01,$55,$55,$01,$00,$00,$00,$00
                      .text $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00
                      .text $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


            

* = $3FF000
FONT_4_BANK0
.binary "FONT/Bm437_PhoenixEGA_8x8.bin", 0, 2048
FONT_4_BANK1
.binary "FONT/CBM-ASCII_8x8.bin", 0, 2048

* = $3A0000
.binary "binaries/basic816.bin"

* = $3B0000

; Credits screen

TXTLINE         .macro txt
                .text \txt
                .fill 128 - len(\txt), $20
                .endm

.align 256
CREDITS_TEXT    TXTLINE "This is the credits screen!"
                TXTLINE "I would like to thank the academy."
                TXTLINE ""
                TXTLINE "Press any key to go back..."
                .fill 128 * 60,$20

.align 256
CREDITS_COLOR   .fill 128 * 64, $F3