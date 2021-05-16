; page_00.asm
; Direct Page Addresses
;
;* Addresses are the byte AFTER the block. Use this to confirm block locations and check for overlaps
BANK0_BEGIN      = $000000 ;Start of bank 0 and Direct page
TMPPTR1          = $000000 ; 4 byte temporary pointer
TMPPTR2          = $000004 ; 4 byte temporary pointer
KRNL_BOOT_MENU_K = $000008 ; Keyboard Tap in Boot Menu
OPL2_ADDY_PTR_LO = $000008 ; THis Points towards the Instruments Database
OPL2_ADDY_PTR_MD = $000009
OPL2_ADDY_PTR_HI = $00000A ;
SCREENBEGIN      = $00000C ;3 Bytes Start of screen in video RAM. This is the upper-left corrner of the current video page being written to. This may not be what's being displayed by VICKY. Update this if you change VICKY's display page.
COLS_VISIBLE     = $00000F ;2 Bytes Columns visible per screen line. A virtual line can be longer than displayed, up to COLS_PER_LINE long. Default = 80
COLS_PER_LINE    = $000011 ;2 Bytes Columns in memory per screen line. A virtual line can be this long. Default=128
LINES_VISIBLE    = $000013 ;2 Bytes The number of rows visible on the screen. Default=25
LINES_MAX        = $000015 ;2 Bytes The number of rows in memory for the screen. Default=64
CURSORPOS        = $000017 ;3 Bytes The next character written to the screen will be written in this location.
CURSORX          = $00001A ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
CURSORY          = $00001C ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
CURCOLOR         = $00001E ;1 Byte Color of next character to be printed to the screen.
COLORPOS         = $00001F ;3 Byte address of cursor's position in the color matrix
COLORBEGIN       = $000022 ;3 Byte, address of the color screen
STACKBOT         = $000022 ;2 Bytes Lowest location the stack should be allowed to write to. If SP falls below this value, the runtime should generate STACK OVERFLOW error and abort.
STACKTOP         = $000024 ;2 Bytes Highest location the stack can occupy. If SP goes above this value, the runtime should generate STACK OVERFLOW error and abort.
; OPL2 Library Variable (Can be shared if Library is not used)
; THis will need to move eventually
OPL2_OPERATOR    = $000026 ;
OPL2_CHANNEL     = $000027 ;
OPL2_REG_REGION  = $000028 ; Offset to the Group of Registers
OPL2_REG_OFFSET  = $00002A ; 2 Bytes (16Bits)
OPL2_IND_ADDY_LL = $00002C ; 2 Bytes Reserved (Only need 3)
OPL2_IND_ADDY_HL = $00002E ; 2 Bytes Reserved (Only need 3)
OPL2_NOTE        = $000030 ; 1 Byte
OPL2_OCTAVE      = $000031 ; 1 Byte
OPL2_PARAMETER0  = $000032 ; 1 Byte - Key On/Feedback
OPL2_PARAMETER1  = $000033 ; 1 Byte
OPL2_PARAMETER2  = $000034 ; 1 Byte
OPL2_PARAMETER3  = $000035 ; 1 Byte
OPL2_LOOP        = $000036 ;
OPL2_BLOCK       = $000036
; SD Card (CH376S) Variables
SDCARD_FILE_PTR  = $000038 ; 3 Bytes Pointer to Filename to open
SDCARD_BYTE_NUM  = $00003C ; 2Bytes
SDCARD_PRSNT_MNT = $00003F ; 1 Byte, Indicate that the SDCard is Present and that it is Mounted

; Bitmap Clear Routine
BM_CLEAR_SCRN_X  = $000040
BM_CLEAR_SCRN_Y  = $000042
; RAD File Player
RAD_STARTLINE    = $000040 ; 1 Byte
RAD_PATTERN_IDX  = $000041 ; 1 Byte
RAD_LINE         = $000042 ; 1 Byte
RAD_LINENUMBER   = $000043 ; 1 Byte
RAD_CHANNEL_NUM  = $000044 ; 1 Byte
RAD_ISLASTCHAN   = $000045 ; 1 Byte
RAD_Y_POINTER    = $000046 ; 2 Bytes
RAD_TICK         = $000048
RAD_CHANNEL_DATA = $00004A ; 2 Bytes
RAD_CHANNE_EFFCT = $00004C
RAD_TEMP         = $00004D

