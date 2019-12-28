

EFFECT_NONE              = $00
EFFECT_NOTE_SLIDE_UP     = $01
EFFECT_NOTE_SLIDE_DOWN   = $02
EFFECT_NOTE_SLIDE_TO     = $03
EFFECT_NOTE_SLIDE_VOLUME = $05
EFFECT_VOLUME_SLIDE      = $0A
EFFECT_SET_VOLUME        = $0C
EFFECT_PATTERN_BREAK     = $0D
EFFECT_SET_SPEED         = $0F

FNUMBER_MIN = $0156
FNUMBER_MAX = $02AE

SongData .struct
patternOffsets      .word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
                    .word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
                    .word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
                    .word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
orderListOffset     .word $00000000
instruments         .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
songLength          .byte $00
InitialSpeed        .byte $06
hasSlowTimer        .byte $00 ;BOOL $00 = False, $01 = True
.ends

PlayerVariables .struct
loopSong            .byte $01 ; Bool
orders              .byte $00
line                .byte $00
tick                .byte $00
speed               .byte $06
endOfPattern        .byte $00 ; Bool
channelNote         .word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
pitchSlideDest      .word $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
efftectParameter    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
pitchSlideSpeed     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00
patternBreak        .byte $FF
.ends



; We are assuming that the RAD File is already Loaded Somewhere

OPL2_INIT_PLAYER
              JSL PARSER_RAD_FILE_INSTRUMENT; Go Parse the Instrument and Order lOst
              JSL OPL2_INIT   ; Init OPL2
              SEC ; Set the WaveFormSelect to True
              JSL OPL2_SET_WAVEFORMSELECT; Set WaveFormSelect True
              ;
              CLC
              JSL OPL2_SET_PERCUSSION ; Set Percussion False
              setas
              LDA @lTuneInfo.InitialSpeed
              STA @lPlayerInfo.speed
              LDA #$FF
              STA  @lPlayerInfo.orders
              LDA #$00
              STA  @lPlayerInfo.line
              STA  @lPlayerInfo.tick
              JSL RADPLAYER_NEXTORDER   ;
              JSL RADPLAYER_READLINE ;
              BRK
              RTL

PARSER_RAD_FILE_INSTRUMENT
              setaxl
              LDY #$0000          ; Pointer in the File
              LDA #<>RAD_FILE_TEMP ; Set the Pointer where the File Begins
              STA OPL2_ADDY_PTR_LO;
              LDA #<`RAD_FILE_TEMP
              STA OPL2_ADDY_PTR_HI;
              setas
              LDY #$0011  ;Jump to Pointer 11 in the File
              LDA [OPL2_ADDY_PTR_LO],Y
              ;Will Ignore the has slowSlowTimer for now
              AND #$1F
              STA @lTuneInfo.InitialSpeed
              LDA [OPL2_ADDY_PTR_LO],Y
              AND #$80
              CMP #$80  ; Check if there is Text following
              BNE No_File_Description
Not_Done_With_Description
              INY ; Move the Pointer Forward
              LDA [OPL2_ADDY_PTR_LO],Y
              CMP #$00  ; Check for the End of Text
              BNE Not_Done_With_Description
No_File_Description
              INY ; This points after either After Description or next to Offset 0x11
              ; Let's Init the Address Point for the instrument Tables
              setal
              LDA #<`TuneInfo.instruments
              STA OPL2_IND_ADDY_HL
              ; Let's Read Some Instruments HERE
ProcessNextInstruments
              setal
              LDA #$0000 ; THis is to make sure that B is 0
              setas
              LDA [OPL2_ADDY_PTR_LO],Y  ; Read Instrument Number
              CMP #$00  ; Check if there is no more instruments
              BEQ DoneProcessingInstrument;
              setal
              DEC A
              ASL A
              ASL A
              ASL A
              ASL A
              CLC
              ADC #<>TuneInfo.instruments
              STA OPL2_IND_ADDY_LL
              setas
              INY
              LDX #$0000
