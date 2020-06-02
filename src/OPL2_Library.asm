.cpu "65816"
.include "OPL3_def.asm"
.include "OPL2_Instruments.asm"
.include "OPL2_Midi_Drums.asm"
.include "OPL2_Midi_Instruments.asm"
.include "OPL2_Midi_Instruments_Win31.asm"

;In some assemblers, BGE (Branch if Greater than or Equal) and BLT (Branch if Less Than) are synonyms for BCS and BCC, respectively.
; BCS ( A > = DATA )
; BCC (  A < DATA )
; BMI ( < ) (Signed)
; BPL ( > )
; BEQ ( A == DATA )
; BNE ( A < > DATA )

NOTE_INTRO  .byte  $3C, $42, $44, $45, $47, $49, $4B, $4C
IOPL2_TONE_TEST
                setas
                setxl
                LDX #0

OPL2_TONE_TESTING_L1
                LDA NOTE_INTRO, X
                AND #$F
                STA OPL2_NOTE ; start at C
                
                LDA NOTE_INTRO, X
                AND #$70
                LSR A
                LSR A
                LSR A
                LSR A
                STA OPL2_OCTAVE
                
                TXA
                AND #$03        ; replace modulo 3 -  play each note on a different channel
                STA OPL2_CHANNEL
                JSL OPL2_PLAYNOTE

                LDY #$0000
                
; Delay around 30ms
OPL2_TONE_TESTING_L2
                NOP
                NOP
                NOP
                NOP
                INY
                CPY #$FFFF
                BNE OPL2_TONE_TESTING_L2

                ;
                ; DELAY of 300ms Here
                ;
                INX
                CPX #8
                BNE OPL2_TONE_TESTING_L1

                RTL

OPL2_INIT
                setal
                ; Just Making sure all the necessary variables are cleared before doing anything
                LDA #$0000
                STA OPL2_REG_REGION
                STA OPL2_REG_OFFSET
                STA OPL2_NOTE
                STA OPL2_PARAMETER0
                STA OPL2_PARAMETER2
                
                ; instrument library address
                LDA #<>INSTRUMENT_ACCORDN
                STA RAD_ADDR
                LDA #<`INSTRUMENT_ACCORDN
                STA RAD_ADDR + 2
                
                setas
                RTL


OPL2_Reset
                RTL


OPL2_Get_FrequencyBlock
                RTL

;OPL2_GET_REGISTER
;OPL2_PARAMETER0  = Register ;
; Return
;A  = Value ;
OPL2_GET_REGISTER        ;Return Byte, Param: (byte reg, byte value);
              setdp BANK0_BEGIN

              setal
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_PARAMETER0
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              RTL

OPL2_GET_WAVEFORM_SELECT   ; Return Bool
              setdp BANK0_BEGIN

              setal
              LDA #<>OPL3_R_BASE
              ADC #$0001
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$20
              RTL

OPL2_GET_SCALINGLEVEL  ; Return Byte, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

              setal
              LDA #$0040  ;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$C0
              LSR A
              LSR A
              LSR A
              LSR A
              LSR A
              LSR A
              RTL

;OPL2_GET_BLOCK
OPL2_GET_BLOCK            ; Return Byte, Param: (byte channel);
              setdp BANK0_BEGIN

              setas
              CLC
              LDA OPL2_CHANNEL
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$B0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
;Address Creation in $AFE700 Memory Section
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas 
              LDA [OPL2_IND_ADDY_LL]
              AND #$1C
              LSR A
              LSR A
              RTL

OPL2_GET_KEYON            ; Return Bool, Param: (byte channel);
              setdp BANK0_BEGIN

              setas
              CLC
              LDA OPL2_CHANNEL
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$B0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
              ;Address Creation in $AFE700 Memory Section
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$20
              RTL

OPL2_GET_FEEDBACK         ; Return Byte, Param: (byte channel);
              setdp BANK0_BEGIN

              setas
              CLC
              LDA OPL2_CHANNEL
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$C0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
              ;Address Creation in $AFE700 Memory Section
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$E0
              LSR
              RTL

OPL2_GET_SYNTHMODE        ; Return Bool, Param: (byte channel);
              setdp BANK0_BEGIN

              setas
              CLC
              LDA OPL2_CHANNEL
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$C0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
              ;Address Creation in $AFE700 Memory Section
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$01
              RTL

