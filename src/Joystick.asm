.cpu "65816"


;///
; Setup the Joystick Port
;
;////////////////////////////////////////////////////////
; IDE_INIT
; Init the HDD
; Inputs:
;  None
; Affects:
;   None
;/////////////////////////////////////////////////////////
;
JOYSTICK_SET_NES_MODE
          setas
          LDA JOYSTICK_MODE
          AND #~NES_SNES_JOY  ; 0 = NES (8 bit shift)
          STA JOYSTICK_MODE
          RTL

JOYSTICK_SET_SNES_MODE
          setas
          LDA JOYSTICK_MODE
          AND #~NES_SNES_JOY
          ORA #NES_SNES_JOY   ; 1 = SNES (12 Bit Shift)
          STA JOYSTICK_MODE
          RTL

JOYSTICK_ENABLE_NES_SNES_PORT0
          setas
          ; Enable Port 0 - NES/SNES Mode
          LDA JOYSTICK_MODE
          AND #~NES_SNES_EN0
          ORA #NES_SNES_EN0
          STA JOYSTICK_MODE
          RTL
;
JOYSTICK_ENABLE_NES_SNES_PORT1
          setas
          ; Enable Port 1 - NES/SNES Mode
          LDA JOYSTICK_MODE
          AND #~NES_SNES_EN1
          ORA #NES_SNES_EN1
          STA JOYSTICK_MODE
          RTL
;
JOYSTICK_DISABLE_NES_SNES_PORT0
          setas
          ; Enable Port 0 - NES/SNES Mode
          LDA JOYSTICK_MODE
          AND #~NES_SNES_EN0
          STA JOYSTICK_MODE
          RTL
;
JOYSTICK_DISABLE_NES_SNES_PORT1
          setas
          ; Enable Port 0 - NES/SNES Mode
          LDA JOYSTICK_MODE
          AND #~NES_SNES_EN1
          STA JOYSTICK_MODE
          RTL


JOYSTICK_NES_SNES_TRIG_WITH_POLL  ; This is a blocking Routine
                                  ;(you should lose waiting 4us for NES and 6us for SNES)
          setas
          ; Check if the Joystick have the NES/SNES mode enabled
          LDA JOYSTICK_MODE
          AND #(NES_SNES_EN0 | NES_SNES_EN1)
          CMP #$00
          BEQ END_OF_JOYSTICK_POLL

          LDA JOYSTICK_MODE
          ORA #NES_SNES_TRIG   ; Set to 1 (Will auto Clear)
          STA JOYSTICK_MODE

JOYSTICK_POLLING_ISNOTOVER
          LDA JOYSTICK_MODE ;
          AND #NES_SNES_DONE
          CMP #NES_SNES_DONE
          BNE JOYSTICK_POLLING_ISNOTOVER


END_OF_JOYSTICK_POLL
          RTL
