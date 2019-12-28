.cpu "65816"

; SD Card OS
;SDOS.asm
;Jump Table
;* = $392000
.include "ch376s_inc.asm"

; Low-Level Command for the SD Card OS
; CH376S Controller Commands

SDOS_CHECK_CD JML ISDOS_CHK_CD ; Check if Card is Present
SDOS_CHECK_WP JML ISDOS_CHK_WP ; Check if Card is Write Protected

; High-Level Command for the SD CARD
SDOS_INIT     JML ISDOS_INIT
SDOS_DIR      JML ISDOS_DIR
SDOS_CHDIR    JML ISDOS_CHDIR
SDOS_LOAD     JML ISDOS_LOAD
SDOS_SAVE     JML ISDOS_SAVE
SDOS_EXEC     JML ISDOS_EXEC

;/////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////
; ISDOS_INIT
; Init the SDCARD
; Inputs:
;  None
; Affects:
;   None
ISDOS_INIT    setas
              LDA @lINT_PENDING_REG1  ; Read the Pending Register &
              AND #~FNX1_INT07_SDCARD   ; Enable
              STA @lINT_PENDING_REG1

              ;LDA @lINT_POL_REG1
              ;ORA #FNX1_INT07_SDCARD
              ;STA @lINT_POL_REG1
              ;LDA @lINT_MASK_REG1
              ;AND #~FNX1_INT07_SDCARD   ; Enable
              ;STA @lINT_MASK_REG1

              LDA #$06
              STA SDCARD_CMD
              JSR DLYCMD_2_DTA
              LDA #$A8
              STA @lSDCARD_DATA
              JSR DLYDTA_2_DTA
              JSR DLYDTA_2_DTA
              JSR DLYDTA_2_DTA
              LDA @lSDCARD_DATA
              JSR DLYCMD_2_DTA

              LDA #CH_CMD_SET_MODE
              STA @lSDCARD_CMD
              JSR DLYCMD_2_DTA
              JSR DLYCMD_2_DTA
              LDA #$03            ; Mode 3 - SDCARD
              STA @lSDCARD_DATA     ; Write the MODE and Wait for around ~10us

ISDOS_WAIT_FOR_MODE_SW
              JSR DLYDTA_2_DTA ; Wait 0.6us
              LDA @lSDCARD_DATA
              CMP #$51   ; CMD_RET_SUCCESS		EQU		051H, CMD_RET_ABORT		EQU		05FH
              BNE ISDOS_WAIT_FOR_MODE_SW

              LDA @lSDCARD_DATA     ; See the Status Output
              RTL

;////////////////////////////////////////////////////////
; ISDOS_MOUNT_CARD
; Check to see if Card exist, then Mount the SDCArd
; Inputs:
;   Pointer to the ASCII File name by
; Located @ $000030..$000032 - SDCARD_FLNMPTR_L
; Affects:
;   None
; Upon the Call of this Routine Display the Files on the SDCARD
ISDOS_DIR
              setas
              setxl
              JSR ISDOS_MOUNT_CARD;     First to See if the Card is Present
;              LDA SDCARD_PRSNT_MNT;
;              BEQ NO_SDCARD_PRESENT     ; No SD Card Present
              ; Transfer the "/*\0" String
              LDX #$0000
ISDOS_DIR_TRF
              LDA sd_card_dir_string,X    ; /
              STA @lSDOS_FILE_NAME,X
              INX
              CPX #$0003
              BNE ISDOS_DIR_TRF

              JSR SDOS_FILE_OPEN         ; Now that the file name is set, go open File
              CMP #CH376S_STAT_DSK_RD
              BEQ ISDOS_DIR_CONT0
              BRL ISDOS_MISS_FILE
ISDOS_DIR_CONT0

;              LDX #<>sd_card_msg4         ; Print Screen the Message "FILE OPENED";
;              JSL IPRINT       ; print the first line
ISDOS_NEXT_ENTRY
              LDA #CH_CMD_RD_DATA0
              STA @lSDCARD_CMD
              JSR DLYCMD_2_DTA;
              LDA @lSDCARD_DATA  ;  Load First Data
              LDY #$0000
              LDX #$0000
              TAY              ; GET Size (Save in Case we need it)