Transfer_Instrument_Info
              LDA [OPL2_ADDY_PTR_LO],Y  ; Read Instrument Number
              STA [OPL2_IND_ADDY_LL]; 2 Different Indexed Pointer
              setal
              INC OPL2_IND_ADDY_LL
              setas
              INY
              INX
              CPX #$09
              BCC Transfer_Instrument_Info
              LDA [OPL2_ADDY_PTR_LO],Y  ; Save the First 8 Bytes in the Data Base
              AND #$07
              STA OPL2_PARAMETER0
              INY
              LDA [OPL2_ADDY_PTR_LO],Y
              INY
              AND #$07
              ASL A
              ASL A
              ASL A
              ASL A
              ORA OPL2_PARAMETER0
              STA [OPL2_IND_ADDY_LL]  ; 2 Different Indexed Pointer
              BRA ProcessNextInstruments;
DoneProcessingInstrument
              INY
              LDA [OPL2_ADDY_PTR_LO],Y  ; Read Instrument Number
              STA @lTuneInfo.songLength
              INY
              CLC
              setal
              TYA ; Store the Pointer of the Offset List
              ADC OPL2_ADDY_PTR_LO
              STA @lTuneInfo.orderListOffset
              LDA OPL2_ADDY_PTR_HI
              STA @lTuneInfo.orderListOffset+2
              CLC ; This will jump over the the OrderList
              LDA @lTuneInfo.orderListOffset
              setas
              ADC @lTuneInfo.songLength
              setal
              STA OPL2_ADDY_PTR_LO
              setas
              ; They are already in Big Endian, so no conversion necessary
              LDY #$0000 ; Now the Point Y has been embedded in the OPL2_ADDY_PTR_LO, let's clear it
              LDX #$0000
TransferPaternOffset ; This is the Table of Pointer for the different Pattern
              LDA [OPL2_ADDY_PTR_LO],Y
              STA @lTuneInfo.patternOffsets,X
              INX
              INY
              CPY #$20
              BCC TransferPaternOffset
              RTL

; Output
; Y = Is the Pointer in the File to the next Patternlist.
; This is a 16Bits Offset, it needs to be added to absolute Starting address of the File
;
RADPLAYER_NEXTORDER
              setas
              LDY #$0000
              LDA #$00
              STA RAD_STARTLINE
              ;  order ++;
              LDA @lPlayerInfo.orders
              INC A
              STA @lPlayerInfo.orders
              TAY
              ;  if (order >= songLength && loopSong) {order = 0;}
              CMP @lTuneInfo.songLength
              BCS NotClearingOrder
              LDA @lPlayerInfo.loopSong
              AND #$01
              CMP #$01
              BNE NotClearingOrder
              LDA #$00
              STA @lPlayerInfo.orders

NotClearingOrder
              setal
              ;  radFile.seekSet(orderListOffset + order);
              LDA @lTuneInfo.orderListOffset
              STA OPL2_ADDY_PTR_LO
              LDA @lTuneInfo.orderListOffset+2
              STA OPL2_ADDY_PTR_HI
              setax
              LDA [OPL2_ADDY_PTR_LO],Y ; (Y = orders)
              STA RAD_PATTERN_IDX     ;byte patternIndex = radFile.read();
              AND #$80
              CMP #$80
              BNE NoOrderJump
              ; Read the PatternIndex Again
              LDA [OPL2_ADDY_PTR_LO],Y ; (Y = orders)
              AND #$7F
              STA @lPlayerInfo.orders
              TAY ; Repoint to a new Order
              LDA [OPL2_ADDY_PTR_LO],Y ; (Y = orders)
              STA RAD_PATTERN_IDX     ;byte patternIndex = radFile.read();
