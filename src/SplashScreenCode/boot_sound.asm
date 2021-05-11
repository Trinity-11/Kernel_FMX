;;
;; Code to play the startup sound
;;

;
; Play the boot sound. This will use the SID to play a F major chord
;
BOOT_SOUND      .proc
                PHA
                PHX
                PHP

                setas
                LDA #0
                LDX #0
clr_loop        STA @l SID0_V1_FREQ_LO,X        ; Clear the SID register
                INX                             ; Move to the next SID register
                CPX #24
                BNE clr_loop                    ; Loop until we've cleared all the main ones

                LDA #$2A                        ; Attack = 2, Decay = 10
                STA @l SID0_V1_ATCK_DECY
                STA @l SID0_V2_ATCK_DECY
                STA @l SID0_V3_ATCK_DECY

                LDA #$1A                        ; Sustain = 1, Release = 10
                STA @l SID0_V1_SSTN_RLSE
                STA @l SID0_V2_SSTN_RLSE
                STA @l SID0_V3_SSTN_RLSE

                LDA #15                         ; Set the volume to max
                STA @l SID0_MODE_VOL

                LDA #96                         ; Set voice 1 to F-3
                STA @l SID0_V1_FREQ_LO
                LDA #22
                STA @l SID0_V1_FREQ_HI

                LDA #$11                        ; Turn on triangle wave
                STA @l SID0_V1_CTRL

                LDX #1500                       ; Wait to press the next key
                JSL ILOOP_MS

                LDA #49                         ; Set voice 2 to A-3
                STA @l SID0_V2_FREQ_LO
                LDA #8
                STA @l SID0_V2_FREQ_HI

                LDA #$11                        ; Turn on triangle wave
                STA @l SID0_V2_CTRL

                LDX #1500                       ; Wait to press the next key
                JSL ILOOP_MS

                LDA #135                        ; Set voice 3 to C-3
                STA @l SID0_V3_FREQ_LO
                LDA #33
                STA @l SID0_V3_FREQ_HI

                LDA #$11                        ; Turn on triangle wave
                STA @l SID0_V3_CTRL

                LDX #40000                      ; Hold down the keys, so to speak... for a while
                JSL ILOOP_MS

                LDA #$10                        ; Release the keys...
                STA @l SID0_V2_CTRL
                STA @l SID0_V2_CTRL
                STA @l SID0_V2_CTRL

                PLP
                PLX
                PLA
                RTL
                .pend

BOOT_SOUND_OFF  .proc
                PHA
                PHX
                PHP

                LDX #0
clr_loop        STA @l SID0_V1_FREQ_LO,X        ; Clear the SID register
                INX                             ; Move to the next SID register
                CPX #24
                BNE clr_loop                    ; Loop until we've cleared all the main ones

                PLP
                PLX
                PLA
                RTL
                .pend