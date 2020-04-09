;;;
;;; DOS -- Basic Input/Output System -- storage operations
;;;

;
; Constants
;

BIOS_DEV_HD0 = 0
BIOS_DEV_HD1 = 1
BIOS_DEV_SD = 2
BIOS_DEV_FDC = 3

BIOS_ERR_BADDEV = $80           ; BIOS bad device # error

;;
;; General Routines
;;

;
; Read a 512 byte block from a block device into memory
;
; Inputs:
;   BIOS_DEV = the number of the block device to read from
;   BIOS_LBA = the 32-bit block address to read
;   BIOS_BUFF_PTR = pointer to the location to store the block
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
IGETBLOCK       .proc
                PHD
                PHB
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                setas
                LDA BIOS_DEV                        ; Check the device number
                CMP #BIOS_DEV_SD                    ; Is it for the SDC?
                BEQ sd_getblock                     ; Yes: go to the SDC GETBLOCK routine

                LDA #BIOS_ERR_BADDEV                ; Otherwise: return a bad device error

ret_failure     setas
                STA BIOS_STATUS                     ; Set BIOS STATUS
                PLP
                PLB
                PLD
                SEC                                 ; Return failure
                RTL

sd_getblock     JSL SDCGETBLOCK                     ; Call the SDC GETBLOCK routine

ret_success     setas
                STZ BIOS_STATUS                     ; Set BIOS STATUS to OK
                PLP
                PLB
                PLD
                SEC                                 ; Return success
                RTL
                .pend

;
; Write a 512 byte block from memory to a block device
;
; Inputs:
;   BIOS_DEV = the number of the block device to write to
;   BIOS_LBA = the 32-bit block address to write
;   BIOS_BUFF_PTR = pointer to the location containing the data to write
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
IPUTBLOCK       .proc
                PHD
                PHB
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                setas
                LDA BIOS_DEV                        ; Check the device number
                CMP #BIOS_DEV_SD                    ; Is it for the SDC?
                BEQ sd_putblock                     ; Yes: go to the SDC PUTBLOCK routine

                LDA #BIOS_ERR_BADDEV                ; Otherwise: return a bad device error

ret_failure     setas
                STA BIOS_STATUS                     ; Set BIOS STATUS
                PLP
                PLB
                PLD
                SEC                                 ; Return failure
                RTL

sd_putblock     JSL SDCPUTBLOCK                     ; Call the SDC PUTBLOCK routine

ret_success     setas
                STZ BIOS_STATUS                     ; Set BIOS STATUS to OK
                PLP
                PLB
                PLD
                SEC                                 ; Return success
                RTL
                .pend

;;
;; SDC Routines
;;

;
; Wait for the SDC to finish its transaction
;
SDCWAITBUSY     .proc
                PHP

                setas
wait_xact       LDA @l SDC_TRANS_STATUS_REG         ; Wait for the transaction to complete
                AND #SDC_TRANS_BUSY
                CMP #SDC_TRANS_BUSY
                BEQ wait_xact

                PLP
                RTL
                .pend

;
; Reset the logic block for the SDC
;
SDCRESET        .proc
                PHP

                setas
                LDA #1
                STA @l SDC_CONTROL_REG

                PLP
                RTL
                .pend
;
; Initialize access to the SD card
;
; Returns:
;   C set if success, clear if failure
;   BIOS_STATUS contains an error code if relevant
;
SDCINIT         PHD
                PHB
                PHP

                setdbr 0
                setdp SDOS_VARIABLES
                
                setas
                LDA #SDC_TRANS_INIT_SD
                STA @l SDC_TRANS_TYPE_REG           ; Set Init SD

                LDA #SDC_TRANS_START                ; Set the transaction to start
                STA @l SDC_TRANS_CONTROL_REG

                JSL SDCWAITBUSY                     ; Wait for initialization to complete

                LDA @l SDC_TRANS_ERROR_REG          ; Check for errors
                BNE ret_error                       ; Is there one? Process the error

ret_success     STZ BIOS_STATUS
                PLP
                PLB
                PLD
                SEC
                RTL

ret_error       STA BIOS_STATUS
                PLP
                PLB
                PLD
                CLC
                RTL