RAD_ADDR         = $000050 ; 3 bytes to avoid OPL2 errors.
RAD_PATTRN       = $000053 ; 1 bytes - offset to patter
RAD_PTN_DEST     = $000054 ; 3 bytes - where to write the pattern data
RAD_CHANNEL      = $000057 ; 2 bytes - 0 to 8 
RAD_LAST_NOTE    = $000059 ; 1 if this is the last note
RAD_LINE_PTR     = $00005A ; 2 bytes - offset to memory location

; BMP File Parser Variables (Can be shared if BMP Parser not used)
; Used for Command Parser Mainly
BMP_X_SIZE       = $000040 ; 2 Bytes
BMP_Y_SIZE       = $000042 ; 2 Bytes
BMP_PRSE_SRC_PTR = $000044 ; 3 Bytes
BMP_PRSE_DST_PTR = $000048 ; 3 Bytes
BMP_COLOR_PALET  = $00004C ; 2 Bytes
SCRN_X_STRIDE    = $00004E ; 2 Bytes, Basically How many Pixel Accross in Bitmap Mode
BMP_FILE_SIZE    = $000050 ; 4 Bytes
BMP_POSITION_X   = $000054 ; 2 Bytes Where, the BMP will be position on the X Axis
BMP_POSITION_Y   = $000056 ; 2 Bytes Where, the BMP will be position on the Y Axis
BMP_PALET_CHOICE = $000058 ;

; EVID Kernel Variables

EVID_SCREENBEGIN      = $000060 ;3 Bytes Start of screen in video RAM. This is the upper-left corrner of the current video page being written to. This may not be what's being displayed by VICKY. Update this if you change VICKY's display page.
EVID_COLS_VISIBLE     = $000063 ;2 Bytes Columns visible per screen line. A virtual line can be longer than displayed, up to COLS_PER_LINE long. Default = 80
EVID_COLS_PER_LINE    = $000065 ;2 Bytes Columns in memory per screen line. A virtual line can be this long. Default=128
EVID_LINES_VISIBLE    = $000067 ;2 Bytes The number of rows visible on the screen. Default=25
EVID_LINES_MAX        = $000069 ;2 Bytes The number of rows in memory for the screen. Default=64
EVID_CURSORPOS        = $00006B ;3 Bytes The next character written to the screen will be written in this location.
EVID_CURSORX          = $00006E ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
EVID_CURSORY          = $000070 ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
EVID_CURCOLOR         = $000072 ;1 Byte Color of next character to be printed to the screen.
EVID_COLORBEGIN       = $000073 ;
EVID_COLORPOS         = $000076 ;3 Byte address of cursor's position in the color matrix
EVID_TMPPTR1          = $000079 ; 4 byte temporary pointer
EVID_PRESENT          = $00007D ;1 Byte: is the EVID present?

;
; Boot screen variables... can probably be reused...
;

TEXT_SRC_PTR_L   = $000098
TEXT_SRC_PTR_H   = $00009A
TEXT_DST_PTR_L   = $00009C
TEXT_DST_PTR_H   = $00009E

TEXT_INDEX       = $0000A0

MOD_SELECT_L     = $0000A0
MOD_SELECT_H     = $0000A2

TEXT_CURSOR_X    = $0000A2
TEXT_CURSOR_Y    = $0000A4
LINE_INDEX       = $0000A6

COLOR_DST_PTR_L  = $0000A8
COLOR_DST_PTR_H  = $0000AA

MODEL            = $0000B0

;
; Mouse variables
;

MOUSE_IDX        = $0000E0
MOUSE_POS_X_LO   = $0000E1
MOUSE_POS_X_HI   = $0000E2
MOUSE_POS_Y_LO   = $0000E3
MOUSE_POS_Y_HI   = $0000E4
MOUSE_BUTTONS    = $0000E6

