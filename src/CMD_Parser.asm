
* = $393000

;;BCC is branch if less than; BCS is branch if greater than or equal.
;KEY_BUFFER       = $000F00 ;64 Bytes keyboard buffer
;KEY_BUFFER_SIZE  = $0080 ;128 Bytes (constant) keyboard buffer length
;KEY_BUFFER_END   = $000F7F ;1 Byte  Last byte of keyboard buffer
;;KEY_BUFFER_RPOS  = $000F80 ;2 Bytes keyboard buffer read position
;;KEY_BUFFER_WPOS  = $000F82 ;2 Bytes keyboard buffer write position
;KEY_BUFFER_CMD   = $000F83 ;1 Byte  Indicates the Command Process Status
;COMMAND_SIZE_STR = $000F84 ; 1 Byte
;COMMAND_COMP_TMP = $000F86 ; 2 Bytes

;KEYBOARD_SC_FLG  = $000F87 ;1 Bytes that indicate the Status of Left Shift, Left CTRL, Left ALT, Right Shift
;KEYBOARD_SC_TMP  = $000F88 ;1 Byte, Interrupt Save Scan Code while Processing

;##########################################
;## Command Parser
;## Interrupt Line Capture Code
;##########################################

; This is the Interrupt Code to Store the Keyboard Input and to trigger process is CR is keyed in
; We assume that X is Long and that A is Short
SAVECHAR2CMDLINE
                ; We don't accept Char less than 32
                PHD
                ;setdbr $00  ; Set the REco
                setas


NOT_CARRIAGE_RETURN
                LDX KEY_BUFFER_WPOS   ; So the Receive Character is saved in the Buffer
                CMP #$20
                BCC CHECK_LOWERTHANSPACE
                ; We Don't accept Char that are greater or Equal to 128
                CMP #$80
                BCS EXIT_SAVE2_CMDLINE

                ; Save the Character in the Buffer
                CPX #KEY_BUFFER_SIZE  ; Make sure we haven't been overboard.
                BCS EXIT_SAVE2_CMDLINE  ; Stop storing - An error should ensue here...
                CMP #$61              ; "a"
                BCC CAPS_NO_CHANGE ;
                CMP #$7B              ; '{'  Char after 'z'
                BCS CAPS_NO_CHANGE ;
                ; if we are here, it is because the ASCII is in small caps
                ; Transfer the small caps in big Caps
                AND #$DF    ; remove the $20 in $61
CAPS_NO_CHANGE
                STA @lKEY_BUFFER, X
                INX
                STX KEY_BUFFER_WPOS
                LDA #$00
                STA @lKEY_BUFFER, X   ; Store a EOL in the following location for good measure
                BRA EXIT_SAVE2_CMDLINE
CHECK_LOWERTHANSPACE
                CMP #$08    ; BackSpace
                BEQ GO_BACKTHEPOINTER;
                CMP #$0D    ; Check to see if the incomming Character is a Cariage Return
                BNE NOT_CARRIAGE_RETURN
                STA @lKEY_BUFFER, X
                ; Just Make sure the Read Point is Pointing at the beginning of the line
                LDX #$0000
                STX KEY_BUFFER_RPOS
                LDA @lKEY_BUFFER_CMD
                ORA #$01      ; Set Bit 0 - to indicate that there is a command to process
                STA @lKEY_BUFFER_CMD
EXIT_SAVE2_CMDLINE
                PLD
                RTL

GO_BACKTHEPOINTER
                LDA #$00
                STA @lKEY_BUFFER, X
                CPX #$0000
                BEQ EXIT_SAVE2_CMDLINE
                DEX
                BRA EXIT_SAVE2_CMDLINE

;##########################################
;## Command Parser
;## Being Executed from Kernel Mainloop
;##########################################
; This is run from the Main KERNEL loop
; We also asume that the Command line is all in CAPS even if a small caps appears on the screen
PROCESS_COMMAND_LINE
                PHP
                setxl   ; let's make sure X is long
                setas   ; and that A is short
                LDX #$0000
                STX KEY_BUFFER_WPOS
                LDX KEY_BUFFER_RPOS ; Load the Read Pointer

