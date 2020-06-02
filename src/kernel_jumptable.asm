;
; Kernel jump table
; This includes all of the externally callable routines and forwards those to their internal
; addresses in the Foenix ROM.
;
; As new routines are added, please add a reference here. The correct procedure is to
; update the memory map spreadsheet, then copy and paste the ;Kernel.asm columns here
; and ;Kernel_INC.asm column to that file.
;
; Naming convention:
; Common kernel I/O routines do NOT get a prefix
; BASIC routines start with B
; MONITOR routines start with M
; The actual routine in ROM should have I in front.
;
; So the BASIC PRINT routine would be labeled "BPRINT" on the jump table and "IBPRINT" in the BASIC.ASM
; source file.
;
* = $381000

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
SETSIZES        JML ISETSIZES

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









;
; End of jump table
;