;
; Read a 512 byte block from the SDC into memory
;
; Inputs:
;   BIOS_LBA = the 32-bit block address to read
;   BIOS_BUFF_PTR = pointer to the location to store the block
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
SDCGETBLOCK     .proc
                PHD
                PHB
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                setas
                LDA @l GABE_MSTR_CTRL               ; Turn on the SDC activity light
                ORA #GABE_CTRL_SDC_LED
                STA @l GABE_MSTR_CTRL

                LDA #0
                STA @l SDC_SD_ADDR_7_0_REG
                LDA BIOS_LBA                        ; Set the LBA to read
                ASL A
                STA @l SDC_SD_ADDR_15_8_REG
                LDA BIOS_LBA+1
                ROL A
                STA @l SDC_SD_ADDR_23_16_REG
                LDA BIOS_LBA+2
                ROL A
                STA @l SDC_SD_ADDR_31_24_REG

                LDA #SDC_TRANS_READ_BLK             ; Set the transaction to READ
                STA @l SDC_TRANS_TYPE_REG

                LDA #SDC_TRANS_START                ; Set the transaction to start
                STA @l SDC_TRANS_CONTROL_REG

                JSL SDCWAITBUSY                     ; Wait for transaction to complete

                LDA @l SDC_TRANS_ERROR_REG          ; Check for errors
                BNE ret_error                       ; Is there one? Process the error

                setas
                LDA @l SDC_RX_FIFO_DATA_CNT_LO      ; Record the number of bytes read
                STA BIOS_FIFO_COUNT
                LDA @l SDC_RX_FIFO_DATA_CNT_HI
                STA BIOS_FIFO_COUNT+1

                setxl
                LDY #0
loop_rd         LDA @l SDC_RX_FIFO_DATA_REG         ; Get the byte...
                STA [BIOS_BUFF_PTR],Y               ; Save it to the buffer
                INY                                 ; Advance to the next byte
                CPY #512                            ; Have we read all the bytes?
                BNE loop_rd                         ; No: keep reading

ret_success     STZ BIOS_STATUS                     ; Return success

                LDA @l GABE_MSTR_CTRL               ; Turn off the SDC activity light
                AND #~GABE_CTRL_SDC_LED
                STA @l GABE_MSTR_CTRL

                PLP
                PLB
                PLD
                SEC
                RTL

ret_error       STA BIOS_STATUS

                LDA @l GABE_MSTR_CTRL               ; Turn off the SDC activity light
                AND #~GABE_CTRL_SDC_LED
                STA @l GABE_MSTR_CTRL

                PLP
                PLB
                PLD
                CLC
                RTL
                .pend

;
; Write a 512 byte block from memory to the SDC
;
; Inputs:
;   BIOS_LBA = the 32-bit block address to write
;   BIOS_BUFF_PTR = pointer to the location of the data to write
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
SDCPUTBLOCK     .proc
                PHD
                PHB
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                setas
                LDA @l GABE_MSTR_CTRL               ; Turn on the SDC activity light
                ORA #GABE_CTRL_SDC_LED
                STA @l GABE_MSTR_CTRL

                setxl
                LDY #0
loop_wr         LDA [BIOS_BUFF_PTR],Y               ; Get the byte...
                STA @l SDC_TX_FIFO_DATA_REG         ; Save it to the SDC
                INY                                 ; Advance to the next byte
                CPY #512                            ; Have we read all the bytes?
                BNE loop_wr                         ; No: keep writing

                LDA #0
                STA @l SDC_SD_ADDR_7_0_REG
                LDA BIOS_LBA                        ; Set the LBA to write
                ASL A
                STA @l SDC_SD_ADDR_15_8_REG
                LDA BIOS_LBA+1
                ROL A
                STA @l SDC_SD_ADDR_23_16_REG
                LDA BIOS_LBA+2
                ROL A
                STA @l SDC_SD_ADDR_31_24_REG

                LDA #SDC_TRANS_WRITE_BLK            ; Set the transaction to WRITE
                STA @l SDC_TRANS_TYPE_REG

                LDA #SDC_TRANS_START                ; Set the transaction to start
                STA @l SDC_TRANS_CONTROL_REG

                JSL SDCWAITBUSY                     ; Wait for transaction to complete

                LDA @l SDC_TRANS_ERROR_REG          ; Check for errors
                BNE ret_error                       ; Is there one? Process the error

ret_success     STZ BIOS_STATUS                     ; Return success

                LDA @l GABE_MSTR_CTRL               ; Turn off the SDC activity light
                AND #~GABE_CTRL_SDC_LED
                STA @l GABE_MSTR_CTRL

                PLP
                PLB
                PLD
                SEC
                RTL

ret_error       STA BIOS_STATUS

                LDA @l GABE_MSTR_CTRL               ; Turn off the SDC activity light
                AND #~GABE_CTRL_SDC_LED
                STA @l GABE_MSTR_CTRL

                PLP
                PLB
                PLD
                CLC
                RTL
                .pend