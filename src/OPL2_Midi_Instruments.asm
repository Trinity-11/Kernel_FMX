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
MIDI_INSTRUMENT_PIANO1     .text $00, $33, $5A, $B2, $50, $01, $00, $31, $00, $B1, $F5, $01
MIDI_INSTRUMENT_PIANO2     .text $00, $31, $49, $F2, $53, $07, $01, $11, $03, $F1, $F5, $00
MIDI_INSTRUMENT_PIANO3     .text $00, $31, $95, $D1, $83, $0D, $01, $32, $03, $C1, $F5, $00
MIDI_INSTRUMENT_HONKTONK   .text $00, $34, $9B, $F3, $63, $01, $01, $11, $00, $92, $F5, $01
MIDI_INSTRUMENT_EP1        .text $00, $27, $28, $F8, $B7, $01, $02, $91, $00, $F1, $F9, $00
MIDI_INSTRUMENT_EP2        .text $00, $1A, $2D, $F3, $EE, $01, $01, $11, $00, $F1, $F5, $00
MIDI_INSTRUMENT_HARPSIC    .text $00, $35, $95, $F2, $58, $0F, $01, $32, $02, $81, $F6, $01
MIDI_INSTRUMENT_CLAVIC     .text $00, $31, $85, $C9, $40, $01, $00, $35, $00, $C2, $B9, $01
MIDI_INSTRUMENT_CELESTA    .text $00, $09, $15, $C7, $64, $08, $00, $01, $05, $B2, $35, $00
MIDI_INSTRUMENT_GLOCK      .text $00, $06, $03, $F4, $44, $00, $01, $01, $1B, $F2, $34, $00
MIDI_INSTRUMENT_MUSICBOX   .text $00, $04, $06, $A9, $24, $0A, $01, $01, $01, $F5, $74, $00
MIDI_INSTRUMENT_VIBES      .text $00, $D4, $00, $F6, $33, $00, $00, $F1, $00, $61, $E3, $00
MIDI_INSTRUMENT_MARIMBA    .text $00, $D4, $00, $F7, $E8, $04, $00, $D1, $00, $A4, $64, $00
MIDI_INSTRUMENT_XYLO       .text $00, $36, $16, $F7, $F7, $01, $00, $31, $07, $B5, $F5, $00
MIDI_INSTRUMENT_TUBEBELL   .text $00, $03, $1B, $A2, $43, $0B, $00, $00, $00, $F3, $74, $00
MIDI_INSTRUMENT_SANTUR     .text $00, $C3, $8E, $F8, $35, $01, $01, $11, $00, $C3, $94, $01
MIDI_INSTRUMENT_ORGAN1     .text $00, $E2, $07, $F4, $1B, $06, $01, $E0, $00, $F4, $0D, $01
MIDI_INSTRUMENT_ORGAN2     .text $00, $F2, $00, $F6, $2C, $04, $00, $F0, $00, $F5, $0B, $01
MIDI_INSTRUMENT_ORGAN3     .text $00, $F1, $06, $B6, $15, $0A, $00, $F0, $00, $BF, $07, $00
MIDI_INSTRUMENT_PIPEORG    .text $00, $22, $03, $79, $16, $08, $01, $E0, $00, $6D, $08, $01
MIDI_INSTRUMENT_REEDORG    .text $00, $31, $27, $63, $06, $01, $00, $72, $00, $51, $17, $01
MIDI_INSTRUMENT_ACORDIAN   .text $00, $B4, $1D, $53, $16, $0F, $01, $71, $00, $51, $17, $01
MIDI_INSTRUMENT_HARMONIC   .text $00, $25, $29, $97, $15, $01, $00, $32, $00, $53, $08, $01
MIDI_INSTRUMENT_BANDNEON   .text $00, $24, $9E, $67, $15, $0F, $00, $31, $00, $53, $06, $01
MIDI_INSTRUMENT_NYLONGT    .text $00, $13, $27, $A3, $B4, $05, $01, $31, $00, $D2, $F8, $00
MIDI_INSTRUMENT_STEELGT    .text $00, $17, $A3, $F3, $32, $01, $00, $11, $00, $E2, $C7, $01
MIDI_INSTRUMENT_JAZZGT     .text $00, $33, $24, $D2, $C1, $0F, $01, $31, $00, $F1, $9C, $00
MIDI_INSTRUMENT_CLEANGT    .text $00, $31, $05, $F8, $44, $01, $00, $32, $02, $F2, $C9, $01
MIDI_INSTRUMENT_MUTEGT     .text $00, $21, $09, $9C, $7B, $07, $00, $02, $03, $95, $FB, $00
MIDI_INSTRUMENT_OVERDGT    .text $00, $21, $84, $81, $98, $07, $01, $21, $04, $A1, $59, $00
MIDI_INSTRUMENT_DISTGT     .text $00, $B1, $0C, $78, $43, $01, $00, $22, $03, $91, $FC, $03
MIDI_INSTRUMENT_GTHARMS    .text $00, $00, $0A, $82, $8C, $09, $00, $08, $02, $B4, $EC, $00
MIDI_INSTRUMENT_ACOUBASS   .text $00, $21, $13, $AB, $46, $01, $00, $21, $00, $93, $F7, $00
MIDI_INSTRUMENT_FINGBASS   .text $00, $01, $0A, $F9, $32, $01, $00, $22, $04, $C1, $58, $00
MIDI_INSTRUMENT_PICKBASS   .text $00, $21, $07, $FA, $77, $0B, $00, $22, $02, $C3, $6A, $00
MIDI_INSTRUMENT_FRETLESS   .text $00, $21, $17, $71, $57, $0B, $00, $21, $00, $62, $87, $00
MIDI_INSTRUMENT_SLAPBAS1   .text $00, $25, $01, $FA, $78, $07, $01, $12, $00, $F3, $97, $00
MIDI_INSTRUMENT_SLAPBAS2   .text $00, $21, $03, $FA, $88, $0D, $00, $13, $00, $B3, $97, $00
MIDI_INSTRUMENT_SYNBASS1   .text $00, $21, $09, $F5, $7F, $09, $01, $23, $04, $F3, $CC, $00
MIDI_INSTRUMENT_SYNBASS2   .text $00, $01, $10, $A3, $9B, $09, $00, $01, $00, $93, $AA, $00
MIDI_INSTRUMENT_VIOLIN     .text $00, $E2, $19, $F6, $29, $0D, $01, $E1, $00, $78, $08, $01
MIDI_INSTRUMENT_VIOLA      .text $00, $E2, $1C, $F6, $29, $0D, $01, $E1, $00, $78, $08, $01
MIDI_INSTRUMENT_CELLO      .text $00, $61, $19, $69, $16, $0B, $01, $61, $00, $54, $27, $01
MIDI_INSTRUMENT_CONTRAB    .text $00, $71, $18, $82, $31, $0D, $01, $32, $00, $61, $56, $00
MIDI_INSTRUMENT_TREMSTR    .text $00, $E2, $23, $70, $06, $0D, $01, $E1, $00, $75, $16, $01
MIDI_INSTRUMENT_PIZZ       .text $00, $02, $00, $88, $E6, $08, $00, $61, $00, $F5, $F6, $01
MIDI_INSTRUMENT_HARP       .text $00, $12, $20, $F6, $D5, $0F, $01, $11, $80, $F3, $E3, $00
MIDI_INSTRUMENT_TIMPANI    .text $00, $61, $0E, $F4, $F4, $01, $01, $00, $00, $B5, $F5, $00
MIDI_INSTRUMENT_STRINGS    .text $00, $61, $1E, $9C, $04, $0F, $01, $21, $80, $71, $16, $00
MIDI_INSTRUMENT_SLOWSTR    .text $00, $A2, $2A, $C0, $D6, $0F, $02, $21, $00, $30, $55, $01
MIDI_INSTRUMENT_SYNSTR1    .text $00, $61, $21, $72, $35, $0F, $01, $61, $00, $62, $36, $01
MIDI_INSTRUMENT_SYNSTR2    .text $00, $21, $1A, $72, $23, $0F, $01, $21, $02, $51, $07, $00
MIDI_INSTRUMENT_CHOIR      .text $00, $E1, $16, $97, $31, $09, $00, $61, $00, $62, $39, $00
MIDI_INSTRUMENT_OOHS       .text $00, $22, $C3, $79, $45, $01, $00, $21, $00, $66, $27, $00
MIDI_INSTRUMENT_SYNVOX     .text $00, $21, $DE, $63, $55, $01, $01, $21, $00, $73, $46, $00
MIDI_INSTRUMENT_ORCHIT     .text $00, $42, $05, $86, $F7, $0A, $00, $50, $00, $74, $76, $01
MIDI_INSTRUMENT_TRUMPET    .text $00, $31, $1C, $61, $02, $0F, $00, $61, $81, $92, $38, $00
MIDI_INSTRUMENT_TROMBONE   .text $00, $71, $1E, $52, $23, $0F, $00, $61, $02, $71, $19, $00
MIDI_INSTRUMENT_TUBA       .text $00, $21, $1A, $76, $16, $0F, $00, $21, $01, $81, $09, $00
MIDI_INSTRUMENT_MUTETRP    .text $00, $25, $28, $89, $2C, $07, $02, $20, $00, $83, $4B, $02
MIDI_INSTRUMENT_FRHORN     .text $00, $21, $1F, $79, $16, $09, $00, $A2, $05, $71, $59, $00
MIDI_INSTRUMENT_BRASS1     .text $00, $21, $19, $87, $16, $0F, $00, $21, $03, $82, $39, $00
MIDI_INSTRUMENT_SYNBRAS1   .text $00, $21, $17, $75, $35, $0F, $00, $22, $82, $84, $17, $00
MIDI_INSTRUMENT_SYNBRAS2   .text $00, $21, $22, $62, $58, $0F, $00, $21, $02, $72, $16, $00
MIDI_INSTRUMENT_SOPSAX     .text $00, $B1, $1B, $59, $07, $01, $01, $A1, $00, $7B, $0A, $00
MIDI_INSTRUMENT_ALTOSAX    .text $00, $21, $16, $9F, $04, $0B, $00, $21, $00, $85, $0C, $01
MIDI_INSTRUMENT_TENSAX     .text $00, $21, $0F, $A8, $20, $0D, $00, $23, $00, $7B, $0A, $01
MIDI_INSTRUMENT_BARISAX    .text $00, $21, $0F, $88, $04, $09, $00, $26, $00, $79, $18, $01
MIDI_INSTRUMENT_OBOE       .text $00, $31, $18, $8F, $05, $01, $00, $32, $01, $73, $08, $00
MIDI_INSTRUMENT_ENGLHORN   .text $00, $A1, $0A, $8C, $37, $01, $01, $24, $04, $77, $0A, $00
MIDI_INSTRUMENT_BASSOON    .text $00, $31, $04, $A8, $67, $0B, $00, $75, $00, $51, $19, $00
MIDI_INSTRUMENT_CLARINET   .text $00, $A2, $1F, $77, $26, $01, $01, $21, $01, $74, $09, $00
MIDI_INSTRUMENT_PICCOLO    .text $00, $E1, $07, $B8, $94, $01, $01, $21, $01, $63, $28, $00
MIDI_INSTRUMENT_FLUTE1     .text $00, $A1, $93, $87, $59, $01, $00, $E1, $00, $65, $0A, $00
MIDI_INSTRUMENT_RECORDER   .text $00, $22, $10, $9F, $38, $01, $00, $61, $00, $67, $29, $00
MIDI_INSTRUMENT_PANFLUTE   .text $00, $E2, $0D, $88, $9A, $01, $01, $21, $00, $67, $09, $00
MIDI_INSTRUMENT_BOTTLEB    .text $00, $A2, $10, $98, $94, $0F, $00, $21, $01, $6A, $28, $00
MIDI_INSTRUMENT_SHAKU      .text $00, $F1, $1C, $86, $26, $0F, $00, $F1, $00, $55, $27, $00
MIDI_INSTRUMENT_WHISTLE    .text $00, $E1, $3F, $9F, $09, $00, $00, $E1, $00, $6F, $08, $00
MIDI_INSTRUMENT_OCARINA    .text $00, $E2, $3B, $F7, $19, $01, $00, $21, $00, $7A, $07, $00
MIDI_INSTRUMENT_SQUARWAV   .text $00, $22, $1E, $92, $0C, $0F, $00, $61, $06, $A2, $0D, $00
MIDI_INSTRUMENT_SAWWAV     .text $00, $21, $15, $F4, $22, $0F, $01, $21, $00, $A3, $5F, $00
MIDI_INSTRUMENT_SYNCALLI   .text $00, $F2, $20, $47, $66, $03, $01, $F1, $00, $42, $27, $00
MIDI_INSTRUMENT_CHIFLEAD   .text $00, $61, $19, $88, $28, $0F, $00, $61, $05, $B2, $49, $00
MIDI_INSTRUMENT_CHARANG    .text $00, $21, $16, $82, $1B, $01, $00, $23, $00, $B2, $79, $01
MIDI_INSTRUMENT_SOLOVOX    .text $00, $21, $00, $CA, $93, $01, $00, $22, $00, $7A, $1A, $00
MIDI_INSTRUMENT_FIFTHSAW   .text $00, $23, $00, $92, $C9, $08, $01, $22, $00, $82, $28, $01
MIDI_INSTRUMENT_BASSLEAD   .text $00, $21, $1D, $F3, $7B, $0F, $00, $22, $02, $C3, $5F, $00
MIDI_INSTRUMENT_FANTASIA   .text $00, $E1, $00, $81, $25, $00, $01, $A6, $86, $C4, $95, $01
MIDI_INSTRUMENT_WARMPAD    .text $00, $21, $27, $31, $01, $0F, $00, $21, $00, $44, $15, $00
MIDI_INSTRUMENT_POLYSYN    .text $00, $60, $14, $83, $35, $0D, $02, $61, $00, $D1, $06, $00
MIDI_INSTRUMENT_SPACEVOX   .text $00, $E1, $5C, $D3, $01, $01, $01, $62, $00, $82, $37, $00
MIDI_INSTRUMENT_BOWEDGLS   .text $00, $28, $38, $34, $86, $01, $02, $21, $00, $41, $35, $00
MIDI_INSTRUMENT_METALPAD   .text $00, $24, $12, $52, $F3, $05, $01, $23, $02, $32, $F5, $01
MIDI_INSTRUMENT_HALOPAD    .text $00, $61, $1D, $62, $A6, $0B, $00, $A1, $00, $61, $26, $00
MIDI_INSTRUMENT_SWEEPPAD   .text $00, $22, $0F, $22, $D5, $0B, $01, $21, $84, $3F, $05, $01
MIDI_INSTRUMENT_ICERAIN    .text $00, $E3, $1F, $F9, $24, $01, $00, $31, $01, $D1, $F6, $00
MIDI_INSTRUMENT_SOUNDTRK   .text $00, $63, $00, $41, $55, $06, $01, $A2, $00, $41, $05, $01
MIDI_INSTRUMENT_CRYSTAL    .text $00, $C7, $25, $A7, $65, $01, $01, $C1, $05, $F3, $E4, $00
MIDI_INSTRUMENT_ATMOSPH    .text $00, $E3, $19, $F7, $B7, $01, $01, $61, $00, $92, $F5, $01
MIDI_INSTRUMENT_BRIGHT     .text $00, $66, $9B, $A8, $44, $0F, $00, $41, $04, $F2, $E4, $01
MIDI_INSTRUMENT_GOBLIN     .text $00, $61, $20, $22, $75, $0D, $00, $61, $00, $45, $25, $00
MIDI_INSTRUMENT_ECHODROP   .text $00, $E1, $21, $F6, $84, $0F, $00, $E1, $01, $A3, $36, $00
MIDI_INSTRUMENT_STARTHEM   .text $00, $E2, $14, $73, $64, $0B, $01, $E1, $01, $98, $05, $01
MIDI_INSTRUMENT_SITAR      .text $00, $21, $0B, $72, $34, $09, $00, $24, $02, $A3, $F6, $01
MIDI_INSTRUMENT_BANJO      .text $00, $21, $16, $F4, $53, $0D, $00, $04, $00, $F6, $F8, $00
MIDI_INSTRUMENT_SHAMISEN   .text $00, $21, $18, $DA, $02, $0D, $00, $35, $00, $F3, $F5, $00
MIDI_INSTRUMENT_KOTO       .text $00, $25, $0F, $FA, $63, $09, $00, $02, $00, $94, $E5, $01
MIDI_INSTRUMENT_KALIMBA    .text $00, $32, $07, $F9, $96, $01, $00, $11, $00, $84, $44, $00
MIDI_INSTRUMENT_BAGPIPE    .text $00, $20, $0E, $97, $18, $09, $02, $25, $03, $83, $18, $01
MIDI_INSTRUMENT_FIDDLE     .text $00, $61, $18, $F6, $29, $01, $00, $62, $01, $78, $08, $01
MIDI_INSTRUMENT_SHANNAI    .text $00, $E6, $21, $76, $19, $0B, $00, $61, $03, $8E, $08, $01
MIDI_INSTRUMENT_TINKLBEL   .text $00, $27, $23, $F0, $D4, $01, $00, $05, $09, $F2, $46, $00
MIDI_INSTRUMENT_AGOGO      .text $00, $1C, $0C, $F9, $31, $0F, $01, $15, $00, $96, $E8, $01
MIDI_INSTRUMENT_STEELDRM   .text $00, $02, $00, $75, $16, $06, $02, $01, $00, $F6, $F6, $01
MIDI_INSTRUMENT_WOODBLOK   .text $00, $25, $1B, $FA, $F2, $01, $00, $12, $00, $F6, $9A, $00
MIDI_INSTRUMENT_TAIKO      .text $00, $02, $1D, $F5, $93, $01, $00, $00, $00, $C6, $45, $00
MIDI_INSTRUMENT_MELOTOM    .text $00, $11, $15, $F5, $32, $05, $00, $10, $00, $F4, $B4, $00
MIDI_INSTRUMENT_SYNDRUM    .text $00, $22, $06, $FA, $99, $09, $00, $01, $00, $D5, $25, $00
MIDI_INSTRUMENT_REVRSCYM   .text $00, $2E, $00, $FF, $00, $0F, $02, $0E, $0E, $21, $2D, $00
MIDI_INSTRUMENT_FRETNOIS   .text $00, $30, $0B, $56, $E4, $01, $01, $17, $00, $55, $87, $02
MIDI_INSTRUMENT_BRTHNOIS   .text $00, $24, $00, $FF, $03, $0D, $00, $05, $08, $98, $87, $01
MIDI_INSTRUMENT_SEASHORE   .text $00, $0E, $00, $F0, $00, $0F, $02, $0A, $04, $17, $04, $03
MIDI_INSTRUMENT_BIRDS      .text $00, $20, $08, $F6, $F7, $01, $00, $0E, $05, $77, $F9, $02
MIDI_INSTRUMENT_TELEPHON   .text $00, $20, $14, $F1, $08, $01, $00, $2E, $02, $F4, $08, $00
MIDI_INSTRUMENT_HELICOPT   .text $00, $20, $04, $F2, $00, $03, $01, $23, $00, $36, $05, $01
MIDI_INSTRUMENT_APPLAUSE   .text $00, $2E, $00, $FF, $02, $0F, $00, $2A, $05, $32, $55, $03
MIDI_INSTRUMENT_GUNSHOT    .text $00, $20, $00, $A1, $EF, $0F, $00, $10, $00, $F3, $DF, $00
;Instrument pointer array to access instruments by MIDI program.
midiInstruments .dword MIDI_INSTRUMENT_PIANO1,   MIDI_INSTRUMENT_PIANO2,   MIDI_INSTRUMENT_PIANO3,   MIDI_INSTRUMENT_HONKTONK, MIDI_INSTRUMENT_EP1,      MIDI_INSTRUMENT_EP2
              	.dword MIDI_INSTRUMENT_HARPSIC,  MIDI_INSTRUMENT_CLAVIC,   MIDI_INSTRUMENT_CELESTA,  MIDI_INSTRUMENT_GLOCK,    MIDI_INSTRUMENT_MUSICBOX, MIDI_INSTRUMENT_VIBES
              	.dword MIDI_INSTRUMENT_MARIMBA,  MIDI_INSTRUMENT_XYLO,     MIDI_INSTRUMENT_TUBEBELL, MIDI_INSTRUMENT_SANTUR,   MIDI_INSTRUMENT_ORGAN1,   MIDI_INSTRUMENT_ORGAN2
              	.dword MIDI_INSTRUMENT_ORGAN3,   MIDI_INSTRUMENT_PIPEORG,  MIDI_INSTRUMENT_REEDORG,  MIDI_INSTRUMENT_ACORDIAN, MIDI_INSTRUMENT_HARMONIC, MIDI_INSTRUMENT_BANDNEON
              	.dword MIDI_INSTRUMENT_NYLONGT,  MIDI_INSTRUMENT_STEELGT,  MIDI_INSTRUMENT_JAZZGT,   MIDI_INSTRUMENT_CLEANGT,  MIDI_INSTRUMENT_MUTEGT,   MIDI_INSTRUMENT_OVERDGT
              	.dword MIDI_INSTRUMENT_DISTGT,   MIDI_INSTRUMENT_GTHARMS,  MIDI_INSTRUMENT_ACOUBASS, MIDI_INSTRUMENT_FINGBASS, MIDI_INSTRUMENT_PICKBASS, MIDI_INSTRUMENT_FRETLESS
              	.dword MIDI_INSTRUMENT_SLAPBAS1, MIDI_INSTRUMENT_SLAPBAS2, MIDI_INSTRUMENT_SYNBASS1, MIDI_INSTRUMENT_SYNBASS2, MIDI_INSTRUMENT_VIOLIN,   MIDI_INSTRUMENT_VIOLA
              	.dword MIDI_INSTRUMENT_CELLO,    MIDI_INSTRUMENT_CONTRAB,  MIDI_INSTRUMENT_TREMSTR,  MIDI_INSTRUMENT_PIZZ,     MIDI_INSTRUMENT_HARP,     MIDI_INSTRUMENT_TIMPANI
              	.dword MIDI_INSTRUMENT_STRINGS,  MIDI_INSTRUMENT_SLOWSTR,  MIDI_INSTRUMENT_SYNSTR1,  MIDI_INSTRUMENT_SYNSTR2,  MIDI_INSTRUMENT_CHOIR,    MIDI_INSTRUMENT_OOHS
              	.dword MIDI_INSTRUMENT_SYNVOX,   MIDI_INSTRUMENT_ORCHIT,   MIDI_INSTRUMENT_TRUMPET,  MIDI_INSTRUMENT_TROMBONE, MIDI_INSTRUMENT_TUBA,     MIDI_INSTRUMENT_MUTETRP
              	.dword MIDI_INSTRUMENT_FRHORN,   MIDI_INSTRUMENT_BRASS1,   MIDI_INSTRUMENT_SYNBRAS1, MIDI_INSTRUMENT_SYNBRAS2, MIDI_INSTRUMENT_SOPSAX,   MIDI_INSTRUMENT_ALTOSAX
              	.dword MIDI_INSTRUMENT_TENSAX,   MIDI_INSTRUMENT_BARISAX,  MIDI_INSTRUMENT_OBOE,     MIDI_INSTRUMENT_ENGLHORN, MIDI_INSTRUMENT_BASSOON,  MIDI_INSTRUMENT_CLARINET
              	.dword MIDI_INSTRUMENT_PICCOLO,  MIDI_INSTRUMENT_FLUTE1,   MIDI_INSTRUMENT_RECORDER, MIDI_INSTRUMENT_PANFLUTE, MIDI_INSTRUMENT_BOTTLEB,  MIDI_INSTRUMENT_SHAKU
              	.dword MIDI_INSTRUMENT_WHISTLE,  MIDI_INSTRUMENT_OCARINA,  MIDI_INSTRUMENT_SQUARWAV, MIDI_INSTRUMENT_SAWWAV,   MIDI_INSTRUMENT_SYNCALLI, MIDI_INSTRUMENT_CHIFLEAD
              	.dword MIDI_INSTRUMENT_CHARANG,  MIDI_INSTRUMENT_SOLOVOX,  MIDI_INSTRUMENT_FIFTHSAW, MIDI_INSTRUMENT_BASSLEAD, MIDI_INSTRUMENT_FANTASIA, MIDI_INSTRUMENT_WARMPAD
              	.dword MIDI_INSTRUMENT_POLYSYN,  MIDI_INSTRUMENT_SPACEVOX, MIDI_INSTRUMENT_BOWEDGLS, MIDI_INSTRUMENT_METALPAD, MIDI_INSTRUMENT_HALOPAD,  MIDI_INSTRUMENT_SWEEPPAD
              	.dword MIDI_INSTRUMENT_ICERAIN,  MIDI_INSTRUMENT_SOUNDTRK, MIDI_INSTRUMENT_CRYSTAL,  MIDI_INSTRUMENT_ATMOSPH,  MIDI_INSTRUMENT_BRIGHT,   MIDI_INSTRUMENT_GOBLIN
              	.dword MIDI_INSTRUMENT_ECHODROP, MIDI_INSTRUMENT_STARTHEM, MIDI_INSTRUMENT_SITAR,    MIDI_INSTRUMENT_BANJO,    MIDI_INSTRUMENT_SHAMISEN, MIDI_INSTRUMENT_KOTO
              	.dword MIDI_INSTRUMENT_KALIMBA,  MIDI_INSTRUMENT_BAGPIPE,  MIDI_INSTRUMENT_FIDDLE,   MIDI_INSTRUMENT_SHANNAI,  MIDI_INSTRUMENT_TINKLBEL, MIDI_INSTRUMENT_AGOGO
              	.dword MIDI_INSTRUMENT_STEELDRM, MIDI_INSTRUMENT_WOODBLOK, MIDI_INSTRUMENT_TAIKO,    MIDI_INSTRUMENT_MELOTOM,  MIDI_INSTRUMENT_SYNDRUM,  MIDI_INSTRUMENT_REVRSCYM
              	.dword MIDI_INSTRUMENT_FRETNOIS, MIDI_INSTRUMENT_BRTHNOIS, MIDI_INSTRUMENT_SEASHORE, MIDI_INSTRUMENT_BIRDS,    MIDI_INSTRUMENT_TELEPHON, MIDI_INSTRUMENT_HELICOPT
              	.dword MIDI_INSTRUMENT_APPLAUSE, MIDI_INSTRUMENT_GUNSHOT
