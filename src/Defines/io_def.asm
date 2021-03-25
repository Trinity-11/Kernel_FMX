;;;
;;; I/O addresses and definitions
;;;

; I/O channel IDs (used for PUTC, GETC*, etc.)
CHAN_CONSOLE  = 0           ; ID for screen and keyboard access
CHAN_COM1     = 1           ; ID for serial access on COM1 (external port)
CHAN_COM2     = 2           ; ID for serial access on COM2 (internal port)
CHAN_LPT      = 3           ; ID for parallel port

; SD Card CH376S Port
SDCARD_DATA   = $AFE810     ;(R/W) SDCARD (CH376S) Data PORT_A (A0 = 0)
SDCARD_CMD    = $AFE811     ;(R/W) SDCARD (CH376S) CMD/STATUS Port (A0 = 1)

; SD Card Card Presence / Write Protect Status Reg
SDCARD_STAT   = $AFE812     ;(R) SDCARD (Bit[0] = CD, Bit[1] = WP)
SDC_DETECTED = $01          ; SD card has been detected (0 = card present, 1 = no card present)
SDC_WRITEPROT = $02         ; SD card is write protected (0 = card is writeable, 1 = card is write protected or missing)

; Audio WM8776 CODEC Control Interface (Write Only)
CODEC_DATA_LO = $AFE900     ;(W) LSB of Add/Data Reg to Control CODEC See WM8776 Spec
CODEC_DATA_HI = $AFE901     ;(W) MSB od Add/Data Reg to Control CODEC See WM8776 Spec
CODEC_WR_CTRL = $AFE902     ;(W) Bit[0] = 1 -> Start Writing the CODEC Control Register
