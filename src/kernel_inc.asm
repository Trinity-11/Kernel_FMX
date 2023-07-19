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
GETSCANCODE      = $001028 ; Get the next scancode from the keyboard (A = scancode, 0 if none available)
GETLOCKS         = $00102C ; Get the state of the lock keys on the keyboard (A[2] = CAPS, A[1] = NUM, A[0] = SCROLL)
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
; Undefined label for: SCRGETWORD       = %ADDR% ; Read a current word on the screen. A word ends with a space, punctuation (except _), or any control character (value < 32). Loads the address into CMPTEXT_VAL and length into CMPTEXT_LEN variables.
CLRSCREEN        = $0010A8 ; Clear the screen
INITCHLUT        = $0010AC ; Init character look-up table
INITSUPERIO      = $0010B0 ; Init Super-IO chip
INITKEYBOARD     = $0010B4 ; Init keyboard
; Undefined label for: INITRTC          = %ADDR% ; Init Real-Time Clock
INITCURSOR       = $0010BC ; Init the Cursors registers
INITFONTSET      = $0010C0 ; Init the Internal FONT Memory
INITGAMMATABLE   = $0010C4 ; Init the RGB GAMMA Look Up Table
INITALLLUT       = $0010C8 ; Init the Graphic Engine (Bitmap/Tile/Sprites) LUT
INITVKYTXTMODE   = $0010CC ; Init the Text Mode @ Reset Time
INITVKYGRPMODE   = $0010D0 ; Init the Basic Registers for the Graphic Mode
SETSIZES         = $00112C ; Set the text screen size variables based on the border and screen resolution.
F_OPEN           = $0010F0 ; open a file for reading/writing/creating
F_CREATE         = $0010F4 ; create a new file
F_CLOSE          = $0010F8 ; close a file (make sure last cluster is written)
F_WRITE          = $0010FC ; write the current cluster to the file
F_READ           = $001100 ; read the next cluster from the file
F_DELETE         = $001104 ; delete a file / directory
; Undefined label for: F_RENAME         = %ADDR% ; rename a file
F_DIROPEN        = $001108 ; open a directory and seek the first directory entry
F_DIRNEXT        = $00110C ; seek to the next directory of an open directory
F_DIRREAD        = $001110 ; Read the directory entry for the specified file
F_DIRWRITE       = $001114 ; Write any changes in the current directory cluster back to the drive
F_LOAD           = $001118 ; load a binary file into memory, supports multiple file formats
F_SAVE           = $00111C ; Save memory to a binary file
CMDBLOCK         = $001120 ; Send a command to a block device
F_RUN            = $001124 ; Load and run an executable binary file
F_MOUNT          = $001128 ; Mount the designated block device
F_COPY           = $001130 ; Copy a file
F_ALLOCFD        = $001134 ; Allocate a file descriptor
F_FREEFD         = $001138 ; Free a file descriptor
TESTBREAK        = $00113C ; Check if BREAK was pressed recently by the user (C is set if true, clear if false)
SETTABLE         = $001140 ; Set the keyboard scan code -> character translation tables (B:X points to the new tables)
READVRAM         = $001144 ; Read a byte from video RAM at B:X
SETHANDLER       = $001148 ; Set the handler for the interrupt # in A to the FAR routine at Y:X
DELAY            = $00114C ; Wait at least Y:X ticks of the system clock.
IP_INIT          = $001150 ; Init network stack; B:Y->ip, mask, default_route.  buffer_ptr below is 24 of 32 bits.
UDP_SEND         = $001154 ; Send a UDP packet:  0:X->local_port, remote_ip, remote_port, buffer_ptr, size, copied
UDP_RECV         = $001158 ; Recv a UDP packet:  0:X->local_port, remote_ip, remote_port, buffer_ptr, size, copied

;
; Interrupt Vector Table
;

VEC_INT00_SOF       = $001700 ; IRQ 0, 0 --- Start Of Frame interrupt 
VEC_INT01_SOL       = $001704 ; IRQ 0, 1 --- Start Of Line interrupt
VEC_INT02_TMR0      = $001708 ; IRQ 0, 2 --- Timer 0 interrupt
VEC_INT03_TMR1      = $00170C ; IRQ 0, 3 --- Timer 1 interrupt
VEC_INT04_TMR2      = $001710 ; IRQ 0, 4 --- Timer 2 interrupt
VEC_INT05_RTC       = $001714 ; IRQ 0, 5 --- Real Time Clock interrupt
VEC_INT06_FDC       = $001718 ; IRQ 0, 6 --- Floppy Drive Controller interrupt
VEC_INT07_MOUSE     = $00171C ; IRQ 0, 7 --- Mouse interrupt

VEC_INT10_KBD       = $001720 ; IRQ 1, 0 --- Keyboard interrupt
VEC_INT11_COL0      = $001724 ; IRQ 1, 1 --- VICKY_II (INT2) Sprite Collision 
VEC_INT12_COL1      = $001728 ; IRQ 1, 2 --- VICKY_II (INT3) Bitmap Collision
VEC_INT13_COM2      = $00172C ; IRQ 1, 3 --- Serial port #2 interrupt
VEC_INT14_COM1      = $001730 ; IRQ 1, 4 --- Serial port #1 interrupt
VEC_INT15_MIDI      = $001734 ; IRQ 1, 5 --- MIDI controller interrupt
VEC_INT16_LPT       = $001738 ; IRQ 1, 6 --- Parallel port interrupt
VEC_INT17_SDC       = $00173C ; IRQ 1, 7 --- SD Card Controller interrupt (CH376S???)

VEC_INT20_OPL       = $001740 ; IRQ 2, 0 --- OPL3
VEC_INT21_GABE0     = $001744 ; IRQ 2, 1 --- GABE (INT0) - TBD
VEC_INT22_GABE1     = $001748 ; IRQ 2, 2 --- GABE (INT1) - TBD
VEC_INT23_VDMA      = $00174C ; IRQ 2, 3 --- VICKY_II (INT4) - VDMA Interrupt
VEC_INT24_COL2      = $001750 ; IRQ 2, 4 --- VICKY_II (INT5) Tile Collision
VEC_INT25_GABE2     = $001754 ; IRQ 2, 5 --- GABE (INT2) - TBD
VEC_INT26_EXT       = $001758 ; IRQ 2, 6 --- External Expansion
VEC_INT17_SDINS     = $00175C ; IRQ 2, 7 --- SDCARD Insertion

VEC_INT30_OPN2      = $001760 ; IRQ 3, 0 --- OPN2
VEC_INT31_OPM       = $001764 ; IRQ 3, 1 --- OPM
VEC_INT32_IDE       = $001768 ; IRQ 3, 2 --- HDD IDE Interrupt