NoOrderJump   setal
              AND #$00FF
              TAX
              LDA @lTuneInfo.patternOffsets,X
              TAY ; Keep the Pointer in Y,
              setas
              LDA #$00
              STA @lPlayerInfo.endOfPattern ; Set to False
              STA RAD_LINE
              ;  for (line = 0; line < startLine; line ++) {readLine();}
ReadMoreLine
              LDA RAD_STARTLINE
              CMP RAD_LINE
              BCS NoMoreLine2Read;
              JSL RADPLAYER_READLINE
              INC RAD_LINE
              BRA ReadMoreLine;
NoMoreLine2Read
              STY RAD_Y_POINTER
              RTL


;
RADPLAYER_READLINE
              setas
              LDY RAD_Y_POINTER
              ;  // Reset note data on each channel.
              LDA #$00
              LDX #$0000
ClearChannelNote
              STA @lPlayerInfo.channelNote,X
              INX
              CPX #18
              BCC ClearChannelNote
              ;// If the previous line was the last line of the pattern then we're done.
              LDA @lPlayerInfo.endOfPattern ; if <> 0 (or True) Exit
              CMP #$00
              BNE ReadLineEndOfPattern
              setal
              LDA #<>RAD_FILE_TEMP ; Set the Pointer where the File Begins
              STA OPL2_ADDY_PTR_LO;
              LDA #<`RAD_FILE_TEMP
              STA OPL2_ADDY_PTR_HI;
              setas
              LDA [OPL2_ADDY_PTR_LO],Y
              STA RAD_LINENUMBER
              AND #$3F
              CMP RAD_LINE
              BEQ MoveOnWithReadLine
              DEY
              STY RAD_Y_POINTER
              RTL
MoveOnWithReadLine
              LDA RAD_LINENUMBER
              AND #$80
              STA @lPlayerInfo.endOfPattern
              LDX #$0000
NextChannelProcess
              ;// Read note and effect data for each channel.
              INY
              LDA [OPL2_ADDY_PTR_LO],Y ;byte channelNumber = radFile.read();
              STA RAD_CHANNEL_NUM
              AND #$80            ;   isLastChannel = channelNumber & 0x80;
              STA RAD_ISLASTCHAN
              LDA RAD_CHANNEL_NUM
              AND #$0F            ; channelNumber = channelNumber & 0x0F;
              STA RAD_CHANNEL_NUM
              ASL ;
              TAX
              INY
              LDA [OPL2_ADDY_PTR_LO],Y ;byte channelNumber = radFile.read();
              STA @lPlayerInfo.channelNote+1, X
              INY
              LDA [OPL2_ADDY_PTR_LO],Y ;byte channelNumber = radFile.read();
              STA @lPlayerInfo.channelNote, X
              setal
              LDA @lPlayerInfo.channelNote, X
              AND #$000F
              CMP #$0000
              BEQ NoEffectParameter
              setas
              LDA RAD_CHANNEL_NUM
              TAX
              INY
              LDA [OPL2_ADDY_PTR_LO],Y ;byte channelNumber = radFile.read();
              STA @lPlayerInfo.efftectParameter,X
              BRA MoveOnToNextChannel
NoEffectParameter
              setas
              LDA RAD_CHANNEL_NUM
              TAX
              LDA #$00
              STA @lPlayerInfo.efftectParameter,X
MoveOnToNextChannel
              LDA RAD_ISLASTCHAN
              CMP #$00
              BEQ NextChannelProcess
ReadLineEndOfPattern
              STY RAD_Y_POINTER
              RTL

; This part will be called by the Interrupt Handler
PLAYMUSIC
              setas
              LDA #$00
              STA RAD_CHANNEL_NUM

              setal
              LDA RAD_CHANNEL_NUM
              AND #$00FF
              TAX
              LDA @lPlayerInfo.channelNote, X
              STA RAD_CHANNEL_DATA
              setas
              AND #$0F
              STA RAD_CHANNE_EFFCT

              LDA RAD_TICK
              CMP #$00
              BEQ InstrumentSetup
              BRL NoInstrumentSetup