USER_TEMP        = $0000F0 ;32 Bytes Temp space for user programs

;
; Boot menu variables -- Used only by the boot menu, so placed at $0000F0, which is scratch storage
;

INTERRUPT_STATE  = $0000F0      ; 1 byte: current state of the boot menu color cycler
INTERRUPT_COUNT  = $0000F1      ; 1 byte: counter for the boot menu color cycler
IRQ_COLOR_CHOICE = $0000F2      ; 1 byte: index of the color to cycle in the boot menu

;;///////////////////////////////////////////////////////////////
;;; NO CODE or Variable ought to be Instantiated in this REGION
;; BEGIN
;;///////////////////////////////////////////////////////////////
GAVIN_BLOCK      = $000100 ;256 Bytes Gavin reserved, overlaps debugging registers at $1F0

; Reserved
INT_CONTROLLER   = $000140 ; $000140...$00015F Interrupt Controller

TIMER_CONTROLLER = $000160 ; $000160...$00017F Timer0/Timer1/Timer2 Block
TIMER_CTRL_REGLL = $000160 ;
TIMER_CTRL_REGLH = $000161 ;
TIMER_CTRL_REGHL = $000162 ;
TIMER_CTRL_REGHH = $000163 ;
;;///////////////////////////////////////////////////////////////
;;; NO CODE or Variable ought to be Instatied in this REGION
;; END
;;///////////////////////////////////////////////////////////////


CPU_REGISTERS    = $000240 ; Byte
CPUPC            = $000240 ;2 Bytes Program Counter (PC)
CPUPBR           = $000242 ;2 Bytes Program Bank Register (K)
CPUA             = $000244 ;2 Bytes Accumulator (A)
CPUX             = $000246 ;2 Bytes X Register (X)
CPUY             = $000248 ;2 Bytes Y Register (Y)
CPUSTACK         = $00024A ;2 Bytes Stack Pointer (S)
CPUDP            = $00024C ;2 Bytes Direct Page Register (D)
CPUDBR           = $00024E ;1 Byte  Data Bank Register (B)
CPUFLAGS         = $00024F ;1 Byte  Flags (P)

MONITOR_VARS     = $000250 ; Byte  MONITOR Variables. BASIC variables may overlap this space
MCMDADDR         = $000250 ;3 Bytes Address of the current line of text being processed by the command parser. Can be in display memory or a variable in memory. MONITOR will parse up to MTEXTLEN characters or to a null character.
MCMP_TEXT        = $000253 ;3 Bytes Address of symbol being evaluated for COMPARE routine
MCMP_LEN         = $000256 ;2 Bytes Length of symbol being evaluated for COMPARE routine
MCMD             = $000258 ;3 Bytes Address of the current command/function string
MCMD_LEN         = $00025B ;2 Bytes Length of the current command/function string
MARG1            = $00025D ;4 Bytes First command argument. May be data or address, depending on command
MARG2            = $000261 ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG3            = $000265 ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG4            = $000269 ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG5            = $00026D ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG6            = $000271 ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG7            = $000275 ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG8            = $000279 ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.

LOADFILE_VARS    = $000300 ; Byte
LOADFILE_NAME    = $000300 ;3 Bytes (addr) Name of file to load. Address in Data Page
LOADFILE_LEN     = $000303 ;1 Byte  Length of filename. 0=Null Terminated
LOADPBR          = $000304 ;1 Byte  First Program Bank of loaded file ($05 segment)
LOADPC           = $000305 ;2 Bytes Start address of loaded file ($05 segment)
LOADDBR          = $000307 ;1 Byte  First data bank of loaded file ($06 segment)
LOADADDR         = $000308 ;2 Bytes FIrst data address of loaded file ($06 segment)
LOADFILE_TYPE    = $00030A ;3 Bytes (addr) File type string in loaded data file. Actual string data will be in Bank 1. Valid values are BIN, PRG, P16
BLOCK_LEN        = $00030D ;2 Bytes Length of block being loaded
BLOCK_ADDR       = $00030F ;2 Bytes (temp) Address of block being loaded
BLOCK_BANK       = $000311 ;1 Byte  (temp) Bank of block being loaded
BLOCK_COUNT      = $000312 ;2 Bytes (temp) Counter of bytes read as file is loaded

