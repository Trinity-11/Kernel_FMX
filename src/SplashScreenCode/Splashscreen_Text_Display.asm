

NumberOfEntry = size( TEXT_POSX ) / 2; (1 more then the actual number)


Set_Text_Color: .proc
            setaxl
            LDA #00
            STA TEXT_CURSOR_X
            LDA #48
            STA TEXT_CURSOR_Y
            JSR Line_Display_Compute_Pointer
            LDY #$0000
            setas 
            LDA #$40
SetColorBranch:            
            STA [COLOR_DST_PTR_L],Y 
            INY 
            CPY #80
            BNE SetColorBranch
            RTS
.pend


Model_Update_Info_Field: .proc 
            setaxl 
            LDA #$0000
            setas
            LDA MODEL 
            ASL 
            ASL 
            TAX
            ; Set Pointers for Source and Destination
            setal
            LDA MODEL_TABLE, X 
            STA MOD_SELECT_L
            LDA MODEL_TABLE + 2, X 
            STA MOD_SELECT_H

            LDY #$0000
            STY LINE_INDEX
Next_Change_Here:
            setal 
            LDY LINE_INDEX
            TYX 
            LDA [MOD_SELECT_L], Y 
            STA TEXT_SRC_PTR_L
            LDA LINE_MOD, X 
            STA TEXT_DST_PTR_L   
            INY 
            INY
            TYX
            LDA [MOD_SELECT_L], Y 
            STA TEXT_SRC_PTR_H
            LDA LINE_MOD, X 
            STA TEXT_DST_PTR_H
            INY 
            INY    
            STY LINE_INDEX
            CPY #16
            BEQ LetsMoveOn
            setas 
            LDY #$0000
nextchar:    
            LDA [TEXT_SRC_PTR_L], Y
            CMP #$00
            BEQ Next_Change_Here
            STA [TEXT_DST_PTR_L], Y 
            INY 
            BRA nextchar

; Let's Get the Hardware Board Revision and Edit the Text Field
LetsMoveOn: 
            LDA LINE_MOD + 12
            STA TEXT_DST_PTR_L 
            LDY #$0000
            setas
            LDA @lREVOFPCB_C
            STA [TEXT_DST_PTR_L], Y
            INY
            LDA @lREVOFPCB_4
            STA [TEXT_DST_PTR_L], Y
            INY            
            LDA @lREVOFPCB_A
            STA [TEXT_DST_PTR_L], Y            

; Add the Actual Dates from the FPGAs to the text Line
; Let's Start with the Dates     
; The FPGA Date Creation is sitting in the Mouse Register
            ; Let's Setup the Pointer
            ; I know this is not pretty, but it is straight to the point, no time to make it fancy.
            ; DAY
            CLC
            LDA @l FPGA_DOR   ; it is in BCD
            JSR HighNibblerBCD
            STA @lLINE8 + 56    ; FAT VICKY in U/U+ Model
            STA @lLINE9 + 47    ; GABE in FMX
            STA @lLINE10 + 51   ; VICKY II in FMX
            LDA @lFPGA_DOR
            AND #$0F
            ADC #$30
            STA @lLINE8 + 57    ; FAT VICKY in U/U+ Model
            STA @lLINE9 + 48    ; GABE in FMX
            STA @lLINE10 + 52   ; VICKY II in FMX
            ; MONTH      
            LDA @lFPGA_MOR   ; it is in BCD
            JSR HighNibblerBCD
            STA @lLINE8 + 59    ; FAT VICKY in U/U+ Model
            STA @lLINE9 + 50    ; GABE in FMX
            STA @lLINE10 + 54   ; VICKY II in FMX
            LDA @lFPGA_MOR
            AND #$0F
            ADC #$30             
            STA @lLINE8 + 60    ; FAT VICKY in U/U+ Model
            STA @lLINE9 + 51    ; GABE in FMX
            STA @lLINE10 + 55   ; VICKY II in FMX
            ; YEAR     
            LDA @lFPGA_YOR   ; it is in BCD
            JSR HighNibblerBCD
            STA @lLINE8 + 62    ; FAT VICKY in U/U+ Model
            STA @lLINE9 + 53    ; GABE in FMX
            STA @lLINE10 + 57   ; VICKY II in FMX
            LDA @lFPGA_YOR
            AND #$0F
            ADC #$30             
            STA @lLINE8 + 63    ; FAT VICKY in U/U+ Model
            STA @lLINE9 + 54    ; GABE in FMX
            STA @lLINE10 + 58   ; VICKY II in FMX

