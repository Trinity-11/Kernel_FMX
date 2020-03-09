.cpu "65816"

; SD Card OS
;SDOS.asm
;Jump Table
.include "ch376s_inc.asm"

fatrec  .struct
  name      .fill 8
  extension .fill 3
  type      .byte 1
  reserved  .fill 16
  size_l    .word 0
  size_h    .word 0
.ends

simplefilestruct .struct
  name      .fill 8
  extension .fill 3
  type      .byte 1
  size_l    .word 0
  size_h    .word 0
.ends

; Low-Level Command for the SD Card OS
; CH376S Controller Commands

SDOS_CHECK_CD JML ISDOS_CHK_CD ; Check if Card is Present
SDOS_CHECK_WP JML ISDOS_CHK_WP ; Check if Card is Write Protected

; High-Level Command for the SD CARD
SDOS_INIT     JML ISDOS_INIT
SDOS_DIR      JML ISDOS_DIR
SDOS_CHDIR    JML ISDOS_CHDIR
SDOS_LOAD     JML ISDOS_READ_FILE
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
ISDOS_INIT    PHA
              PHX
              PHY
              PHP
              PHD

              setdp SDOS_BLOCK_BEGIN

              setas
              LDA @lINT_PENDING_REG1    ; Read the Pending Register &
              AND #~FNX1_INT07_SDCARD   ; Enable
              STA @lINT_PENDING_REG1

              LDA #CH_CMD_CHECK_EXIST
              STA SDCARD_CMD
              JSR DLYCMD_2_DTA
              LDA #$A8
              STA SDCARD_DATA
    CHK_LOOP
              JSR DLYDTA_2_DTA
              JSR DLYDTA_2_DTA
              JSR DLYDTA_2_DTA
              LDA SDCARD_DATA  ; the data returned must be the complement
              CMP #~$A8;  $57
              BNE CHK_LOOP
              JSR DLYCMD_2_DTA

              LDA #CH_CMD_SET_MODE
              STA SDCARD_CMD
              JSR DLYCMD_2_DTA
              JSR DLYCMD_2_DTA
              LDA #$03            ; Mode 3 - SDCARD
              STA SDCARD_DATA     ; Write the MODE and Wait for around ~10us

    ISDOS_WAIT_FOR_MODE_SW
              JSR DLYDTA_2_DTA ; Wait 0.6us
              LDA SDCARD_DATA
              CMP #$51         ; CMD_RET_SUCCESS = 051H, CMD_RET_ABORT = 05FH
              BEQ CHK_SET_OK
              CMP #$5F
              BEQ CHK_SET_NOK
              
              BNE ISDOS_WAIT_FOR_MODE_SW
    CHK_SET_OK
              LDA #SDCARD_PRSNT_CD
              STA SDCARD_PRSNT_MNT
              BRA SD_INIT_DONE
    CHK_SET_NOK
              LDA #SDCARD_PRSNT_NO_CARD
              STA SDCARD_PRSNT_MNT
              BRA SD_INIT_DONE
              
    SD_INIT_DONE
              PLD
              PLP
              PLY
              PLX
              PLA
              RTL

; ***************************************************************
; * Clear the current FAT record
; ***************************************************************
ISDOS_CLEAR_FAT_REC
              PHD

              setdp SDOS_BLOCK_BEGIN

              LDY #0
              LDA #0
    CLEAR_LOOP
              STA [SDOS_FILE_REC_PTR],Y
              INY
              CPY #32
              BNE CLEAR_LOOP

              PLD
              RTS
              