NOT_VALID_CHAR4CMD
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #$0D              ; Check for Carriage Return
                BEQ NO_CMD_2_PROCESS  ; Exit, if the first char is a Carriage return
                ; Let's eliminate any Space before the command
                CMP #$41              ; Smaller than "A"
                BCC NOT_A_VALIDCHAR   ; check for space before the Command
                CMP #$5B              ; Smaller than "Z" We are going to accept the character
                BCC VALIDCHAR_GO_FIND_CMD;
NOT_A_VALIDCHAR
                INX
                CPX #KEY_BUFFER_SIZE
                BNE NOT_VALID_CHAR4CMD
                BEQ ERROR_BUFFER_OVERRUN  ; This means that we have reached the end of Buffer
VALIDCHAR_GO_FIND_CMD
                JSR HOWMANYCHARINCMD  ; Comming back from this Routine we know the size of the Command

                CPY #$0010            ; if the value of the size of the command is 16, then it is not a legit command
                BCS NOTRECOGNIZEDCOMMAND  ; This will output a Command Not Recognized
                JSR FINDCMDINLIST     ; This is where, it gets really cool
                BRA DONE_COMMANDPROCESS
ERROR_BUFFER_OVERRUN
                LDX #<>CMD_Error_Overrun
                JSL IPRINT       ; print the first line

DONE_COMMANDPROCESS
NO_CMD_2_PROCESS
                PLP
                RTL

                ; Error Handling Section
NOTRECOGNIZEDCOMMAND
                LDX #<>CMD_Error_Notfound
                JSL IPRINT       ; print the first line
                PLP
                RTS


; Let's count how many Characters there is in the Command
; Output: Y = How Many Character Does the Command has
HOWMANYCHARINCMD
                LDY #$0000
                PHX ; Push X to Stack for the time being
ENDOFCOMMANDNOTFOUND
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #$20              ; Check for a Space
                BEQ FOUNDTHEFOLLOWINGSPACE
                CMP #$0D              ; Check to see end of Command (if there is no arguments)
                BEQ FOUNDTHEFOLLOWINGSPACE
                INX
                INY
                CPY #$0010              ; Set the Maximum number of Character to 16 in the command
                BCC ENDOFCOMMANDNOTFOUND
FOUNDTHEFOLLOWINGSPACE
                PLX ; Get the Pointer Location of the First Character of the Command
                RTS

; This is where we are going to go fetch the Command and its Attributes
; Y = Lenght of the Command in Characters
; X = Read Pointer in the Line Buffer
FINDCMDINLIST
                STX CMD_PARSER_TMPX   ; Save X for the Time Being
                STY CMD_PARSER_TMPY   ; Save Y for the Time Being
                ; First load the Pointer of the List of Pointer
                setal
                LDA #<>CMDListPtr
                STA CMD_LIST_PTR
                LDA #$0000  ; Just to make sure B is zero
                setas
                LDA #`CMDListPtr
                STA CMD_LIST_PTR+2

                LDY #$0000
                STY CMD_VARIABLE_TMP