; Let's do the FPGA Version And Subversion
            LDA @l GABE_SUBVERSION_HI
            JSR HighNibblerBCD
            STA @lLINE8 + 46    ; U/U+
            STA @lLINE9 + 37    ; When FMX, this is the Info for GABE
            LDA @l GABE_SUBVERSION_HI
            AND #$0F
            ADC #$30             
            STA @lLINE8 + 47
            STA @lLINE9 + 38    ; When FMX, this is the Info for GABE
            ; VICKY II in FMX Mode
            LDA @l VKY_INFO_CHIP_VER_H
            JSR HighNibblerBCD 
            STA @lLINE10 + 41    ; When FMX, this is the Info for GABE
            LDA @l VKY_INFO_CHIP_VER_H
            AND #$0F
            ADC #$30    
            STA @lLINE10 + 42    ; When FMX, this is the Info for GABE
            LDA @l GABE_SUBVERSION_LO
            JSR HighNibblerBCD
            STA @lLINE8 + 48
            STA @lLINE9 + 39    ; When FMX, this is the Info for GABE       
            LDA @l GABE_SUBVERSION_LO
            AND #$0F
            ADC #$30             
            STA @lLINE8 + 49
            STA @lLINE9 + 40    ; When FMX, this is the Info for GABE
            ; VICKY II in FMX Mode
            LDA @l VKY_INFO_CHIP_VER_L
            JSR HighNibblerBCD 
            STA @lLINE10 + 43    ; When FMX, this is the Info for GABE
            LDA @l VKY_INFO_CHIP_VER_L
            AND #$0F
            ADC #$30    
            STA @lLINE10 + 44    ; When FMX, this is the Info for GABE
            LDA @l GABE_VERSION_HI
            JSR HighNibblerBCD
            STA @lLINE8 + 34
            STA @lLINE9 + 25    ; When FMX, this is the Info for GABE
            LDA @l GABE_VERSION_HI
            AND #$0F
            ADC #$30             
            STA @lLINE8 + 35 
            STA @lLINE9 + 26    ; When FMX, this is the Info for GABE     
            ; VICKY II in FMX Mode
            LDA @l VKY_INFO_CHIP_NUM_H
            JSR HighNibblerBCD 
            STA @lLINE10 + 30    ; When FMX, this is the Info for GABE
            LDA @l VKY_INFO_CHIP_NUM_H
            AND #$0F
            ADC #$30    
            STA @lLINE10 + 31    ; When FMX, this is the Info for GABE
            LDA @l GABE_VERSION_LO
            JSR HighNibblerBCD
            STA @lLINE8 + 36
            STA @lLINE9 + 27    ; When FMX, this is the Info for GABE
            LDA @l GABE_VERSION_LO
            AND #$0F
            ADC #$30             
            STA @lLINE8 + 37
            STA @lLINE9 + 28    ; When FMX, this is the Info for GABE             
            ; VICKY II in FMX Mode
            LDA @l VKY_INFO_CHIP_NUM_L
            JSR HighNibblerBCD 
            STA @lLINE10 + 32    ; When FMX, this is the Info for GABE
            LDA @l VKY_INFO_CHIP_NUM_L
            AND #$0F
            ADC #$30    
            STA @lLINE10 + 32    ; When FMX, this is the Info for GABE
            JSR GODETECTHIRES ; Dip-Switch and Change Text
            JSR GODETECTHDD   ; Dip-Switch and Change Text
            JSR GODETECTEXP   ; Go Check if there is a Card Change Text

; We will Finish with that
; Remove the Field that are not necessary for the actual Model
            LDA MODEL 
            AND #$03
            CMP #$00
            BEQ Erase_FATVicky_Line;
            CMP #$01
            BEQ Erase_2Lines;
            CMP #$02
            BEQ Erase_2Lines;

            RTS

HighNibblerBCD: .proc 
            AND #$F0 
            LSR A 
            LSR A 
            LSR A 
            LSR A
            ADC #$30
            RTS
.pend

Erase_FATVicky_Line:
            setal
            LDA #<>LINE8
            STA TEXT_DST_PTR_L
            LDA #`LINE8
            STA TEXT_DST_PTR_H 
            setas 
            LDY #$0000
            LDA #$20    ; Put One Space
            STA [TEXT_DST_PTR_L], Y
            INY 
            LDA #$00    ; Terminate the Line
            STA [TEXT_DST_PTR_L], Y
            RTS