OPL2_GET_DEEPTREMOLO      ; Return Bool, Param: (none);
              setdp BANK0_BEGIN

              setal
              LDA #$00BD;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$80
              RTL

OPL2_GET_DEEPVIBRATO      ; Return Bool, Param: (none);
              setdp BANK0_BEGIN

              setal
              LDA #<>OPL3_R_BASE
              ADC #$00BD
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$40
              RTL

OPL2_GET_PERCUSSION       ; Return Bool, Param: (none);
              setdp BANK0_BEGIN

              setal
              LDA #<>OPL3_R_BASE
              ADC #$00BD
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$20
              RTL

OPL2_GET_DRUMS          ; Return Byte, Param: (none);
              setdp BANK0_BEGIN

              setal
              LDA #<>OPL3_R_BASE
              ADC #$00BD
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$1F
              RTL



OPL2_Get_WaveForm         ; Return Byte, Param: (byte channel, byte operatorNum);

                RTL
;
;OPL2_PLAYNOTE
; Inputs
; OPL2_CHANNEL @ $000027 ;
; OPL2_NOTE    @ $000030 ; Notes start at 1 to 12
; OPL2_OCTAVE  @ $000031 ;
; OPL2_PARAMETER0 Will Change
OPL2_PLAYNOTE   ;Return void, Param: (byte channel, byte octave, byte note);
              setdp BANK0_BEGIN

                setas
                PHX
                LDA #$00
                STA OPL2_PARAMETER0 ; Set Keyon False
                JSR OPL2_SET_KEYON
                ; Set Octave
                JSR OPL2_SET_BLOCK  ; OPL2_SET_BLOCK Already to OPL2_OCTAVE
                ; Now lets go pick the FNumber for the note we want
                
                setxs
                LDA OPL2_NOTE
                DEC A
                ASL A
                TAX
                LDA @lnoteFNumbers,X
                STA OPL2_PARAMETER0 ; Store the 8it in Param OPL2_PARAMETER0
                INX
                LDA @lnoteFNumbers,X
                STA OPL2_PARAMETER1 ; Store the 8bit in Param OPL2_PARAMETER1
                JSL OPL2_SET_FNUMBER
                LDA #$01
                STA OPL2_PARAMETER0 ; Set Keyon False
                JSR OPL2_SET_KEYON
                setxl
                PLX
                RTL

; **************************************************************
; * Not used
; **************************************************************
OPL2_PLAYDRUM             ;Return void, Param: (byte drum, byte octave, byte note);
                RTL
;
;
;OPL2_SET_INSTRUMENT
; Inputs
; OPL2_CHANNEL @ $000027 ; Channel
; OPL2_ADDY_PTR_LO @ $00:0008  ; Pointer to Instrument
; OPL2_ADDY_PTR_MD @ $00:0009  ;
; OPL2_ADDY_PTR_HI @ $00:000A  ;
; OPL2_PARAMETER3 @ $00:0035
OPL2_SET_INSTRUMENT         ;Return Byte, Param: (byte channel, const unsigned char *instrument);
              setdp BANK0_BEGIN

              SEC ; Set the WaveFormSelect to True
              JSL OPL2_SET_WAVEFORMSELECT;
              setas
              setxl
              LDY #$0000
              LDX #$0000
              LDA [OPL2_ADDY_PTR_LO],Y ; Pointer Location 0 in Instrument Profile
              STA OPL2_PARAMETER3
              INY
              ;Base drum...
              CMP #$06
              BNE PERCUSSION_NEXT07
              BRL Percussion_6

              ;Snare drum...
PERCUSSION_NEXT07
              CMP #$07
              BNE PERCUSSION_NEXT08
              BRL Percussion_7

              ;Tom Tom
PERCUSSION_NEXT08
              CMP #$08
              BNE PERCUSSION_NEXT09
              BRL Percussion_8

              ;Top Cymbal
PERCUSSION_NEXT09
              CMP #$09
              BNE PERCUSSION_NEXT0A
              BRL Percussion_9
              ;Hi Hat
PERCUSSION_NEXT0A
              CMP #$0A
              BNE Percussion_Default
              BRL Percussion_A