NOTTHERIGHTSIZEMOVEON
                LDY CMD_VARIABLE_TMP
                ; Setup the Pointer to the Field Entry of the Command Structure
                LDA [CMD_LIST_PTR],Y
                STA CMD_PARSER_PTR
                INY
                LDA [CMD_LIST_PTR],Y
                STA CMD_PARSER_PTR+1
                INY
                LDA [CMD_LIST_PTR],Y
                STA CMD_PARSER_PTR+2
                INY
                CPY #size(CMDListPtr)
                BCS COMMANDNOTFOUND   ; If we reach that limit then the Count didn't match any command in place
                STY CMD_VARIABLE_TMP
                ; Load the Size of the Actual Command
                LDA [CMD_PARSER_PTR] ;
                CMP CMD_PARSER_TMPY ;
                BNE NOTTHERIGHTSIZEMOVEON
                JSR CHECKSYNTAX       ; Now we have found a Command in the list that matches the number of Char, let's see if this is one if we are looking for
                BCS NOTTHERIGHTSIZEMOVEON ; Failed to Find
                ; Now if we pass this branch and we are here, well, your parents didn't take things too bad, and despite that you are going to brake your own children than there should be no worry
                ; Let's move on
                ; at this point, the
                STX CMD_PARSER_TMPX   ; Just to make sure, this is where the Pointer in the line buffer is...
                INY   ; Point to after the $00, the next 2 bytes are the Attributes
                LDA #$FF
                STA CMD_VALID
                LDA [CMD_PARSER_PTR], Y ;
                STA CMD_ATTRIBUTE
                INY
                LDA [CMD_PARSER_PTR], Y
                STA CMD_ATTRIBUTE+1
                INY   ; This will point towards the Jumping Vector for the execution of the Command
                LDA [CMD_PARSER_PTR], Y
                STA CMD_EXEC_ADDY
                INY
                LDA [CMD_PARSER_PTR], Y
                STA CMD_EXEC_ADDY+1
                INY
                LDA [CMD_PARSER_PTR], Y
                STA CMD_EXEC_ADDY+2

                LDX CMD_ATTRIBUTE
                CPX #$0000
                BEQ NO_ATTRIBUTE_GO_EXEC

                JSR PROCESS_ARGUMENTS
                LDA CMD_VALID
                CMP #$FF
                BEQ EXITWITHERROR       ; if Carry Set

NO_ATTRIBUTE_GO_EXEC
                setas
                JML [CMD_EXEC_ADDY]

COMMANDNOTFOUND
                LDX #<>CMD_Error_Notfound
                JSL IPRINT       ; print the first line
EXITWITHERROR
                RTS
; If we are here, it is because we have match in size and we have a point to one of the Command Structure Entry, so let's see if it matches the LinebUffer

; Check the Structure Entry for the Name of the Command , if the calls exits with Zero than, the Command was Found
; Found the Command Return Carry Clear
; Not Found the Command Return Carry Set
CHECKSYNTAX
                LDY #$0001      ; Point towards the Next Byte after the Size
                LDX CMD_PARSER_TMPX ; This is the Pointer in the Line Buffer where the First Character ought to be...
CHECKSYNTAXNEXTCHAR
                LDA [CMD_PARSER_PTR], Y ;
                CMP #$00  ; End of Character Check, if we reach that point, then we are on our way to have something happening! Call mom and dad and tell them how they failed to be good parents! Like all parents
                BEQ SUCCESSFOUNDCOMMAND
                CMP @lKEY_BUFFER, X   ;
                BNE CHARDONTMATCH
                INX
                INY
                BRA CHECKSYNTAXNEXTCHAR

CHARDONTMATCH   SEC
                RTS

SUCCESSFOUNDCOMMAND ; If Success, it will return 00
                CLC
                RTS


PROCESS_ARGUMENTS
                setaxl  ; Just making sure X/Y and A are 16bit wide right now
                ; before we can process the Attributes we need to know, which one that needs to be done
                LDX CMD_PARSER_TMPX ; This is the Pointer after the command
                JSR MOVE_POINTER_2_ARG  ; If there is supposed to be a parameter, this will go and fetch the next valid char
                BCC ATTRIBUTE_2_PROCESS
                setas
                RTS
                ; IF there is no Error let's load the Attribu
ATTRIBUTE_2_PROCESS
                setal
                LDA CMD_ATTRIBUTE
; Find the Device
                AND #CMD_ARGTYPE_DEV    ; This is to know, if it is for a Flppy or for the SDCard
                CMP #CMD_ARGTYPE_DEV
                BNE NOT_CMD_ARGTYPE_DEV ; Device Type @S, @F, @C, @P
                JSR FIND_CMD_ARGTYPE_DEV
                BCC NOT_CMD_ARGTYPE_DEV
                setas
                RTS
