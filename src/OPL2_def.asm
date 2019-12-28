;assign CS_OPL2L_o 	= (BUS_A_i[23:8] == 22'b0111_1111_1110_0101) & Valid_Address;			// $7F:E500..$7F:E5FF	// OPL2 - Left Side
;assign CS_OPL2R_o 	= (BUS_A_i[23:8] == 22'b0111_1111_1110_0110) & Valid_Address;			// $7F:E600..$7F:E6FF	// OPL2 - Right Side
; assign CS_OPL2B_o 	= (BUS_A_i[23:8] == 22'b0111_1111_1110_0111) & Valid_Address;			// $7F:E700..$7F:E7FF	// OPL2 - Both Side (Write Sequence Only)



;  1 - Channel c, operator 1, register $20
;		Tremolo(1) | Vibrato(1) | Sustain(1) | KSR(1) | Frequency multiplier (4)
;
;  2 - Channel c, operator 1, register $40
;		Key scale level(2) | Output level(6)
;
;  3 - Channel c, operator 1, register $60
;		Attack(4) | Decay(4)
;
;  4 - Channel c, operator 1, register $80
;		Sustain(4) | Release(4)
;
;  5 - Channel c, register $C0
;		Undefined(4) | Modulation feedback factor(3) | Synth type(1)
;
;  6 - Channel c, operator 1, register $E0
;		Undefined(5) | Waveform(3)
;
;  7 - Channel c, operator 2, register $20
;  8 - Channel c, operator 2, register $40
;  9 - Channel c, operator 2, register $60
; 10 - Channel c, operator 2, register $80
; 11 - Channel c, operator 2, register $E0
; Direct Access to Left Channel
; L = Left
OPL2_L_BASE               = $AFE500
OPL2_L_TEST               = $AFE501 ; TEST
OPL2_L_TIMER1             = $AFE502 ; TIMER-1
OPL2_L_TIMER2             = $AFE503 ; TIMER-2
OPL2_L_IRQ                = $AFE504 ;
OPL2_L_CSM                = $AFE508 ;
OPL2_L_AM_VID_EG_KSR_MULT = $AFE520 ; $40..$35 (21 Registers)
OPL2_L_KSL_TL             = $AFEE40;  $40..$55 (21 Registers)
OPL2_L_AR_DR              = $AFE560;  $60..$75 (21 Registers)
OPL2_L_SL_RR              = $AFE580;  $80..$95 (21 Registers)
OPL2_L_FNumber            = $AFE5A0;  $A0..$A8
OPL2_L_KON_BLOCK_FNumber  = $AFE5B0;  $B0..$B9
OPL2_L_DPTH_RHYTM         = $AFE5BD;  $BD
OPL2_L_FEEDBACK           = $AFE5C0;  $C0..$C9
OPL2_L_WAVE_SELECT        = $AFE5E0;  $E0..$F5
; Direct Access to Right Channel
; R = Right
OPL2_R_BASE               = $AFE600
OPL2_R_TEST               = $AFE601 ; TEST
OPL2_R_TIMER1             = $AFE602 ; TIMER-1
OPL2_R_TIMER2             = $AFE603 ; TIMER-2
OPL2_R_IRQ                = $AFE604 ;
OPL2_R_CSM                = $AFE608 ;
OPL2_R_AM_VID_EG_KSR_MULT = $AFE620 ; $40..$35 (21 Registers)
OPL2_R_KSL_TL             = $AFE640;  $40..$55 (21 Registers)
OPL2_R_AR_DR              = $AFE660;  $60..$75 (21 Registers)
OPL2_R_SL_RR              = $AFE680;  $80..$95 (21 Registers)
OPL2_R_FNumber            = $AFE6A0;  $A0..$A8
OPL2_R_KON_BLOCK_FNumber  = $AFE6B0;  $B0..$B9
OPL2_R_DPTH_RHYTM         = $AFE6BD;  $BD
OPL2_R_FEEDBACK           = $AFE6C0;  $C0..$C9
OPL2_R_WAVE_SELECT        = $AFE6E0;  $E0..$F5
; Direct Access to Both at the same time (Write Only of course)
; S = Stereo
OPL2_S_BASE_LL            = $E700
OPL2_S_BASE_HL            = $00AF
OPL2_S_TEST               = $AFE701 ; TEST
OPL2_S_TIMER1             = $AFE702 ; TIMER-1
OPL2_S_TIMER2             = $AFE703 ; TIMER-2
OPL2_S_IRQ                = $AFE704 ;
OPL2_S_CSM                = $AFE708 ;
OPL2_S_AM_VID_EG_KSR_MULT = $AFE720 ; $20..$35 (21 Registers)
OPL2_S_KSL_TL             = $AFE740;  $40..$55 (21 Registers)
OPL2_S_AR_DR              = $AFE760;  $60..$75 (21 Registers)
OPL2_S_SL_RR              = $AFE780;  $80..$95 (21 Registers)
OPL2_S_FNumber            = $AFE7A0;  $A0..$A8
OPL2_S_KON_BLOCK_FNumber  = $AFE7B0;  $B0..$B9
OPL2_S_DPTH_RHYTM         = $AFE7BD;  $BD
OPL2_S_FEEDBACK           = $AFE7C0;  $C0..$C9
OPL2_S_WAVE_SELECT        = $AFE7E0;  $E0..$F5




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

;Note to frequency mapping.
NOTE_C =    0
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
