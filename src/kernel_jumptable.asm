;
; Kernel jump table
; This includes all of the externally callable routines and forwards those to their internal
; addresses in the Foenix ROM.
;
; The kernel vector table exists in three locations:
; 1. $F0:1xxx -- This is the master copy in the flash memory
; 2. $38:1xxx -- GABE copies the flash memory into RAM, starting at bank $38 on the FMX.
;                Note: other systems may use different locations for this copy in RAM.
; 3. $00:1xxx -- GABE also copies the first bank of flash to the first bank of RAM, this puts
;                a copy of the kernel vector table to $00:1xxx. This copy will be in the same
;                location for all versions of the C256, and is the copy that should be used by
;                all programs.
;
; To add new vectors:
; 1. Add the vector between the .logical and .here directives
; 2. Compile the kernel.
; 3. Add an entry for the vector to kernel_inc.txt, using "%ADDR%" as a substitution variable
;    for its actual jump point.
; 4. Run the Python script genjumptable.py to generate the kernel_inc.asm file for programs to use.
;
* = START_OF_FLASH + $001000        ; This table will be set up to load initially into bank $38 on the FMX, and $18 on the U
.logical $001000                    ; But it will copied to bank $00 on startup for all systems
BOOT            JML IBOOT
RESTORE         JML IRESTORE
BREAK           JML IBREAK
READY           JML IREADY
SCINIT          JML ISCINIT
IOINIT          JML IIOINIT
PUTC            JML IPUTC
PUTS            JML IPUTS
PUTB            JML IPUTB
PUTBLOCK        JML IPUTBLOCK
GETSCANCODE     JML KBD_GET_SCANCODE    ; Get the next 8-bit scan code from the keyboard: A = 0 if no scancode present, contains the scancode otherwise
GETLOCKS        JML KBD_GETLOCKS        ; Get the state of the lock keys on the keyboard
OPEN            JML IOPEN
CLOSE           JML ICLOSE
SETIN           JML ISETIN
SETOUT          JML ISETOUT
GETB            JML IGETB
GETBLOCK        JML IGETBLOCK
GETCH           JML IGETCH
GETCHW          JML IGETCHW
GETCHE          JML IGETCHE
GETS            JML IGETS
GETLINE         JML IGETLINE
GETFIELD        JML IGETFIELD
TRIM            JML ITRIM
PRINTC          JML IPRINTC
PRINTS          JML IPRINTS
PRINTCR         JML IPRINTCR
PRINTF          JML IPRINTF
PRINTI          JML IPRINTI
PRINTH          JML IPRINTH
PRINTAI         JML IPRINTAI
PRINTAH         JML IPRINTAH
LOCATE          JML ILOCATE
PUSHKEY         JML IPUSHKEY
PUSHKEYS        JML IPUSHKEYS
CSRRIGHT        JML ICSRRIGHT
CSRLEFT         JML ICSRLEFT
CSRUP           JML ICSRUP
CSRDOWN         JML ICSRDOWN
CSRHOME         JML ICSRHOME
SCROLLUP        JML ISCROLLUP
CLRSCREEN       JML ICLRSCREEN
INITCHLUT	    JML IINITCHLUT
INITSUPERIO	    JML IINITSUPERIO
INITKEYBOARD    JML IINITKEYBOARD
INITMOUSE       JML IINITMOUSE
INITCURSOR      JML IINITCURSOR
INITFONTSET     JML IINITFONTSET
INITGAMMATABLE  JML IINITGAMMATABLE
INITALLLUT      JML IINITALLLUT
INITVKYTXTMODE  JML IINITVKYTXTMODE
INITVKYGRPMODE  JML IINITVKYGRPMODE
ISETDAC32KHZ    JML INOP            ; Depracated Routine Replaced by New Ones - To be Implemented
ISETDAC48KHZ    JML INOP            ; Depracated Routine Replaced by New Ones - To be Implemented
INITCODEC       JML IINITCODEC
RESETCODEC      JML IRESETCODEC
BMP_PARSER      JML IBMP_PARSER
BM_FILL_SCREEN  JML IBM_FILL_SCREEN
OPL2_TONE_TEST  JML IOPL2_TONE_TEST

; SimpleDOS Jumps

F_OPEN          JML IF_OPEN         ; open a file for reading/writing/creating
F_CREATE        JML IF_CREATE       ; create a new file
F_CLOSE         JML IF_CLOSE        ; close a file (make sure last cluster is written)
F_WRITE         JML IF_WRITE        ; write the current cluster to the file
F_READ          JML IF_READ         ; read the next cluster from the file
F_DELETE        JML IF_DELETE       ; delete a file / directory
F_DIROPEN       JML IF_DIROPEN      ; open a directory and seek the first directory entry
F_DIRNEXT       JML IF_DIRNEXT      ; seek to the next directory of an open directory
F_DIRREAD       JML IF_DIRREAD      ; Read the directory entry for the specified file
F_DIRWRITE      JML IF_DIRWRITE     ; Write any changes in the current directory cluster back to the drive
F_LOAD          JML IF_LOAD         ; load a binary file into memory, supports multiple file formats
F_SAVE          JML IF_SAVE         ; Save memory to a binary file
CMDBLOCK        JML ICMDBLOCK       ; Send a command to a block device
F_RUN           JML IF_RUN          ; Load an run a binary file
F_MOUNT         JML DOS_MOUNT       ; Mount the designated block device