; Floppy drive code variables
FDC_DRIVE        = $000300 ;1 byte - The number of the selected drive
FDC_HEAD         = $000301 ;1 byte - The head number (0 or 1)
FDC_CYLINDER     = $000302 ;1 byte - The cylinder number
FDC_SECTOR       = $000303 ;1 byte - The sector number
FDC_SECTOR_SIZE  = $000304 ;1 byte - The sector size code (2 = 512)
FDC_SECPERTRK    = $000305 ;1 byte - The number of sectors per track (18 for 1.44 MB floppy)
FDC_ST0          = $000306 ;1 byte - Status Register 0
FDC_ST1          = $000307 ;1 byte - Status Register 1
FDC_ST2          = $000308 ;1 byte - Status Register 2
FDC_ST3          = $000309 ;1 byte - Status Register 3
FDC_PCN          = $00030A ;1 byte - Present Cylinder Number
FDC_STATUS       = $00030B ;1 byte - Status of what we think is going on with the FDC:
                           ;    $80 = motor is on

DIVIDEND         = $00030C ;4 bytes - Dividend for 32-bit division
DIVISOR          = $000310 ;4 bytes - Divisor for 32-bit division
REMAINDER        = $000314 ;4 bytes - Remainder for 32-bit division

; $00:0320 to $00:06FF - Reserved for block device access and FAT file system support

; Low-level (BIOS) sector access variables
SDOS_VARIABLES   = $000320
BIOS_STATUS      = $000320      ; 1 byte - Status of any BIOS operation
BIOS_DEV         = $000321      ; 1 byte - Block device number for block operations
BIOS_LBA         = $000322      ; 4 bytes - Address of block to read/write (this is the physical block, w/o reference to partition)
BIOS_BUFF_PTR    = $000326      ; 4 bytes - 24-bit pointer to memory for read/write operations
BIOS_FIFO_COUNT  = $00032A      ; 2 bytes - The number of bytes read on the last block read
BIOS_FLAGS       = $00032C      ; 1 byte - Flags for various BIOSy things:
                                ; $80 = time out flag: if set, a timeout has occurred (see ISETTIMEOUT)
BIOS_TIMER       = $00032D      ; 1 byte - the number of 1/60 ticks for a time out

; FAT (cluster level) access
DOS_STATUS       = $00032E      ; 1 byte - The error code describing any error with file access
DOS_CLUS_ID      = $000330      ; 4 bytes - The cluster desired for a DOS operation
DOS_DIR_PTR      = $000338      ; 4 bytes - Pointer to a directory entry (assumed to be within DOS_SECTOR)
DOS_BUFF_PTR     = $00033C      ; 4 bytes - A pointer for DOS cluster read/write operations
DOS_FD_PTR       = $000340      ; 4 bytes - A pointer to a file descriptor
DOS_FAT_LBA      = $000344      ; 4 bytes - The LBA for a sector of the FAT we need to read/write
DOS_TEMP         = $000348      ; 4 bytes - Temporary storage for DOS operations
DOS_FILE_SIZE    = $00034C      ; 4 bytes - The size of a file
DOS_SRC_PTR      = $000350      ; 4 bytes - Pointer for transferring data
DOS_DST_PTR      = $000354      ; 4 bytes - Pointer for transferring data
DOS_END_PTR      = $000358      ; 4 bytes - Pointer to the last byte to save
DOS_RUN_PTR      = $00035C      ; 4 bytes - Pointer for starting a loaded program
DOS_RUN_PARAM    = $000360      ; 4 bytes - Pointer to the ASCIIZ string for arguments in loading a program
DOS_STR1_PTR     = $000364      ; 4 bytes - pointer to a string
DOS_STR2_PTR     = $000368      ; 4 bytes - pointer to a string
DOS_SCRATCH      = $00036B      ; 4 bytes - general purpose short term storage
DOS_BLOCK_SIZE   = $000370      ; 4 bytes - the size of a block to load (in bytes)

DOS_PATH_BUFF    = $000400      ; 256 bytes - A buffer for path names