InstrumentSetup
              CLC
              LDA RAD_CHANNEL_DATA+1
              AND #$80
              LSR A
              LSR A
              LSR A
              STA RAD_TEMP
              LDA RAD_CHANNEL_DATA
              AND #$F0
              LSR A
              LSR A
              LSR A
              LSR A
              ADC RAD_TEMP
              STA OPL2_PARAMETER3 ; Save Instruments
              LDA RAD_CHANNEL_DATA+1
              AND #$70
              LSR A
              LSR A
              LSR A
              LSR A
              STA OPL2_OCTAVE
              LDA RAD_CHANNEL_DATA+1
              AND #$0F
              STA OPL2_NOTE
              LDA RAD_CHANNEL_NUM
              STA OPL2_CHANNEL
              LDA OPL2_PARAMETER3
              CMP #$00
              BEQ BypassSetupInstrument
              JSR RAD_SETINSTRUMENT

BypassSetupInstrument
              setas
              LDA OPL2_NOTE
              CMP #$0F
              BNE NoSetKeyOn
              ;      // Stop note.
              LDA #$00
              STA OPL2_PARAMETER0
              JSR OPL2_SET_KEYON
              BRA MoveOn2ProcessLineEffect
NoSetKeyOn
              LDA RAD_CHANNE_EFFCT
              CMP #EFFECT_NOTE_SLIDE_TO
              BEQ MoveOn2ProcessLineEffect
              ;      // Trigger note.
              JSR RAD_PLAYNOTE

MoveOn2ProcessLineEffect
              setas ; This is for security, just in case
              LDA RAD_CHANNE_EFFCT
              CMP #EFFECT_NOTE_SLIDE_TO
              BNE NoEffectNoteSlideTo
              LDA OPL2_NOTE
              CMP #$00
              BNE NoteBiggerThanZero
              BRL DoneWithEffectSwitchCase
NoteBiggerThanZero
              CMP #$0F
              BCC NoteUnderFifteen
              BRL DoneWithEffectSwitchCase
NoteUnderFifteen
              setal
              LDA RAD_CHANNEL_NUM ; Multiply by 2
              AND #$00FF
              ASL A
              TAX
              setas
              ; Compute the (Note/12) First
              ; Set Octave
              LDA OPL2_NOTE    ;Divide Note/12
              STA D0_OPERAND_A
              LDA #$00
              STA D0_OPERAND_A+1
              STA D0_OPERAND_B+1
              LDA #$0C
              STA D0_OPERAND_B
              CLC
              LDA OPL2_OCTAVE
              ADC D0_RESULT
              ASL A
              ASL A
              ASL A
              ASL A
              STA @lPlayerInfo.pitchSlideDest+1,X
              LDA #$00
              STA @lPlayerInfo.pitchSlideDest,X
              PHX
              setal
              CLC
              LDA OPL2_NOTE
              AND #$00FF
              ADC D0_REMAINDER    ; Remainder of the Division Modulo
              ASL A ;<<<<<<<<<<<<<<<<<<<<<<<<<
              TAX
              CLC
              LDA @lnoteFNumbers,X
              PLX
              ADC @lPlayerInfo.pitchSlideDest,X
              STA @lPlayerInfo.pitchSlideDest,X
              LDA RAD_CHANNEL_NUM
              AND #$00FF
              TAX
              setas
              LDA @lPlayerInfo.efftectParameter,X
              STA @lPlayerInfo.pitchSlideSpeed,X
              BRA DoneWithEffectSwitchCase
NoEffectNoteSlideTo
              CMP #EFFECT_SET_VOLUME
              BNE NoEffectSetVolume
              LDA #$01
              STA OPL2_OPERATOR
              setxs
              LDX OPL2_CHANNEL
              LDA #64
              SBC @lPlayerInfo.efftectParameter,X
              STA OPL2_PARAMETER0
              setxl
              JSL OPL2_SET_VOLUME
              BRA DoneWithEffectSwitchCase

