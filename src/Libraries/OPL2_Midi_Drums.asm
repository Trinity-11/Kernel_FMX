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
; Instrument definition is based on Adlib instrument bank format.
;  0 - Rhythm mode drum channel
;		Drum channels are predefined by the YM3812 and cannot be redefined. Regular instruments have their channel set
;		to $00 and can be assigned to any channel by the setInstrument function. Rhythm mode instruments can only be
;		used when rhythm mode is active (see OPL2.setPercussion).
;
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
; MIDI DRUMS
DRUMINS_CLAP2         .text $00, $3E, $00, $9F, $0F, $0F, $00, $30, $00, $87, $FA, $00
DRUMINS_SCRATCH1      .text $00, $01, $00, $78, $97, $09, $00, $02, $00, $88, $98, $03
DRUMINS_SCRATCH2      .text $00, $01, $00, $78, $97, $09, $00, $02, $00, $88, $98, $03
DRUMINS_RIMSHOT2      .text $00, $16, $08, $F1, $FB, $01, $00, $11, $00, $F9, $69, $00
DRUMINS_HIQ           .text $00, $00, $00, $F8, $6C, $01, $00, $0E, $80, $E8, $4A, $00
DRUMINS_WOODBLOK      .text $00, $25, $1B, $FA, $F2, $01, $00, $12, $00, $F6, $9A, $00
DRUMINS_GLOCK         .text $00, $06, $03, $F4, $44, $00, $01, $01, $1B, $F2, $34, $00
DRUMINS_BASS_DR2      .text $00, $00, $00, $F9, $F3, $05, $00, $01, $00, $F7, $8A, $00
DRUMINS_BASS_DR1      .text $00, $01, $07, $FA, $FD, $05, $00, $01, $00, $F6, $47, $00
DRUMINS_RIMSHOT       .text $00, $16, $08, $F1, $FB, $01, $00, $11, $00, $F9, $69, $00
DRUMINS_SNARE_AC      .text $00, $24, $00, $FF, $00, $0F, $00, $02, $00, $F7, $A9, $00
DRUMINS_CLAP          .text $00, $3E, $00, $9F, $0F, $0F, $00, $30, $00, $87, $FA, $00
DRUMINS_SNARE_EL      .text $00, $24, $00, $FF, $00, $0F, $00, $02, $00, $F7, $A9, $00
DRUMINS_LO_TOMS       .text $00, $06, $0A, $FA, $1F, $0C, $00, $11, $00, $F5, $F5, $00
DRUMINS_HIHAT_CL      .text $00, $2C, $00, $F2, $FE, $07, $00, $02, $06, $B8, $D8, $03
DRUMINS_HI_TOMS       .text $00, $06, $0A, $FA, $1F, $0C, $00, $11, $00, $F5, $F5, $00
DRUMINS_HIHAT_PL      .text $00, $2C, $00, $F2, $FE, $07, $00, $02, $06, $B8, $D8, $03
DRUMINS_LOW_TOM       .text $00, $06, $0A, $FA, $1F, $0C, $00, $11, $00, $F5, $F5, $00
DRUMINS_HIHAT_OP      .text $00, $2E, $00, $82, $F6, $05, $00, $04, $10, $74, $F8, $03
DRUMINS_LTOM_MID      .text $00, $06, $0A, $FA, $1F, $0C, $00, $11, $00, $F5, $F5, $00
DRUMINS_HTOM_MID      .text $00, $06, $0A, $FA, $1F, $0C, $00, $11, $00, $F5, $F5, $00
DRUMINS_CRASH         .text $00, $2C, $00, $9F, $00, $0F, $02, $0E, $05, $C5, $D4, $03
DRUMINS_TOM_HIGH      .text $00, $06, $0A, $FA, $1F, $0C, $00, $11, $00, $F5, $F5, $00
DRUMINS_RIDE_CY       .text $00, $29, $10, $94, $00, $0F, $00, $04, $04, $F9, $44, $03
DRUMINS_TAMBOUR       .text $00, $2C, $00, $9F, $00, $0F, $02, $0E, $05, $C5, $D4, $03
DRUMINS_CYMBAL        .text $00, $29, $10, $94, $00, $0F, $00, $04, $04, $F9, $44, $03
DRUMINS_TAMBOU2       .text $00, $2E, $09, $F5, $F1, $01, $00, $06, $03, $87, $F7, $03
DRUMINS_SPLASH        .text $00, $2C, $00, $9F, $00, $0F, $02, $0E, $05, $C5, $D4, $03
DRUMINS_COWBELL       .text $00, $37, $14, $F7, $A1, $09, $01, $03, $00, $F6, $28, $00
DRUMINS_CRASH2        .text $00, $2C, $00, $9F, $00, $0F, $02, $0E, $05, $C5, $D4, $03
DRUMINS_VIBRASLA      .text $00, $80, $00, $FF, $00, $0D, $01, $00, $00, $F5, $F7, $01
DRUMINS_RIDE2         .text $00, $29, $10, $94, $00, $0F, $00, $04, $04, $F9, $44, $03
DRUMINS_HI_BONGO      .text $00, $25, $C4, $FA, $FA, $01, $00, $03, $00, $99, $F9, $00
DRUMINS_LO_BONGO      .text $00, $21, $03, $FB, $FA, $01, $01, $02, $00, $A8, $F7, $00
DRUMINS_MUTECONG      .text $00, $25, $C4, $FA, $FA, $01, $00, $03, $00, $99, $F9, $00
DRUMINS_OPENCONG      .text $00, $24, $18, $F9, $FA, $0F, $02, $03, $00, $A6, $F6, $00
DRUMINS_LOWCONGA      .text $00, $24, $18, $F9, $FA, $0F, $02, $03, $00, $A6, $F6, $00
DRUMINS_HI_TIMBA      .text $00, $05, $14, $F5, $F5, $07, $02, $03, $00, $F6, $36, $02
DRUMINS_LO_TIMBA      .text $00, $05, $14, $F5, $F5, $07, $02, $03, $00, $F6, $36, $02
DRUMINS_HI_AGOGO      .text $00, $1C, $0C, $F9, $31, $0F, $01, $15, $00, $96, $E8, $01
DRUMINS_LO_AGOGO      .text $00, $1C, $0C, $F9, $31, $0F, $01, $15, $00, $96, $E8, $01
DRUMINS_CABASA        .text $00, $0E, $00, $FF, $01, $0F, $00, $0E, $02, $79, $77, $03
DRUMINS_MARACAS       .text $00, $0E, $00, $FF, $01, $0F, $00, $0E, $02, $79, $77, $03
DRUMINS_S_WHISTL      .text $00, $20, $15, $AF, $07, $05, $01, $0E, $00, $A5, $2B, $02
DRUMINS_L_WHISTL      .text $00, $20, $18, $BF, $07, $01, $01, $0E, $00, $93, $3B, $02
DRUMINS_S_GUIRO       .text $00, $20, $00, $F0, $F7, $0B, $00, $08, $01, $89, $3B, $03
DRUMINS_L_GUIRO       .text $00, $20, $00, $F3, $FA, $09, $00, $08, $0A, $53, $2B, $02
DRUMINS_CLAVES        .text $00, $15, $21, $F8, $9A, $09, $01, $13, $00, $F6, $89, $00
DRUMINS_HI_WDBLK      .text $00, $25, $1B, $FA, $F2, $01, $00, $12, $00, $F6, $9A, $00
DRUMINS_LO_WDBLK      .text $00, $25, $1B, $FA, $F2, $01, $00, $12, $00, $F6, $9A, $00
DRUMINS_MU_CUICA      .text $00, $20, $01, $5F, $07, $01, $00, $08, $00, $87, $4B, $01
DRUMINS_OP_CUICA      .text $00, $25, $12, $57, $F7, $01, $01, $03, $00, $78, $67, $01
DRUMINS_MU_TRNGL      .text $00, $22, $2F, $F1, $F0, $07, $00, $27, $02, $F8, $FC, $00
DRUMINS_OP_TRNGL      .text $00, $26, $44, $F1, $F0, $07, $00, $27, $40, $F5, $F5, $00
DRUMINS_SHAKER        .text $00, $0E, $00, $FF, $01, $0F, $00, $0E, $02, $79, $77, $03
DRUMINS_TRIANGL1      .text $00, $26, $44, $F1, $F0, $07, $00, $27, $40, $F5, $F5, $00
DRUMINS_TRIANGL2      .text $00, $26, $44, $F1, $F0, $07, $00, $27, $40, $F5, $F5, $00
DRUMINS_RIMSHOT3      .text $00, $16, $08, $F1, $FB, $01, $00, $11, $00, $F9, $69, $00
DRUMINS_RIMSHOT4      .text $00, $16, $08, $F1, $FB, $01, $00, $11, $00, $F9, $69, $00
DRUMINS_TAIKO         .text $00, $02, $1D, $F5, $93, $01, $00, $00, $00, $C6, $45, $00
;MIDI note number of the first drum sound.
DRUM_NOTE_BASE = 27;
NUM_MIDI_DRUMS = 60;
;Instrument pointer array to access instruments by MIDI program (24Bit Address Stored within 32Bit Boundary)
midiDrums     .dword DRUMINS_CLAP2, DRUMINS_SCRATCH1, DRUMINS_SCRATCH2, DRUMINS_RIMSHOT2
              .dword DRUMINS_HIQ, DRUMINS_WOODBLOK, DRUMINS_GLOCK, DRUMINS_BASS_DR2
              .dword DRUMINS_BASS_DR1, DRUMINS_RIMSHOT,  DRUMINS_SNARE_AC, DRUMINS_CLAP
              .dword DRUMINS_SNARE_EL, DRUMINS_LO_TOMS,  DRUMINS_HIHAT_CL, DRUMINS_HI_TOMS
              .dword DRUMINS_HIHAT_PL, DRUMINS_LOW_TOM,	DRUMINS_HIHAT_OP, DRUMINS_LTOM_MID
              .dword DRUMINS_HTOM_MID, DRUMINS_CRASH,    DRUMINS_TOM_HIGH, DRUMINS_RIDE_CY
              .dword DRUMINS_TAMBOUR,  DRUMINS_CYMBAL,   DRUMINS_TAMBOU2,  DRUMINS_SPLASH
              .dword DRUMINS_COWBELL,  DRUMINS_CRASH2, 	DRUMINS_VIBRASLA, DRUMINS_RIDE2
              .dword DRUMINS_HI_BONGO, DRUMINS_LO_BONGO, DRUMINS_MUTECONG, DRUMINS_OPENCONG
              .dword DRUMINS_LOWCONGA, DRUMINS_HI_TIMBA, DRUMINS_LO_TIMBA, DRUMINS_HI_AGOGO
              .dword DRUMINS_LO_AGOGO, DRUMINS_CABASA, DRUMINS_MARACAS,  DRUMINS_S_WHISTL
              .dword DRUMINS_L_WHISTL, DRUMINS_S_GUIRO,  DRUMINS_L_GUIRO,  DRUMINS_CLAVES
              .dword DRUMINS_HI_WDBLK, DRUMINS_LO_WDBLK, DRUMINS_MU_CUICA, DRUMINS_OP_CUICA
              .dword DRUMINS_MU_TRNGL, DRUMINS_OP_TRNGL, DRUMINS_SHAKER, DRUMINS_TRIANGL1
              .dword DRUMINS_TRIANGL2, DRUMINS_RIMSHOT3, DRUMINS_RIMSHOT4, DRUMINS_TAIKO
