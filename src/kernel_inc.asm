;Kernel_INC.asm
;Kernel ROM jump table

BOOT             = $00F000 ; Cold boot routine
RESTORE          = $00F004 ; Warm boot routine
BREAK            = $00F008 ; End program and return to command prompt
READY            = $00F00C ; Print prompt and wait for keyboard input
SCINIT           = $00F010 ;
IOINIT           = $00F014 ;
PUTC             = $00F018 ; Print a character to the currently selected channel
PUTS             = $00F01C ; Print a string to the currently selected channel
PUTB             = $00F020 ; Output a byte to the currently selected channel
PUTBLOCK         = $00F024 ; Ouput a binary block to the currently selected channel
SETLFS           = $00F028 ; Obsolete (done in OPEN)
SETNAM           = $00F02C ; Obsolete (done in OPEN)
OPEN             = $00F030 ; Open a channel for reading and/or writing. Use SETLFS and SETNAM to set the channels and filename first.
CLOSE            = $00F034 ; Close a channel
SETIN            = $00F038 ; Set the current input channel
SETOUT           = $00F03C ; Set the current output channel
GETB             = $00F040 ; Get a byte from input channel. Return 0 if no input. Carry is set if no input.
GETBLOCK         = $00F044 ; Get a X byes from input channel. If Carry is set, wait. If Carry is clear, do not wait.
GETCH            = $00F048 ; Get a character from the input channel. A=0 and Carry=1 if no data is wating
GETCHW           = $00F04C ; Get a character from the input channel. Waits until data received. A=0 and Carry=1 if no data is wating
GETCHE           = $00F050 ; Get a character from the input channel and echo to the screen. Wait if data is not ready.
GETS             = $00F054 ; Get a string from the input channel. NULL terminates
GETLINE          = $00F058 ; Get a line of text from input channel. CR or NULL terminates.
GETFIELD         = $00F05C ; Get a field from the input channel. Value in A, CR, or NULL terminates
TRIM             = $00F060 ; Removes spaces at beginning and end of string.
PRINTC           = $00F064 ; Print character to screen. Handles terminal commands
PRINTS           = $00F068 ; Print string to screen. Handles terminal commands
PRINTCR          = $00F06C ; Print Carriage Return
PRINTF           = $00F070 ; Print a float value
PRINTI           = $00F074 ; Prints integer value in TEMP
PRINTH           = $00F078 ; Print Hex value in DP variable
PRINTAI          = $00F07C ; Prints integer value in A
PRINTAH          = $00F080 ; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
LOCATE           = $00F084 ;
PUSHKEY          = $00F088 ;
PUSHKEYS         = $00F08C ;
CSRRIGHT         = $00F090 ;
CSRLEFT          = $00F094 ;
CSRUP            = $00F098 ;
CSRDOWN          = $00F09C ;
CSRHOME          = $00F0A0 ;
SCROLLUP         = $00F0A4 ; Scroll the screen up one line. Creates an empty line at the bottom.
SCRREADLINE      = $00F0A8 ; Loads the MCMDADDR/BCMDADDR variable with the address of the current line on the screen. This is called when the RETURN key is pressed and is the first step in processing an immediate mode command.
SCRGETWORD       = $00F0AC ; Read a current word on the screen. A word ends with a space, punctuation (except _), or any control character (value < 32). Loads the address into CMPTEXT_VAL and length into CMPTEXT_LEN variables.
CLRSCREEN        = $00F0B0 ; Clear the screen
INITCHLUT        = $00F0B4 ; Init character look-up table
INITSUPERIO      = $00F0B8 ; Init Super-IO chip
INITKEYBOARD     = $00F0BC ; Init keyboard
INITRTC          = $00F0C0 ; Init Real-Time Clock
INITCURSOR       = $00F0C4 ; Init the Cursors registers
INITFONTSET      = $00F0C8 ; Init the Internal FONT Memory
INITGAMMATABLE   = $00F0CC ; Init the RGB GAMMA Look Up Table
INITALLLUT       = $00F0D0 ; Init the Graphic Engine (Bitmap/Tile/Sprites) LUT
INITVKYTXTMODE   = $00F0D4 ; Init the Text Mode @ Reset Time
INITVKYGRPMODE   = $00F0D8 ; Init the Basic Registers for the Graphic Mode