; Melodic Instruments
Percussion_Default
              LDA #$00
              STA OPL2_OPERATOR
              ; The Channel Has been Set Already
              setal
              LDA #$0020;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 1 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$0040;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 2 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$0060;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 3 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$0080;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 4 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$00E0;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 5 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              ; Zone $C0
              setxs
              LDA OPL2_CHANNEL
              AND #$0F
              TAX
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 6 in Instrument Profile
              STA @lOPL3_R_FEEDBACK,X
              INY
              ; Deal with Operator 1
              LDA #$01
              STA OPL2_OPERATOR
              ; The Channel Has been Set Already
              setal
              LDA #$0020;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 7 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$0040;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 8 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$0060;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 9 in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$0080;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location A in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
              INY
              setal
              LDA #$00E0;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location B in Instrument Profile
              STA [OPL2_IND_ADDY_LL]
                RTL
Percussion_A
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 1 in Instrument Profile
              STA @lOPL3_R_AM_VID_EG_KSR_MULT + $11
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 2 in Instrument Profile
              STA @lOPL3_R_KSL_TL + $11
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 3 in Instrument Profile
              STA @lOPL3_R_AR_DR + $11
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 4 in Instrument Profile
              STA @lOPL3_R_SL_RR + $11
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 5 in Instrument Profile
              STA @lOPL3_R_WAVE_SELECT + $11
                RTL
Percussion_9
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 1 in Instrument Profile
              STA @lOPL3_R_AM_VID_EG_KSR_MULT + $15
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 2 in Instrument Profile
              STA @lOPL3_R_KSL_TL + $15
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 3 in Instrument Profile
              STA @lOPL3_R_AR_DR + $15
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 4 in Instrument Profile
              STA @lOPL3_R_SL_RR + $15
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 5 in Instrument Profile
              STA @lOPL3_R_WAVE_SELECT + $15
              RTL
Percussion_8
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 1 in Instrument Profile
              STA @lOPL3_R_AM_VID_EG_KSR_MULT + $12
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 2 in Instrument Profile
              STA @lOPL3_R_KSL_TL + $12
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 3 in Instrument Profile
              STA @lOPL3_R_AR_DR + $12
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 4 in Instrument Profile
              STA @lOPL3_R_SL_RR + $12
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 5 in Instrument Profile
              STA @lOPL3_R_WAVE_SELECT + $12
              RTL
Percussion_7
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 1 in Instrument Profile
              STA @lOPL3_R_AM_VID_EG_KSR_MULT + $14
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 2 in Instrument Profile
              STA @lOPL3_R_KSL_TL + $14
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 3 in Instrument Profile
              STA @lOPL3_R_AR_DR + $14
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 4 in Instrument Profile
              STA @lOPL3_R_SL_RR + $14
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 5 in Instrument Profile
              STA @lOPL3_R_WAVE_SELECT + $14
              RTL
; If Percussion Type 6, Use the Profile to Adjust those Registers
Percussion_6
              setas
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 1 in Instrument Profile
              STA @lOPL3_R_AM_VID_EG_KSR_MULT + $10
              STA @lOPL3_R_AM_VID_EG_KSR_MULT + $13
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 2 in Instrument Profile
              STA @lOPL3_R_KSL_TL + $10
              STA @lOPL3_R_KSL_TL + $13
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 3 in Instrument Profile
              STA @lOPL3_R_AR_DR + $10
              STA @lOPL3_R_AR_DR + $13
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 4 in Instrument Profile
              STA @lOPL3_R_SL_RR + $10
              STA @lOPL3_R_SL_RR + $13
              INY
              LDA [OPL2_ADDY_PTR_LO], Y ; Pointer Location 5 in Instrument Profile
              STA @lOPL3_R_WAVE_SELECT + $10
              STA @lOPL3_R_WAVE_SELECT + $13
              RTL







;
;OPL2_PARAMETER0  = Register ;
;OPL2_PARAMETER1  = Value ;
OPL2_SET_REGISTER        ;Return Byte, Param: (byte reg, byte value);
              setdp BANK0_BEGIN

              setal
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_PARAMETER0
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA OPL2_PARAMETER1
              STA [OPL2_IND_ADDY_LL]
              RTL

OPL2_SET_WAVEFORMSELECT     ;Return Byte, Param: (bool enable);
              setdp BANK0_BEGIN

              setal
              LDA #<>OPL3_R_BASE + $0001
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              BCS OPL2_Set_WaveFormSelect_set
              ;clear
              LDA [OPL2_IND_ADDY_LL]
              AND #$DF
              STA [OPL2_IND_ADDY_LL]
              RTL
