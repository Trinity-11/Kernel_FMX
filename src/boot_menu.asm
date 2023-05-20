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