FDC_PARAMETERS   = $000500      ; 16 bytes - a buffer of parameter data for the FDC
FDC_RESULTS      = $000510      ; 16 bytes - Buffer for results of FDC commands
FDC_PARAM_NUM    = $000530      ; 1 byte - The number of parameters to send to the FDC (including command)
FDC_RESULT_NUM   = $000532      ; 1 byte - The number of results expected
FDC_EXPECT_DAT   = $000533      ; 1 byte - 0 = the command expects no data, otherwise expects data
FDC_CMD_RETRY    = $000534      ; 1 byte - a retry counter for commands

;
; Channel, UART variables, and Timer
;
CURRUART         = $000700 ; 3-bytes: the base address of the current UART
CHAN_OUT         = $000703 ; 1-byte: the number of the current output channel (for PUTC, etc.)
CHAN_IN          = $000704 ; 1-byte: the number of the current input channel (for GETCH, etc.)
TIMERFLAGS       = $000705 ; 1-byte: flags to indicate that one of the timer interupts has triggered
TIMER0TRIGGER    = $80
TIMER1TRIGGER    = $40
TIMER2TRIGGER    = $20

KBD_VARS = $000F00
KBD_STATE           = $000F00   ; 1 byte - The state of the keyboard controller state machine
KBD_SC_BUF          = $000F01   ; 16 bytes - Buffer for keyboard scancodes read
KBD_SC_HEAD         = $000F11   ; 1 byte - Index of the first scancode cell to write to
KBD_CHAR_BUF        = $000F12   ; 16 bytes - Character buffer
KBD_CHAR_HEAD       = $000F22   ; 1 byte - Number of characters in the character buffer
KBD_MODIFIERS       = $000F23   ; 1 byte - State of the modifier keys
KBD_LOCKS           = $000F24   ; 1 byte - State of the lock keys: Caps, Num, Scroll
KBD_TBL_UNMOD       = $000F25   ; 4 bytes - Pointer to the scan code translation table for unmodified keys
KBD_TBL_SHIFT       = $000F29   ; 4 bytes - Pointer to the scan code translation table for shifted keys
KBD_TBL_CTRL        = $000F2D   ; 4 bytes - Pointer to the scan code translation table for keys modified by CTRL
KBD_TBL_LOCK        = $000F31   ; 4 bytes - Pointer to the scan code translation table for keys modified by CAPSLOCK or NUMLOCK
KBD_TBL_LOCK_SHIFT  = $000F35   ; 4 bytes - Pointer to the scan code translation table for keys modified by CAPSLOCK and SHIFT
KBD_TBL_CTRL_SHIFT  = $000F39   ; 4 bytes - Pointer to the scan code translation table for keys modified by CTRL and SHIFT

; COMMAND PARSER Variables
; Command Parser Stuff between $000F00 -> $000F84 (see CMD_Parser.asm)
KEY_BUFFER       = $000F00 ; 64 Bytes keyboard buffer
KEY_BUFFER_SIZE  = $0080   ;128 Bytes (constant) keyboard buffer length
KEY_BUFFER_END   = $000F7F ;  1 Byte  Last byte of keyboard buffer
KEY_BUFFER_CMD   = $000F83 ;  1 Byte  Indicates the Command Process Status
COMMAND_SIZE_STR = $000F84 ;  1 Byte
COMMAND_COMP_TMP = $000F86 ;  2 Bytes
KEYBOARD_SC_FLG  = $000F87 ;  1 Bytes that indicate the Status of Left Shift, Left CTRL, Left ALT, Right Shift
KEYBOARD_SC_TMP  = $000F88 ;  1 Byte, Interrupt Save Scan Code while Processing
KEYBOARD_LOCKS   = $000F89 ;  1 Byte, the status of the various lock keys
KEYFLAG          = $000F8A ;  1 Byte, flag to indicate if CTRL-C has been pressed
KEY_BUFFER_RPOS  = $000F8B ;  2 Byte, position of the character to read from the KEY_BUFFER
KEY_BUFFER_WPOS  = $000F8D ;  2 Byte, position of the character to write to the KEY_BUFFER

