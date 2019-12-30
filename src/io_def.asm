; Channel numbers for PUTC/GETCH/etc.
CHAN_CONSOLE = 0        ; Channel number for the screen/keyboard
CHAN_COM1 = 1           ; Channel number for the external serial port
CHAN_COM2 = 2           ; Channel number for the internal serial port
CHAN_LPT = 3            ; Channel number for the parallel port

; Joystick Ports
JOYSTICK0     = $AFE800  ;(R) Joystick 0 - J7 (Next to Buzzer)
JOYSTICK1     = $AFE801  ;(R) Joystick 1 - J8
JOYSTICK2     = $AFE802  ;(R) Joystick 2 - J9
JOYSTICK3     = $AFE803  ;(R) Joystick 3 - J10 (next to SD Card)

LFSR          = $AFE804
; Hard Coded (in ASCII) PCB Revision
PCB_REV_C     = $AFE808
PCB_REV_X     = $AFE809
PCB_REV_1     = $AFE80A
PCB_REV_EOL   = $AFE80B
; Dip switch Ports
DIP_OPTIONS   = $AFE80C
DIP_MEM_SIZE  = $AFE80D
DIP_BOOTMODE  = $AFE80E

HD_INSTALLED  = $80
BOOT_MODE1    = $02
BOOT_MODE0    = $01
; Hard Coded ID1
MACHINE_ID    = $AFE80F

; SD Card CH376S Port
SDCARD_DATA   = $AFE810  ;(R/W) SDCARD (CH376S) Data PORT_A (A0 = 0)
SDCARD_CMD    = $AFE811  ;(R/W) SDCARD (CH376S) CMD/STATUS Port (A0 = 1)
; SD Card Card Presence / Write Protect Status Reg
SDCARD_STAT   = $AFE812  ;(R) SDCARD (Bit[0] = CD, Bit[1] = WP)
; Audio WM8776 CODEC Control Interface (Write Only)
CODEC_DATA_LO = $AFE900  ;(W) LSB of Add/Data Reg to Control CODEC See WM8776 Spec
CODEC_DATA_HI = $AFE901  ;(W) MSB od Add/Data Reg to Control CODEC See WM8776 Spec
CODEC_WR_CTRL = $AFE902  ;(W) Bit[0] = 1 -> Start Writing the CODEC Control Register
; IDE Interface
IDE_DATA_LO   = $AFE830 ; ALways Read or Write that Register in 16Bits
IDE_DATA_HI   = $AFE831
IDE_ERROR     = $AFE832 ; Error Information register (only read when there is an error ) - Probably clears Error Bits
IDE_SECT_CNT  = $AFE834 ; Sector Count Register (also used to pass parameter for timeout for IDLE modus Command)
IDE_SECT_SRT  = $AFE836 ; Start Sector Register (0 = 256), so start @ 1
IDE_CLDR_LO   = $AFE838 ; Low Byte of Cylinder Numnber {7:0}
IDE_CLDR_HI   = $AFE83A ;  Hi Byte of Cylinder Number {9:8} (1023-0).
IDE_HEAD      = $AFE83C ; Head, device select, {3:0} HEad Number, 4 -> 0:Master, 1:Slave, {7:5} = 101 (legacy);
IDE_CMD_STAT  = $AFE83E ; Command/Status Register - Reading this will clear the Interrupt Registers
;7    6    5   4  3   2   1    0
;BSY DRDY DF DSC DRQ CORR IDX ERR

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
