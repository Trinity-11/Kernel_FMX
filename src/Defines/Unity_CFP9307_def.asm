; UNITY CHIPSET
; CFP9307 Memory Map

; IDE Interface
IDE_DATA      = $AFE830 ; 8-Bit Access here Only
IDE_ERROR     = $AFE831 ; Error Information register (only read when there is an error ) - Probably clears Error Bits
IDE_SECT_CNT  = $AFE832 ; Sector Count Register (also used to pass parameter for timeout for IDLE modus Command)
IDE_SECT_SRT  = $AFE833 ; Start Sector Register (0 = 256), so start @ 1
IDE_CLDR_LO   = $AFE834 ; Low Byte of Cylinder Numnber {7:0}
IDE_CLDR_HI   = $AFE835 ;  Hi Byte of Cylinder Number {9:8} (1023-0).
IDE_HEAD      = $AFE836 ; Head, device select, {3:0} HEad Number, 4 -> 0:Master, 1:Slave, {7:5} = 101 (legacy);
IDE_CMD_STAT  = $AFE837 ; Command/Status Register - Reading this will clear the Interrupt Registers
IDE_DATA_LO   = $AFE838 ; 16-bit access here
IDE_DATA_HI   = $AFE839 ;

; Bit flags for IDE_ERROR

IDE_ERR_AMNF = $01      ; Error: Address mark not found
IDE_ERR_TKZNF = $02     ; Error: Track 0 not found
IDE_ERR_ABRT = $04      ; Error: Aborted command
IDE_ERR_MCR = $08       ; Error: Media change request
IDE_ERR_IDNF = $10      ; Error: ID not found
IDE_ERR_MC = $20        ; Error: Media change
IDE_ERR_UNC = $40       ; Error: Uncorrectable data error
IDE_ERR_BBK = $80       ; Error: Bad block detected

; Bit Flags for IDE_CMD_STAT 

;7    6    5   4  3   2   1    0
;BSY DRDY DF DSC DRQ CORR IDX ERR

IDE_STAT_BSY = $80      ; BSY (Busy) is set whenever the device has control of the command Block Registers.
IDE_STAT_DRDY = $40     ; DRDY (Device Ready) is set to indicate that the device is capable of accepting all command codes.
IDE_STAT_DF = $20       ; DF (Device Fault) indicates a device fault error has been detected.
IDE_STAT_DSC = $10      ; DSC (Device Seek Complete) indicates that the device heads are settled over a track.
IDE_STAT_DRQ = $08      ; DRQ (Data Request) indicates that the device is ready to transfer a word or byte of data between
                        ;   the host and the device.
IDE_STAT_CORR = $04     ; CORR (Corrected Data) is used to indicate a correctable data error.
IDE_STAT_IDX = $02      ; Vendor specific bit
IDE_STAT_ERR = $01      ; ERR (Error) indicates that an error occurred during execution of the previous command.

;BSY (Busy) is set whenever the device has control of the command Block Registers. When the
;BSY bit is equal to one, a write to a command block register by the host shall be ignored by the
;device.
;The device shall not change the state of the DRQ bit unless the BSY bit is equal to one. When the
;last block of a PIO data in command has been transferred by the host, then the DRQ bit is cleared
;without the BSY bit being set.
;When the BSY bit equals zero, the device may only change the IDX, DRDY, DF, DSC, and CORR
;bits in the Status register and the Data register. None of the other command block registers nor
;other bits within the Status register shall be changed by the device.
;NOTE - BIOSs and software device drivers that sample status as soon as the BSY
;bit is cleared to zero may not detect the assertion of the CORR bit by the device.
;After the host has written the Command register either the BSY bit shall be set, or if the BSY bit is
;cleared, the DRQ bit shall be set, until command completion.
;NOTE - The BSY bit is set and then cleared so quickly, that host detection of the
;BSY bit being set is not certain.
;The BSY bit shall be set by the device under the following circumstances:
;a) within 400 ns after either the negation of RESET- or the setting of the SRST bit in the
;Device Control register;
;X3T13/2008D Revision 7b
;Page 28 working draft AT Attachment-3 (ATA-3)
;b) within 400 ns after writing the Command register if the DRQ bit is not set;
;c) between blocks of a data transfer during PIO data in commands if the DRQ bit is not set;
;d) after the transfer of a data block during PIO data out commands if the DRQ bit is not set;
;e) during the data transfer of DMA commands if the DRQ bit is not set.
;The device shall not set the BSY bit at any other time.


;- DRDY (Device Ready) is set to indicate that the device is capable of accepting all command codes.
;This bit shall be cleared at power on. Devices that implement the power management features shall
;maintain the DRDY bit equal to one when they are in the Idle or Standby power modes. When the
;state of the DRDY bit changes, it shall not change again until after the host reads the Status
;register.
;When the DRDY bit is equal to zero, a device responds as follows:
;a) the device shall accept and attempt to execute the EXECUTE DEVICE DIAGNOSTIC
;and INITIALIZE DEVICE PARAMETERS commands;
;b) If a device accepts commands other than EXECUTE DEVICE DIAGNOSTIC and
;INITIALIZE DEVICE PARAMETERS during the time the DRDY bit is equal to zero, the
;results are vendor specific.

;- DF (Device Fault) indicates a device fault error has been detected. The internal status or internal
;conditions that causes this error to be indicated is vendor specific.

;- DSC (Device Seek Complete) indicates that the device heads are settled over a track. When an
;error occurs, this bit shall not be changed until the Status register is read by the host, at which time
;the bit again indicates the current Seek Complete status.

;- DRQ (Data Request) indicates that the device is ready to transfer a word or byte of data between
;the host and the device.

;- CORR (Corrected Data) is used to indicate a correctable data error. The definition of what
;constitutes a correctable error is vendor specific. This condition does not terminate a data transfer.

;- IDX (Index) is vendor specific.

;- ERR (Error) indicates that an error occurred during execution of the previous command. The bits in
;the Error register have additional information regarding the cause of the error. Once the device has
;set the error bit, the device shall not change the contents of the following items until a new command
;has been accepted, the SRST bit is set to one, or RESET- is asserted:
;the ERR bit in the Status register
;Error register
;Cylinder High register
;Cylinder Low register
;Sector Count register
;Sector Number register
;Device/Head register.

;;
;; IDE Command Codes (well, the ones we will support)
;;

IDE_CMD_IDENTIFY = $EC      ; Get device identification data
IDE_CMD_READ_SECTOR = $21   ; Read 1 or more sectors
IDE_CMD_WRITE_SECTOR = $30  ; Write 1 or more sectors

