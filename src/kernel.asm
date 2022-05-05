.cpu "65816"

TEST_KEYBOARD = 0 ; This is to enable the ScreenOutput
;
; Target system assembly directive IDs.
; These will be used by the assemble.bat command to specify what target is intended
; TARGET_SYS values. These will allow the kernel to be assembled properly for the
; Foenix FMX and Foenix User, which have different devices and memory layouts.
SYS_C256_FMX = 1                            ; The target system is the C256 Foenix FMX
SYS_C256_U = 2                              ; The target system is the C256 Foenix U With 2Megs of Code Memory
SYS_C256_U_PLUS = 3                         ; The target system is the C256 Foenix U With 4Megs of Code Memory
SYS_C256_GENX = 4                           ; The target system is the GenX

; TARGET values. These allow assemble.bat to generate either a BIN or a HEX file and
; set the location of some bank 0 data correctly.
TARGET_FLASH = 1                            ; The code is being assembled for Flash
TARGET_RAM = 2                              ; The code is being assembled for RAM

START_OF_FLASH := 0
START_OF_KERNEL := 0
START_OF_BASIC := 0
START_OF_CREDITS := 0
START_OF_SPLASH := 0
START_OF_FONT := 0

.if ( TARGET_SYS == SYS_C256_FMX ) || ( TARGET_SYS == SYS_C256_GENX ) ||  ( TARGET_SYS == SYS_C256_U_PLUS )
; Key memory areas for the Foenix FMX
  START_OF_FLASH := $380000                   ; The Foenix FMX Flash starts at $380000
  START_OF_KERNEL := $390400                  ; The kernel itself starts at $390400
  START_OF_BASIC := $3A0000                   ; The BASIC flash code starts at $3A0000
  START_OF_CREDITS := $3B0000                 ; The credits screen starts at $3B0000
  START_OF_SPLASH := $3E0000                  ; SplashScreen Code and Data $3E0000
  START_OF_FONT := $3F0000                    ; The font starts at $3F0000
.else
; Key memory areas for the Foenix User
  START_OF_FLASH := $180000                   ; The Foenix U Flash starts at $180000
  START_OF_KERNEL := $190400                  ; The kernel itself starts at $190400
  START_OF_BASIC := $1A0000                   ; The BASIC flash code starts at $1A0000
  START_OF_CREDITS := $1B0000                 ; The credits screen starts at $1B0000
  START_OF_SPLASH := $1E0000                  ; SplashScreen Code and Data $3E0000  
  START_OF_FONT := $1F0000                    ; The font starts at $3F0000
.endif
;
; Includes
;
.include "Includes/macros_inc.asm"
.include "Includes/characters.asm"                   ; Definition of special ASCII control codes
.include "Includes/simulator_inc.asm"
.include "Includes/page_00_inc.asm"
.include "Includes/page_00_data.asm"
.include "Includes/page_00_code.asm"
.include "Includes/dram_inc.asm"                     ; old Definition file that was supposed to be a Memory map
.include "Includes/fdc_inc.asm"                      ; Definitions for the floppy drive controller
.include "Includes/basic_inc.asm"                    ; Pointers into BASIC and the machine language monitor
;
; Others
;
.include "kernel_jumptable.asm"
.include "Interrupt_Handler.asm"                    ; Interrupt Handler Routines

;
; Defines
;
.include "Defines/Math_def.asm"                     ; Math Co_processor Definition
.include "Defines/timer_def.asm"                    ; Timer Block
.include "Defines/interrupt_def.asm"                ; Interrupr Controller Registers Definitions
.include "Defines/super_io_def.asm"                 ; SuperIO Registers Definitions
.include "Defines/keyboard_def.asm"                 ; Keyboard 8042 Controller (in SuperIO) bit Field definitions
.include "Defines/RTC_def.asm"                      ; Real-Time Clock Register Definition (BQ4802)
.include "Defines/io_def.asm"                       ; CODEC, SDCard Controller Registers
.include "Defines/Trinity_CFP9301_def.asm"          ; Definitions for Trinity chip: Joystick, DipSwitch
.include "Defines/Unity_CFP9307_def.asm"            ; Definitions for Unity chip (IDE)
.include "Defines/GABE_Control_Registers_def.asm"   ; Definitions for GABE registers
.include "Defines/SID_def.asm"
.include "Defines/VKYII_CFP9553_GENERAL_def.asm"    ; VICKY's registers Definitions
.include "Defines/VKYII_CFP9553_SDMA_def.asm"       ; SDMA
.include "Defines/VKYII_CFP9553_VDMA_def.asm"       ; VDMA
.include "Defines/VKYII_CFP9553_BITMAP_def.asm"     ; Bitmap
.include "Defines/VKYII_CFP9553_TILEMAP_def.asm"    ; Tiles
.include "Defines/VKYII_CFP9553_SPRITE_def.asm"     ; Sprite
.include "Defines/VKYII_CFP9553_COLLISION_def.asm"  ; Collision
.include "Defines/EXP_C100_ESID_def.asm"            ; EXP Ethernet/SID Combo
.include "Defines/EXP_C200_EVID_def.asm"            ; EXP Ethernet/Video Combo

; C256 Foenix Kernel
; The Kernel is located in flash @ F8:0000 but not accessible by CPU
; Kernel Transfered by GAVIN @ Cold Reset to $18:0000 - $1F:FFFF on the User version, $38:0000 - $3F:FFFF on the FMX



* = START_OF_KERNEL

IBOOT           ; boot the system
                CLC               ; clear the carry flag
                XCE               ; move carry to emulation flag.

                SEI               ; Disable interrupts

                setaxl
                LDA #STACK_END    ; initialize stack pointer
                TAS

                LDX #<>BOOT       ; Copy the kernel jump table to bank 0
                LDY #<>BOOT       ; Ordinarily, this is done by GAVIN, but
                LDA #$2000        ; this is ensures it can be reloaded in case of errors

.if ( TARGET_SYS == SYS_C256_FMX ) || ( TARGET_SYS == SYS_C256_GENX ) ||  ( TARGET_SYS == SYS_C256_U_PLUS )
                MVN $38,$00       ; Or during soft loading of the kernel from the debug port
.else
                MVN $18,$00       ; Or during soft loading of the kernel from the debug port
.endif
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

                JSL INITRTC               ; Initialize the RTC

                setas
                ; Here we check for Expansion Card and Init them soon in the process
                LDA @L GABE_SYS_STAT      ; Let's check the Presence of an Expansion Card here
                AND #GABE_SYS_STAT_EXP    ; When there is a Card the Value is 1
                CMP #GABE_SYS_STAT_EXP
                BNE SkipInitExpC100C200
                setal 
                LDA @L ESID_ID_CARD_ID_Lo    ; Load the Card ID and check for C100 or C200
                CMP #$0064
                BEQ InitC100ESID
                CMP #$00C8
                BNE SkipInitExpC100C200
                ; Let's Init the Ethernet First, it is short and Sweet
                ; This is just enabling the LEDs for when there is a cable Connected, we will see the
                ; EVID Here
                JSL SIMPLE_INIT_ETHERNET_CTRL
                JSL INIT_EVID_VID_MODE
                BRA SkipInitExpC100C200
                ; ESID INIT HERE