OPL2_Set_WaveFormSelect_set
              setdp BANK0_BEGIN

              ;set
              LDA [OPL2_IND_ADDY_LL]
              ORA #$20
              STA [OPL2_IND_ADDY_LL]
                RTL

;OPL2_SET_TREMOLO
; Inputs
; Carry (1 = Enable, 0 = Disable)
;OPL2_OPERATOR    = $000026 ;
;OPL2_CHANNEL     = $000027 ;
;OPL2_ENABLE      = $000028 ;
;OPL2_REG_OFFSET  = $00002A ;
; Output
;
; Note: Only Support Stereo (dual Write) - No Individual (R-L Channel) Target
OPL2_SET_TREMOLO            ;Return Byte, Param: (byte channel, byte operatorNum, bool enable);
              setdp BANK0_BEGIN

                PHP ; Push the Carry
                setal
                CLC
                LDA #$0020 ; 
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                ; Now Check if we are going to enable the bit or disable it
                PLP ; Pull the Carry out
                setas
                BCS OPL2_Set_Tremolo_Set;
                ; Clear the Bit
                LDA [OPL2_IND_ADDY_LL]
                AND #$7F
                STA [OPL2_IND_ADDY_LL]
                BRA OPL2_Set_Tremolo_Exit
                ; Set the Bit
OPL2_Set_Tremolo_Set
                LDA [OPL2_IND_ADDY_LL]
                ORA #$80
                STA [OPL2_IND_ADDY_LL]
                ; Let's get out of here
OPL2_Set_Tremolo_Exit
                RTL

;OPL2_GET_TREMOLO
; Inputs
;OPL2_OPERATOR    = $000026 ;
;OPL2_CHANNEL     = $000027 ;
;OPL2_ENABLE      = $000028 ;
;OPL2_REG_OFFSET  = $00002A ;
; Output
; A = Tremolo Status Bit7
OPL2_GET_TREMOLO          ; Return Bool, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

                setal
                LDA #$0020;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA [OPL2_IND_ADDY_LL]
                AND #$80
                RTL

;OPL2_SET_VIBRATO
; Inputs
; C = Enable
;OPL2_OPERATOR    = $000026 ;
;OPL2_CHANNEL     = $000027 ;
;OPL2_ENABLE      = $000028 ;
;OPL2_REG_OFFSET  = $00002A ;
; C = Enable (1 = Enable, 0 = Disable)
OPL2_SET_VIBRATO            ;Return Byte, Param: (byte channel, byte operatorNum, bool enable);
              setdp BANK0_BEGIN

                PHP ; Push the Carry
                setal
                CLC
                LDA #$0020;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                ; Now Check if we are going to enable the bit or disable it
                PLP ; Pull the Carry out
                setas
                BCS OPL2_Set_Vibrato_Set;
                ; Clear the Bit
                LDA [OPL2_IND_ADDY_LL]
                AND #$BF
                STA [OPL2_IND_ADDY_LL]
                BRA OPL2_Set_Vibrato_Exit
                ; Set the Bit
OPL2_Set_Vibrato_Set
                LDA [OPL2_IND_ADDY_LL]
                ORA #$40
                STA [OPL2_IND_ADDY_LL]
                ; Let's get out of here
OPL2_Set_Vibrato_Exit
                RTL
;
;OPL2_GET_VIBRATO
; Inputs
;OPL2_OPERATOR    = $000026 ;
;OPL2_CHANNEL     = $000027 ;
;OPL2_ENABLE      = $000028 ;
;OPL2_REG_OFFSET  = $00002A ;
; Output
; A = Tremolo Status Bit6
OPL2_GET_VIBRATO          ; Return Bool, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

                setal
                LDA #$0020;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA [OPL2_IND_ADDY_LL]
                AND #$40
                RTL
;
;OPL2_SET_MAINTAINSUSTAIN
; Inputs
; C = Enable
;OPL2_OPERATOR    = $000028 ;
;OPL2_CHANNEL     = $000029 ;
;OPL2_ENABLE      = $00002A ;
;OPL2_REG_OFFSET  = $00002B ;
; C = Enable (1 = Enable, 0 = Disable)
OPL2_SET_MAINTAINSUSTAIN    ;Return Byte, Param: (byte channel, byte operatorNum, bool enable);
              setdp BANK0_BEGIN

              PHP ; Push the Carry
              setal
              CLC
              LDA #$0020;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
