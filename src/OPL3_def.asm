; Direct Access to Right Channel
; R = Right
OPL3_R_BASE               = $AFE600
OPL3_R_BASE_LL            = $E600
OPL3_R_BASE_HL            = $00AF
OPL3_R_TEST               = $AFE601 ; TEST
OPL3_R_TIMER1             = $AFE602 ; TIMER-1
OPL3_R_TIMER2             = $AFE603 ; TIMER-2
OPL3_R_IRQ                = $AFE604 ;
OPL3_R_OPL3_MODE          = $AFE605 ; Set bit 0 to 1 if you want to use in OPL3 Mode
OPL3_R_CSM                = $AFE608 ;
OPL3_R_AM_VID_EG_KSR_MULT = $AFE620 ; $40..$35 (21 Registers)
OPL3_R_KSL_TL             = $AFE640;  $40..$55 (21 Registers)
OPL3_R_AR_DR              = $AFE660;  $60..$75 (21 Registers)
OPL3_R_SL_RR              = $AFE680;  $80..$95 (21 Registers)
OPL3_R_FNumber            = $AFE6A0;  $A0..$A8
OPL3_R_KON_BLOCK_FNumber  = $AFE6B0;  $B0..$B9
OPL3_R_DPTH_RHYTM         = $AFE6BD;  $BD
OPL3_R_FEEDBACK           = $AFE6C0;  $C0..$C9
OPL3_R_WAVE_SELECT        = $AFE6E0;  $E0..$F5

; Direct Access to Left Channel
; L = Left
OPL3_L_BASE               = $AFE700
OPL3_L_BASE_LL            = $E700
OPL3_L_BASE_HL            = $00AF
OPL3_L_TEST               = $AFE701 ; TEST
OPL3_L_TIMER1             = $AFE702 ; TIMER-1
OPL3_L_TIMER2             = $AFE703 ; TIMER-2
OPL3_L_IRQ                = $AFE704 ;
OPL3_L_CSM                = $AFE708 ;
OPL3_L_AM_VID_EG_KSR_MULT = $AFE720 ; $40..$35 (21 Registers)
OPL3_L_KSL_TL             = $AFE740;  $40..$55 (21 Registers)
OPL3_L_AR_DR              = $AFE760;  $60..$75 (21 Registers)
OPL3_L_SL_RR              = $AFE780;  $80..$95 (21 Registers)
OPL3_L_FNumber            = $AFE7A0;  $A0..$A8
OPL3_L_KON_BLOCK_FNumber  = $AFE7B0;  $B0..$B9
OPL3_L_DPTH_RHYTM         = $AFE7BD;  $BD
OPL3_L_FEEDBACK           = $AFE7C0;  $C0..$C9
OPL3_L_WAVE_SELECT        = $AFE7E0;  $E0..$F5

TREMOLO    = $80
VIBRATO    = $40
SUSTAINING = $20
KSR        = $10
MULTIPLIER = $0F

KEY_SCALE  = $C0
OP_LEVEL   = $3F
ATTACK_RT  = $F0
DECAY_RT   = $0F
SUSTAIN_RT = $F0
RELEASE_RT = $0F

FEEDBACK   = $0E
ALGORITHM  = $01

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; All the code for the C256 Foenix support is coming from
;; https://github.com/DhrBaksteen/ArduinoOPL2/
;; The OPL2 for the Arduino Project created by DhrBaksteen
;; All the code in the Foenix has been translated from it for the 65C816
;; Coding for the C256 Foenix has been coded by Stefany Allaire
; Copy of the GIT Hub License File:
;
;MIT License

;Copyright (c) 2016-2018 Maarten Janssen

;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:

;The above copyright notice and this permission notice shall be included in all
;copies or substantial portions of the Software.

;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;SOFTWARE.
;  Macro from the C Code
;		#define min(a, b) ((a) < (b) ? (a) : (b))
;		#define max(a, b) ((a) > (b) ? (a) : (b))

;General OPL2 definitions.
OPL2_NUM_CHANNELS = 9

;Operator definitions.
OPERATOR1 = 0
OPERATOR2 = 1
MODULATOR = 0
CARRIER = 1

;Synthesis type definitions.
FREQ_MODULATION = 0
ADDITIVE_SYNTH  = 1

;Drum sounds.
DRUM_BASS   = $10
DRUM_SNARE  = $08
DRUM_TOM    = $04
DRUM_CYMBAL = $02
DRUM_HI_HAT = $01

;Note to frequency mapping.  -- 0 is no note and F is key-off
NOTE_CS =   1
NOTE_D =    2
NOTE_DS =   3
NOTE_E =    4
NOTE_F =    5
NOTE_FS =   6
NOTE_G =    7
NOTE_GS =   8
NOTE_A =    9
NOTE_AS =  10
NOTE_B =   11
NOTE_C =   12

;const float fIntervals[8] = {
;  0.048, 0.095, 0.190, 0.379, 0.759, 1.517, 3.034, 6.069
;};
noteFNumbers    .word  $016B, $0181, $0198, $01B0, $01CA, $01E5, $0202, $0220, $0241, $0263, $0287, $02AE

;const float blockFrequencies[8] = {
   ;48.503,   97.006,  194.013,  388.026,
  ;776.053, 1552.107, 3104.215, 6208.431
;};
registerOffsets_operator0 .byte $00, $01, $02, $08, $09, $0A, $10, $11, $12 ;initializers for operator 1 */
registerOffsets_operator1 .byte $03, $04, $05, $0B, $0C, $0D, $13, $14, $15 ;initializers for operator 2 */
drumOffsets               .byte $10, $13, $14, $12, $15, $11
drumBits                  .byte $10, $08, $04, $02, $01
instrumentBaseRegs        .byte $20, $40, $60, $80, $E0, $C0
