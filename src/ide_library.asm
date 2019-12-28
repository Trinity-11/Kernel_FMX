.cpu "65816"


;/// IDENTIFY DEVICE Structure: (T13/1699-D Revision 6a)
IDE_ID .struct
General_Config        .word $0000
Obsolete0             .word $0000
Specific_Config       .word $0000
Obsolete1             .word $0000
Retired0              .word $0000
Retired1              .word $0000
Obsolete2             .word $0000
Reserved_CFlash0      .word $0000
Reserved_CFlash1      .word $0000
Retired2              .word $0000
Serial_Number_String  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Retired3              .word $0000, $0000
Obsolete3             .word $0000
Firmware_Rev_String   .byte $00, $00, $00, $00, $00, $00, $00, $00
Model_Number_String   .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                      .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                      .byte $00, $00, $00, $00, $00, $00, $00, $00
Max_Number_Logic_Sec  .word $0000
Trusted_Comp_Feature  .word $0000
Capabilities          .word $0000, $0000
Obsolete4             .word $0000, $0000
Free_Fall_Control     .word $0000
Obsolete5             .word $0000, $0000, $0000, $0000, $0000
Reserved0             .word $0000
Total_Addy_Logic_Sec  .word $0000, $0000
Obsolete6             .word $0000
Reserved1             .word $0000, $0000
Min_Multiword_DMA_Trf .word $0000
Manu_Recommended_Mult .word $0000
Min_PIO_Trf           .word $0000      ; Word 67
Min_PIO_Trf_with_IORD .word $0000      ; Word 68
Reserved2             .word $0000, $0000
Reserved3             .word $0000, $0000, $0000, $0000
Queue_Dept            .word $0000
SATA_Capabilities     .word $0000
Reserved_SATA         .word $0000
Sup_Feat_SATA         .word $0000
Sup_Feat_SATA_Enabled .word $0000    ; Word 79
Major_Version_Number  .word $0000    ; Word 80
Minor_Version_Number  .word $0000    ; Word 81
Cmd_And_Features_Sup  .word $0000, $0000, $0000, $0000, $0000, $0000
UDMA_Modes            .word $0000
Reserved4             .word $0000, $0000 ; Word 89
Current_APM_Level     .word $0000
Master_Password_Ident .word $0000
Hardware_Reset_Result .word $0000
Current_AAM_Value     .word $0000  ; Word 94
Stream_Min_Req_Size   .word $0000  ; Word 95
Stream_Trf_Time_DMA   .word $0000  ; Word 96
Stream_Access_Lat     .word $0000
Streaming_Perf_Gran   .word $0000, $0000
Tot_Num_Add_Logic_Sec .word $0000, $0000, $0000, $0000
Streaming_Trf_Time    .word $0000 ; Word 104
Reserved5             .word $0000 ; Word 105
.ends

;///
; the 512Byte Data is Temporary dumped in the same Buffer for the SDCard
;SDOS_BLK_BEGIN @00:0400
;////////////////////////////////////////////////////////
; IDE_INIT
; Init the HDD
; Inputs:
;  None
; Affects:
;   None
;/////////////////////////////////////////////////////////
IDE_INIT
              setas
              ; Init Drive
              JSR IDE_DRIVE_BSY ; Check to see if drive is busy
              LDA #$00
              STA IDE_CLDR_HI
              STA IDE_CLDR_LO
              STA IDE_SECT_CNT
              LDA #$01
              STA IDE_SECT_SRT
              LDA #$A0 ; HEAD 0 - Select Master Drive
              STA IDE_HEAD
              JSR IDE_DRV_READY_NOTBUSY
              RTL
;
;////////////////////////////////////////////////////////
; IDE_DRIVE_BLOCK_BSY
; Check to see if it the drive is Busy (BSY = 1'b0 == Not Busy)
; Inputs:
;  None
; Affects:
;   A
;/////////////////////////////////////////////////////////
IDE_DRIVE_BSY
              LDA IDE_CMD_STAT
              AND #$80    ;; Check for RDY Bit, this needs to be 1'b1
              CMP #$80    ;; If not go read again
              BEQ IDE_DRIVE_BSY
              RTS

;////////////////////////////////////////////////////////
; IDE_DRIVE_READY
; Indicates that the drive is capabable to respond to a command
; Inputs:
;  None
; Affects:
;   A
;/////////////////////////////////////////////////////////
IDE_DRIVE_READY
              LDA IDE_CMD_STAT
              AND #$40    ;; Check to see if the Busy Signal is Cleared
              CMP #$40    ; if it is still one, then go back to read again.
              BNE IDE_DRIVE_READY
              RTS

;
IDE_DRV_READY_NOTBUSY
              LDA IDE_CMD_STAT
              AND #$40    ;; Check to see if the Busy Signal is Cleared
              CMP #$40    ; if it is still one, then go back to read again.
              BNE IDE_DRV_READY_NOTBUSY
;
              LDA IDE_CMD_STAT
              AND #$80    ;; Check for RDY Bit, this needs to be 1'b1
              CMP #$80    ;; If not go read again
              BEQ IDE_DRV_READY_NOTBUSY
              RTS



;
;////////////////////////////////////////////////////////
; IDE_NOT_DRQ
; Indicates that the drive is ready to transfer word or byte of data
; Inputs:
;  None
; Affects:
;   A
;/////////////////////////////////////////////////////////
IDE_NOT_DRQ
              LDA IDE_CMD_STAT
              AND #$08
              CMP #$08
              BNE IDE_NOT_DRQ
              RTS
;
;////////////////////////////////////////////////////////
; IDE_GET_512BYTES
; Fetch the Data from the Drive and Save it in the SDCard Data Buffer
; Inputs:
;  None
; Affects:
;   None
;/////////////////////////////////////////////////////////
IDE_GET_512BYTES
              setaxl
              LDA IDE_DATA_LO
              LDX #$0000
IDE_GET_INFO_KEEP_FETCHING
              LDA IDE_DATA_LO
              STA SDOS_BLK_BEGIN, X
              ;LDA IDE_DATA_HI
              ;INX
              ;STA SDOS_BLK_BEGIN, x
              INX
              INX
              CPX #$0200
              BNE IDE_GET_INFO_KEEP_FETCHING
              RTL
;
;////////////////////////////////////////////////////////
; IDE_GET_INFO
; Fetch the Data from the Drive and Save it in the SDCard Data Buffer
; Inputs:
;  None
; Affects:
;   None
; ATA Strings are Little Endian - (16 bits - each byte in the word needs to be inverted)
;/////////////////////////////////////////////////////////
IDE_GET_INFO
              setas
              JSR IDE_DRIVE_BSY
              LDA #$EC              ; Send the Command #$EC to fetch the INFO about the HDD
              STA IDE_CMD_STAT
              JSR IDE_DRV_READY_NOTBUSY
              JSR IDE_NOT_DRQ       ; Wait for the Drive to let us know that the Data is ready
              JSL IDE_GET_512BYTES
              setas
              setxl
              LDX #$0000
GET_INFO_LOOP
              LDA SDOS_BLK_BEGIN+55, X    ; Model String
              JSL IPUTC
              LDA SDOS_BLK_BEGIN+54, X    ; Model String
              JSL IPUTC
              INX 
              INX
              CPX #40
              BNE GET_INFO_LOOP
              RTL

IDE_DISPLAY_INFO