;#1 Display File Name @ Empty the buffer, since we don't need info for now.
ISDOS_DIR_GET_CHAR
              JSR DLYDTA_2_DTA ; Wait 0.6us
              LDA @lSDCARD_DATA  ;
              JSL IPUTC        ; Print the character
              INX
              CPX #$0008
              BNE ISDOS_DIR_CONT1
              JSR ISDOS_DISPLAY_DOT
ISDOS_DIR_CONT1
              CPX #$000B          ; the First 11th Character is the file name
              BNE ISDOS_DIR_GET_CHAR
              LDA #$20
              JSL IPUTC        ; Print the character
              LDA #'('
              JSL IPUTC        ; Print the character
              LDA @lSDCARD_DATA  ;
              AND #$10
              CMP #$10
              BEQ ISDOS_DIR_ATTR0
              LDA #'F'
              BRA ISDOS_DIR_ATTR1
ISDOS_DIR_ATTR0
              LDA #'D'
ISDOS_DIR_ATTR1
              JSL IPUTC        ; Print the character
              LDA #')'
              JSL IPUTC        ; Print the character
              LDA #$0D         ; Carriage Return
              JSL IPUTC        ; Print the character
ISDOS_DIR_GET_CHAR_FINISH
              JSR DLYDTA_2_DTA ; Wait 0.6us
              LDA @lSDCARD_DATA  ; After the name Just empty the buffer
;             JSL IPUTC        ; Print the character
              INX
              CPX #$0020
              BNE ISDOS_DIR_GET_CHAR_FINISH
              JSR DLYCMD_2_DTA
              ; Ask Controller to go fetch the next entry in the Directory
              LDA #CH_CMD_FILE_ENUM_GO
              STA @lSDCARD_CMD
              JSR SDCARD_WAIT_4_INT       ; Go Wait for Interrupt
              CMP #CH376S_STAT_DSK_RD
              BEQ ISDOS_NEXT_ENTRY
              CMP #CH376S_ERR_MISS_FIL
              BNE  ISDOS_MISS_FILE
              LDX #<>sd_card_msg5   ; End of File
              BRL ISDOS_DIR_DONE
ISDOS_MISS_FILE
              LDX #<>sd_card_err0
              BRL ISDOS_DIR_DONE
NO_SDCARD_PRESENT
              LDX #<>sd_no_card_msg
ISDOS_DIR_DONE
              JSL IPRINT       ; print the first line
              JSR SDOS_FILE_CLOSE
              ; There should be an Error Code Displayed here...
              RTL;
ISDOS_DISPLAY_DOT
              LDA #'.'
              JSL IPUTC        ; Print the character
              RTS;
; Upon the Call of this Routine will Change the pointer to a new Sub-Directory
ISDOS_CHDIR   BRK;
;/////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////
; ISDOS_LOAD
; Load a File to Memory
; Inputs:
;  None
; Affects:
;   None
ISDOS_LOAD
              JSR SDOS_READ_FILE;
              RTL;

; Upon the Call of this Routine this will Save a file defined by the given name and Location
ISDOS_SAVE    BRK;

; Load a File ".FNX" and execute it
ISDOS_EXEC    BRK;

;/////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////
; ISDOS_MOUNT_CARD
; Check to see if Card exist, then Mount the SDCArd
; Inputs:
;   Pointer to the ASCII File name by
; Located @ $000030..$000032 - SDCARD_FLNMPTR_L
; Affects:
;   None
ISDOS_MOUNT_CARD
              setas
;              JSR ISDOS_CHK_CD            ; Check to See if a Card is present
;              BCC ISDOS_NO_CARD           ;
              setxl
              ;LDX #<>sd_card_msg1         ; Print Screen the Message "Card Detected"
              ;JSL IPRINT       ; print the first line
;              LDA SDCARD_PRSNT_MNT        ; Load Presence Status
;              AND #$05
;              CMP #$05
;              BEQ ISDOS_MOUNTED
              LDY #$0000
              LDA #$01
              STA SDCARD_PRSNT_MNT        ; Bit[0] = Card Present
TRY_MOUNT_AGAIN
              LDA #CH_CMD_DISK_MOUNT      ; If Present, go Mount it.
              STA @lSDCARD_CMD              ;
              JSR SDCARD_WAIT_4_INT       ;
              CMP #CH376S_STAT_SUCCESS    ;
              BEQ ISDOS_MOUNTED
              INY
              CPY #$0005
              BNE TRY_MOUNT_AGAIN
              JMP SDCARD_ERROR_MOUNT
