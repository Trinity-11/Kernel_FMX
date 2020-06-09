;;;
;;; DOS -- Basic Input/Output System -- storage operations
;;;

;
; Constants
;

;
; BIOS Flags
;

BIOS_TIMEOUT = $80              ; Flag to indicate if a time out has occurred (see ISETTIMEOUT)

;
; Block device numbers, used by GETBLOCK and PUTBLOCK routines
;

BIOS_DEV_FDC = 0                ; Floppy 0
BIOS_DEV_FD1 = 1                ; Future support: Floppy 1 (not likely to be attached)
BIOS_DEV_SD = 2                 ; SD card, partition 0
BIOS_DEV_SD1 = 3                ; Future support: SD card, partition 1
BIOS_DEV_SD2 = 4                ; Future support: SD card, partition 2
BIOS_DEV_SD3 = 5                ; Future support: SD card, partition 3
BIOS_DEV_HD0 = 6                ; Future support: IDE Drive 0, partition 0
BIOS_DEV_HD1 = 7                ; Future support: IDE Drive 0, partition 1
BIOS_DEV_HD2 = 8                ; Future support: IDE Drive 0, partition 2
BIOS_DEV_HD3 = 9                ; Future support: IDE Drive 0, partition 3

;
; BIOS error codes
;

BIOS_ERR_BADDEV = $80           ; BIOS bad device # error
BIOS_ERR_MOUNT = $81            ; BIOS failed to mount the device
BIOS_ERR_READ = $82             ; BIOS failed to read from a device
BIOS_ERR_WRITE = $83            ; BIOS failed to write to a device
BIOS_ERR_TRACK = $84            ; BIOS failed to seek to the correct track
BIOS_ERR_CMD = $85              ; A general block device command error
BIOS_ERR_WRITEPROT = $86        ; The media was write-protected
BIOS_ERR_NOMEDIA = $87          ; No media detected... unable to read/write in time
BIOS_ERR_RESULT = $88           ; Couldn't get the result bytes for some reason
BIOS_ERR_OOS = $89              ; FDC state is somehow out of sync with the driver.
BIOS_ERR_NOTATA = $8A           ; IDE drive is not ATA
BIOS_ERR_NOTINIT = $8B          ; Could not initilize the device
BIOS_ERR_TIMEOUT = $8C          ; Timeout error

;;
;; General Routines
;;

;
; Print a trace message
; 
; Inputs:
;   Stack: 32-bit address to ASCIIZ string to print passed on the stack
;
; Returns:
;   Nothing: pointer to string removed from stack prior to return
;
; Stack in call:
;   +
;   | 0
;   + 
; 8 | TEXT_H
;   +
; 7 | TEXT_M
;   +
; 6 | TEXT_L
;   +
; 5 | PCH
;   +
; 4 | PCM
;   +
; 3 | PCL
;   +
; 2 | P
;   +
; 1 | B
;   +
ITRACE          .proc
                PHP

                setaxl

                PHB                 ; Print the text
                LDA #6,S            ; Get bits[15..0] of string pointer
                TAX                 ; ... into X
                setas
                LDA #8,S            ; Get bits[23..16] of string pointer
                PHA
                PLB                 ; ... into B
                JSL IPUTS           ; Print the string

                setal
                LDA #4,S            ; Move P and return address down over the string pointer
                STA #8,S
                LDA #2,S
                STA #6,S

                PLB

                PLA                 ; Clean up the stack
                PLA

                PLP
                RTL
                .pend

;
; Set a timeout for an operation that may get stuck.
;
; Immediately after the call, the BIOS_TIMEOUT flag of BIOS_FLAGS will be cleared
; and a timer will be set. If the timer reaches the end before the timeout is cleared,
; the BIOS_TIMEOUT flag will be set. It is the caller's responsibility to monitor the
; flag and to act appropriately.
;
; NOTE: the timer will be managed by the SOF interrupt
;
; Inputs:
;   A = the number of 1/60 second ticks to wait until the time out should occurr
;
ISETTIMEOUT     .proc
                PHB
                PHD
                PHP

                setdbr 0
                setdp SDOS_VARIABLES

                SEI                             ; We don't want to be interrupted

                setas
                STA @b BIOS_TIMER               ; Set the number of ticks to wait

                LDA @b BIOS_FLAGS               ; Clear the BIOS_TIMEOUT flag
                AND #~BIOS_TIMEOUT
                STA @b BIOS_FLAGS

