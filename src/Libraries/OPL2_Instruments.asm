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

                      ;     DR   $20  $40  $60  $80  $C0  $E0  $20  $40  $60  $80  $E0
INSTRUMENT_ACCORDN    .text $00, $24, $4F, $F2, $0B, $00, $0E, $31, $00, $52, $0B, $00, 'ACCORDN   '
INSTRUMENT_BAGPIPE1   .text $00, $31, $43, $6E, $17, $01, $02, $22, $05, $8B, $0C, $02, 'BAGPIPE1  '
INSTRUMENT_BAGPIPE2   .text $00, $30, $00, $FF, $A0, $03, $00, $A3, $00, $65, $0B, $02, 'BAGPIPE2  '
INSTRUMENT_BANJO1     .text $00, $31, $87, $A1, $11, $00, $08, $16, $80, $7D, $43, $00, 'BANJO1    '
INSTRUMENT_BASS1      .text $00, $01, $15, $25, $2F, $00, $0A, $21, $80, $65, $6C, $00, 'BASS1     '
INSTRUMENT_BASS2      .text $00, $01, $1D, $F2, $EF, $00, $0A, $01, $00, $F5, $78, $00, 'BASS2     '
INSTRUMENT_BASSHARP   .text $00, $C0, $6D, $F9, $01, $01, $0E, $41, $00, $F2, $73, $00, 'BASSHARP  '
INSTRUMENT_BASSOON1   .text $00, $30, $C8, $D5, $19, $00, $0C, $71, $80, $61, $1B, $00, 'BASSOON1  '
INSTRUMENT_BASSTRLG   .text $00, $C1, $4F, $B1, $53, $03, $06, $E0, $00, $12, $74, $03, 'BASSTRLG  '
INSTRUMENT_BDRUM1     .text $06, $00, $0B, $A8, $4C, $00, $00, $00, $00, $00, $00, $00, 'BDRUM1    '
INSTRUMENT_BELLONG    .text $00, $64, $DB, $FF, $01, $00, $04, $3E, $C0, $F3, $62, $00, 'BELLONG   '
INSTRUMENT_BELLS      .text $00, $07, $4F, $F2, $60, $00, $08, $12, $00, $F2, $72, $00, 'BELLS     '
INSTRUMENT_BELSHORT   .text $00, $64, $DB, $FF, $01, $00, $04, $3E, $C0, $F5, $F3, $00, 'BELSHORT  '
INSTRUMENT_BNCEBASS   .text $00, $20, $4B, $7B, $04, $01, $0E, $21, $00, $F5, $72, $00, 'BNCEBASS  '
INSTRUMENT_BRASS1     .text $00, $21, $16, $71, $AE, $00, $0E, $21, $00, $81, $9E, $00, 'BRASS1    '
INSTRUMENT_CBASSOON   .text $00, $30, $C5, $52, $11, $00, $00, $31, $80, $31, $2E, $00, 'CBASSOON  '
INSTRUMENT_CELESTA    .text $00, $33, $87, $01, $10, $00, $08, $14, $80, $7D, $33, $00, 'CELESTA   '
INSTRUMENT_CLAR1      .text $00, $32, $16, $73, $24, $00, $0E, $21, $80, $75, $57, $00, 'CLAR1     '
INSTRUMENT_CLAR2      .text $00, $31, $1C, $41, $1B, $00, $0C, $60, $80, $42, $3B, $00, 'CLAR2     '
INSTRUMENT_CLARINET   .text $00, $32, $9A, $51, $1B, $00, $0C, $61, $82, $A2, $3B, $00, 'CLARINET  '
INSTRUMENT_CLAVECIN   .text $00, $11, $0D, $F2, $01, $00, $0A, $15, $0D, $F2, $B1, $00, 'CLAVECIN  '
INSTRUMENT_CROMORNE   .text $00, $00, $02, $F0, $FF, $00, $06, $11, $80, $F0, $FF, $00, 'CROMORNE  '
INSTRUMENT_CYMBAL1    .text $09, $01, $00, $F5, $B5, $00, $00, $00, $00, $00, $00, $00, 'CYMBAL1   '
INSTRUMENT_ELCLAV1    .text $00, $05, $8A, $F0, $7B, $00, $08, $01, $80, $F4, $7B, $00, 'ELCLAV1   '
INSTRUMENT_ELCLAV2    .text $00, $01, $49, $F1, $53, $01, $06, $11, $00, $F1, $74, $02, 'ELCLAV2   '
INSTRUMENT_ELECFL     .text $00, $E0, $6D, $57, $04, $01, $0E, $61, $00, $67, $7D, $00, 'ELECFL    '
INSTRUMENT_ELECVIBE   .text $00, $13, $97, $9A, $12, $02, $0E, $91, $80, $9B, $11, $00, 'ELECVIBE  '
INSTRUMENT_ELGUIT1    .text $00, $F1, $01, $97, $17, $00, $08, $21, $0D, $F1, $18, $00, 'ELGUIT1   '
INSTRUMENT_ELGUIT2    .text $00, $13, $96, $FF, $21, $00, $0A, $11, $80, $FF, $03, $00, 'ELGUIT2   '
INSTRUMENT_ELGUIT3    .text $00, $07, $8F, $82, $7D, $00, $0C, $14, $80, $82, $7D, $00, 'ELGUIT3   '
INSTRUMENT_ELGUIT4    .text $00, $05, $8F, $DA, $15, $00, $0A, $01, $80, $F9, $14, $02, 'ELGUIT4   '
INSTRUMENT_ELORGAN1   .text $00, $B2, $CD, $91, $2A, $02, $09, $B1, $80, $91, $2A, $01, 'ELORGAN1  '
INSTRUMENT_ELPIANO1   .text $00, $01, $4F, $F1, $50, $00, $06, $01, $04, $D2, $7C, $00, 'ELPIANO1  '
INSTRUMENT_ELPIANO2   .text $00, $02, $22, $F2, $13, $00, $0E, $02, $00, $F5, $43, $00, 'ELPIANO2  '
INSTRUMENT_EPIANO1A   .text $00, $81, $63, $F3, $58, $00, $00, $01, $80, $F2, $58, $00, 'EPIANO1A  '
INSTRUMENT_EPIANO1B   .text $00, $07, $1F, $F5, $FA, $00, $0E, $01, $57, $F5, $FA, $00, 'EPIANO1B  '
INSTRUMENT_FLUTE      .text $00, $21, $83, $74, $17, $00, $07, $A2, $8D, $65, $17, $00, 'FLUTE     '
INSTRUMENT_FLUTE1     .text $00, $A1, $27, $74, $8F, $00, $02, $A1, $80, $65, $2A, $00, 'FLUTE1    '
INSTRUMENT_FLUTE2     .text $00, $E0, $EC, $6E, $8F, $00, $0E, $61, $00, $65, $2A, $00, 'FLUTE2    '
INSTRUMENT_FRHORN1    .text $00, $21, $9F, $53, $5A, $00, $0C, $21, $80, $AA, $1A, $00, 'FRHORN1   '
INSTRUMENT_FRHORN2    .text $00, $20, $8E, $A5, $8F, $02, $06, $21, $00, $36, $3D, $00, 'FRHORN2   '
INSTRUMENT_FSTRP1     .text $00, $F0, $18, $55, $EF, $02, $00, $E0, $80, $87, $1E, $03, 'FSTRP1    '
INSTRUMENT_FSTRP2     .text $00, $70, $16, $55, $2F, $02, $0C, $E0, $80, $87, $1E, $03, 'FSTRP2    '
INSTRUMENT_FUZGUIT1   .text $00, $F1, $00, $97, $13, $00, $0A, $25, $0D, $F1, $18, $01, 'FUZGUIT1  '
INSTRUMENT_FUZGUIT2   .text $00, $31, $48, $F1, $53, $00, $06, $32, $00, $F2, $27, $02, 'FUZGUIT2  '
INSTRUMENT_GUITAR1    .text $00, $01, $11, $F2, $1F, $00, $0A, $01, $00, $F5, $88, $00, 'GUITAR1   '
INSTRUMENT_HARP1      .text $00, $02, $29, $F5, $75, $00, $00, $01, $83, $F2, $F3, $00, 'HARP1     '
INSTRUMENT_HARP2      .text $00, $02, $99, $F5, $55, $00, $00, $01, $80, $F6, $53, $00, 'HARP2     '
INSTRUMENT_HARP3      .text $00, $02, $57, $F5, $56, $00, $00, $01, $80, $F6, $54, $00, 'HARP3     '
INSTRUMENT_HARPE1     .text $00, $02, $29, $F5, $75, $00, $00, $01, $03, $F2, $F3, $00, 'HARPE1    '
INSTRUMENT_HARPSI1    .text $00, $32, $87, $A1, $10, $00, $08, $16, $80, $7D, $33, $00, 'HARPSI1   '
INSTRUMENT_HARPSI2    .text $00, $33, $87, $A1, $10, $00, $06, $15, $80, $7D, $43, $00, 'HARPSI2   '
INSTRUMENT_HARPSI3    .text $00, $35, $84, $A8, $10, $00, $08, $18, $80, $7D, $33, $00, 'HARPSI3   '
INSTRUMENT_HARPSI4    .text $00, $11, $0D, $F2, $01, $00, $0A, $15, $0D, $F2, $B1, $00, 'HARPSI4   '
INSTRUMENT_HARPSI5    .text $00, $36, $87, $8A, $00, $00, $08, $1A, $80, $7F, $33, $00, 'HARPSI5   '
INSTRUMENT_HELICPTR   .text $00, $F0, $00, $1E, $11, $01, $08, $E2, $C0, $11, $11, $01, 'HELICPTR  '
INSTRUMENT_HIHAT1     .text $0A, $01, $00, $F7, $B5, $00, $00, $00, $00, $00, $00, $00, 'HIHAT1    '
INSTRUMENT_HIHAT2     .text $0A, $01, $03, $DA, $18, $00, $00, $00, $00, $00, $00, $00, 'HIHAT2    '
INSTRUMENT_JAVAICAN   .text $00, $87, $4D, $78, $42, $00, $0A, $94, $00, $85, $54, $00, 'JAVAICAN  '
INSTRUMENT_JAZZGUIT   .text $00, $03, $5E, $85, $51, $01, $0E, $11, $00, $D2, $71, $00, 'JAZZGUIT  '
INSTRUMENT_JEWSHARP   .text $00, $00, $50, $F2, $70, $00, $0E, $13, $00, $F2, $72, $00, 'JEWSHARP  '
INSTRUMENT_KEYBRD1    .text $00, $00, $02, $F0, $FA, $01, $06, $11, $80, $F2, $FA, $01, 'KEYBRD1   '
INSTRUMENT_KEYBRD2    .text $00, $01, $8F, $F2, $BD, $00, $08, $14, $80, $82, $BD, $00, 'KEYBRD2   '
INSTRUMENT_KEYBRD3    .text $00, $01, $00, $F0, $F0, $00, $00, $E4, $03, $F3, $36, $00, 'KEYBRD3   '
INSTRUMENT_LASER      .text $09, $E6, $00, $25, $B5, $00, $00, $00, $00, $00, $00, $00, 'LASER     '
INSTRUMENT_LOGDRUM1   .text $00, $32, $44, $F8, $FF, $00, $0E, $11, $00, $F5, $7F, $00, 'LOGDRUM1  '
INSTRUMENT_MARIMBA1   .text $00, $05, $4E, $DA, $25, $00, $0A, $01, $00, $F9, $15, $00, 'MARIMBA1  '
INSTRUMENT_MARIMBA2   .text $00, $85, $4E, $DA, $15, $00, $0A, $81, $80, $F9, $13, $00, 'MARIMBA2  '
INSTRUMENT_MDRNPHON   .text $00, $30, $00, $FE, $11, $01, $08, $AE, $C0, $F1, $19, $01, 'MDRNPHON  '
INSTRUMENT_MLTRDRUM   .text $07, $0C, $00, $C8, $B6, $01, $00, $00, $00, $00, $00, $00, 'MLTRDRUM  '
INSTRUMENT_MOOGSYNT   .text $00, $20, $90, $F5, $9E, $02, $0C, $11, $00, $F4, $5B, $03, 'MOOGSYNT  '
INSTRUMENT_NOISE1     .text $00, $0E, $40, $D1, $53, $00, $0E, $0E, $00, $F2, $7F, $03, 'NOISE1    '
INSTRUMENT_OBOE1      .text $00, $B1, $C5, $6E, $17, $00, $02, $22, $05, $8B, $0E, $00, 'OBOE1     '
INSTRUMENT_ORGAN1     .text $00, $65, $D2, $81, $03, $00, $02, $71, $80, $F1, $05, $00, 'ORGAN1    '
INSTRUMENT_ORGAN2     .text $00, $24, $80, $FF, $0F, $00, $01, $21, $80, $FF, $0F, $00, 'ORGAN2    '
INSTRUMENT_ORGAN3     .text $00, $03, $5B, $F0, $1F, $00, $0A, $01, $80, $F0, $1F, $00, 'ORGAN3    '
INSTRUMENT_ORGAN3A    .text $00, $03, $5B, $F0, $1F, $00, $0A, $01, $8D, $F0, $13, $00, 'ORGAN3A   '
INSTRUMENT_ORGAN3B    .text $00, $03, $5B, $F0, $1F, $00, $0A, $01, $92, $F0, $12, $00, 'ORGAN3B   '
INSTRUMENT_ORGNPERC   .text $00, $0C, $00, $F8, $B5, $00, $01, $00, $00, $D6, $4F, $00, 'ORGNPERC  '
INSTRUMENT_PHONE1     .text $00, $17, $4F, $F2, $61, $00, $08, $12, $08, $F1, $B2, $00, 'PHONE1    '
INSTRUMENT_PHONE2     .text $00, $17, $4F, $F2, $61, $00, $08, $12, $0A, $F1, $B4, $00, 'PHONE2    '
INSTRUMENT_PIAN1A     .text $00, $81, $63, $F3, $58, $00, $00, $01, $80, $F2, $58, $00, 'PIAN1A    '
INSTRUMENT_PIAN1B     .text $00, $07, $1F, $F5, $FA, $00, $0E, $01, $26, $F5, $FA, $00, 'PIAN1B    '
INSTRUMENT_PIAN1C     .text $00, $07, $1F, $F5, $FA, $00, $0E, $01, $57, $F5, $FA, $00, 'PIAN1C    '
INSTRUMENT_PIANO      .text $00, $03, $4F, $F1, $53, $00, $06, $17, $00, $F2, $74, $00, 'PIANO     '
INSTRUMENT_PIANO1     .text $00, $01, $4F, $F1, $53, $00, $06, $11, $00, $D2, $74, $00, 'PIANO1    '
INSTRUMENT_PIANO2     .text $00, $41, $9D, $F2, $51, $00, $06, $13, $00, $F2, $F1, $00, 'PIANO2    '
INSTRUMENT_PIANO3     .text $00, $01, $4F, $F1, $50, $00, $06, $01, $04, $D2, $7C, $00, 'PIANO3    '
INSTRUMENT_PIANO4     .text $00, $01, $4D, $F1, $60, $00, $08, $11, $00, $D2, $7B, $00, 'PIANO4    '
INSTRUMENT_PIANOBEL   .text $00, $03, $4F, $F1, $53, $00, $06, $17, $03, $F2, $74, $00, 'PIANOBEL  '
INSTRUMENT_PIANOF     .text $00, $01, $CF, $F1, $53, $00, $02, $12, $00, $F2, $83, $00, 'PIANOF    '
INSTRUMENT_POPBASS1   .text $00, $10, $00, $75, $93, $01, $00, $01, $00, $F5, $82, $01, 'POPBASS1  '
INSTRUMENT_RKSNARE1   .text $07, $0C, $00, $C7, $B4, $00, $00, $00, $00, $00, $00, $00, 'RKSNARE1  '
INSTRUMENT_SAX1       .text $00, $01, $4F, $71, $53, $00, $0A, $12, $00, $52, $7C, $00, 'SAX1      '
INSTRUMENT_SCRATCH    .text $00, $07, $00, $F0, $F0, $00, $0E, $00, $00, $5C, $DC, $00, 'SCRATCH   '
INSTRUMENT_SCRATCH4   .text $00, $07, $00, $F0, $F0, $00, $0E, $00, $00, $5C, $DC, $00, 'SCRATCH4  '
INSTRUMENT_SDRUM2     .text $00, $06, $00, $F0, $F0, $00, $0E, $00, $00, $F6, $B4, $00, 'SDRUM2    '
INSTRUMENT_SHRTVIBE   .text $00, $E4, $0E, $FF, $3F, $01, $00, $C0, $00, $F3, $07, $00, 'SHRTVIBE  '
INSTRUMENT_SITAR1     .text $00, $01, $40, $F1, $53, $00, $00, $08, $40, $F1, $53, $00, 'SITAR1    '
INSTRUMENT_SITAR2     .text $00, $01, $40, $F1, $53, $00, $00, $08, $40, $F1, $53, $01, 'SITAR2    '
INSTRUMENT_SNAKEFL    .text $00, $61, $0C, $81, $03, $00, $08, $71, $80, $61, $0C, $00, 'SNAKEFL   '
INSTRUMENT_SNARE1     .text $07, $0C, $00, $F8, $B5, $00, $00, $00, $00, $00, $00, $00, 'SNARE1    '
INSTRUMENT_SNRSUST    .text $00, $06, $00, $F0, $F0, $00, $0E, $C4, $03, $C4, $34, $00, 'SNRSUST   '
INSTRUMENT_SOLOVLN    .text $00, $70, $1C, $51, $03, $02, $0E, $20, $00, $54, $67, $02, 'SOLOVLN   '
INSTRUMENT_STEELGT1   .text $00, $01, $46, $F1, $83, $00, $06, $61, $03, $31, $86, $00, 'STEELGT1  '
INSTRUMENT_STEELGT2   .text $00, $01, $47, $F1, $83, $00, $06, $61, $03, $91, $86, $00, 'STEELGT2  '
INSTRUMENT_STRINGS1   .text $00, $B1, $8B, $71, $11, $00, $06, $61, $40, $42, $15, $01, 'STRINGS1  '
INSTRUMENT_STRNLONG   .text $00, $E1, $4F, $B1, $D3, $03, $06, $21, $00, $12, $74, $01, 'STRNLONG  '
INSTRUMENT_SYN1       .text $00, $55, $97, $2A, $02, $00, $00, $12, $80, $42, $F3, $00, 'SYN1      '
INSTRUMENT_SYN2       .text $00, $13, $97, $9A, $12, $00, $0E, $11, $80, $9B, $14, $00, 'SYN2      '
INSTRUMENT_SYN3       .text $00, $11, $8A, $F1, $11, $00, $06, $01, $40, $F1, $B3, $00, 'SYN3      '
INSTRUMENT_SYN4       .text $00, $21, $0D, $E9, $3A, $00, $0A, $22, $80, $65, $6C, $00, 'SYN4      '
INSTRUMENT_SYN5       .text $00, $01, $4F, $71, $53, $00, $06, $19, $00, $52, $7C, $00, 'SYN5      '
INSTRUMENT_SYN6       .text $00, $24, $0F, $41, $7E, $00, $0A, $21, $00, $F1, $5E, $00, 'SYN6      '
INSTRUMENT_SYN9       .text $00, $07, $87, $F0, $05, $00, $04, $01, $80, $F0, $05, $00, 'SYN9      '
INSTRUMENT_SYNBAL1    .text $00, $26, $03, $E0, $F0, $00, $08, $1E, $00, $FF, $31, $00, 'SYNBAL1   '
INSTRUMENT_SYNBAL2    .text $00, $28, $03, $E0, $F0, $00, $04, $13, $00, $E8, $11, $00, 'SYNBAL2   '
INSTRUMENT_SYNBASS1   .text $00, $30, $88, $D5, $19, $00, $0C, $71, $80, $61, $1B, $00, 'SYNBASS1  '
INSTRUMENT_SYNBASS2   .text $00, $81, $86, $65, $01, $00, $0C, $11, $00, $32, $74, $00, 'SYNBASS2  '
INSTRUMENT_SYNBASS4   .text $00, $81, $83, $65, $05, $00, $0A, $51, $00, $32, $74, $00, 'SYNBASS4  '
INSTRUMENT_SYNSNR1    .text $00, $06, $00, $F0, $F0, $00, $0E, $00, $00, $F8, $B6, $00, 'SYNSNR1   '
INSTRUMENT_SYNSNR2    .text $00, $06, $00, $F0, $F0, $00, $0E, $00, $00, $F6, $B4, $00, 'SYNSNR2   '
INSTRUMENT_TINCAN1    .text $00, $8F, $81, $EF, $01, $00, $04, $01, $00, $98, $F1, $00, 'TINCAN1   '
INSTRUMENT_TOM1       .text $08, $04, $00, $F7, $B5, $00, $00, $00, $00, $00, $00, $00, 'TOM1      '
INSTRUMENT_TOM2       .text $08, $02, $00, $C8, $97, $00, $00, $00, $00, $00, $00, $00, 'TOM2      '
INSTRUMENT_TRAINBEL   .text $00, $17, $4F, $F2, $61, $00, $08, $12, $08, $F2, $74, $00, 'TRAINBEL  '
INSTRUMENT_TRIANGLE   .text $00, $26, $03, $E0, $F0, $00, $08, $1E, $00, $FF, $31, $00, 'TRIANGLE  '
INSTRUMENT_TROMB1     .text $00, $B1, $1C, $41, $1F, $00, $0E, $61, $80, $92, $3B, $00, 'TROMB1    '
INSTRUMENT_TROMB2     .text $00, $21, $1C, $53, $1D, $00, $0C, $61, $80, $52, $3B, $00, 'TROMB2    '
INSTRUMENT_TRUMPET1   .text $00, $31, $1C, $41, $0B, $00, $0E, $61, $80, $92, $3B, $00, 'TRUMPET1  '
INSTRUMENT_TRUMPET2   .text $00, $31, $1C, $23, $1D, $00, $0C, $61, $80, $52, $3B, $00, 'TRUMPET2  '
INSTRUMENT_TRUMPET3   .text $00, $31, $1C, $41, $01, $00, $0E, $61, $80, $92, $3B, $00, 'TRUMPET3  '
INSTRUMENT_TRUMPET4   .text $00, $31, $1C, $41, $0B, $00, $0C, $61, $80, $92, $3B, $00, 'TRUMPET4  '
INSTRUMENT_TUBA1      .text $00, $21, $19, $43, $8C, $00, $0C, $21, $80, $85, $2F, $00, 'TUBA1     '
INSTRUMENT_VIBRA1     .text $00, $84, $53, $F5, $33, $00, $06, $A0, $80, $FD, $25, $00, 'VIBRA1    '
INSTRUMENT_VIBRA2     .text $00, $06, $73, $F6, $54, $00, $00, $81, $03, $F2, $B3, $00, 'VIBRA2    '
INSTRUMENT_VIBRA3     .text $00, $93, $97, $AA, $12, $02, $0E, $91, $80, $AC, $21, $00, 'VIBRA3    '
INSTRUMENT_VIOLIN1    .text $00, $31, $1C, $51, $03, $00, $0E, $61, $80, $54, $67, $00, 'VIOLIN1   '
INSTRUMENT_VIOLIN2    .text $00, $E1, $88, $62, $29, $00, $0C, $22, $80, $53, $2C, $00, 'VIOLIN2   '
INSTRUMENT_VIOLIN3    .text $00, $E1, $88, $64, $29, $00, $06, $22, $83, $53, $2C, $00, 'VIOLIN3   '
INSTRUMENT_VLNPIZZ1   .text $00, $31, $9C, $F1, $F9, $00, $0E, $31, $80, $F7, $E6, $00, 'VLNPIZZ1  '
INSTRUMENT_WAVE       .text $00, $00, $02, $00, $F0, $00, $0E, $14, $80, $1B, $A2, $00, 'WAVE      '
INSTRUMENT_XYLO1      .text $00, $11, $2D, $C8, $2F, $00, $0C, $31, $00, $F5, $F5, $00, 'XYLO1     '
INSTRUMENT_XYLO2      .text $06, $2E, $00, $FF, $0F, $00, $00, $00, $00, $00, $00, $00, 'XYLO2     '
INSTRUMENT_XYLO3      .text $00, $06, $00, $FF, $F0, $00, $0E, $C4, $00, $F8, $B5, $00, 'XYLO3     '