ISDOS_MOUNTED ; The Card is already mounted
;              LDX #<>sd_card_msg2         ; Print Screen the Message "Card Detected"
;              JSL IPRINT       ; print the first line

              LDA SDCARD_PRSNT_MNT
              AND #~SDCARD_PRSNT_MNTED
              ORA #SDCARD_PRSNT_MNTED     ; Set Bit to Indicate that is mounted
              RTS

SDCARD_ERROR_MOUNT
              LDX #<>sd_card_msg3         ; Print Screen the Message "Card Detected"
              JSL IPRINT       ; print the first line
              RTS

ISDOS_NO_CARD LDA #SDCARD_PRSNT_NO_CARD
              STA SDCARD_PRSNT_MNT
              RTS

;
; ISDOS_FILE_OPEN
; Open the File
; Inputs:
; File Name ought to be here: SDOS_FILE_NAME and be terminated by NULL.
; Affects:
;   A
; Outputs:
; A = Interrupt Status
SDOS_FILE_OPEN
              JSR SDOS_SET_FILE_NAME ; Make Sure the Pointer to the File Name is properly
              JSR DLYCMD_2_DTA
              LDA #CH_CMD_FILE_OPEN ;
              STA @lSDCARD_CMD          ; Go Request to open the File
              JSR SDCARD_WAIT_4_INT   ; A Interrupt is Generated, so go polling it
              RTS

SDOS_FILE_CLOSE
              LDA #CH_CMD_FILE_CLOSE ;
              STA @lSDCARD_CMD          ; Go Request to open the File
              JSR DLYCMD_2_DTA
              LDA #$00                ; FALSE
              STA @lSDCARD_DATA         ; Store into the Data Register of the CH376s
              JSR SDCARD_WAIT_4_INT   ; A Interrupt is Generated, so go polling it
              RTS
; SDOS_SET_FILE_NAME
; Set the Filename to the Controller CH376D
; Inputs:
; File Name ought to reside here: SDOS_FILE_NAME
; Affects:
;   None
SDOS_SET_FILE_NAME
              LDA #CH_CMD_SET_FILENAME
              STA @lSDCARD_CMD
              JSR DLYCMD_2_DTA
              LDX #$0000
SDOS_SET_FILE_LOOP
              LDA @lSDOS_FILE_NAME, X   ; This is where the FileName ought to be.
              STA @lSDCARD_DATA         ; Store into the Data Register of the CH376s
              JSR DLYDTA_2_DTA
              INX
              CMP #$00              ; Check end of Line
              BNE SDOS_SET_FILE_LOOP
              RTS

;
; 1.5us Delay inbetween the time the Cmd is Sent and Data is either Read or Writen
; NOP takes 2 Cycles Now
DLYCMD_2_DTA
              NOP
              NOP
              NOP
              NOP
              NOP
; 0.6us Delay inbetween the time the Cmd is Sent and Data is either Read or Writen
DLYDTA_2_DTA
              NOP
              NOP
              NOP
              NOP
              NOP
              RTS;
;
; SDCARD_WAIT_4_INT
; Blocking - Wait for the CH376S Interrupt
; Inputs:
;
; Outputs:
;   A = Interrupt Status
;SDCARD_WAIT_4_INT
;              setas             ; This is for security
;              SEI                 ; There is no time out on this, so let's
                                  ; make sure it is not going to be interrupted
;SDCARD_BUSY_INT
;              LDA @lSDCARD_CMD    ; Read Status of Interrupt and
;              AND #$80          ; Bit[7] = !INT if Zero = Busy
;              CMP #$80          ;
;              BEQ SDCARD_BUSY_INT
;              CLI
              ; Fetch the Status
;              JSR DLYCMD_2_DTA ;
;              JSR DLYCMD_2_DTA ;
;              LDA #CH_CMD_GET_STATUS
;              STA @lSDCARD_CMD;
;              JSR DLYCMD_2_DTA;   ; 1.5us Delay to get the Value Return
;              LDA @lSDCARD_DATA;
;              RTS           ;

SDCARD_WAIT_4_INT
              setas             ; This is for security
;              SEI                 ; There is no time out on this, so let's
                                                ; make sure it is not going to be interrupted