InitC100ESID:
                JSL SIMPLE_INIT_ETHERNET_CTRL
                ; There is nothing else to Init in the ESID 

SkipInitExpC100C200:                
                ; Shutdown the SN76489 before the CODEC enables all the channels

                setas
                setxl
                LDA #$9F              ; Channel 1 - Full Atteniation
                STA $AFF100
                LDA #$BF              ; Channel 2 - Full Atteniation
                STA $AFF100
                LDA #$DF              ; Channel 3 - No Atteniation
                STA $AFF100
                LDA #$FF              ; Channel 4 - No Atteniation
                STA $AFF100

                LDA #$70                  ; Set the default text color to dim white on black
                STA CURCOLOR              

                ; This is to force the DotClock Frequency to 25.175Mhz no matter what it is when it is reseted.
                LDA @l MASTER_CTRL_REG_H
                AND #$01
                CMP #$01
                BNE Alreadyin640480Mode

                ; Otherwise, we need to flip the bit once to get the PLL to go back to Zero
                LDA @L MASTER_CTRL_REG_H
                AND #$FC
                STA @L MASTER_CTRL_REG_H
                LDA @L MASTER_CTRL_REG_H
                ORA #$01
                STA @L MASTER_CTRL_REG_H

Alreadyin640480Mode     ; Make sure to turn off the Doubling Pixel As well.
                LDA @L MASTER_CTRL_REG_H
                AND #$FC
                STA @L MASTER_CTRL_REG_H ; Set it to 640x480 for real

                ; Set the default I/O devices to the screen and keyboard
                LDA #0
                JSL SETIN
                JSL SETOUT

                ; Initialize the ANSI screen driver
                JSL ANSI_INIT
                JSL SETSIZES

                ;Init CODEC
                JSL INITCODEC

                ; Init Suprt IO (Keyboard/Floppy/Etc...)
.if (TARGET_SYS == SYS_C256_FMX) || (TARGET_SYS == SYS_C256_GENX)
                setaxl                
                JSL INITSUPERIO
.endif 
                ; Init GAMMA Table
                JSL INITGAMMATABLE
                
                ; Init All the Graphic Mode Look-up Table (by default they are all Zero)
                JSL INITALLLUT

                ; Initialize the Mouse Pointer Graphic
                JSL INITMOUSEPOINTER  
                
                ; Go Enable and Setup the Cursor's Position
                JSL INITCURSOR

.if (TARGET_SYS == SYS_C256_FMX) || (TARGET_SYS == SYS_C256_GENX)
                ; Initialize the UARTs (SuperIO UART)
                LDA #CHAN_COM1    ; Initialize COM1
                JSL UART_SELECT
                JSL UART_INIT
                LDA #CHAN_COM2    ; Initialize COM2
                JSL UART_SELECT
                JSL UART_INIT
.endif

                setal
                setdp 0
                JSL INITKEYBOARD        ; Initialize the keyboard
                JSL INITMOUSE           ; Initialize the mouse

                CLI

                LDA #0
                STA @w MOUSE_IDX
                 
                setas
                setxl
                setdbr `greet_msg     ; set data bank to 39 (Kernel Variables)

                ; Copy the jump table from the "pristine" copy that came from flahs
                ; down to the working copy in bank 0.
                LDX #0
jmpcopy         LDA @l BOOT,X
                STA @l $001000,X
                INX
                CPX #$1000
                BNE jmpcopy
retry_boot
                JSL DOS_INIT            ; Initialize the "disc operating system"
                JSL BOOT_SOUND          ; Play the boot sound
                JSL BOOT_MENU           ; Show the splash screen / boot menu and wait for key presses
                                        ; Coming back from the Splash Screen the Value of the Keyboard has been pushed in the stack
                                        ; This is the balance of House Keeping that needs to be done to put it back the way it was
                                     
                ; Now, clear the screen and Setup Foreground/Background Bytes, so we can see the Text on screen

                JSL CLRSCREEN           ; Clear Screen and Set a standard color in Color Memory
                JSL CSRHOME             ; Move to the home position

greet           setaxl
                setdbr `greet_msg       ; Set data bank to ROM
                LDX #<>greet_msg
                JSL IPRINT              ; print the first line           
                JSL ICOLORFLAG          ; This is to set the color memory for the text logo
                JSL EVID_GREET          ; Print the EVID greeting, if the EVID card is installed

                ; Set up the stack

                setaxl 
                LDA #STACK_END          ; We are the root, let's make sure from now on, that we start clean
                TAS

                ; Init Global Look-up Table
                ; Moved the DOS Init after the FLashing Moniker Display

                setas
                setxl
                LDA @l KRNL_BOOT_MENU_K ; Get the Value of the Keyboard Boot Choice
                CMP #SCAN_SP          ; Did the user press SPACE?
                BEQ BOOT_DIP          ; Yes: boot via the DIP switches

                CMP #SCAN_CR          ; Did the user press RETURN?
                BEQ BOOTBASIC         ; Yes: go straight to BASIC

                CMP #CHAR_F1          ; Did the user press F1?
                BEQ BOOTFLOPPY        ; Yes: boot via the floppy

                CMP #CHAR_F2          ; Did the user press F2?
                BEQ BOOTSDC           ; Yes: boot via the SDC

                CMP #CHAR_F3          ; Did the user press F3?
                BEQ BOOTIDE           ; Yes: boot via the IDE

                ;
                ; Determine the boot mode on the DIP switches and complete booting as specified
                ;