Erase_2Lines
            setal
            LDA #<>LINE9
            STA TEXT_DST_PTR_L
            LDA #`LINE9
            STA TEXT_DST_PTR_H 
            setas 
            LDY #$0000
            LDA #$20    ; Put One Space
            STA [TEXT_DST_PTR_L], Y
            INY 
            LDA #$00    ; Terminate the Line
            STA [TEXT_DST_PTR_L], Y
            setal
            LDA #<>LINE10
            STA TEXT_DST_PTR_L
            LDA #`LINE10
            STA TEXT_DST_PTR_H 
            setas 
            LDY #$0000
            LDA #$20    ; Put One Space
            STA [TEXT_DST_PTR_L], Y
            INY 
            LDA #$00    ; Terminate the Line
            STA [TEXT_DST_PTR_L], Y            
            RTS
.pend

; Go Check Hi-Res DipSwitch and Change the Text
GODETECTHIRES .proc 
            setas
            ; Here we check for Expansion Card and Init them soon in the process
            LDA @l GAMMA_CTRL_REG   ; Go Read the Hi-Res DIP Switch Value
            AND #HIRES_DP_SW_VAL    ; Isolate the Hi-Res Bit ($10) when 1 = 640x480, 0 = 800x600
            CMP #HIRES_DP_SW_VAL    ; When the Switch is off, the Returned value is 1 (The Pullup is there)
            BEQ WeAreDone
            setxl
            LDX #$0000
ChangeNextChar            
            LDA @l ON_TEXT, X
            CMP #$00
            BEQ WeAreDone
            STA @l LINE17 +13, X 
            INX 
            BNE ChangeNextChar
WeAreDone
NoExpansionCardPresent     
            RTS
.pend

; Go Check the HDD Present Dip-Switch and Report
GODETECTHDD  .proc 

            RTS
.pend

; Go Check the HDD
GODETECTEXP  .proc 
            setas
            ; Here we check for Expansion Card and Init them soon in the process
            LDA @L GABE_SYS_STAT      ; Let's check the Presence of an Expansion Card here
            AND #GABE_SYS_STAT_EXP    ; When there is a Card the Value is 1
            CMP #GABE_SYS_STAT_EXP
            BNE NoExpansionCardPresent
            setxl
            LDX #$0000
ChangeNextChar            
            LDA @l YES_TEXT, X
            CMP #$00
            BEQ WeAreDone
            STA @l LINE19 +26, X 
            INX 
            BNE ChangeNextChar
WeAreDone
            LDX #$0000
AddCardName            
            LDA @l EVID_ID_NAME_ASCII, X 
            STA @l LINE20, X
            INX 
            CPX #$10
            BNE AddCardName
NoExpansionCardPresent            
            RTS
.pend
; This SHould be call Once every time a line is Done
Line_Setup_Before_Display .proc
            setaxl
            LDA LINE_INDEX
            CMP #NumberOfEntry
            BEQ DONE
            ; Get the Source Pointer from the Pointer
            LDA LINE_INDEX
            ASL A 
            ASL A
            TAX 
            LDA TEXT_TABLE, X 
            STA TEXT_SRC_PTR_L
            LDA TEXT_TABLE + 2, X 
            STA TEXT_SRC_PTR_H
            ; Set the Cursor Position
            LDA LINE_INDEX
            ASL A 
            TAX             
            LDA TEXT_POSX, X 
            STA TEXT_CURSOR_X
            STA @l VKY_TXT_CURSOR_X_REG_L
            LDA TEXT_POSY, X 
            STA TEXT_CURSOR_Y
            STA @l VKY_TXT_CURSOR_Y_REG_L
            ; Go Computer the Address Pointer for the Display memory
            JSR Line_Display_Compute_Pointer
            LDA #$0000
            STA TEXT_INDEX
            INC LINE_INDEX 
DONE:            
            RTS
.pend


; When the Carry is Set, the Line is over with
Line_Display_1_Character .proc
            setaxl
            INC TEXT_CURSOR_X       ; Always put the Cursor In Front of the "To be displayed Char"
            LDA TEXT_CURSOR_X
            STA @l VKY_TXT_CURSOR_X_REG_L
            setas             
            SEC
            LDY TEXT_INDEX
            LDA [TEXT_SRC_PTR_L], Y
            CMP #$00
            BEQ WE_ARE_DONE;
            CLC            
            STA [TEXT_DST_PTR_L], Y 
            INY
            STY TEXT_INDEX