;              LDA @lINT_PENDING_REG1  ; Read the Pending Register &
;              AND #$7F   ; Enable
;              STA @lINT_PENDING_REG1
SDCARD_BUSY_INT
              LDA @lINT_PENDING_REG1  ; Check to See if the Pending Register for the SD_INT is Set
              AND #FNX1_INT07_SDCARD  ;
              CMP #FNX1_INT07_SDCARD
              BNE SDCARD_BUSY_INT   ; Go Check again to see if it is checked
              STA @lINT_PENDING_REG1    ;Interrupt as occured, clear the Pending Register for next time.
              ; Fetch the Status
              JSR DLYCMD_2_DTA ;
              JSR DLYCMD_2_DTA ;
              LDA #CH_CMD_GET_STATUS
              STA @lSDCARD_CMD;
              JSR DLYCMD_2_DTA;   ; 1.5us Delay to get the Value Return
              LDA @lSDCARD_DATA;
              RTS           ;
; ISDOS_CHK_CD
; Return the Value of SD Card Present Status
; Inputs:
;   None
; Affects:
;   Carry - If Card Present -> Carry = 1
ISDOS_CHK_CD  setas
              CLC
              LDA SDCARD_STAT;  BIT[0] = Cd, BIT[1] = WP
              AND #$01
              CMP #$01
              BEQ SDCD_NOT_PRST;
              SEC
SDCD_NOT_PRST RTS
;
; ISDOS_CHK_WP
; Return the Value of WP Card Present Status
; Inputs:
;   None
; Affects:
;   Carry - If Card Write Protect -> Carry = 1
ISDOS_CHK_WP  setas
              CLC
              LDA SDCARD_STAT;  BIT[0] = Cd, BIT[1] = WP
              AND #$02
              BNE SDCD_NOT_WP;
              SEC
SDCD_NOT_WP   RTS

ISDOS_GET_FILE_SIZE
              setas
              LDA #CH_CMD_RD_VAR32
              STA @lSDCARD_CMD;
              JSR DLYCMD_2_DTA;   ; 3us Delay to get the Value Return
              LDA #CH_VAR_FILE_SIZE
              STA @lSDCARD_DATA;
              JSR DLYCMD_2_DTA
              LDA @lSDCARD_DATA         ;LSB First
              STA @lSDOS_FILE_SIZE+0
              STA @lADDER32_A_LL;     ; Store in ADDER32 REgister A
              JSR DLYDTA_2_DTA
              LDA @lSDCARD_DATA
              STA @lSDOS_FILE_SIZE+1
              STA @lADDER32_A_LH;     ; Store in ADDER32 REgister A
              JSR DLYDTA_2_DTA
              LDA @lSDCARD_DATA
              STA @lSDOS_FILE_SIZE+2
              STA @lADDER32_A_HL;     ; Store in ADDER32 REgister A
              JSR DLYDTA_2_DTA
              LDA @lSDCARD_DATA
              STA @lSDOS_FILE_SIZE+3   ;MSB Last
              STA @lADDER32_A_HH;     ; Store in ADDER32 REgister A
              JSR DLYDTA_2_DTA
              LDA @lADDER32_R_LL;
              LDA @lADDER32_R_LH;
              LDA @lADDER32_R_HL;
              LDA @lADDER32_R_HH;
              RTS


; ISDOS_READ_FILE
; Go Open and Read a file and store it to prefedined address
; Inputs:
;  Name @ SDOS_FILE_NAME, Pointer to Store the DATA: @ SDCARD_FILE_PTR ($00:00030)
; Affects:
;   A, X probably Y and CC and the whole thing... So don't asume anything...
; Returns:
; Well, you ought to have your file loaded where you asked it.
SDOS_READ_FILE
              setaxl
              JSR SDOS_SETUP_ADDER_B;
              ; First Let's Setup the file Name and Open the File
              ; First Step, Let's find and open the file we want to load.
              setas
              JSR SDOS_FILE_OPEN
              ; If successful, get the file sizeof
              CMP #CH376S_STAT_SUCCESS ; if the file open successfully, let's go on.
              BEQ SDOS_READ_FILE_KEEP_GOING
              BRL SDOS_READ_END
SDOS_READ_FILE_KEEP_GOING
              ; Then go read the file
              LDX #<>sd_card_msg6         ; Print Screen the Message "FILE FOUND, LOADING..."
              JSL IPRINT       ; print the first line
              ;
              JSR ISDOS_GET_FILE_SIZE   ; Get the File Size in 32Bits
              setal