KERNEL_JMP_BEGIN = $001000 ; Reserved for the Kernel jump table
KERNEL_JMP_END   = $001FFF

TEST_BEGIN       = $002000 ;28672 Bytes Test/diagnostic code for prototype.
TEST_END         = $007FFF ;0 Byte

STACK_BEGIN      = $008000 ;32512 Bytes The default beginning of stack space
STACK_END        = $00FEFF ;0 Byte  End of stack space. Everything below this is I/O space

.if TARGET = TARGET_RAM
    ISR_BEGIN        = $00FF00 ; Byte  Beginning of CPU vectors in Direct page
    HRESET           = $00FF00 ;16 Bytes Handle RESET asserted. Reboot computer and re-initialize the kernel.
    HCOP             = $00FF10 ;16 Bytes Handle the COP instruction. Program use; not used by OS
    HBRK             = $00FF20 ;16 Bytes Handle the BRK instruction. Returns to BASIC Ready prompt.
    HABORT           = $00FF30 ;16 Bytes Handle ABORT asserted. Return to Ready prompt with an error message.
    HNMI             = $00FF40 ;32 Bytes Handle NMI
    HIRQ             = $00FF60 ;32 Bytes Handle IRQ
    Unused_FF80      = $00FF80 ;End of direct page Interrrupt handlers
    VECTORS_BEGIN    = $00FFE0 ;0 Byte  Interrupt vectors
    JMP_READY        = $00FFE0 ;4 Bytes Jumps to ROM READY routine. Modified whenever alternate command interpreter is loaded.
    VECTOR_COP       = $00FFE4 ;2 Bytes Native COP Interrupt vector
    VECTOR_BRK       = $00FFE6 ;2 Bytes Native BRK Interrupt vector
    VECTOR_ABORT     = $00FFE8 ;2 Bytes Native ABORT Interrupt vector
    VECTOR_NMI       = $00FFEA ;2 Bytes Native NMI Interrupt vector
    VECTOR_RESET     = $00FFEC ;2 Bytes Unused (Native RESET vector)
    VECTOR_IRQ       = $00FFEE ;2 Bytes Native IRQ Vector
    RETURN           = $00FFF0 ;4 Bytes RETURN key handler. Points to BASIC or MONITOR subroutine to execute when RETURN is pressed.
    VECTOR_ECOP      = $00FFF4 ;2 Bytes Emulation mode interrupt handler
    VECTOR_EBRK      = $00FFF6 ;2 Bytes Emulation mode interrupt handler
    VECTOR_EABORT    = $00FFF8 ;2 Bytes Emulation mode interrupt handler
    VECTOR_ENMI      = $00FFFA ;2 Bytes Emulation mode interrupt handler
    VECTOR_ERESET    = $00FFFC ;2 Bytes Emulation mode interrupt handler
    VECTOR_EIRQ      = $00FFFE ;2 Bytes Emulation mode interrupt handler
    VECTORS_END      = $010000 ;*End of vector space
