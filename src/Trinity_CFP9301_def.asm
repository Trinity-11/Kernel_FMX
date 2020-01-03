; TRINITY CHIPSET
; CFP9301 Memory Map

; Joystick Ports
JOYSTICK0           = $AFE800   ;(R) Joystick 0 - J7 (next to SD Card)
JOYSTICK1           = $AFE801   ;(R) Joystick 1 - J8
JOYSTICK2           = $AFE802   ;(R) Joystick 2 - J9
JOYSTICK3           = $AFE803   ;(R) Joystick 3 - J10 (Next to Buzzer)
JOYSTICK_MODE       = $AFE804
NES_SNES_EN0        = $01       ; Enable the NES/SNES Mode on Port 0
NES_SNES_EN1        = $02       ; Enable the NES/SNES Mode on Port 1
NES_SNES_JOY        = $04       ; 0 = NES, 1 = SNES
NES_SNES_DONE       = $40       ; Poll to see if the Deserializer is done
NES_SNES_TRIG       = $80       ; Set to start the Serializer

;SNES Controller Bit Mapping: (6us Transaction Time)
;NES_SNES0_DAT_LO
;Bit 0 - "RIGHT"
;Bit 1 - "LEFT"
;Bit 2 - "DOWN"
;Bit 3 - "UP"
;Bit 4 - "START"
;Bit 5 - "SELECT"
;Bit 6 - "Y"
;Bit 7 - "B"
;SNES0_DAT_HI0
;Bit 0 - "R"
;Bit 1 - "L"
;Bit 2 - "X"
;Bit 3 - "A"

;NES Controller Bit Mapping:
;NES_SNES0_DAT_LO
;Bit 0 - "RIGHT"
;Bit 1 - "LEFT"
;Bit 2 - "DOWN"
;Bit 3 - "UP"
;Bit 4 - "START"
;Bit 5 - "SELECT"
;Bit 6 - "B"
;Bit 7 - "A"

;JOYSTICK Normal Mode Port 0
;Bit 0 - "UP"
;Bit 1 - "DOWN"
;Bit 2 - "LEFT"
;Bit 3 - "RIGHT"
;Bit 4 - "BUTTON"
;Bit 5 - 0
;Bit 6 - "BUTTON1"
;Bit 7 - "BUTTON2"

;JOYSTICK Normal Mode Port 1
;Bit 0 - "UP"
;Bit 1 - "DOWN"
;Bit 2 - "LEFT"
;Bit 3 - "RIGHT"
;Bit 4 - "BUTTON"
;Bit 5 - 0
;Bit 6 - "BUTTON1"
;Bit 7 - "BUTTON2"

;JOYSTICK Normal Mode Port 2
;Bit 0 - "UP"
;Bit 1 - "DOWN"
;Bit 2 - "LEFT"
;Bit 3 - "RIGHT"
;Bit 4 - "BUTTON"
;Bit 5 - 0
;Bit 6 - 0
;Bit 7 - 0

;JOYSTICK Normal Mode Port 3
;Bit 0 - "UP"
;Bit 1 - "DOWN"
;Bit 2 - "LEFT"
;Bit 3 - "RIGHT"
;Bit 4 - "BUTTON"
;Bit 5 - 0
;Bit 6 - 0
;Bit 7 - 0

; Board identification registers
REVOFPCB_C          = $AFE805   ; You should read the ASCCII for "C"
REVOFPCB_4          = $AFE806   ; You should read the ASCCII for "4"
REVOFPCB_A          = $AFE807   ; You should read the ASCCII for "A"

;NES/SNES Data Output from Deserializer Port 0
NES_SNES0_DAT_LO    = $AFE808   ; Contains the 8bits From NES and SNES
SNES0_DAT_HI0       = $AFE809   ; Contains the extra 4 bit from the SNES Controller

;NES/SNES Data Output from Deserializer Port 1
NES_SNES1_DAT_LO    = $AFE80A
SNES1_DAT_HI0       = $AFE80B

; CPLD Revsion
CFP9301_REV         = $AFE80C   ; Hardware Revision of the CPLD Code

; Dip switch Ports
DIP_USER            = $AFE80D   ; Dip Switch 3/4/5 can be user Defined
DIP_BOOTMODE        = $AFE80E
BOOT_MODE0          = $01
BOOT_MODE1          = $02
HD_INSTALLED        = $80
DIP_BOOT_IDE        = $00
DIP_BOOT_SDCARD     = $01
DIP_BOOT_FLOPPY     = $02
DIP_BOOT_BASIC      = $03

; Boot modes
; DIP1  DIP2
; ----  ----
; OFF   OFF (1,1): Boot on BASIC
; ON    OFF (0,1): Boot from SD CARD
; OFF   ON  (1,0): Boot from Floppy (Illegal if MachineID doesn't specify a Floppy)
; ON    ON  (0,0): Boot from HDD (Illegal if Dip switch 8 is OFF (1))