;              JSR SDOS_LOAD_ADDER_A_WITH_SIZE;  Load the Size in the Signed Adder
              JSR SDOS_SETUP_CH376S_BUFFER_SIZE;
              LDA #$0000
              STA @lSDCARD_BYTE_NUM; Just make sure the High Part of the Size is Zero
              STA @lSDOS_BYTE_PTR   ; Clear the Byte Pointer 32 Bytes Register
              STA @lSDOS_BYTE_PTR+2 ; This is to Relocated the Pointer after you passed the 64K Boundary
              ; Second Step, Setup the Amount of Data to Send
              ; Set the Transfer Size, I will try 256 bytes
              setas
SDOS_READ_FILE_GO_FETCH_A_NEW_64KBlock
              LDA #CH_CMD_BYTE_READ
              STA @lSDCARD_CMD;
              JSR DLYCMD_2_DTA;   ; 3us Delay to get the Value Return
              LDA @lSDOS_BYTE_NUMBER
              STA @lSDCARD_DATA
              JSR DLYDTA_2_DTA;   ; 1.5us Delay to get the Value Return
              LDA @lSDOS_BYTE_NUMBER+1
              STA @lSDCARD_DATA
              JSR SDCARD_WAIT_4_INT
              CMP #CH376S_STAT_DSK_RD ;
              BEQ SDOS_READ_FILE_GO_FETCH_A_NEW_BLOCK
              BRL SDOS_READ_END
SDOS_READ_FILE_GO_FETCH_A_NEW_BLOCK
              ; Go Read 1 Block and Store it @ ($00:0030)
              JSR SDOS_READ_BLOCK
              LDA #CH_CMD_BYTE_RD_GO
              STA @lSDCARD_CMD
              ;Now let's go to Poll the INTERRUPT and wait for
              JSR SDCARD_WAIT_4_INT
              CMP #CH376S_STAT_DSK_RD ;
              BNE SDOS_READ_PROC_DONE
              JSR SDOS_ADJUST_POINTER  ; Go Adjust the Address
              BRA SDOS_READ_FILE_GO_FETCH_A_NEW_BLOCK
SDOS_READ_PROC_DONE
              setal
              LDA @lSDOS_BYTE_NUMBER  ; Load the Previously number of Byte
              CMP #$FFFF
              BNE SDOS_READ_DONE1                  ; if it equal 64K, then the file is bugger than 64K
              ; Now let's go compute the Nu Value for the Next Batch
              LDA @lADDER32_R_LL
              STA @lADDER32_A_LL
              LDA @lADDER32_R_HL
              STA @lADDER32_A_HL
              JSR SDOS_SETUP_CH376S_BUFFER_SIZE ;
              JSR SDOS_COMPUTE_LOCATE_POINTER
              setas
              JSR SDOS_BYTE_LOCATE    ; Apply the new location for the CH376S
              JSR SDCARD_WAIT_4_INT
              CMP #CH376S_STAT_SUCCESS ;
              BNE SDOS_READ_END
              ; Check to see that we have Loaded all the bytes.
              BRA SDOS_READ_FILE_GO_FETCH_A_NEW_64KBlock ; Let's go fetch a new block of 64K or less
;SDOS_READ_DONE
;              CMP #CH376S_STAT_SUCCESS
;              BNE SDOS_READ_END
SDOS_READ_DONE1
              LDA #$00
              LDX #<>sd_card_msg7         ; Print Screen the Message "FILE LOADED"
              BRA SDOS_READ_PROC_DONE1
SDOS_READ_END
              LDA #$FF
              LDX #<>sd_card_err1         ;"ERROR LOADING FILE"
SDOS_READ_PROC_DONE1
              JSL IPRINT       ; print the first line
              RTS;

SDOS_ADJUST_POINTER
              setal
              CLC
              LDA SDCARD_FILE_PTR ;Load the Pointer
              ADC SDCARD_BYTE_NUM
              STA SDCARD_FILE_PTR;
              setas
              LDA SDCARD_FILE_PTR+2;
              ADC #$00          ; This is just add up the Carry
              STA SDCARD_FILE_PTR+2;
SDOS_ADJ_DONE
              RTS