; Now Check if we are going to enable the bit or disable it
              PLP ; Pull the Carry out
              setas
              BCS OPL2_Set_MaintainSustain_Set;
                ; Clear the Bit
              LDA [OPL2_IND_ADDY_LL]
              AND #$DF
              STA [OPL2_IND_ADDY_LL]
              BRA OPL2_Set_MaintainSustain_Exit
OPL2_Set_MaintainSustain_Set
              LDA [OPL2_IND_ADDY_LL]
              ORA #$20
              STA [OPL2_IND_ADDY_LL]
                ; Let's get out of here
OPL2_Set_MaintainSustain_Exit
                RTL
;OPL2_GET_MAINTAINSUSTAIN
OPL2_GET_MAINTAINSUSTAIN  ; Return Bool, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

              setal
              LDA #$0020;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$20
                RTL
;OPL2_SET_ENVELOPESCALING
; Inputs
; C = Enable
;OPL2_OPERATOR    = $000028 ;
;OPL2_CHANNEL     = $000029 ;
;OPL2_ENABLE      = $00002A ;
;OPL2_REG_OFFSET  = $00002B ;
; C = Enable (1 = Enable, 0 = Disable)
OPL2_SET_ENVELOPESCALING    ;Return Byte, Param: (byte channel, byte operatorNum, bool enable);
              setdp BANK0_BEGIN

              PHP ; Push the Carry
              setal
              CLC
              LDA #$0020;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              ; Now Check if we are going to enable the bit or disable it
              PLP ; Pull the Carry out
              setas
              BCS OPL2_Set_EnvelopeScaling_Set;
              ; Clear the Bit
              LDA [OPL2_IND_ADDY_LL]
              AND #$EF
              STA [OPL2_IND_ADDY_LL]
              BRA OPL2_Set_EnvelopeScaling_Exit
OPL2_Set_EnvelopeScaling_Set
              LDA [OPL2_IND_ADDY_LL]
              ORA #$10
              STA [OPL2_IND_ADDY_LL]
; Let's get out of here
OPL2_Set_EnvelopeScaling_Exit
                RTL
;
OPL2_GET_ENVELOPESCALING  ; Return Bool, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

              setal
              LDA #$0020;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$10
                RTL

OPL2_GET_MODFREQMULTIPLE       ; Return Byte, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

              setal
              LDA #$0020;
              STA OPL2_REG_REGION
              JSR OPL2_GET_REG_OFFSET
              setas
              LDA [OPL2_IND_ADDY_LL]
              AND #$0F
              RTL
;
;OPL2_SET_MULTIPLIER
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Multiplier
OPL2_SET_MODFREQMULTIPLE         ;Return Byte, Param: (byte channel, byte operatorNum, byte multiplier);
              setdp BANK0_BEGIN

                setal
                LDA #$0020;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0
                AND #$0F
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$F0
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
;
;
; REGISTERS REGION $40
;
;OPL2_SET_SCALINGLEVEL
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = ScalingLevel
OPL2_SET_SCALINGLEVEL       ;Return Byte, Param: (byte channel, byte operatorNum, byte scaling);
              setdp BANK0_BEGIN

                setal
                LDA #$0040;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0 ; Attack
                AND #$03
                ASL
                ASL
                ASL
                ASL
                ASL
                ASL
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$3F
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
;OPL2_SET_VOLUME
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Volume
OPL2_SET_VOLUME             ;Return Byte, Param: (byte channel, byte operatorNum, byte volume);
              setdp BANK0_BEGIN

                setal
                LDA #$0040  ;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0 ; Volume
                AND #$3F
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$C0
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
;OPL2_GET_VOLUME
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; Output
; A = Volume
OPL2_GET_VOLUME           ; Return Byte, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

                setal
                LDA #$0040  ;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA [OPL2_IND_ADDY_LL]
                AND #$3F
                RTL
;
;
; REGISTERS REGION $60
;
;OPL2_SET_ATTACK
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Attack
OPL2_SET_ATTACK             ;Return Byte, Param: (byte channel, byte operatorNum, byte attack);
              setdp BANK0_BEGIN

                setal
                LDA #$0060  ;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0 ; Attack
                AND #$0F
                ASL
                ASL
                ASL
                ASL
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$0F
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
;
;OPL2_GET_ATTACK
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; Output
; A = Attack
OPL2_GET_ATTACK           ; Return Byte, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

                setal
                LDA #$0060
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA [OPL2_IND_ADDY_LL]
                AND #$F0
                LSR
                LSR
                LSR
                LSR
                RTL