done            PLP
                PLD
                PLB
                RTL
                .pend

;
; Send a special command code to a block device.
; This should be used for things like spinning up or down the motor, ejecting media, etc.
; See individual device command subroutines for specific command codes.
;
; Inputs:
;   BIOS_DEV = the block device number
;   X = the command # to send.
;
; Returns:
;   BIOS_STATUS = status code for any errors (0 = fine)
;   C = set if success, clear on error
;
ICMDBLOCK       .proc
                PHD
                PHP

                setdp SDOS_VARIABLES
                
                setas
                LDA BIOS_DEV                ; Get the device number
                
                CMP #BIOS_DEV_FDC           ; Check to see if we're sending to the floppy
                BNE ret_success             ; No: just return
                JSL FDC_CMDBLOCK            ; Yes: call upon the floppy code
                BCC pass_failure

ret_success     setas
                STZ BIOS_STATUS
                PLP
                PLD
                SEC
                RTL

ret_failure     setas
                STA BIOS_STATUS
pass_failure    PLP
                PLD
                CLC
                RTL
                .pend

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

                TRACE "IGETBLOCK"

                setdbr 0
                setdp SDOS_VARIABLES

                setas
                LDA BIOS_DEV                        ; Check the device number
                CMP #BIOS_DEV_SD                    ; Is it for the SDC?
                BEQ sd_getblock                     ; Yes: go to the SDC GETBLOCK routine

                CMP #BIOS_DEV_FDC                   ; Is it for the floppy drive?
                BEQ fd_getblock                     ; Yes: go to the FDC GETBLOCK routine

                CMP #BIOS_DEV_HD0                   ; Is it for the IDE drive?
                BEQ hd_getblock

                LDA #BIOS_ERR_BADDEV                ; Otherwise: return a bad device error

ret_failure     setas
                STA BIOS_STATUS                     ; Set BIOS STATUS
                PLP
                PLB
                PLD
                SEC                                 ; Return failure
                RTL

sd_getblock     JSL SDC_GETBLOCK                    ; Call the SDC GETBLOCK routine
                BCS ret_success
                BRA ret_failure

fd_getblock     JSL FDC_GETBLOCK                    ; Call the FDC GETBLOCK routine
                BCS ret_success
                BRA ret_failure

hd_getblock     JSL IDE_GETBLOCK                    ; Call the IDE GETBLOCK routine
                BCS ret_success
                BRA ret_failure

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

                TRACE "IPUTBLOCK"

                setdbr 0
                setdp SDOS_VARIABLES

                setas
                LDA BIOS_DEV                        ; Check the device number
                CMP #BIOS_DEV_SD                    ; Is it for the SDC?
                BEQ sd_putblock                     ; Yes: go to the SDC PUTBLOCK routine

                CMP #BIOS_DEV_FDC                   ; Is it for the FDC?
                BEQ fd_putblock                     ; Yes: go to the FDC PUTBLOCK routine

                CMP #BIOS_DEV_HD0                   ; Is it for the IDE drive?
                BEQ hd_putblock

                LDA #BIOS_ERR_BADDEV                ; Otherwise: return a bad device error

ret_failure     setas
                STA BIOS_STATUS                     ; Set BIOS STATUS
                PLP
                PLB
                PLD
                CLC                                 ; Return failure
                RTL

sd_putblock     JSL SDC_PUTBLOCK                    ; Call the SDC PUTBLOCK routine
                BCC ret_failure
                BRA ret_success

fd_putblock     JSL FDC_PUTBLOCK                    ; Call the FDC PUTBLOCK routine
                BCC ret_failure
                BRA ret_success

hd_putblock     JSL IDE_PUTBLOCK                    ; Call the IDE PUTBLOCK routine
                BCC ret_failure
                BRA ret_success           

ret_success     setas
                STZ BIOS_STATUS                     ; Set BIOS STATUS to OK
                PLP
                PLB
                PLD
                SEC                                 ; Return success
                RTL
                .pend

