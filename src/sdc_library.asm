;;;
;;; BIOS level code for the SDC
;;;

;;
;; SDC Routines
;;

;
; Test the SDC interface
;
SDC_TEST        .proc
                PHB
                PHD
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                setas

                LDA #$F0                            ; Set white on black background
                STA @w CURCOLOR
                JSL CLRSCREEN
                JSL CSRHOME
                
                JSL SDC_INIT                        ; Attempt to initilize the SDC interface
                BCS init_ok

                TRACE "Could not initilialize the SDC."
                BRL done

init_ok         LDA #BIOS_DEV_SD
                STA BIOS_DEV

                JSL DOS_MOUNT                       ; Attempt to mount the SDC
                BCS mount_ok

                TRACE "Could not mount the SDC."
                BRL done

mount_ok        JSL IF_DIROPEN
                BCS all_ok

                TRACE "Could not open SDC directory."
                BRA done

all_ok          TRACE "OK"

done            JSL PRINTCR
                
                PLP
                PLD
                PLB
                RTL
                .pend

;
; Wait for the SDC to finish its transaction
;
SDC_WAITBUSY    .proc
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
SDC_RESET       .proc
                PHP

                TRACE "SDC_RESET"

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
;   FDC_ST0 contains the SDC error bits
;
SDC_INIT        PHD
                PHB
                PHP

                TRACE "SDC_INIT"

                setdbr 0
                setdp SDOS_VARIABLES
                
                setas
                LDA #SDC_TRANS_INIT_SD
                STA @l SDC_TRANS_TYPE_REG           ; Set Init SD

                LDA #SDC_TRANS_START                ; Set the transaction to start
                STA @l SDC_TRANS_CONTROL_REG

                JSL SDC_WAITBUSY                    ; Wait for initialization to complete

                LDA @l SDC_TRANS_ERROR_REG          ; Check for errors
                BNE ret_error                       ; Is there one? Process the error

ret_success     STZ BIOS_STATUS
                PLP
                PLB
                PLD
                SEC
                RTL

ret_error       STA @w FDC_ST0
                LDA #BIOS_ERR_NOTINIT
                STA BIOS_STATUS
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
;   FDC_ST0 contains the SDC error bits
;
SDC_GETBLOCK    .proc
                PHD
                PHB
                PHP

                TRACE "SDC_GETBLOCK"

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

                JSL SDC_WAITBUSY                    ; Wait for transaction to complete

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

ret_error       STA @w FDC_ST0
                LDA #BIOS_ERR_READ
                STA BIOS_STATUS

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
;   FDC_ST0 contains the SDC error bits
;
SDC_PUTBLOCK    .proc
                PHD
                PHB
                PHP

                TRACE "SDC_PUTBLOCK"

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

                JSL SDC_WAITBUSY                    ; Wait for transaction to complete

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

ret_error       STA @w FDC_ST0
                LDA #BIOS_ERR_READ
                STA BIOS_STATUS
                
                LDA @l GABE_MSTR_CTRL               ; Turn off the SDC activity light
                AND #~GABE_CTRL_SDC_LED
                STA @l GABE_MSTR_CTRL

                PLP
                PLB
                PLD
                CLC
                RTL
                .pend
