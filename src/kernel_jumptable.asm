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
SETLFS          JML ISETLFS
SETNAM          JML ISETNAM
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
TESTSID         JML ITESTSID
INITCURSOR      JML IINITCURSOR
INITFONTSET     JML IINITFONTSET
INITGAMMATABLE  JML IINITGAMMATABLE
INITALLLUT      JML IINITALLLUT
INITVKYTXTMODE  JML IINITVKYTXTMODE
INITVKYGRPMODE  JML IINITVKYGRPMODE
INITTILEMODE    JML IINITTILEMODE
INITSPRITE      JML IINITSPRITE
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

SETSIZES        JML ISETSIZES

F_COPY          JML IF_COPY         ; Copy a file
F_ALLOCFD       JML IF_ALLOCFD      ; Allocate a file descriptor
F_FREEFD        JML IF_FREEFD       ; Free a file descriptor
.here

;
; Interrupt Vector Table... after a small gap to leave some room to expand for the kernel
;

* = START_OF_FLASH + $001700
.logical $001700
VEC_INT00_SOF   JML FDC_TIME_HANDLE ; IRQ 0, 0 --- Start Of Frame interrupt 
VEC_INT01_SOL   JML IRQHANDLESTUB   ; IRQ 0, 1 --- Start Of Line interrupt
VEC_INT02_TMR0  JML IRQHANDLESTUB   ; IRQ 0, 2 --- Timer 0 interrupt
VEC_INT03_TMR1  JML IRQHANDLESTUB   ; IRQ 0, 3 --- Timer 1 interrupt
VEC_INT04_TMR2  JML IRQHANDLESTUB   ; IRQ 0, 4 --- Timer 2 interrupt
.here

;
; End of jump tables
;