;OPL2_Set_Decay
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Decay
OPL2_SET_DECAY              ;Return Byte, Param: (byte channel, byte operatorNum, byte decay);
              setdp BANK0_BEGIN

                setal
                LDA #$0060;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0 ; Attack
                AND #$0F
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$F0
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
;
;OPL2_GET_DECAY
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; Output
; A = Decay
OPL2_GET_DECAY           ; Return Byte, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

                setal
                LDA #$0060
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA [OPL2_IND_ADDY_LL]
                AND #$0F
                RTL
;
; REGISTERS REGION $80
;
;OPL2_SET_SUSTAIN
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Sustain
OPL2_SET_SUSTAIN            ;Return Byte, Param: (byte channel, byte operatorNum, byte sustain);
              setdp BANK0_BEGIN

                setal
                LDA #$0080;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0 ; Attack
                AND #$0F
                ASL
                ASL
                ASL
                ASL
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$0F
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
;
; OPL2_GET_SUSTAIN
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; Output
; A = Decay
OPL2_GET_SUSTAIN          ; Return Byte, Param: (byte channel, byte operatorNum);
              setdp BANK0_BEGIN

                setal
                LDA #$0080
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA [OPL2_IND_ADDY_LL]
                AND #$F0
                LSR
                LSR
                LSR
                LSR
                RTL
;
;OPL2_SET_RELEASE
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Decay
OPL2_SET_RELEASE            ;Return Byte, Param: (byte channel, byte operatorNum, byte release);
              setdp BANK0_BEGIN

                setal
                LDA #$0080;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0 ; Attack
                AND #$0F
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$F0
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
;
; OPL2_GET_RELEASE
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; Output
; A = Decay
OPL2_GET_RELEASE          ; Return Byte, Param: (byte channel);
              setdp BANK0_BEGIN

                setal
                LDA #$0080
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA [OPL2_IND_ADDY_LL]
                AND #$0F
                RTL
;
; REGISTERS REGION $A0
;
;OPL2_SET_FNUMBER
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = LSB fNumber
; OPL2_PARAMETER1 = MSB fNumber
OPL2_SET_FNUMBER            ;Return Byte, Param: (byte channel, short fNumber);
              setdp BANK0_BEGIN

                setas
                CLC
                LDA OPL2_CHANNEL
                AND #$0F  ; This is just precaution, it should be between 0 to 8
                ADC #$A0
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA OPL2_PARAMETER0     ; Load the first 8 Bits Value of FNumber
                STA [OPL2_IND_ADDY_LL]  ; Load
                ; Let's go in Region $B0 Now
                CLC
                LDA OPL2_IND_ADDY_LL
                ADC #$10
                STA OPL2_IND_ADDY_LL
                LDA OPL2_PARAMETER1
                AND #$03
                STA OPL2_PARAMETER1
                LDA [OPL2_IND_ADDY_LL]
                AND #$FC
                ORA OPL2_PARAMETER1
                STA [OPL2_IND_ADDY_LL]
                RTL
;
; REGISTERS REGION $A0
;
;OPL2_GET_FNUMBER
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = LSB fNumber
; OPL2_PARAMETER1 = MSB fNumber
OPL2_GET_FNUMBER
              setdp BANK0_BEGIN

                setas
                CLC
                LDA OPL2_CHANNEL
                AND #$0F  ; This is just precaution, it should be between 0 to 8
                ADC #$A0
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA [OPL2_IND_ADDY_LL]
                STA OPL2_PARAMETER0
                CLC
                LDA OPL2_IND_ADDY_LL
                ADC #$10
                STA OPL2_IND_ADDY_LL
                LDA [OPL2_IND_ADDY_LL]
                AND #$03
                STA OPL2_PARAMETER1
                RTL

OPL2_Set_Frequency          ;Return Byte, Param: (byte channel, float frequency);

                RTL
;
OPL2_Get_Frequency        ; Return Float, Param: (byte channel);
                RTL