.elsif TARGET = TARGET_FLASH
	.if ( TARGET_SYS == SYS_C256_FMX ) || ( TARGET_SYS == SYS_C256_U_PLUS )
        ISR_BEGIN        = $38FF00 ; Byte  Beginning of CPU vectors in Direct page
        HRESET           = $38FF00 ;16 Bytes Handle RESET asserted. Reboot computer and re-initialize the kernel.
        HCOP             = $38FF10 ;16 Bytes Handle the COP instruction. Program use; not used by OS
        HBRK             = $38FF20 ;16 Bytes Handle the BRK instruction. Returns to BASIC Ready prompt.
        HABORT           = $38FF30 ;16 Bytes Handle ABORT asserted. Return to Ready prompt with an error message.
        HNMI             = $38FF40 ;32 Bytes Handle NMI
        HIRQ             = $38FF60 ;32 Bytes Handle IRQ
        Unused_FF80      = $38FF80 ;End of direct page Interrrupt handlers

        VECTORS_BEGIN    = $38FFE0 ;0 Byte  Interrupt vectors
        JMP_READY        = $38FFE0 ;4 Bytes Jumps to ROM READY routine. Modified whenever alternate command interpreter is loaded.
        VECTOR_COP       = $38FFE4 ;2 Bytes Native COP Interrupt vector
        VECTOR_BRK       = $38FFE6 ;2 Bytes Native BRK Interrupt vector
        VECTOR_ABORT     = $38FFE8 ;2 Bytes Native ABORT Interrupt vector
        VECTOR_NMI       = $38FFEA ;2 Bytes Native NMI Interrupt vector
        VECTOR_RESET     = $38FFEC ;2 Bytes Unused (Native RESET vector)
        VECTOR_IRQ       = $38FFEE ;2 Bytes Native IRQ Vector
        RETURN           = $38FFF0 ;4 Bytes RETURN key handler. Points to BASIC or MONITOR subroutine to execute when RETURN is pressed.
        VECTOR_ECOP      = $38FFF4 ;2 Bytes Emulation mode interrupt handler
        VECTOR_EBRK      = $38FFF6 ;2 Bytes Emulation mode interrupt handler
        VECTOR_EABORT    = $38FFF8 ;2 Bytes Emulation mode interrupt handler
        VECTOR_ENMI      = $38FFFA ;2 Bytes Emulation mode interrupt handler
        VECTOR_ERESET    = $38FFFC ;2 Bytes Emulation mode interrupt handler
        VECTOR_EIRQ      = $38FFFE ;2 Bytes Emulation mode interrupt handler
        VECTORS_END      = $400000 ;*End of vector space    
    .else
        ISR_BEGIN        = $18FF00 ; Byte  Beginning of CPU vectors in Direct page
        HRESET           = $18FF00 ;16 Bytes Handle RESET asserted. Reboot computer and re-initialize the kernel.
        HCOP             = $18FF10 ;16 Bytes Handle the COP instruction. Program use; not used by OS
        HBRK             = $18FF20 ;16 Bytes Handle the BRK instruction. Returns to BASIC Ready prompt.
        HABORT           = $18FF30 ;16 Bytes Handle ABORT asserted. Return to Ready prompt with an error message.
        HNMI             = $18FF40 ;32 Bytes Handle NMI
        HIRQ             = $18FF60 ;32 Bytes Handle IRQ
        Unused_FF80      = $18FF80 ;End of direct page Interrrupt handlers

        VECTORS_BEGIN    = $18FFE0 ;0 Byte  Interrupt vectors
        JMP_READY        = $18FFE0 ;4 Bytes Jumps to ROM READY routine. Modified whenever alternate command interpreter is loaded.
        VECTOR_COP       = $18FFE4 ;2 Bytes Native COP Interrupt vector
        VECTOR_BRK       = $18FFE6 ;2 Bytes Native BRK Interrupt vector
        VECTOR_ABORT     = $18FFE8 ;2 Bytes Native ABORT Interrupt vector
        VECTOR_NMI       = $18FFEA ;2 Bytes Native NMI Interrupt vector
        VECTOR_RESET     = $18FFEC ;2 Bytes Unused (Native RESET vector)
        VECTOR_IRQ       = $18FFEE ;2 Bytes Native IRQ Vector
        RETURN           = $18FFF0 ;4 Bytes RETURN key handler. Points to BASIC or MONITOR subroutine to execute when RETURN is pressed.
        VECTOR_ECOP      = $18FFF4 ;2 Bytes Emulation mode interrupt handler
        VECTOR_EBRK      = $18FFF6 ;2 Bytes Emulation mode interrupt handler
        VECTOR_EABORT    = $18FFF8 ;2 Bytes Emulation mode interrupt handler
        VECTOR_ENMI      = $18FFFA ;2 Bytes Emulation mode interrupt handler
        VECTOR_ERESET    = $18FFFC ;2 Bytes Emulation mode interrupt handler
        VECTOR_EIRQ      = $18FFFE ;2 Bytes Emulation mode interrupt handler
        VECTORS_END      = $200000 ;*End of vector space
    .endif
.endif

BANK0_END        = $00FFFF ;End of Bank 00 and Direct page
;