;////////////////////////////////////////////////////////
; ISDOS_DIR
;   Upon the Call of this Routine Display the Files on the SDCARD
; Inputs:
;   Pointer to the ASCII File name by
; Located @ $000030..$000032 - SDCARD_FLNMPTR_L
; Affects:
;   None
ISDOS_DIR     PHA
              PHX
              PHY
              PHD
              PHP

              setdp SDOS_BLOCK_BEGIN

              setas
              setxl
              JSR ISDOS_MOUNT_CARD;     First to See if the Card is Present
              
              JSR ISDOS_CLEAR_FAT_REC
              
              ; STZ SDOS_LINE_SELECT

              JSR SDOS_FILE_OPEN     ; Now that the file name is set, go open File

              LDX #0 ; count the number of items displayed - limit to 38
    ISDOS_NEXT_ENTRY
              LDA #CH_CMD_RD_DATA0
              STA SDCARD_CMD
              JSR DLYCMD_2_DTA;      ; Wait 1.5us
              LDA SDCARD_DATA        ;  Load Data Length - should be 32 - we don't care.
              
              ; populate the FAT records - only copy the filename, type and size
              LDY #0
    FAT_REC_LOOP
              JSR DLYDTA_2_DTA       ; Wait 0.6us
              LDA SDCARD_DATA
              STA [SDOS_FILE_REC_PTR],Y
              INY
              CPY #32
              BNE FAT_REC_LOOP
              
              ; copy the filelength bytes from 28-31 to 12-15.
              setal
              LDY #28
              LDA [SDOS_FILE_REC_PTR],Y
              LDY #12
              STA [SDOS_FILE_REC_PTR],Y
              LDY #30
              LDA [SDOS_FILE_REC_PTR],Y
              LDY #14
              STA [SDOS_FILE_REC_PTR],Y
              
              ; move the file pointer ahead
              LDA SDOS_FILE_REC_PTR
              CLC
              ADC #$10
              STA SDOS_FILE_REC_PTR
              setas
              INX
              CPX #64
              BEQ ISDOS_DIR_DONE
              
              JSR DLYCMD_2_DTA;      ; Wait 1.5us
              
              ; Ask Controller to go fetch the next entry in the Directory
              LDA #CH_CMD_FILE_ENUM_GO
              STA SDCARD_CMD
              JSR SDCARD_WAIT_4_INT       ; Go Wait for Interrupt
              CMP #CH376S_STAT_DSK_RD
              BEQ ISDOS_NEXT_ENTRY

    ISDOS_DIR_DONE
              JSR SDOS_FILE_CLOSE

              PLP
              PLD
              PLY
              PLX
              PLA
              RTL

; Upon the Call of this Routine will Change the pointer to a new Sub-Directory
ISDOS_CHDIR   BRK;

; Upon the Call of this Routine this will Save a file defined by the given name and Location
ISDOS_SAVE    BRK;

; Load a File ".FNX" and execute it
ISDOS_EXEC    BRK;

;/////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////
; ISDOS_MOUNT_CARD
; Check to see if Card exist, then Mount the SD Card
; Inputs:
;   Pointer to the ASCII File name by
; Located @ $000030..$000032 - SDCARD_FLNMPTR_L
; Affects:
;   None
ISDOS_MOUNT_CARD
              setas
              setxl
              LDY #$0000
              LDA #$01
              STA SDCARD_PRSNT_MNT        ; Bit[0] = Card Present
    TRY_MOUNT_AGAIN
              LDA #CH_CMD_DISK_MOUNT      ; If Present, go Mount it.
              STA SDCARD_CMD              ;
              JSR SDCARD_WAIT_4_INT       ;
              CMP #CH376S_STAT_SUCCESS    ;
              BEQ ISDOS_MOUNTED
              INY
              CPY #$0005
              BNE TRY_MOUNT_AGAIN
              JMP SDCARD_ERROR_MOUNT
    ISDOS_MOUNTED ; The Card is already mounted

              LDA SDCARD_PRSNT_MNT
              AND #~SDCARD_PRSNT_MNTED
              ORA #SDCARD_PRSNT_MNTED     ; Set Bit to Indicate that is mounted
              RTS

    SDCARD_ERROR_MOUNT
              LDX #<>sd_card_msg3         ; Print Screen the Message "Card Detected"
              ; JSL DISPLAY_MSG           ; print the first line
              BRK
              RTS

    ISDOS_NO_CARD 
              LDA #SDCARD_PRSNT_NO_CARD
              STA SDCARD_PRSNT_MNT
              RTS