BOOT_DIP        LDA @lDIP_BOOTMODE    ; {HD_INSTALLED, 5'b0_0000, BOOT_MODE[1], BOOT_MODE[0]}
                AND #%00000011        ; Look at the mode bits
                CMP #DIP_BOOT_IDE     ; DIP set for IDE?
                BEQ BOOTIDE           ; Yes: Boot from the IDE

                CMP #DIP_BOOT_SDCARD  ; DIP set for SD card?
                BEQ BOOTSDC           ; Yes: try to boot from the SD card
                
                CMP #DIP_BOOT_FLOPPY  ; DIP set for floppy?
                BEQ BOOTFLOPPY        ; Yes: try to boot from the floppy

IRESTORE        ; For the moment, have RESTART just bring up BASIC

BOOTBASIC       JML BASIC             ; Cold start of the BASIC interpreter (or its replacement)

CREDIT_LOCK     NOP
                BRA CREDIT_LOCK

BOOTSDC         LDX #<>sdc_boot
                JSL IPRINT
                setas
                LDA #BIOS_DEV_SD
                STA @l BIOS_DEV
                JSL DOS_MOUNT         ; Mount the SDC
                BCC sdc_error         ; Print an error message if couldn't get anything
                JSL DOS_TESTBOOT      ; Try to boot from the SDC's MBR
                BRA BOOTBASIC         ; If we couldn't fall, into BASIC

sdc_error       LDX #<>sdc_err_boot   ; Print a message saying SD card booting is not implemented
                BRA PR_BOOT_ERROR

BOOTIDE         LDX #<>ide_boot
                JSL IPRINT
                
                setas
                LDA #BIOS_DEV_HD0
                STA @l BIOS_DEV
                JSL DOS_MOUNT         ; Mount the IDE drive
                BCC hdc_error         ; Print an error message if couldn't get anything
                JSL DOS_TESTBOOT      ; Try to boot from the IDE's MBR
                BRL BOOTBASIC         ; If we couldn't fall, into BASIC

hdc_error       LDX #<>ide_err_boot   ; Print a message saying SD card booting is not implemented
                BRA PR_BOOT_ERROR

BOOTFLOPPY      LDX #<>fdc_boot
                JSL IPRINT

                setas
                LDA #BIOS_DEV_FDC
                STA @l BIOS_DEV
                JSL FDC_MOUNT         ; Mount the floppy drive
                BCC fdc_error         ; Print an error message if couldn't get anything
                JSL DOS_TESTBOOT      ; Try to boot from the FDC's MBR
                BRL BOOTBASIC         ; If we couldn't, fall into BASIC

fdc_error       LDX #<>fdc_err_boot   ; Print a message saying SD card booting is not implemented

PR_BOOT_ERROR   JSL IPRINT            ; Print the error message in X

                LDX #<>boot_retry     ; Print the boot retry prompt
                JSL IPRINT

boot_wait_key   JSL IGETCHW           ; Wait for a keypress
                CMP #'R'              ; Was "R" pressed?
                BNE chk_r_lc
                BRL retry_boot        ; Yes: retry the boot sequence
chk_r_lc        CMP #'r'
                BNE chk_b_lc
                BRL retry_boot

chk_b_lc        CMP #'b'              ; Was "B" pressed?
                BNE chk_b_lc_not         ; Yes: try going to BASIC
                BRL BOOTBASIC
chk_b_lc_not:                
                CMP #'B'
                BNE chk_b_lc_not0
                BRL BOOTBASIC
chk_b_lc_not0:                
                BRA boot_wait_key     ; No: keep waiting

;
; Display the boot menu / splash screen and give the user some time to respond
;
; Outputs:
;   A = 0 for no response
;       CR for boot to BASIC
;       F1 for boot to floppy
;       F2 for boot to SDC
;       F3 for boot to IDE
;
; February 6th Changes, this is depracated till somebody decides that they don't like the SplashScreen Code ;)
; I will keep this in case
.comment
BOOT_MENU       .proc
                PHB
                PHP

                setas
                setxl
                LDA #`bootmenu          ; Point DBR:X to the boot menu
                PHA
                PLB
                LDX #<>bootmenu         

                JSL PUTS                ; Display the boot menu
                                        ; TODO: replace with the splash screen

                setxl
                LDY #1000               ; Number of cycles we'll wait... total wait time is about 30s (ish)

                setas
wait_key        LDX #100
                JSL ILOOP_MS            ; Wait ...
                DEY                     ; Count down the tenths of seconds
                BEQ timeout             ; If we've got to 0, we're done

                JSL GETSCANCODE         ; Try to get a character
                CMP #0                  ; Did we get anything
                BEQ wait_key            ; No: keep waiting until timeout

                CMP #CHAR_F1            ; Did the user press F1?
                BEQ return              ; Yes: return it
                CMP #CHAR_F2            ; Did the user press F2?
                BEQ return              ; Yes: return it
                CMP #CHAR_F3            ; Did the user press F3?
                BEQ return              ; Yes: return it
                CMP #SCAN_CR            ; Did the user press CR?
                BEQ return              ; Yes: return it
                CMP #SCAN_SP            ; Did the user press SPACE?
                BNE wait_key            ; No: keep waiting

timeout         LDA #0                  ; Return 0 for a timeout / SPACE

return          PLP
                PLB
                RTL

.if (TARGET_SYS == SYS_C256_FMX) || (TARGET_SYS == SYS_C256_GENX) 
  bootmenu        .null "F1=FDC, F2=SDC, F3=IDE, RETURN=BASIC, SPACE=DEFAULT", CHAR_CR
.else
  bootmenu        .null "F2=SDC, F3=IDE, RETURN=BASIC, SPACE=DEFAULT", CHAR_CR
.endif
                .pend
.endc

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
;       4 = EVID (if installed)
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
IGETCHE         JSL GETCHW
                JSL PUTC
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
                PHX
                PHY
                PHB
                PHD
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
                PLD
                PLB
                PLY
                PLX
                RTL

getc_uart       JSL UART_SELECT     ; Select the correct COM port
                JSL UART_GETC       ; Get the charater from the COM port
                BRA done            

getc_keyboard   JSL KBD_GETCW       ; Get the character from the keyboard
done            PLP
                CLC                 ; Return carry clear for valid data
                PLD
                PLB
                PLY
                PLX
                RTL
                .pend

;
; IGETCH
;
; Get a character from the input channel.
;
; Inputs:
;
; Outputs:
;   A = key pressed (0 for none)
;
IGETCH          .proc
                PHX
                PHY
                PHB
                PHD
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
                PLD
                PLB
                PLY
                PLX
                RTL

getc_uart       JSL UART_SELECT     ; Select the correct COM port
                JSL UART_GETC       ; Get the charater from the COM port
                BRA done            

getc_keyboard   JSL KBD_GETC        ; Get the character from the keyboard
done            PLP
                CLC                 ; Return carry clear for valid data
                PLD
                PLB
                PLY
                PLX
                RTL
                .pend

;
; IPRINT
; Print a string, followed by a carriage return
; DBR: bank containing string
; X: address of the string in data bank
; Modifies: X
;
IPRINT          JSL PUTS
                JSL PRINTCR
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
iputs2          JSL PUTC
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
                BEQ putc_ansi       ; If it's 0: print to the screen
                CMP #CHAN_EVID      ; Check to see if it's the second video port
                BEQ putc_ansi       ; Yes: handle printing to the second video port

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

putc_ansi       PLA                 ; Recover the character to send
                JSL ANSI_PUTC       ; Print to the current selected ANSI screen

done            PLP
                PLB
                PLD
                PLY
                PLX
                RTL
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

                CLC                 ; Calculate the length of the block to move
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
                LDA CURSORX         ; What column are we on
                INC A
                CMP COLS_VISIBLE    ; >= the # visible?
                BGE done            ; Yes: just skip the whole thing

                SEC                 ; Calculate the length of the block to move
                LDA COLS_VISIBLE
                SBC CURSORX
                INC A
                CLC
                ADC CURSORPOS       ; Add the current cursor position
                DEC A
                TAY                 ; Make it the destination
                DEC A               ; Move to the previous column
                TAX                 ; Make it the source              

                SEC                 ; Calculate the length of the block to move
                LDA COLS_VISIBLE    ; as columns visible - X
                SBC CURSORX

                MVP $AF, $AF        ; And move the block

                setas
                LDA #CHAR_SP        ; Put a blank space at the cursor position
                STA [CURSORPOS]

done            PLP
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
                PHB
                PHD
                PHP

                setdbr 0
                setdp 0

                setas
                setxl
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
                JSL PUTC
                LDA #CHAR_LF
                JSL PUTC
                BRA done

scr_printcr     LDX #0
                LDY CURSORY
                INY
                JSL LOCATE

done            PLP
                PLD
                PLB
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
                JSL LOCATE

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

                JSL ANSI_CSRRIGHT

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

                JSL ANSI_CSRLEFT

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

                JSL ANSI_CSRUP

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

                JSL ANSI_CSRDOWN

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

                JSL ANSI_LOCATE

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

                JSL ANSI_SCROLLUP

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

                LDA @lCPUA+1          ; Get nibble [15..12]
                .rept 4
                LSR A
                .next
                JSL iprint_digit      ; And print it
                LDA @lCPUA+1          ; Get nibble [11..8]
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

                JSL ANSI_CLRSCREEN

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

                JSL ANSI_INIT_LUTS

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
; Author: Stefany
; Init the Text Mode ByPass, this is to force 640x480 when booting so Splash can be always in 800x600
INITVKYTXTMODE_BYPASS_DPSW
                PHA 
                PHP 
                BRA WeNeed640480Here
                
; IINITVKYTXTMODE
; Author: Stefany
;Init the Text Mode
; Inputs:
;   None
; Affects:
;  Vicky's Internal Registers
IINITVKYTXTMODE 
                PHA
                PHP
                setas
                LDA @l GAMMA_CTRL_REG   ; Go Read the Hi-Res DIP Switch Value
                AND #HIRES_DP_SW_VAL    ; Isolate the Hi-Res Bit ($10) when 1 = 640x480, 0 = 800x600
                CMP #HIRES_DP_SW_VAL    ; When the Switch is off, the Returned value is 1 (The Pullup is there)
                BEQ WeNeed640480Here
                ; Now Here - We need 800x600 Text Mode (100x75)
                ; What mode are we in right now
                LDA @l MASTER_CTRL_REG_H
                AND #Mstr_Ctrl_Video_Mode0
                CMP #Mstr_Ctrl_Video_Mode0
                BEQ INITVICKYMODEHIRES       ; if we are already in 800x600 Skip to the rest of the Init
                ; Otherwise set Rodeo for 100x75 Text Mode
                LDA @L MASTER_CTRL_REG_H
                ORA #Mstr_Ctrl_Video_Mode0
                STA @L MASTER_CTRL_REG_H
                BRA INITVICKYMODEHIRES
                ; Make sure we're in 640x480 mode, this process is a bit of a work-around for a VICKY II quirk
                ; What follows is a piece of code to get the PLL in the FPGA to toggle the input channel to its original state
WeNeed640480Here:
                setas
                LDA @l MASTER_CTRL_REG_H
                AND #$01
                CMP #$01
                BNE INITVICKYMODE

                LDA #$00
                STA @L MASTER_CTRL_REG_H
                NOP
                NOP
                NOP
                NOP
                NOP

                LDA #$01
                STA @L MASTER_CTRL_REG_H
                NOP
                NOP
                NOP
                NOP

INITVICKYMODE
                LDA #$00
                STA @L MASTER_CTRL_REG_H ; Set it to 640x480 for real

INITVICKYMODEHIRES     
                LDA #Mstr_Ctrl_Text_Mode_En
                STA @L MASTER_CTRL_REG_L

           
                ; Set the Border Color
                setas
.if TARGET_SYS == SYS_C256_FMX                
                LDA #$20
                STA BORDER_COLOR_B
                STA BORDER_COLOR_R
                LDA #$00
                STA BORDER_COLOR_G
.elsif TARGET_SYS == SYS_C256_GENX 
                ; Light Purple
                LDA #$60
                STA BORDER_COLOR_R
                LDA #$1D
                STA BORDER_COLOR_G
                LDA #$99
                STA BORDER_COLOR_B

                ; Dark Orange
                ; LDA #$99
                ; STA BORDER_COLOR_R
                ; LDA #$34
                ; STA BORDER_COLOR_G
                ; LDA #$14
                ; STA BORDER_COLOR_B

                ; Burnt Orange
                ; LDA #$CC
                ; STA BORDER_COLOR_R
                ; LDA #$55
                ; STA BORDER_COLOR_G
                ; LDA #$00
                ; STA BORDER_COLOR_B
.else
                LDA #$00
                STA BORDER_COLOR_R
                LDA #$54
                STA BORDER_COLOR_G
                LDA #$54
                STA BORDER_COLOR_B
.endif

                LDA #Border_Ctrl_Enable           ; Enable the Border
                STA BORDER_CTRL_REG

                LDA #32                           ; Set the border to the standard 32 pixels
                STA BORDER_X_SIZE
                STA BORDER_Y_SIZE

                setaxl                            ; Set Acc back to 16bits before setting the Cursor Position

                JSL SETSIZES                      ; Calculate the size of the text screen

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
                JSL ANSI_SETSIZES
                RTL
                .pend

; IINITVKYGRPMODE
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
                STA @lBM0_CONTROL_REG
                ; Set the BitMap Start Address to $00C0000 ($B0C000)
                LDA #$00          ;; (L)Load Base Address of where Bitmap begins
                STA @lBM0_START_ADDY_L
                LDA #$C0
                STA @lBM0_START_ADDY_M
                LDA #$00
                STA @lBM0_START_ADDY_H ; This address is always base from
                                      ; of starting of FRAME Buffer $B00000

                LDA #$00          ; Enable Bit-Map and uses LUT0
                STA @lBM1_CONTROL_REG
                ; Set the BitMap Start Address to $00C0000 ($B0C000)
                LDA #$00          ;; (L)Load Base Address of where Bitmap begins
                STA @lBM1_START_ADDY_L
                LDA #$C0
                STA @lBM1_START_ADDY_M
                LDA #$00
                STA @lBM1_START_ADDY_H ; This address is always base from
                                      ; of starting of FRAME Buffer $B00000

                setaxl        ; Set Acc back to 16bits before setting the Cursor Position
                PLA
                RTL

IINITTILEMODE

                RTL

;
; Read a byte out of video RAM.
; Waits until the byte is available in Vicky's video RAM queue
;
; Inputs:
;   B:X = pointer to the address to read
;
; Outputs:
;   A = the data at that address in video RAM.
;   C set on failure (timeout), clear on success
;
IREADVRAM       .proc
                PHP
                setas

                LDA #0,B,X                      ; Request the byte

                setal
                LDX #100
wait_loop       LDA @l VMEM2CPU_Fifo_Count_LO   ; Wait for the FIFO to have data
                BIT #$8000
                BEQ read_byte                   ; If it has data, go read the byte
                DEX                             ; Otherwise, decrement timeout counter
                BNE wait_loop                   ; Keep waiting so long as it's not 0             

ret_failure     PLP                             ; Return failure
                CLC
                RTL

read_byte       setas
                LDA @l VMEM2CPU_Data_Port       ; Get the byte from Vicky

ret_success     PLP                             ; Return success
                CLC
                RTL
                .pend

INOP            RTL  

; IINITFONTSET
; Author: Stefany
; Init the Text Mode
; Inputs:
;   None
; Affects:
;  Vicky's Internal FONT Memory
IINITFONTSET    .proc
                PHA
                PHX 
                PHY
                PHB
                PHP
                setaxl

                LDX #<>FONT_4_BANK0         ; Font data to load
                LDY #<>FONT_MEMORY_BANK0    ; Location to load the font data
                LDA #8 * 256                ; Size of a FONT in bytes
                MVN #`FONT_4_BANK0, #`FONT_MEMORY_BANK0

                PLP
                PLB
                PLY
                PLX
                PLA
                RTL
                .pend
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
IINITCURSOR 
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

; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Initialize the Real Time Clock
; Inputs:
;   None
                ; Affects:
                ;   None

INITRTC         PHA
                PHP
                setas				        ; Just make sure we are in 8bit mode

                LDA #0
                STA @l RTC_RATES    ; Set watch dog timer and periodic interrupt rates to 0

                STA @l RTC_ENABLE   ; Disable all the alarms and interrupts
                
                LDA @lRTC_CTRL      ; Make sure the RTC will continue to tick in battery mode
                ORA #%00000100
                STA @lRTC_CTRL

                PLP
                PLA
                RTL

; IINITCODEC
; Author: Stefany
; Note: We assume that A & X are 16Bits Wide when entering here.
; Verify that the Math Block Works
; Inputs:
; None
IINITCODEC      PHA
                PHP
                setal
                LDA #%0001101000000000     ;R10 - Programming the DAC 
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED				
				
				
                LDA #%0001101000000000     ;R13 - Turn On Headphones
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED
                ;
                LDA #%0010101000011110       ;R21 - Enable All the Analog In
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
                LDA #%0001100_001000101      ;R12 - Master Mode Control
                STA CODEC_DATA_LO
                LDA #$0001
                STA CODEC_WR_CTRL             ; Execute the Write
                JSR CODEC_TRF_FINISHED
                PLP 
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
                STA @lUNSIGNED_MULT_A_LO
                LDA SCRN_X_STRIDE
                STA @lUNSIGNED_MULT_B_LO
                LDA @lUNSIGNED_MULT_AL_LO
                STA @lADDER32_A_LL          ; Store in 32Bit Adder (A)
                LDA @lUNSIGNED_MULT_AL_LO+2
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
; IDELAY -- Wait at least Y:X ticks of the system clock.
;
; NOTE: This routine will use the built in timer that count system clock ticks.
;       There will be overhead for the routine, so this routine should be used
;       To wait for at least Y:X ticks, and the caller should be tolerant of additional
;       delays in processing the timer and book keeping.
;
; Inputs:
;   Y = Bits[23:16] of the number of ticks to wait
;   X = Bits[15:0] of the number of ticks to wait
;
IDELAY          .proc
                PHA
                PHB
                PHP

                TRACE "IDELAY"

                setdbr 0

                setaxl
                PHX                         ; Save the delay amount
                PHY

                LDA #$02                    ; Set the handler for TIMER0 interrupts
                LDY #`HANDLE_TIMER0
                LDX #<>HANDLE_TIMER0
                JSL SETHANDLER

                PLY                         ; Restore the delay amount
                PLX

                setas
                LDA #0                      ; Stop the timer if it's running
                STA @l TIMER0_CTRL_REG

                LDA @l INT_MASK_REG0        ; Enable Timer 0 Interrupts
                AND #~FNX0_INT02_TMR0
                STA @l INT_MASK_REG0

                LDA #~TIMER0TRIGGER         ; Clear the timer 0 trigger flag
                STA @w TIMERFLAGS

                LDA #0
                STA @l TIMER0_CHARGE_L      ; Clear the comparator for count-down
                STA @l TIMER0_CHARGE_M
                STA @l TIMER0_CHARGE_H

                setaxl
                TXA
                STA @l TIMER0_CMP_L         ; Set the number of ticks
                TYA
                setas
                STA @l TIMER0_CMP_H

                LDA #TMR0_EN | TMR0_UPDWN   ; Enable the timer to count up
                STA @l TIMER0_CTRL_REG

                LDA #TIMER0TRIGGER          ; Timer zero's trigger flag
loop            WAI                         ; Wait for an interrupt
                TRB @w TIMERFLAGS           ; Check for the flag
                BEQ loop                    ; Keep checking until it's set

                LDA #0                      ; Stop the timer
                STA @l TIMER0_CTRL_REG

                LDA #~TIMER0TRIGGER         ; Clear the timer 0 trigger flag
                STA @w TIMERFLAGS

                LDA @l INT_MASK_REG0        ; Disable Timer 0 Interrupts
                ORA #FNX0_INT02_TMR0
                STA @l INT_MASK_REG0

                PLP
                PLB
                PLA
                RTL
                .pend
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
ISCINIT         BRK ;
IIOINIT         BRK ;
ISETLFS         BRK ; Obsolete (done in OPEN)
ISETNAM         BRK ; Obsolete (done in OPEN)
IOPEN           BRK ; Open a channel for reading and/or writing. Use SETLFS and SETNAM to set the channels and filename first.
ICLOSE          BRK ; Close a channel
IGETB           BRK ; Get a byte from input channel. Return 0 if no input. Carry is set if no input.
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
; Stub for an interrupt handler... just return from subroutine
;
; This will be the default address for the interrupt vector table jumps
;
IRQHANDLESTUB   RTL

.include "Libraries/OPL2_Library.asm"             ; Library code to drive the OPL2 (right now, only in mono (both side from the same data))
.include "Defines/SDCard_Controller_def.asm"
.include "SDOS.asm"
.include "Libraries/uart.asm"                     ; The code to handle the UART
.include "Joystick.asm"                           ; Code for the joysticks and gamepads
.include "Libraries/sdc_library.asm"              ; Library code for the SD card interface
.include "Libraries/fdc_library.asm"              ; Library code for the floppy drive controller
.include "Libraries/ide_library.asm"              ; Library code for the IDE interface
.include "Libraries/Ethernet_Init_library.asm"    ; This is a simple Init of the Controller, by Seting the MAC and enabling the RX and TX
.include "Libraries/EXP-C200_EVID_Library.asm"
.include "Libraries/ansi_screens.asm"               ; Include the ANSI text screen common code
.include "Libraries/kbd_driver.asm"                 ; Include the keyboard reading code
.include "Libraries/mouse_driver.asm"               ; Include the mouse driver code
.include "SplashScreenCode/boot_sound.asm"        ; Include the code to play the boot sound

;
; Greeting message and other kernel boot data
;
.if TARGET_SYS == SYS_C256_FMX
; FMX
KERNEL_DATA
greet_msg       .text $20, $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, " FFFFFFF MMMMMMMM XX    XXX " ,$0D
                .text $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FF      MM MM MM   XX XXX   ",$0D
                .text $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FFFFF   MM MM MM    XXX      ",$0D
                .text $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FF      MM MM MM  XXX  XX     ",$0D
                .text $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "FF      MM MM MM XXX     XX    ",$0D
                .text $0D, "C256 FOENIX FMX -- 3,670,016 Bytes Free", $0D
                .text "www.c256foenix.com -- Kernel: " 
                .include "version.asm"
                .text $0D,$00                
.endif

.if TARGET_SYS == SYS_C256_GENX
; GENX 
    KERNEL_DATA
greet_msg       .text $20, $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, " GGGGGG  EEEEEEE NN    NN XX    XXX" ,$0D
                .text $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "GG       EE      NNN   NN   XX XXX",$0D
                .text $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "GG  GGGG EEEEE   NN NN NN    XXX",$0D
                .text $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "GG    GG EE      NN   NNN  XXX  XX",$0D
                .text $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, " GGGGGG  EEEEEEE NN    NN XXX     XX",$0D
                .text $0D, "C256 FOENIX GENX -- 3,670,016 Bytes Free", $0D
                .text "www.c256foenix.com -- Kernel: " 
                .include "version.asm"
                .text $0D,$00      
.endif 

.if TARGET_SYS == SYS_C256_U_PLUS
; U+  
    KERNEL_DATA
    greet_msg   .text $20, $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, " UU    UU   +" ,$0D
                .text $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UU    UU   +",$0D
                .text $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UU    UU +++++",$0D
                .text $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UU    UU   +",$0D
                .text $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UUUUUUUU   +",$0D
                .text $0D, "C256 FOENIX U+ -- 3,670,016 Bytes Free", $0D
                .text "www.c256foenix.com -- Kernel: " 
                .include "version.asm"
                .text $0D,$00  
.endif 

.if TARGET_SYS == SYS_C256_U
    KERNEL_DATA
    greet_msg   .text $20, $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, " UU    UU" ,$0D
                .text $20, $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UU    UU",$0D
                .text $20, $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UU    UU",$0D
                .text $20, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UU    UU",$0D
                .text $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $0B, $0C, $20, "UUUUUUUU",$0D
                .text $0D, "C256 FOENIX U -- 1,572,864 Bytes Free", $0D
                .text "www.c256foenix.com -- Kernel: " 
                .include "version.asm"
                .text $0D,$00  
  .endif
.if TARGET_SYS == SYS_C256_FMX
  greet_clr_line1 .text $90, $90, $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line2 .text $90, $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line3 .text $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line4 .text $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line5 .text $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
.elsif TARGET_SYS == SYS_C256_GENX
  greet_clr_line1 .text $90, $90, $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line2 .text $90, $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line3 .text $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line4 .text $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line5 .text $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
.else 
  greet_clr_line1 .text $90, $90, $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line2 .text $90, $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line3 .text $90, $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line4 .text $90, $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
  greet_clr_line5 .text $90, $90, $D0, $D0, $B0, $B0, $A0, $A0, $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
.endif

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
Success_ms_init .text "Mouse Present", $0D, $00
Failed_kb_init  .text "No Keyboard Attached or Failed Init...", $0D, $00
Failed_ms_init  .text "No Mouse Attached or Failed Init...", $0D, $00
IamStuckHeremsg .text "I am stuck here...", $0D, $00
bmp_parser_err0 .text "NO SIGNATURE FOUND.", $00
bmp_parser_msg0 .text "BMP LOADED.", $00
bmp_parser_msg1 .text "EXECUTING BMP PARSER", $00
IDE_HDD_Present_msg0 .text "IDE HDD Present:", $00

boot_invalid    .null "Boot DIP switch settings are invalid."
boot_retry      .null "Press R to retry, B to go to BASIC.", 13
sdc_err_boot    .null "Unable to read the SD card."
ide_err_boot    .null "Unable to read from the IDE drive."
fdc_err_boot    .null "Unable to read from the floppy drive."
fdc_boot        .null "Booting from floppy..."
sdc_boot        .null "Booting from SDCard..."
ide_boot        .null "Booting from Hard Drive..."

ready_msg       .null $0D,"READY."

error_01        .null "ABORT ERROR"
hex_digits      .text "0123456789ABCDEF",0

; Keyboard scan code -> ASCII conversion tables (SCAN CODE 1) - FYI The Keyboard is spewing SCAN CODE 2 ( the controller does the translation)
.align 256
ScanCode_Press_Set1   .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $81, $82, $83, $84, $85    ; $30
                      .text $86, $87, $88, $89, $8A, $00, $00, $00, $11, $00, $00, $9D, $00, $1D, $00, $00    ; $40
                      .text $91, $00, $00, $00, $00, $00, $00, $8B, $8C, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Shift_Set1   .text $00, $00, $21, $40, $23, $24, $25, $5E, $26, $2A, $28, $29, $5F, $2B, $08, $09    ; $00
                      .text $51, $57, $45, $52, $54, $59, $55, $49, $4F, $50, $7B, $7D, $0D, $00, $41, $53    ; $10
                      .text $44, $46, $47, $48, $4A, $4B, $4C, $3A, $22, $7E, $00, $7C, $5A, $58, $43, $56    ; $20
                      .text $42, $4E, $4D, $3C, $3E, $3F, $00, $00, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Ctrl_Set1    .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $11, $17, $05, $12, $14, $19, $15, $09, $0F, $10, $5B, $5D, $0D, $00, $01, $13    ; $10
                      .text $04, $06, $07, $08, $0A, $0B, $0C, $3B, $27, $00, $00, $5C, $1A, $18, $03, $16    ; $20
                      .text $02, $0E, $0D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $18, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
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
                      .text $00, $00, $00, $00, $00, $00, $00, $01, $11, $00, $00, $9D, $00, $1D, $00, $05    ; $40
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


;
; Include the BASIC binary
;

* = START_OF_BASIC
.if ( TARGET_SYS == SYS_C256_FMX ) || ( TARGET_SYS == SYS_C256_GENX ) || ( TARGET_SYS == SYS_C256_U_PLUS )
        .binary "binaries/basic816_3A0000.bin"
.else
        .binary "binaries/basic816_1A0000.bin"
.endif

* = START_OF_CREDITS

;
; Credits screen
;

TXTLINE         .macro txt
                .text \txt
                .fill 80 - len(\txt), $20
                .endm

.align 256
CREDITS_TEXT    TXTLINE "                              CREDITS                                  "
                TXTLINE "                       The C256 Foenix Project                         "
                TXTLINE "                                                                       "
                TXTLINE "                                                                       "                
                TXTLINE "Project Creator & Hardware Design: Stefany Allaire"
                TXTLINE "www.c256foenix.com"
                TXTLINE " "
                TXTLINE " "
                TXTLINE "EARLY ALPHA & KEY PLAYERS:"
                TXTLINE "  Foenix IDE Design : Daniel Tremblay"
                TXTLINE "  Kernel Design, BASIC816 Creator: Peter J. Weingartner "
                TXTLINE "  FX/OS (GUI Environment) Design: Mike Bush"
                TXTLINE "Special Thanks:"
                TXTLINE "  Early Creator for the Foenix IDE & Kernel: Tom Wilson"
                TXTLINE " "
                TXTLINE " "
                TXTLINE "FPGA CORES AUTHORS:"
                TXTLINE "  LPC Core: Howard M. Harte, hharte@opencores.org"
                TXTLINE "  SDCard Core: Steve Fielding, sfielding@base2designs.com"
                TXTLINE "  PS2 Controller (C256 Foenix U): Miha Dolenc, mihad@opencores.org "
                TXTLINE "  SN76489 (JT89) (C256 Foenix U): Jose Tejada Gomez"
                TXTLINE "  YM2612 (JT12): Jose Tejada Gomez"
                TXTLINE "  YM2151 (JT51) (C256 Foenix U): Jose Tejada Gomez"
                TXTLINE "  SID (6581): Gideon Zweijtzer, gideon.zweijtzer@gmail.com"
                TXTLINE "  UART (16550) (C256 Foenix U): TBD"
                TXTLINE " "
                TXTLINE " "
                TXTLINE "SPECIAL THANKS:"
                TXTLINE "  Joeri Vanharen"
                TXTLINE "  Jim Drew"
                TXTLINE "  Aidan Lawrence (Sound Chip Schematic references)"
                TXTLINE " "
                TXTLINE " "
                TXTLINE "                                                                       "
                TXTLINE "                     I would like to say a big thanks               "
                TXTLINE "                  from the bottom of my heart for all of            "
                TXTLINE "              those who have believed in this project since          " 
                TXTLINE "                the very beginning and have been there to            "
                TXTLINE "                        make it what it is today!!!                  "
                TXTLINE "                                                                       "
                TXTLINE "                        Stefany"
                .fill 80 * (60 - 26),$20

.align 256
CREDITS_COLOR   .fill 80 * 60, $F4


;
; The default font and end of flash memory
;
* = START_OF_SPLASH

         ; This is for the Color Rolling Scheme
BOOT_MENU .proc
SplashScreenMain:
                setdp 0
                setxl 
                setas     
                JSL INITCHLUT ; The Software does change one of the CH LUT, so, let's Init again

                LDA #$00
                STA INTERRUPT_STATE
                STA INTERRUPT_COUNT
                STA IRQ_COLOR_CHOICE
                ; Clear Any Pending Interrupt
                LDA @lINT_PENDING_REG0  ; Read the Pending Register &
                AND #FNX0_INT02_TMR0
                STA @lINT_PENDING_REG0  ; Writing it back will clear the Active Bit

                ; Go Get the Model Number here:
                JSR Splash_Get_Machine_ID
                JSR Splash_Clear_Screen
                JSR Splash_Load_FontSet
                JSL Splashscreen_BitMapSetup
                JSR Model_Update_Info_Field
                JSR Set_Text_Color
                LDA #$00 
                STA LINE_INDEX  ; Point to the first line to be displayed
                STA LINE_INDEX + 1
                JSR Line_Setup_Before_Display   ; Assign and Compute the Pointer   
;Main Loop is here, Timed @ 16ms
;
;
HAVE_FUN:
                JSL BOOT_SOUND_OFF
                JSL Splash_Moniker_Color_Rolling  ; Go Move The Colors on the Logo
                LDX LINE_INDEX
                CPX #NumberOfEntry
                BEQ ByPassCharDisplay           ; If Equal all Lines have been displayed
                JSR Line_Display_1_Character    ; Go move the cursor one stop 
                BCC Still_Displaying_Char
                JSR Line_Setup_Before_Display   ; Assign and Compute the Pointer
; Replication of the old BOOT_MENU Code - Sorry PJW, it needed some upgrades
ByPassCharDisplay:
                setas 
                JSL GETSCANCODE         ; Try to get a scan code
                CMP #0                  ; Did we get anything
                BEQ Still_Displaying_Char            ; No: keep waiting until timeout
                CMP #CHAR_F1            ; Did the user press F1?
                BEQ return              ; Yes: return it
                CMP #CHAR_F2            ; Did the user press F2?
                BEQ return              ; Yes: return it
                CMP #CHAR_F3            ; Did the user press F3?
                BEQ return              ; Yes: return it
                CMP #SCAN_CR            ; Did the user press CR?
                BEQ return              ; Yes: return it
                CMP #SCAN_SP            ; Did the user press SPACE?
                BEQ exitshere
                ;BNE wait_key            ; No: keep waiting
Still_Displaying_Char:        
                ;JSR Pause_16ms
WaitForNextSOF:   
                LDA @l INT_PENDING_REG0
                AND #FNX0_INT00_SOF
                CMP #FNX0_INT00_SOF
                BNE WaitForNextSOF;
                JMP HAVE_FUN

exitshere: 
timeout 
                LDA #0                  ; Return 0 for a timeout / SPACE
return      
                STA @l KRNL_BOOT_MENU_K          ; Store ther Keyboard Value
                ; Let's do some housekeeping before giving back the computer to the user
                LDA #$00
                STA @l MASTER_CTRL_REG_L         ; Disable Everything
                JSL SS_VDMA_CLEAR_MEMORY_640_480 ; Clear the Bitmap Screen
                JSR VickyII_Registers_Clear      ; Reset All Vicky Registers
                JSL INITFONTSET ; Reload the Official FONT set
                JSL INITCURSOR ; Reset the Cursor to its origin
                JSL INITCHLUT ; The Software does change one of the CH LUT, so, let's Init again
                JSL INITVKYTXTMODE  ; Init VICKY TextMode now contains Hi-Res Dipswitch read and Automatic Text Size Parameter adjust
                NOP
                RTL
.pend

; Let's initialized all the registers to make sure the app doesn't pick up stuff from a previously ran code
VickyII_Registers_Clear: .proc
                setas
                setxl
                ; SPRITE CLEAR
                LDX #$0000
                LDA #$00
                ; This will clear all the Sprite Registers
ClearSpriteRegisters:
                STA @l SP00_CONTROL_REG, X
                INX
                CPX #$0200
                BNE ClearSpriteRegisters

                ; TILE CLEAR
                ; This will clear all the Tile Layers Registers
                LDX #$0000
                LDA #$00
ClearTiles0Registers:
                STA @l TL0_CONTROL_REG, X
                INX
                CPX #$0030
                BNE ClearTiles0Registers
                NOP
                ; This will clear all the Tiles Graphics Registers
                LDX #$0000
                LDA #$00
ClearTiles1Registers:
                STA @l TILESET0_ADDY_L, X
                INX
                CPX #$0020
                BNE ClearTiles1Registers
                NOP

                LDX #$0000
                LDA #$00
                ; This will clear all the Tiles Registers
ClearBitmapRegisters:
                STA @l BM0_CONTROL_REG, X
                STA @l BM1_CONTROL_REG, X
                INX
                CPX #$0010
                BNE ClearBitmapRegisters
                RTS
.pend
;Bit 2, Bit 1, Bit 0
;$000: FMX
;$100: FMX (Future C5A)
;$001: U 2Meg
;$101: U+ 4Meg U+
;$010: TBD (Reserved)
;$110: TBD (Reserved)
;$011: A2560 Dev
;$111: A2560 Keyboard
Splash_Get_Machine_ID .proc
                setas 
                LDA @lGABE_SYS_STAT
                AND #$03        ; Isolate the first 2 bits to know if it is a U or FMX
                STA MODEL
                CMP #$00
                BEQ DONE 
                ; Now let's figure out if it has 2Megs or 4Megs
                ; Here we got the Code $01 from Sys_Stat
                LDA @lGABE_SYS_STAT
                AND #GABE_SYS_STAT_MID2 ; High 4Meg, Low - 2Megs
                CMP #GABE_SYS_STAT_MID2
                BEQ DONE
                LDA #$02
                STA MODEL       ; In this Scheme 00 - FMX, 01 - U+, 02 - U
DONE: 
                RTS
.pend

Splash_Load_FontSet .proc
                setas 
                setxl
                LDX #$0000
DONE_LOADING_FONT:        
                LDA @l FONT_4_SPLASH, X 
                STA @l FONT_MEMORY_BANK0, X
                INX 
                CPX #2048
                BNE DONE_LOADING_FONT
                RTS
.pend

Splash_Clear_Screen .proc
                setas
                setxl
                LDX #$0000
Branch_Clear:
                LDA #$20
                STA @l CS_TEXT_MEM_PTR,X
                LDA #$F0
                STA @l CS_COLOR_MEM_PTR,X
                INX
                CPX #$2000
                BNE Branch_Clear
                RTS
.pend

IRQ_SOF_ST0 = $00
IRQ_SOF_ST1 = $01
IRQ_SOF_ST2 = $02
;
; ///////////////////////////////////////////////////////////////////
; ///
; /// Timer Driver Routine (Not using Interrupts)
; /// 60Hz, 16ms Cyclical
; ///
; ///////////////////////////////////////////////////////////////////
Splash_Moniker_Color_Rolling   .proc
                ; Let's go throught the statemachine
                setas
                LDA @lINT_PENDING_REG0
                AND #FNX0_INT00_SOF
                STA @lINT_PENDING_REG0

                LDA INTERRUPT_STATE
                CMP #IRQ_SOF_ST0
                BEQ SERVE_STATE0

                CMP #IRQ_SOF_ST1
                BEQ SERVE_STATE1

                CMP #IRQ_SOF_ST2
                BNE NOT_SERVE_STATE2
                BRL SERVE_STATE2
NOT_SERVE_STATE2
                RTL

; Go Count for a 4 Frame Tick
SERVE_STATE0
                LDA INTERRUPT_COUNT
                CMP #$04
                BEQ SERVE_NEXT_STATE
                INC INTERRUPT_COUNT
                RTL

SERVE_NEXT_STATE
                LDA #$00
                STA INTERRUPT_COUNT
                LDA #IRQ_SOF_ST1
                STA INTERRUPT_STATE
                RTL
; Change the Color Here
SERVE_STATE1
                setaxl
                LDA #$0000
                LDX #$0000
                setaxs
                ; RED
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+0, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+992
                ;STA @lBORDER_COLOR_B
                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+993
                ;STA @lBORDER_COLOR_G
                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+994
                ;STA @lBORDER_COLOR_R
                ;BRL HERE
                ; ORANGE
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+1, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+996
                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+997
                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+998
                ; YELLOW
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+2, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+1000
                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+1001
                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+1002
                ; GREEN
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+3, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+1004
                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+1005
                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+1006
                ; CYAN
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+4, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+1008
                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+1009
                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+1010
                ; BLUE
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+5, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+1012
                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+1013
                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+1014
                ; PURPLE
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+6, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+1016
                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+1017
                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+1018
                ; New Color Here - Jan 2021
                LDX IRQ_COLOR_CHOICE
                LDA @lCOLOR_POINTER+7, X
                TAX
                LDA @lCOLOR_CHART, X
                STA @lGRPH_LUT7_PTR+1020
                
                STA @lFG_CHAR_LUT_PTR + $10           ; 

                LDA @lCOLOR_CHART+1, X
                STA @lGRPH_LUT7_PTR+1021
                
                STA @lFG_CHAR_LUT_PTR + $11            ;

                LDA @lCOLOR_CHART+2, X
                STA @lGRPH_LUT7_PTR+1022                
                STA @lFG_CHAR_LUT_PTR + $12            ;

HERE
                CLC
                LDA IRQ_COLOR_CHOICE
                ADC #$09
                STA IRQ_COLOR_CHOICE
                LDA IRQ_COLOR_CHOICE
                CMP #$48
                BNE EXIT_COLOR_CHANGE
                LDA #$00
                STA IRQ_COLOR_CHOICE
EXIT_COLOR_CHANGE
                setxl
                LDA #IRQ_SOF_ST0
                STA INTERRUPT_STATE
                RTL

SERVE_STATE2
                LDA #IRQ_SOF_ST0
                STA INTERRUPT_STATE
                RTL
.pend
.align 16
COLOR_CHART     .text 46, 46, 164, 00     ;248
                .text 37, 103, 193, 00    ;249
                .text 32, 157, 164, 00    ;250
                .text 44, 156 , 55, 00    ;251
                .text 148, 142, 44, 00    ;252
                .text 145, 75, 43, 00     ;253
                .text 142, 47, 97, 00     ;254
                .text 33, 80, 127, 00     ;255

COLOR_POINTER   .text 0,4,8,12,16,20,24,28,0
                .text 4,8,12,16,20,24,28,0,0
                .text 8,12,16,20,24,28,0,4,0
                .text 12,16,20,24,28,0,4,8,0
                .text 16,20,24,28,0,4,8,12,0
                .text 20,24,28,0,4,8,12,16,0
                .text 24,28,0,4,8,12,16,20,0
                .text 28,0,4,8,12,16,20,24,0

.include "SplashScreenCode/Splashscreen_Bitmap_Setup.asm"             ;
.include "SplashScreenCode/Splashscreen_Text_Display.asm"
.align 256
SS_MONIKER_LUT
.binary "SplashScreenCode/Graphics Assets/Graphic_C256Foenix.data.pal"
SS_MONIKER
.binary "SplashScreenCode/Graphics Assets/Graphic_C256Foenix.data"
SS_FMX_TXT
.binary "SplashScreenCode/Graphics Assets/Graphic_FMX.data"
SS_UPlus_TXT
.binary "SplashScreenCode/Graphics Assets/Graphic_UPlus.data"
SS_U_TXT
.binary "SplashScreenCode/Graphics Assets/Graphic_U.data"
;
; The default font and end of flash memory
;
* = START_OF_FONT
FONT_4_BANK0
;.binary "FONT/CBM-ASCII_new_8x8.bin", 0, 2048
.binary "FONT/Bm437_PhoenixEGA_8x8.bin", 0, 2048
FONT_4_SPLASH 
.binary "FONT/quadrotextFONT.bin"
* = START_OF_FONT + $00FFFF
                .byte $FF               ; Last byte of flash data