WE_ARE_DONE:            
            RTS 
.pend

; This Will set the Starting Address from the Cursor Position
Line_Display_Compute_Pointer .proc
            setaxl 
            ; Y x 80
            LDA TEXT_CURSOR_Y
            STA @lUNSIGNED_MULT_A_LO
            LDA #80
            STA @lUNSIGNED_MULT_B_LO
            ;
            CLC  
            LDA @lUNSIGNED_MULT_AL_LO
            ADC TEXT_CURSOR_X
            ADC #$A000 
            STA TEXT_DST_PTR_L
            ADC #$2000
            STA COLOR_DST_PTR_L
            LDA #$00AF
            STA TEXT_DST_PTR_H
            STA COLOR_DST_PTR_H           
            RTS
.pend

TEXT_TABLE  .dword LINE0, LINE1, LINE2, LINE3, LINE4, LINE5, LINE6, LINE7
            .dword LINE8, LINE9, LINE10, LINE11, LINE12, LINE13, LINE14, LINE15
            .dword LINE16, LINE17, LINE18, LINE19, LINE20, LINE21, LINE22 

TEXT_POSX  .word  leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, leftAlign, 31, leftAlign, 5, 25, 45, 45, 30, 72                     ;
TEXT_POSY  .word  25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 37, 38, 39, 40, 46, 48, 52, 52, 52, 53, 57, 57

leftAlign = 6


LINE0  .text "COMPUTER MODEL:                 ", $00 ; Offset $10
LINE1  .text "                     ", $00
LINE2  .text "SYSTEM INFO: ", $00
LINE3  .text "CPU: WDC65C816 @ 14MHZ ", $00
LINE4  .text "CODE MEMORY SIZE:                 ", $00 ; Offset 17
LINE5  .text "VIDEO MEMORY SIZE:                 ", $00 ; Offset
LINE6  .text "PCB REVISION:       ", $00
LINE7  .text "CHIPSET(S): ", $00
LINE8  .text "PN: CFP95169 - FAT VICKY II - REV:0000 SUBREV:0000 DATE:00/00/00 ", $00
LINE9  .text "PN: CFP9533  - GABE     - REV:0000 SUBREV:0000 DATE:00/00/00     ", $00
LINE10 .text "PN: CFP9551  - VICKY II - REV:0000 SUBREV:0000 DATE:00/00/00     ", $00
LINE11 .text "CREDITS: ", $00
LINE12 .text "CONCEPT & SYSTEM DESIGN: STEFANY ALLAIRE", $00
LINE13 .text "KERNEL DESIGN / BASIC816 CREATOR: PETER J. WEINGARTNER", $00
LINE14 .text "FOENIX IDE DESIGN: DANIEL TREMBLAY", $00
LINE15 .text "----BOOT MENU----", $00
LINE16 .text " PRESS F2 = SDCARD, F3 = HDD, RETURN = BASIC, SPACE = DEFAULT ", $00
LINE17 .text "HI-RES MODE: OFF ", $00
LINE18 .text "HDD INSTALLED: -- ", $00
LINE19 .text "EXPANSION CARD INSTALLED: NO ", $00
LINE20 .text $20, $20, $20, $20, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
LINE21 .text "WWW.C256FOENIX.COM", $00
LINE22 .text " ", $00

MODEL_TABLE .dword MODEL_00, MODEL_01, MODEL_02, MODEL_03

MODEL_00   .dword FIELD_MOD0, FIELD_MEM1, FIELD_MEM1, $00000000 ; FMX
MODEL_01   .dword FIELD_MOD1, FIELD_MEM1, FIELD_MEM0, $00000000 ; U+
MODEL_02   .dword FIELD_MOD2, FIELD_MEM0, FIELD_MEM0, $00000000 ; U
MODEL_03   .dword  $00000000,  $00000000, $00000000, $00000000  ; TBD

LINE_MOD   .dword LINE0 + $10, LINE4 + $12, LINE5 + $13, LINE6 + $0E 

FIELD_MOD0 .text "C256 FOENIX FMX", $00 ; 15 Characters
FIELD_MOD1 .text "C256 FOENIX U+ ", $00
FIELD_MOD2 .text "C256 FOENIX U  ", $00
FIELD_MEM0 .text "2,097,152 BYTES", $00
FIELD_MEM1 .text "4,194,304 BYTES", $00
ON_TEXT    .text "ON ", $00
YES_TEXT   .text "YES", $00



