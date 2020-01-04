;Kernel_INC.asm
;Kernel ROM jump table

BOOT             = $001000 ; Cold boot routine
RESTORE          = $001004 ; Warm boot routine
BREAK            = $001008 ; End program and return to command prompt
READY            = $00100C ; Print prompt and wait for keyboard input
SCINIT           = $001010 ;
IOINIT           = $001014 ;
PUTC             = $001018 ; Print a character to the currently selected channel
PUTS             = $00101C ; Print a string to the currently selected channel
PUTB             = $001020 ; Output a byte to the currently selected channel
PUTBLOCK         = $001024 ; Ouput a binary block to the currently selected channel
SETLFS           = $001028 ; Obsolete (done in OPEN)
SETNAM           = $00102C ; Obsolete (done in OPEN)
OPEN             = $001030 ; Open a channel for reading and/or writing. Use SETLFS and SETNAM to set the channels and filename first.
CLOSE            = $001034 ; Close a channel
SETIN            = $001038 ; Set the current input channel
SETOUT           = $00103C ; Set the current output channel
GETB             = $001040 ; Get a byte from input channel. Return 0 if no input. Carry is set if no input.
GETBLOCK         = $001044 ; Get a X byes from input channel. If Carry is set, wait. If Carry is clear, do not wait.
GETCH            = $001048 ; Get a character from the input channel. A=0 and Carry=1 if no data is wating
GETCHW           = $00104C ; Get a character from the input channel. Waits until data received. A=0 and Carry=1 if no data is wating
GETCHE           = $001050 ; Get a character from the input channel and echo to the screen. Wait if data is not ready.
GETS             = $001054 ; Get a string from the input channel. NULL terminates
GETLINE          = $001058 ; Get a line of text from input channel. CR or NULL terminates.
GETFIELD         = $00105C ; Get a field from the input channel. Value in A, CR, or NULL terminates
TRIM             = $001060 ; Removes spaces at beginning and end of string.
PRINTC           = $001064 ; Print character to screen. Handles terminal commands
PRINTS           = $001068 ; Print string to screen. Handles terminal commands
PRINTCR          = $00106C ; Print Carriage Return
PRINTF           = $001070 ; Print a float value
PRINTI           = $001074 ; Prints integer value in TEMP
PRINTH           = $001078 ; Print Hex value in DP variable
PRINTAI          = $00107C ; Prints integer value in A
PRINTAH          = $001080 ; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
LOCATE           = $001084 ;
PUSHKEY          = $001088 ;
PUSHKEYS         = $00108C ;
CSRRIGHT         = $001090 ;
CSRLEFT          = $001094 ;
CSRUP            = $001098 ;
CSRDOWN          = $00109C ;
CSRHOME          = $0010A0 ;
SCROLLUP         = $0010A4 ; Scroll the screen up one line. Creates an empty line at the bottom.
SCRREADLINE      = $0010A8 ; Loads the MCMDADDR/BCMDADDR variable with the address of the current line on the screen. This is called when the RETURN key is pressed and is the first step in processing an immediate mode command.
SCRGETWORD       = $0010AC ; Read a current word on the screen. A word ends with a space, punctuation (except _), or any control character (value < 32). Loads the address into CMPTEXT_VAL and length into CMPTEXT_LEN variables.
CLRSCREEN        = $0010B0 ; Clear the screen
INITCHLUT        = $0010B4 ; Init character look-up table
INITSUPERIO      = $0010B8 ; Init Super-IO chip
INITKEYBOARD     = $0010BC ; Init keyboard
INITRTC          = $0010C0 ; Init Real-Time Clock
INITCURSOR       = $0010C4 ; Init the Cursors registers
INITFONTSET      = $0010C8 ; Init the Internal FONT Memory
INITGAMMATABLE   = $0010CC ; Init the RGB GAMMA Look Up Table
INITALLLUT       = $0010D0 ; Init the Graphic Engine (Bitmap/Tile/Sprites) LUT
INITVKYTXTMODE   = $0010D4 ; Init the Text Mode @ Reset Time
INITVKYGRPMODE   = $0010D8 ; Init the Basic Registers for the Graphic Mode