;
;OPL2_SET_BLOCK
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_OCTAVE      = $000031 ; Destructive
; OPL2_PARAMETER0 = Block
OPL2_SET_BLOCK           ;Return Byte, Param: (byte channel, byte block);
              setdp BANK0_BEGIN

                setas
                CLC
                LDA OPL2_CHANNEL
                AND #$0F  ; This is just precaution, it should be between 0 to 8
                ADC #$B0
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA OPL2_OCTAVE
                AND #$07
                ASL
                ASL
                STA OPL2_OCTAVE
                LDA [OPL2_IND_ADDY_LL]
                AND #$E3
                ORA OPL2_OCTAVE
                STA [OPL2_IND_ADDY_LL]
                RTS
;
;OPL2_SET_KEYON
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0 = Key On
OPL2_SET_KEYON              ;Return Byte, Param: (byte channel, bool keyOn);
              setdp BANK0_BEGIN

                setas
                CLC
                LDA OPL2_CHANNEL
                AND #$0F  ; This is just precaution, it should be between 0 to 8
                ADC #$B0
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA OPL2_PARAMETER0
                AND #$01
                BEQ SET_KEYON_OFF
                LDA #$20
    SET_KEYON_OFF
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$DF
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTS

; OPL2_SET_FEEDBACK
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER1 = Feedback
OPL2_SET_FEEDBACK           ;Return Byte, Param: (byte channel, byte feedback);
              setdp BANK0_BEGIN

              setas
              CLC
              LDA OPL2_CHANNEL
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$C0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
              ;Address Creation in $AFE700 Memory Section
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              LDA OPL2_PARAMETER0
              AND #$07
              ASL
              STA OPL2_PARAMETER0
              LDA [OPL2_IND_ADDY_LL]
              AND #$01
              ORA OPL2_PARAMETER0
              STA [OPL2_IND_ADDY_LL]
                RTL
;
; OPL2_SET_SYNTHMODE
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER1 = Feedback
OPL2_SET_SYNTHMODE          ;Return Byte, Param: (byte channel, bool isAdditive);
              setdp BANK0_BEGIN

              PHP ; Push the Carry
              setas
              CLC
              LDA OPL2_CHANNEL
              AND #$0F  ; This is just precaution, it should be between 0 to 8
              ADC #$C0
              STA OPL2_REG_OFFSET
              LDA #$00
              STA OPL2_REG_OFFSET+1;
              setaxl
              ;Address Creation in $AFE700 Memory Section
              CLC
              LDA #<>OPL3_R_BASE
              ADC OPL2_REG_OFFSET
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              PLP ; Pull the Carry out
              setas
              BCS OPL2_Set_Synthmode_Set;
              ; Clear the Bit
              LDA [OPL2_IND_ADDY_LL]
              AND #$FE
              STA [OPL2_IND_ADDY_LL]
              BRA OPL2_Set_Synthmode_Exit
OPL2_Set_Synthmode_Set
              LDA [OPL2_IND_ADDY_LL]
              ORA #$01
              STA [OPL2_IND_ADDY_LL]
; Let's get out of here
OPL2_Set_Synthmode_Exit
                RTL

;OPL2_SET_DEEPTREMOLO
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; C = Enable (1 = Enable, 0 = Disable)
OPL2_SET_DEEPTREMOLO        ;Return Byte, Param: (bool enable);
              setdp BANK0_BEGIN

              setal
              LDA #<>OPL3_R_BASE + $00BD
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              BCS OPL2_Set_DeepTremolo_Set;
              ; Clear the Bit
              LDA [OPL2_IND_ADDY_LL]
              AND #$7F
              STA [OPL2_IND_ADDY_LL]
              BRA OPL2_Set_DeepTremolo_Exit
              ; Set the Bit
OPL2_Set_DeepTremolo_Set
              LDA [OPL2_IND_ADDY_LL]
              ORA #$80
              STA [OPL2_IND_ADDY_LL]
OPL2_Set_DeepTremolo_Exit
                RTL
;OPL2_SET_DEEPVIBRATO
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; C = Enable (1 = Enable, 0 = Disable)
OPL2_SET_DEEPVIBRATO        ;Return Byte, Param: (bool enable);
              setdp BANK0_BEGIN

              setal
              LDA #<>OPL3_R_BASE + $00BD
              STA OPL2_IND_ADDY_LL
              LDA #`OPL3_R_BASE
              STA OPL2_IND_ADDY_HL
              setas
              BCS OPL2_Set_DeepVibrato_Set;
              ; Clear the Bit
              LDA [OPL2_IND_ADDY_LL]
              AND #$BF
              STA [OPL2_IND_ADDY_LL]
              BRA OPL2_Set_DeepVibrato_Exit
              ; Set the Bit