; Find the Filename
NOT_CMD_ARGTYPE_DEV
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_FN
                CMP #CMD_ARGTYPE_FN
                BNE NOT_CMD_ARGTYPE_FN
                JSR FIND_CMD_ARGTYPE_FN ; File Name
                BCC NOT_CMD_ARGTYPE_FN
                setas
                RTS

; Find the Starting Address
NOT_CMD_ARGTYPE_FN
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_SA
                CMP #CMD_ARGTYPE_SA
                BNE NOT_CMD_ARGTYPE_SA; Starting Address (Source)
                JSR FIND_CMD_ARGTYPE_SA

; Find the Ending Address
NOT_CMD_ARGTYPE_SA
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_EA
                CMP #CMD_ARGTYPE_EA
                BNE NOT_CMD_ARGTYPE_EA ; Ending Address (Destination)
                JSR FIND_CMD_ARGTYPE_EA

; Find 8bit Data
NOT_CMD_ARGTYPE_EA
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_8D
                CMP #CMD_ARGTYPE_8D
                BNE NOT_CMD_ARGTYPE_8D
                JSR FIND_CMD_ARGTYPE_8D ; 8bits Data

NOT_CMD_ARGTYPE_8D
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_16D
                CMP #CMD_ARGTYPE_16D
                BNE NOT_CMD_ARGTYPE_16D
                JSR FIND_CMD_ARGTYPE_16D; 16bit Data

NOT_CMD_ARGTYPE_16D
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_TIM
                CMP #CMD_ARGTYPE_TIM
                BNE NOT_CMD_ARGTYPE_TIM
                JSR FIND_CMD_ARGTYPE_TIM ; Time HH:MM:SS

NOT_CMD_ARGTYPE_TIM
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_DAT
                CMP #CMD_ARGTYPE_DAT
                BNE NOT_CMD_ARGTYPE_DAT
                JSR FIND_CMD_ARGTYPE_DAT ; DD/MM/YY, SAT

NOT_CMD_ARGTYPE_DAT
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_RGB
                CMP #CMD_ARGTYPE_RGB
                BNE NOT_CMD_ARGTYPE_RGB ; 24bit Data
                JSR FIND_CMD_ARGTYPE_RGB;

NOT_CMD_ARGTYPE_RGB
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_FN2
                CMP #CMD_ARGTYPE_FN2
                BNE NOT_CMD_ARGTYPE_FN2 ; Second File Name
                JSR FIND_CMD_ARGTYPE_FN2

NOT_CMD_ARGTYPE_FN2
                setal
                LDA CMD_ATTRIBUTE
                AND #CMD_ARGTYPE_DEC
                CMP #CMD_ARGTYPE_DEC
                BNE NO_ATTRIBUTE_2_PROCESS
                JSR FIND_CMD_ARGTYPE_DEC

NO_ATTRIBUTE_2_PROCESS
                setas
                LDA #$00
                STA CMD_VALID
                RTS

MOVE_POINTER_2_ARG
                setas
MOVE_POINTER_2_NEXT_SPACE
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #$0D
                BEQ ERROR_PARAMETERMISSING
                CMP #$20
                BNE POINTER_POINTING_NOT_A_SPACE_EXIT


                INX
                CPX #$0030  ; If the Move Pointer gets
                BCC MOVE_POINTER_2_NEXT_SPACE
                BRA ERROR_PARAMETERMISSING

POINTER_POINTING_NOT_A_SPACE_EXIT
                STX CMD_PARSER_TMPX
                setal
                CLC
                RTS
;
ERROR_PARAMETERMISSING
                setal
                LDX #<>CMD_Error_Missing
                JSL IPRINT       ; print the first line
                SEC
                RTS

;
ERROR_WRONGDEVICE
                setal
                LDX #<>CMD_Wrong_Device
                JSL IPRINT       ; print the first line
                SEC
                RTS