SDOS_BYTE_LOCATE  ; Reposition the Pointer of the CH376S when the File is > 64K
              setas
              LDA #CH_CMD_BYTE_LOCATE
              STA @lSDCARD_CMD
              JSR DLYCMD_2_DTA
              LDA @lSDOS_BYTE_PTR
              STA @lSDCARD_DATA
              JSR DLYDTA_2_DTA
              LDA @lSDOS_BYTE_PTR+1
              STA @lSDCARD_DATA
              JSR DLYDTA_2_DTA
              LDA @lSDOS_BYTE_PTR+2
              STA @lSDCARD_DATA
              JSR DLYDTA_2_DTA
              LDA @lSDOS_BYTE_PTR+3
              STA @lSDCARD_DATA
              RTS
; This will increment the pointer for the CH376S
SDOS_COMPUTE_LOCATE_POINTER
              setal
              CLC
              LDA @lSDOS_BYTE_PTR ; $00330
              ADC #$FFFF
              STA @lSDOS_BYTE_PTR
              LDA @lSDOS_BYTE_PTR+2
              ADC #$0000          ; this is to Add the Carry
              STA @lSDOS_BYTE_PTR+2
              RTS
; Load Register B of the 32Bit Adder with the Value -65535 (size of the CH376S Buffer)
SDOS_SETUP_ADDER_B
              setal
              LDA #$0001
              STA @lADDER32_B_LL
              LDA #$FFFF
              STA @lADDER32_B_HL
              RTS
; Load Register A with the Size of the File
SDOS_LOAD_ADDER_A_WITH_SIZE
              setal
              LDA @lSDOS_FILE_SIZE;
              STA @lADDER32_A_LL;
              LDA @lSDOS_FILE_SIZE+2;
              STA @lADDER32_A_HL;
              RTS

SDOS_SETUP_CH376S_BUFFER_SIZE
              setal
              LDA  @lADDER32_R_HL
              AND #$8000          ; Check if it is negative
              CMP #$8000          ; if it is then just put the Size of the file in ByteNumber
              BEQ SDOS_SETUP_SMALLR_THAN64K
              LDA #$FFFF
              STA @lSDOS_BYTE_NUMBER
              RTS
SDOS_SETUP_SMALLR_THAN64K
              LDA @lADDER32_A_LL
              STA @lSDOS_BYTE_NUMBER
              RTS
; SDOS_READ_BLOCK (A needs to be short)
; Read a Block of Data from Controller
; Inputs:
;  None
; Affects:
;   A, X
; Returns:
;   A = Number of byte Fetched
;  Buffer @ SDOS_SECTOR_BEGIN
SDOS_READ_BLOCK
              setas
              LDA #CH_CMD_RD_DATA0
              STA @lSDCARD_CMD;
              JSR DLYCMD_2_DTA;   ; 3us Delay to get the Value Return
              LDA @lSDCARD_DATA     ; Read First Byte for Number of Byte to Read
              STA SDCARD_BYTE_NUM  ; Store the Number of byte to be read
              JSR DLYDTA_2_DTA;   ; 3us Delay to get the Value Return
              LDY #$0000
SDOS_READ_MORE
              LDA @lSDCARD_DATA
              STA [SDCARD_FILE_PTR], Y        ; Store Block Data Sector Begin
              INY
              CPY SDCARD_BYTE_NUM
              BNE SDOS_READ_MORE
;              LDA #'.'
;              JSL IPUTC        ; Print the character
              LDA SDCARD_BYTE_NUM  ; Reload the Number of Byte Read
              RTS
;
; MESSAGES
;
sd_card_dir_string  .text $2F, $2A ,$00
sd_no_card_msg      .text "NO SDCARD PRESENT", $0D, $00
sd_card_err0        .text "ERROR IN READIND CARD", $00
sd_card_err1        .text "ERROR LOADING FILE", $00
sd_card_msg0        .text "Name: ", $0D,$00
sd_card_msg1        .text "SDCARD DETECTED", $00
sd_card_msg2        .text "SDCARD MOUNTED", $00
sd_card_msg3        .text "FAILED TO MOUNT SDCARD", $0D, $00
sd_card_msg4        .text "FILE OPENED", $0D, $00
sd_card_msg5        .text "END OF LINE...", $00
sd_card_msg6        .text "FILE FOUND, LOADING...", $00
sd_card_msg7        .text "FILE LOADED", $00