OPL2_Set_DeepVibrato_Set
              LDA [OPL2_IND_ADDY_LL]
              ORA #$40
              STA [OPL2_IND_ADDY_LL]
OPL2_Set_DeepVibrato_Exit
                RTL
;OPL2_SET_PERCUSSION
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; C = Enable (1 = Enable, 0 = Disable)
OPL2_SET_PERCUSSION         ;Return Byte, Param: (bool enable);
              setdp BANK0_BEGIN

                setal
                LDA #<>OPL3_R_BASE + $00BD
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                BCS OPL2_Set_Percussion_Set;
                ; Clear the Bit
                LDA [OPL2_IND_ADDY_LL]
                AND #$DF
                STA [OPL2_IND_ADDY_LL]
                BRA OPL2_Set_Percussion_Exit
                ; Set the Bit
OPL2_Set_Percussion_Set
                LDA [OPL2_IND_ADDY_LL]
                ORA #$20
                STA [OPL2_IND_ADDY_LL]
OPL2_Set_Percussion_Exit
                RTL

;OPL2_SET_DRUMS
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER0[4] = DRUM_BASS = 0x10
; OPL2_PARAMETER0[3] = DRUM_SNARE = 0x08
; OPL2_PARAMETER0[2] = DRUM_TOM = 0x04
; OPL2_PARAMETER0[1] = DRUM_CYMBAL = 0x02
; OPL2_PARAMETER0[0] = DRUM_HI_HAT 0x01
; Changes OPL2_PARAMETER1
OPL2_SET_DRUMS              ;Return Byte, Param: (bool bass, bool snare, bool tom, bool cymbal, bool hihat);
              setdp BANK0_BEGIN

                setal
                LDA #<>OPL3_R_BASE + $00BD
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                setas
                LDA OPL2_PARAMETER0
                AND #$1F
                STA OPL2_PARAMETER0
                EOR #$FF
                STA OPL2_PARAMETER1
                LDA [OPL2_IND_ADDY_LL]
                AND OPL2_PARAMETER1
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL
              
;OPL2_SET_WAVEFORM
; Inputs
; OPL2_OPERATOR    @ $000026 ;
; OPL2_CHANNEL     @ $000027 ;
; OPL2_REG_OFFSET  @ $00002A ;
; OPL2_PARAMETER1 = waveForm
OPL2_SET_WAVEFORM           ;Return Byte, Param: (byte channel, byte operatorNum, byte waveForm);
              setdp BANK0_BEGIN
              
                setal
                LDA #$00E0;
                STA OPL2_REG_REGION
                JSR OPL2_GET_REG_OFFSET
                setas
                LDA OPL2_PARAMETER0
                AND #$03
                STA OPL2_PARAMETER0
                LDA [OPL2_IND_ADDY_LL]
                AND #$FC
                ORA OPL2_PARAMETER0
                STA [OPL2_IND_ADDY_LL]
                RTL

                ; Local Routine (Can't be Called by Exterior Code)
OPL2_GET_REG_OFFSET
                setaxs
                ; Get the Right List
                LDA OPL2_CHANNEL
                AND #$0F
                TAX
                LDA OPL2_OPERATOR   ; 0 = operator 1, other = operator 2
                BNE OPL2_Get_Register_Offset_l0
                LDA @lregisterOffsets_operator0, X
                BRA OPL2_Get_Register_Offset_exit
OPL2_Get_Register_Offset_l0
                LDA @lregisterOffsets_operator1, X
OPL2_Get_Register_Offset_exit
                STA OPL2_REG_OFFSET
                LDA #$00
                STA OPL2_REG_OFFSET+1;
                setaxl
                ;Address Creation in $AFE700 Memory Section
                CLC
                LDA #<>OPL3_R_BASE
                ADC OPL2_REG_OFFSET
                ADC OPL2_REG_REGION ; Ex: $20, or $40, $60, $80 (in 16bits)
                STA OPL2_IND_ADDY_LL
                LDA #`OPL3_R_BASE
                STA OPL2_IND_ADDY_HL
                RTS