;S
;///////////////////////////////////////////////////////////////////////
;// Arguments Process
;//
;/
;/////////////////////////////////////////////////////////////////////
; Find the Device that the command wants to Target
FIND_CMD_ARGTYPE_DEV
                setas
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #'@'
                BNE ERROR_PARAMETERMISSING
                INX
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #'S'                ; Is it
                BEQ SDCARD_CHOICE
                CMP #'F'
                BNE ERROR_WRONGDEVICE
SDCARD_CHOICE
                STA CMD_ARG_DEV
                STX CMD_PARSER_TMPX
                CLC
                setal
                RTS

; Find the Filename that the command wants to target
FIND_CMD_ARGTYPE_FN
                LDX CMD_PARSER_TMPX
                INX
                JSR MOVE_POINTER_2_ARG  ; Check if there is a space after the parameter
                setas
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #','
                BNE ERROR_PARAMETERMISSING
                INX
                JSR MOVE_POINTER_2_ARG  ; Check if there is a space after the parameter
                setas
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #'"'
                BNE ERROR_PARAMETERMISSING
                LDY #$0000
                INX
KEEP_READING_FN
                LDA @lKEY_BUFFER, X     ; Fetch the first char
                CMP #'"'
                BEQ DONE_FILE_SAVE
                STA SDOS_FILE_NAME,Y
                INX
                INY
                CPY #$0010
                BNE KEEP_READING_FN
DONE_FILE_SAVE

                RTS

; Find the Filename that the command wants to target
FIND_CMD_ARGTYPE_SA
                PHA


                setal
                PLA
                RTS
;
; Find the Filename that the command wants to target
FIND_CMD_ARGTYPE_EA
                PHA


                setal
                PLA
                RTS

; Find 8bit data ($00 to $FF)
FIND_CMD_ARGTYPE_8D
                PHA


                setal
                PLA
                RTS
;
; Find 16bit data ($0000 to $FFFF)
FIND_CMD_ARGTYPE_16D
                PHA


                setal
                PLA
                RTS

;Find Time Parameters
FIND_CMD_ARGTYPE_TIM
                PHA


                setal
                PLA
                RTS
;
;Find Date Parameters
FIND_CMD_ARGTYPE_DAT
                PHA


                setal
                PLA
                RTS
;Find RGB Argument 24bit Data
FIND_CMD_ARGTYPE_RGB
                PHA


                setal
                PLA
                RTS
;Second Filename
FIND_CMD_ARGTYPE_FN2
                PHA


                setal
                PLA
                RTS
;Find a Decimal Number
FIND_CMD_ARGTYPE_DEC
                PHA


                setal
                PLA
                RTS
;///////////////////////////////////////////////////////////////////////
;// Commands Process
;//
;//
;/////////////////////////////////////////////////////////////////////

ENTRY_CMD_CLS
              setas
              setxl
              LDX #$0000		; Only Use One Pointer
              LDA #$20		; Fill the Entire Screen with Space
CLEARSCREENL0	STA CS_TEXT_MEM_PTR, x	;
              inx
              cpx #$2000
              bne CLEARSCREENL0
; Now Set the Colors so we can see the text
              LDX	#$0000		; Only Use One Pointer
              LDA #$ED		; Fill the Color Memory with Foreground: 75% Purple, Background 12.5% White
CLEARSCREENL1	STA CS_COLOR_MEM_PTR, x	;
              inx
              cpx #$2000
              bne CLEARSCREENL1
              LDX #$0000
              STX KEY_BUFFER_WPOS
              STX KEY_BUFFER_RPOS
              LDY #$0000
              JSL ILOCATE
              RTS

ENTRY_CMD_DIR
              LDX #<>DIR_COMMAND
              JSL IPRINT       ; print the first line
;              LDA @lJOYSTICK2
;              AND #$80        ; Card Present when 1
;              BNE SDNOT_PRESENT;
              ; If where are here, there is a Card inserted in the slot