;
; ISDOS_FILE_OPEN
; Open the File - whenever a / is found, call File Open until 0 is found.
; Inputs:
; File Name ought to be here: SDOS_FILE_NAME and be terminated by NULL.
; Affects:
;   A
; Outputs:
; A = Interrupt Status
SDOS_FILE_OPEN
              .as
              .xl
              PHB
              LDX #0
              LDY #1
              LDA #'/'
              STA @lSDOS_FILE_NAME,X
              INX
              setdbr `sd_card_dir_string
              
    ISDOS_DIR_TRF
              LDA sd_card_dir_string,Y
              CMP #'/'
              BEQ FO_READ_SLASH
              STA @lSDOS_FILE_NAME,X
              INX
              INY
              CMP #0
              BEQ FO_READ_END_PATH
              BRA ISDOS_DIR_TRF  ; path string must be 0 terminated
              
    FO_READ_SLASH
              LDA #0
              STA @lSDOS_FILE_NAME,X
              INX
              INY
              LDA #'/'
    FO_READ_END_PATH
              PHA
              JSR SDOS_SET_FILE_NAME ; Make Sure the Pointer to the File Name is properly
              JSR DLYCMD_2_DTA
              LDA #CH_CMD_FILE_OPEN ;
              STA SDCARD_CMD          ; Go Request to open the File
              JSR SDCARD_WAIT_4_INT   ; A Interrupt is Generated, so go polling it
               
              PLA
              CMP #0
              BEQ FO_DONE
              LDX #0
              BRA ISDOS_DIR_TRF
    FO_DONE
              PLB
              RTS

SDOS_FILE_CLOSE
              LDA #CH_CMD_FILE_CLOSE ;
              STA SDCARD_CMD          ; Go Request to open the File
              JSR DLYCMD_2_DTA
              LDA #$00                ; FALSE
              STA SDCARD_DATA         ; Store into the Data Register of the CH376s
              JSR SDCARD_WAIT_4_INT   ; A Interrupt is Generated, so go polling it
              RTS

; SDOS_SET_FILE_NAME
; Set the Filename to the Controller CH376D
; Inputs:
; File Name ought to reside here: SDOS_FILE_NAME
; Affects:
;   None
SDOS_SET_FILE_NAME
              PHX
              LDA #CH_CMD_SET_FILENAME
              STA SDCARD_CMD
              JSR DLYCMD_2_DTA
              LDX #$0000
    SDOS_SET_FILE_LOOP
              LDA @lSDOS_FILE_NAME, X   ; This is where the FileName ought to be.
              STA SDCARD_DATA         ; Store into the Data Register of the CH376s
              JSR DLYDTA_2_DTA
              INX
              CMP #$00              ; Check end of Line
              BNE SDOS_SET_FILE_LOOP
              PLX
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
              RTS


; SDCARD_WAIT_4_INT
; Blocking - Wait for the CH376S Interrupt
; Inputs:
;
; Outputs:
;   A = Interrupt Status
SDCARD_WAIT_4_INT
              setas                    ; This is for security
;              SEI                     ; There is no time out on this, so let's
                                       ; make sure it is not going to be interrupted
;              LDA @lINT_PENDING_REG1  ; Read the Pending Register &
;              AND #$7F   ; Enable
;              STA @lINT_PENDING_REG1
    SDCARD_BUSY_INT
              LDA @lINT_PENDING_REG1   ; Check to See if the Pending Register for the SD_INT is Set
              AND #FNX1_INT07_SDCARD   ;
              CMP #FNX1_INT07_SDCARD
              BNE SDCARD_BUSY_INT      ; Go Check again to see if it is checked
              STA @lINT_PENDING_REG1   ;Interrupt as occured, clear the Pending Register for next time.
              ; Fetch the Status
              JSR DLYCMD_2_DTA ;
              JSR DLYCMD_2_DTA ;
              LDA #CH_CMD_GET_STATUS
              STA SDCARD_CMD;
              JSR DLYCMD_2_DTA;   ; 1.5us Delay to get the Value Return
              LDA SDCARD_DATA;
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
    SDCD_NOT_PRST 
              RTS
;
; ISDOS_CHK_WP
; Return the Value of Write Protection Status
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
    SDCD_NOT_WP   
              RTS
              
; ISDOS_READ_FILE
; Go Open and Read a file and store it to prefedined address
; Inputs:
;  Name @ SDOS_FILE_NAME, Pointer to Store the DATA: @ SDCARD_FILE_PTR ($00:00030)
; Affects:
;   A, X probably Y and CC and the whole thing... So don't asume anything...
; Returns:
; Well, you ought to have your file loaded where you asked it.
ISDOS_READ_FILE
              .as
              JSR SDOS_FILE_OPEN   ; open the file
              
              ; If successful, get the file sizeof
              LDA SDCARD_DATA
              CMP #CH376S_STAT_SUCCESS ; if the file open successfully, let's go on.
              BEQ SDOS_READ_FILE_KEEP_GOING
              BRL SDOS_READ_DONE
              
    SDOS_READ_FILE_KEEP_GOING

              setal
              JSR SDOS_SET_FILE_LENGTH;
              LDA #$0000
              STA @lSDCARD_BYTE_NUM; Just make sure the High Part of the Size is Zero
              STA @lSDOS_BYTE_PTR   ; Clear the Byte Pointer 32 Bytes Register
              STA @lSDOS_BYTE_PTR+2 ; This is to Relocated the Pointer after you passed the 64K Boundary
              ; Second Step, Setup the Amount of Data to Send
              ; Set the Transfer Size, I will try 256 bytes
              setas
    SDOS_READ_FILE_GO_FETCH_A_NEW_64KBlock
              LDA #CH_CMD_BYTE_READ
              STA SDCARD_CMD;
              JSR DLYCMD_2_DTA;   ; 3us Delay to get the Value Return
              LDA @lSDOS_BYTE_NUMBER
              STA SDCARD_DATA
              JSR DLYDTA_2_DTA;   ; 1.5us Delay to get the Value Return
              LDA @lSDOS_BYTE_NUMBER+1
              STA SDCARD_DATA
              JSR SDCARD_WAIT_4_INT
              CMP #CH376S_STAT_DSK_RD ;
              BEQ SDOS_READ_FILE_GO_FETCH_A_NEW_BLOCK
              BRL SDOS_READ_DONE
    SDOS_READ_FILE_GO_FETCH_A_NEW_BLOCK
              ; Go Read 1 Block and Store it @ ($00:0030)
              JSR SDOS_READ_BLOCK
              LDA #CH_CMD_BYTE_RD_GO
              STA SDCARD_CMD
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
              BNE SDOS_READ_DONE                  ; if it equal 64K, then the file is bigger than 64K
              ; Now let's go compute the Nu Value for the Next Batch
              LDA @lADDER32_R_LL
              STA @lADDER32_A_LL
              LDA @lADDER32_R_LL+2
              STA @lADDER32_A_LL+2
              JSR SDOS_SET_FILE_LENGTH ;
              JSR SDOS_COMPUTE_LOCATE_POINTER
              setas
              JSR SDOS_BYTE_LOCATE    ; Apply the new location for the CH376S
              JSR SDCARD_WAIT_4_INT
              CMP #CH376S_STAT_SUCCESS ;
              BNE SDOS_READ_PROC_DONE
              ; Check to see that we have Loaded all the bytes.
              BRA SDOS_READ_FILE_GO_FETCH_A_NEW_64KBlock ; Let's go fetch a new block of 64K or less

    SDOS_READ_DONE
              setas
              RTL

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
              STA SDCARD_CMD
              JSR DLYCMD_2_DTA
              LDA @lSDOS_BYTE_PTR
              STA SDCARD_DATA
              JSR DLYDTA_2_DTA
              LDA @lSDOS_BYTE_PTR+1
              STA SDCARD_DATA
              JSR DLYDTA_2_DTA
              LDA @lSDOS_BYTE_PTR+2
              STA SDCARD_DATA
              JSR DLYDTA_2_DTA
              LDA @lSDOS_BYTE_PTR+3
              STA SDCARD_DATA
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

; ********************************************************
; * Prepare the buffer for reading - max 64k bytes
; ********************************************************
SDOS_SET_FILE_LENGTH
              LDA SDOS_FILE_SIZE + 2
              BEQ SFL_DONE
              
              ; the file is too large, just exit
              PLY ; deplete the stack to return back to the long jump
              RTL
              
    SFL_DONE
              LDA SDOS_FILE_SIZE
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
              PHD
              setdp BANK0_BEGIN
              .as
              .xl
              LDA #CH_CMD_RD_DATA0
              STA SDCARD_CMD;
              JSR DLYCMD_2_DTA;   ; 3us Delay to get the Value Return
              LDA SDCARD_DATA     ; Read First Byte for Number of Byte to Read
              STA SDCARD_BYTE_NUM  ; Store the Number of byte to be read
              JSR DLYDTA_2_DTA;   ; 3us Delay to get the Value Return
              LDY #$0000
    SDOS_READ_MORE
              LDA SDCARD_DATA
              STA [SDCARD_FILE_PTR], Y        ; Store Block Data Sector Begin
              INY
              CPY SDCARD_BYTE_NUM
              BNE SDOS_READ_MORE
              LDA SDCARD_BYTE_NUM  ; Reload the Number of Byte Read
              PLD
              RTS
;
; MESSAGES
;
sd_card_dir_string  .text '/*' ,$00
                    .fill 128-3,0  ; leave space for the path
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