SETSIZES        JML ISETSIZES       ; Set the size information in the kernel's text screen routines based on the screen configuration

F_COPY          JML IF_COPY         ; Copy a file
F_ALLOCFD       JML IF_ALLOCFD      ; Allocate a file descriptor
F_FREEFD        JML IF_FREEFD       ; Free a file descriptor

TESTBREAK       JML KBD_TEST_BREAK  ; Check if BREAK was pressed recently by the user (C is set if true, clear if false)
SETTABLE        JML KBD_SETTABLE    ; Set the keyboard scan code -> character translation tables (B:X points to the new tables)
READVRAM        JML IREADVRAM       ; Read a byte from video RAM at B:X
SETHANDLER      JML ISETHANDLER     ; Set the handler for the interrupt # in A to the FAR routine at Y:X
DELAY           JML IDELAY          ; Wait at least Y:X ticks of the system clock.
IP_INIT         JML kernel.net.user.init        ; Initialize the network stack; B:Y->ip_info
UDP_SEND        JML kernel.net.user.udp_send    ; Send a UDP packet; 0:X->udp_info
UDP_RECV        JML kernel.net.user.udp_recv    ; Recv a UDP packet; 0:X->udp_info
.here

;
; Interrupt Vector Table... after a small gap to leave some room to expand for the kernel
;

* = START_OF_FLASH + $001700
.logical $001700
VEC_INT_START = *                           ; Label for the start of the IRQ vectors

VEC_INT00_SOF   JML FDC_TIME_HANDLE         ; IRQ 0, 0 --- Start Of Frame interrupt 
VEC_INT01_SOL   JML IRQHANDLESTUB           ; IRQ 0, 1 --- Start Of Line interrupt
VEC_INT02_TMR0  JML IRQHANDLESTUB           ; IRQ 0, 2 --- Timer 0 interrupt
VEC_INT03_TMR1  JML IRQHANDLESTUB           ; IRQ 0, 3 --- Timer 1 interrupt
VEC_INT04_TMR2  JML IRQHANDLESTUB           ; IRQ 0, 4 --- Timer 2 interrupt
VEC_INT05_RTC   JML IRQHANDLESTUB           ; IRQ 0, 5 --- Real Time Clock interrupt
VEC_INT06_FDC   JML IRQHANDLESTUB           ; IRQ 0, 6 --- Floppy Drive Controller interrupt
VEC_INT07_MOUSE JML MOUSE_INTERRUPT         ; IRQ 0, 7 --- Mouse interrupt

VEC_INT10_KBD   JML KBD_PROCESS_BYTE        ; IRQ 1, 0 --- Keyboard interrupt
VEC_INT11_COL0  JML IRQHANDLESTUB           ; IRQ 1, 1 --- VICKY_II (INT2) Sprite Collision 
VEC_INT12_COL1  JML IRQHANDLESTUB           ; IRQ 1, 2 --- VICKY_II (INT3) Bitmap Collision
VEC_INT13_COM2  JML IRQHANDLESTUB           ; IRQ 1, 3 --- Serial port #2 interrupt
VEC_INT14_COM1  JML IRQHANDLESTUB           ; IRQ 1, 4 --- Serial port #1 interrupt
VEC_INT15_MIDI  JML IRQHANDLESTUB           ; IRQ 1, 5 --- MIDI controller interrupt
VEC_INT16_LPT   JML IRQHANDLESTUB           ; IRQ 1, 6 --- Parallel port interrupt
VEC_INT17_SDC   JML IRQHANDLESTUB           ; IRQ 1, 7 --- SD Card Controller interrupt (CH376S???)

VEC_INT20_OPL   JML IRQHANDLESTUB           ; IRQ 2, 0 --- OPL3
VEC_INT21_GABE0 JML IRQHANDLESTUB           ; IRQ 2, 1 --- GABE (INT0) - TBD
VEC_INT22_GABE1 JML IRQHANDLESTUB           ; IRQ 2, 2 --- GABE (INT1) - TBD
VEC_INT23_VDMA  JML IRQHANDLESTUB           ; IRQ 2, 3 --- VICKY_II (INT4) - VDMA Interrupt
VEC_INT24_COL2  JML IRQHANDLESTUB           ; IRQ 2, 4 --- VICKY_II (INT5) Tile Collision
VEC_INT25_GABE2 JML IRQHANDLESTUB           ; IRQ 2, 5 --- GABE (INT2) - TBD
VEC_INT26_EXT   JML IRQHANDLESTUB           ; IRQ 2, 6 --- External Expansion
VEC_INT17_SDINS JML IRQHANDLESTUB           ; IRQ 2, 7 --- SDCARD Insertion

VEC_INT30_OPN2  JML IRQHANDLESTUB           ; IRQ 3, 0 --- OPN2
VEC_INT31_OPM   JML IRQHANDLESTUB           ; IRQ 3, 1 --- OPM
VEC_INT32_IDE   JML IRQHANDLESTUB           ; IRQ 3, 2 --- HDD IDE Interrupt
.here

;
; End of jump tables
;