;              LDA @lJOYSTICK3
;              AND #$80        ; Card WProtect When 0
;              BEQ SDNOT_WP;
;              LDX #<>CMD_Error_SD_WP
;              JSL IPRINT       ; print the first line
;SDNOT_WP
              JSL ISDOS_INIT
              JSL ISDOS_DIR
              RTS
SDNOT_PRESENT
              LDX #<>CMD_Error_SD_NotPresent
              JSL IPRINT       ; print the first line
              RTS

RTS

ENTRY_CMD_EXEC
  LDX #<>EXEC_COMMAND
  JSL IPRINT       ; print the first line
RTS

ENTRY_CMD_LOAD
LDX #<>LOAD_COMMAND
JSL IPRINT       ; print the first line
RTS

ENTRY_CMD_SAVE RTS

ENTRY_CMD_PEEK8     RTS
ENTRY_CMD_POKE8     RTS
ENTRY_CMD_POKE16    RTS
ENTRY_CMD_PEEK16    RTS
ENTRY_CMD_RECWAV    RTS
ENTRY_CMD_EXECFNX   RTS
ENTRY_CMD_GETDATE
              setas
              LDA @lRTC_DAY   ; Go Read the Hour Registers
              PHA
              AND #$30
              LSR A
              LSR A
              LSR A
              LSR A
              ORA #$30
              JSL IPUTC
              PLA
              AND #$0F
              ORA #$30
              JSL IPUTC
              LDA #'/'
              JSL IPUTC
              LDA @lRTC_MONTH   ; Go Read the Min Registers
              PHA
              AND #$10
              LSR A
              LSR A
              LSR A
              LSR A
              ADC #$30
              JSL IPUTC
              PLA
              AND #$0F
              ORA #$30
              JSL IPUTC
              LDA #'/'
              JSL IPUTC
              LDA @lRTC_YEAR   ; Go Read the Sec Registers
              PHA
              AND #$F0
              LSR A
              LSR A
              LSR A
              LSR A
              ORA #$30
              JSL IPUTC
              PLA
              AND #$0F
              ORA #$30
              JSL IPUTC
              LDA #','
              JSL IPUTC
              ; Now let's display the DOW
              LDA @lRTC_DOW
              DEC A
              ASL A
              ASL A
              TAX
GO_PUTC_THE_DOW
              LDA @lDOW,X
              CMP #$00
              BEQ DOW_IPUTC_DONE
              INX
              PHX
              JSL IPUTC
              PLX
              BRA GO_PUTC_THE_DOW
DOW_IPUTC_DONE
              LDA #$0D
              JSL IPUTC
              RTS

; This is the Command to go read the RTC Internal Registers and to Display them on the screen
ENTRY_CMD_GETTIME
              setas
              LDA @lRTC_HRS   ; Go Read the Hour Registers
              PHA
              AND #$30
              LSR A
              LSR A
              LSR A
              LSR A
              ORA #$30
              JSL IPUTC
              PLA
              AND #$0F
              ORA #$30
              JSL IPUTC
              LDA #':'
              JSL IPUTC
              LDA @lRTC_MIN   ; Go Read the Min Registers
              PHA
              AND #$70
              LSR A
              LSR A
              LSR A
              LSR A
              ADC #$30
              JSL IPUTC
              PLA
              AND #$0F
              ORA #$30
              JSL IPUTC
              LDA #':'
              JSL IPUTC
              LDA @lRTC_SEC   ; Go Read the Sec Registers
              PHA
              AND #$F0
              LSR A
              LSR A
              LSR A
              LSR A
              ORA #$30
              JSL IPUTC
              PLA
              AND #$0F
              ORA #$30
              JSL IPUTC
              LDA @lRTC_HRS
              AND #$80
              CMP #$80
              BEQ AMFMCHOICE
              LDA #'A'
              JSL IPUTC
              BRA GO_PUTC_THE_M
AMFMCHOICE
              LDA #'P'
              JSL IPUTC