NoEffectSetVolume
              CMP #EFFECT_PATTERN_BREAK
              BNE NoEffectPatternBreak
              LDX OPL2_CHANNEL
              LDA @lPlayerInfo.efftectParameter,X
              STA @lPlayerInfo.patternBreak
              BRA DoneWithEffectSwitchCase

NoEffectPatternBreak
              CMP #EFFECT_SET_SPEED
              BNE DoneWithEffectSwitchCase
              LDX OPL2_CHANNEL
              LDA @lPlayerInfo.efftectParameter,X
              STA @lPlayerInfo.speed
DoneWithEffectSwitchCase


NoInstrumentSetup ; Point outside of Tick == 0
              setas ; This is for security, just in case
              LDA RAD_CHANNE_EFFCT
              CMP #EFFECT_NOTE_SLIDE_UP
              BNE No_Effect_Note_Slide_Up


              BRA DoneWithTickEffects
No_Effect_Note_Slide_Up
              CMP #EFFECT_NOTE_SLIDE_DOWN
              BNE No_Effect_Note_Slide_Down


              BRA DoneWithTickEffects
No_Effect_Note_Slide_Down
              CMP #EFFECT_NOTE_SLIDE_VOLUME
              BNE No_Effect_Note_Slide_Volume



              BRA DoneWithTickEffects
No_Effect_Note_Slide_Volume
              CMP #EFFECT_NOTE_SLIDE_TO
              BNE No_Effect_Note_Slide_To



              BRA DoneWithTickEffects
No_Effect_Note_Slide_To
              CMP #EFFECT_VOLUME_SLIDE
              BNE No_Effect_Volume_Slide
              NOP

DoneWithTickEffects
No_Effect_Volume_Slide
              RTL


RAD_PITCH_ADJUST
              setal
              LDA OPL2_PARAMETER2 ;amount = OPL2_PARAMETER2, OPL2_PARAMETER3
              JSL OPL2_GET_BLOCK
              STA OPL2_BLOCK
              JSL OPL2_GET_FNUMBER ;OPL2_PARAMETER0, OPL2_PARAMETER1
              setal
              CLC
              LDA OPL2_PARAMETER2
              ADC OPL2_PARAMETER0
              STA OPL2_PARAMETER0
              AND #$03FF
              CMP #FNUMBER_MIN ; 0x156
              BCS IncreaseOneOctave
              setas
              LDA OPL2_BLOCK
              CMP #$00
              BEQ ExitDropAnOctave
              DEC OPL2_BLOCK
;
;
;  // Drop one octave (if possible) when the F-number drops below octave minimum.
;  if (fNumber < FNUMBER_MIN) {
;    if (block > 0) {
;      block --;
;      fNumber = FNUMBER_MAX - (FNUMBER_MIN - fNumber);
;    }

;  // Increase one octave (if possible) when the F-number reaches above octave maximum.
;  } else if (fNumber > FNUMBER_MAX) {
;    if (block < 7) {
;      block ++;;
;      fNumber = FNUMBER_MIN + (fNumber - FNUMBER_MAX);;
;    }
;  }




ExitDropAnOctave
IncreaseOneOctave

              RTS