GO_PUTC_THE_M
              LDA #'M'
              JSL IPUTC
              LDA #$0D
              JSL IPUTC
RTS



ENTRY_CMD_MONITOR   RTS
ENTRY_CMD_PLAYRAD   RTS
ENTRY_CMD_PLAYWAV   RTS
ENTRY_CMD_SETDATE   RTS
ENTRY_CMD_SETTIME   RTS
ENTRY_CMD_SYSINFO   RTS
ENTRY_CMD_DISKCOPY  RTS
ENTRY_CMD_SETTXTLUT RTS



; Command List
; Please Order the Commands by Size then Alpha
; Command Lenght, Command Text, EOS($00), ARGTYPE, Pointer To Code to Execute
CMD .block
CLS       .text $03, "CLS", $00, CMD_ARGTYPE_NO, ENTRY_CMD_CLS                                        ; Clear Screen
DIR       .text $03, "DIR", $00, CMD_ARGTYPE_DEV, ENTRY_CMD_DIR                                       ; @F, @S
EXEC      .text $04, "EXEC", $00, CMD_ARGTYPE_SA, ENTRY_CMD_EXEC                                        ; EXEC S:$00000
LOAD      .text $04, "LOAD", $00, (CMD_ARGTYPE_DEV | CMD_ARGTYPE_FN | CMD_ARGTYPE_EA), ENTRY_CMD_LOAD   ; "LOAD @F, "NAME.XXX", D:$000000
SAVE      .text $04, "SAVE", $00, (CMD_ARGTYPE_DEV | CMD_ARGTYPE_FN | CMD_ARGTYPE_SA | CMD_ARGTYPE_EA), ENTRY_CMD_SAVE           ; SAVE @F, "NAME.XXX", S:$000000, D:$000000
PEEK8     .text $06, "PEEK8H", $00,  CMD_ARGTYPE_SA, ENTRY_CMD_PEEK8       ; PEEK8 $000000
POKE8     .text $06, "POKE8H", $00, (CMD_ARGTYPE_SA | CMD_ARGTYPE_8D), ENTRY_CMD_POKE8          ; POKE8 $000000, $00
RECWAV    .text $06, "RECWAV", $00, (CMD_ARGTYPE_DEV | CMD_ARGTYPE_FN) , ENTRY_CMD_RECWAV          ; RECWAV @S, "NAME.XXX" (Samples)
EXECFNX   .text $07, "EXECFNX", $00, CMD_ARGTYPE_FN, ENTRY_CMD_EXECFNX        ; "EXECFNX "NAME.XXX"
GETDATE   .text $07, "GETDATE", $00, CMD_ARGTYPE_NO, ENTRY_CMD_GETDATE       ; GETDATE
GETTIME   .text $07, "GETTIME", $00, CMD_ARGTYPE_NO, ENTRY_CMD_GETTIME        ; GETTIME
MONITOR   .text $07, "MONITOR", $00, CMD_ARGTYPE_NO, ENTRY_CMD_MONITOR       ; MONITOR TBD
PLAYRAD   .text $07, "PLAYRAD", $00, (CMD_ARGTYPE_DEV | CMD_ARGTYPE_FN), ENTRY_CMD_PLAYRAD        ; PLAYRAD @S, "NAME.XXX" (music File)
PLAYWAV   .text $07, "PLAYWAV", $00, (CMD_ARGTYPE_DEV | CMD_ARGTYPE_FN), ENTRY_CMD_PLAYWAV                ; PLAYWAV @S, "NAME.XXX" (samples)
PEEK16    .text $07, "PEEK16H", $00, CMD_ARGTYPE_SA, ENTRY_CMD_POKE16, ENTRY_CMD_PEEK16        ; PEEK16 $000000
POKE16    .text $07, "POKE16H", $00, (CMD_ARGTYPE_SA | CMD_ARGTYPE_16D), ENTRY_CMD_POKE16           ; POKE16 $000000, $0000
SETDATE   .text $07, "SETDATE", $00, CMD_ARGTYPE_DAT, ENTRY_CMD_SETDATE      ; SETDATE YY:MM:DD
SETTIME   .text $07, "SETTIME", $00, CMD_ARGTYPE_TIM, ENTRY_CMD_SETTIME       ; SETTIME HH:MM:SS
SYSINFO   .text $04, "SYSINFO", $00, CMD_ARGTYPE_NO, ENTRY_CMD_SYSINFO
DISKCOPY  .text $08, "DISKCOPY", $00, CMD_ARGTYPE_DEV, CMD_ARGTYPE_DEV, ENTRY_CMD_DISKCOPY           ; DISKCOPY @F, @F
FILECOPY  .text $08, "FILECOPY", $00, (CMD_ARGTYPE_FN | CMD_ARGTYPE_FN2)
SETBGCLR  .text $08, "SETBGCLR", $00, CMD_ARGTYPE_DEC
SETFGCLR  .text $08, "SETFGCLR", $00, CMD_ARGTYPE_DEC
SETTXTLUT .text $09, "SETTXTLUT", $00, (CMD_ARGTYPE_DAT | CMD_ARGTYPE_RGB), ENTRY_CMD_SETTXTLUT        ; SETLUT $00, $000000
SETBRDCLR .text $09, "SETBRDCLR", $00, CMD_ARGTYPE_RGB
      .bend