RAD_PLAYNOTE
              setas
              LDA #$00
              STA OPL2_PARAMETER0 ; Set Keyon False
              JSR OPL2_SET_KEYON
              ; Set Octave
              LDA OPL2_NOTE    ;Divide Note/12
              STA D0_OPERAND_A
              LDA #$00
              STA D0_OPERAND_A+1
              STA D0_OPERAND_B+1
              LDA #$0C
              STA D0_OPERAND_B
              CLC
              LDA OPL2_OCTAVE
              PHA
              ADC D0_RESULT
              STA OPL2_OCTAVE
              JSR OPL2_SET_BLOCK  ; OPL2_SET_BLOCK Already to OPL2_OCTAVE
              ; Now lets go pick the FNumber for the note we want
              PLA
              STA OPL2_OCTAVE
              setal
              CLC
              LDA OPL2_NOTE
              AND #$00FF
              ADC D0_REMAINDER    ; Remainder of the Division Modulo
              ASL A ;<<<<<<<<<<<<<<<<<<<<<<<<<
              TAX
              LDA @lnoteFNumbers,X
              ADC D0_REMAINDER    ; Remainder of the Division Modulo
              STA OPL2_PARAMETER0 ; Store the 16bit in Param OPL2_PARAMETER0 & OPL2_PARAMETER1
              JSL OPL2_SET_FNUMBER
              setas
              LDA #$01
              STA OPL2_PARAMETER0 ; Set Keyon False
              JSR OPL2_SET_KEYON
              setxl
              RTS

;
RAD_SETINSTRUMENT
              PHY
              ; Carrier
              setas
              LDA #$01
              STA OPL2_OPERATOR
              setal

              LDA #<`TuneInfo.instruments
              STA OPL2_ADDY_PTR_HI
              LDA OPL2_PARAMETER0
              AND #$00FF
              DEC A
              ASL A
              ASL A
              ASL A
              ASL A
              CLC
              ADC #<>TuneInfo.instruments
              STA OPL2_ADDY_PTR_LO
              setal
              LDA #$0020
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0000
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$0040
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0002
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$0060
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0004
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$0080
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0006
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              setal
              LDA #$00E0
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0009
              LDA [OPL2_ADDY_PTR_LO],Y
              AND #$0F
              STA [OPL2_IND_ADDY_LL]
              ; MODULATOR
              LDA #$00
              STA OPL2_OPERATOR
              ;  opl2.setRegister(0x20 + registerOffset, instruments[instrumentIndex][1]);
              setal
              LDA #$0020
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0001
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0x40 + registerOffset, instruments[instrumentIndex][3]);
              setal
              LDA #$0040
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0003
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ; opl2.setRegister(0x60 + registerOffset, instruments[instrumentIndex][5]);
              setal
              LDA #$0060
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0005
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0x80 + registerOffset, instruments[instrumentIndex][7]);
              setal
              LDA #$0080
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$00071
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0xE0 + registerOffset, (instruments[instrumentIndex][9] & 0xF0) >> 4);
              setal
              LDA #$00E0
              JSR OPL2_GET_REG_OFFSET
              setas
              LDY #$0009
              LDA [OPL2_ADDY_PTR_LO],Y
              AND #$F0
              LSR A
              LSR A
              LSR A
              LSR A
              STA [OPL2_IND_ADDY_LL]
              ;  opl2.setRegister(0xC0 + channel, instruments[instrumentIndex][8]);
              LDA OPL2_CHANNEL
              CLC
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$C0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
              CLC
              LDA #OPL2_S_BASE_LL
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #OPL2_S_BASE_HL
              STA OPL2_IND_ADDY_HL
              setas
              LDY #$0008
              LDA [OPL2_ADDY_PTR_LO],Y
              STA [OPL2_IND_ADDY_LL]
              PLY
              RTS

COMPUTE_POINTER
              setal
              LDA #$000A ; Clear  ; Let's Find the Pointer in the Instruments List
              STA M1_OPERAND_A
              LDA OPL2_PARAMETER0 ; Which Entry in the list
              STA M1_OPERAND_B  ;
              CLC
              LDA OPL2_IND_ADDY_LL
              ADC M1_RESULT
              STA OPL2_IND_ADDY_LL
              RTS
;
;#define OPERATOR1 0
;#define OPERATOR2 1
;#define MODULATOR 0
;#define CARRIER   1

* = $370000
TuneInfo .dstruct SongData

.align 16
PlayerInfo .dstruct PlayerVariables


* = $378000
RAD_FILE_TEMP
.binary "RAD_Files/adlibsp.rad"