CMDListPtr .long CMD.CLS, CMD.DIR, CMD.EXEC, CMD.LOAD, CMD.SAVE, CMD.PEEK8, CMD.POKE8, CMD.PEEK16, CMD.POKE16, CMD.RECWAV, CMD.EXECFNX, CMD.GETDATE, CMD.GETTIME, CMD.MONITOR, CMD.PLAYRAD, CMD.PLAYWAV, CMD.SETDATE, CMD.SETTIME, CMD.SYSINFO, CMD.DISKCOPY, CMD.SETTXTLUT

CMD_ARGTYPE_NO    = $0000 ; No Argument
CMD_ARGTYPE_DEV   = $0001 ; Device Type @S, @F
CMD_ARGTYPE_FN    = $0002 ; File Name
CMD_ARGTYPE_SA    = $0004 ; Starting Address (Source)
CMD_ARGTYPE_EA    = $0008 ; Ending Address (Destination)
CMD_ARGTYPE_8D    = $0010 ; 8bits Data
CMD_ARGTYPE_16D   = $0020 ; 16bits Data
CMD_ARGTYPE_TIM   = $0040 ; Time
CMD_ARGTYPE_DAT   = $0080 ; Date
CMD_ARGTYPE_RGB   = $0100 ; RGB Data (24Bit Data) for LUT mainly
CMD_ARGTYPE_FN2   = $0200 ; Second File name
CMD_ARGTYPE_DEC   = $0400 ; Decimal value

DIR_COMMAND .text $0D, "@SDCARD:", $00
CLS_COMMAND .text "CLS", $00
EXEC_COMMAND .text "EXEC Command Executing...", $00
LOAD_COMMAND .text "LOAD", $00
CMD_Error_Syntax  .text "E000 - SYNTAX ERROR", $00
CMD_Error_Missing .text "E001 - MISSING PARAMETER(S)", $00
CMD_Wrong_Device  .text "E002 - NO SUCH DEVICE EXISTS", $00
CMD_Error_Wrong   .text "Wrong Parameters...", $00
CMD_Error_Overrun .text "E004 BUFFER OVERRUN ERROR", $00
CMD_Error_Notfound .text "SYNTAX ERROR", $00
CMD_Error_SD_NotPresent .text "SDCARD NOT PRESENT", $00
CMD_Error_SD_WP .text "SDCARD WP", $00

; the Day of the Week must stay 4 Characters 3 Char + $00, or the routine won't work.
DOW      .text "SUN", $00, "MON", $00, "TUE", $00, "WED", $00, "THU", $00, "FRI", $00, "SAT", $00
