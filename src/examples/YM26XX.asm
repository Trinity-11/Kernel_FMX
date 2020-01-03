.cpu "65816"
.include "YM26XX_def.asm"

YM2612_test_piano
			;PHP
			;PHD
			;setaxl
			;PHX
			;PHA
			setas
			LDA #$0;
			STA OPN2_22_LFO ; LFO off
			LDA #$0;
			STA OPN2_27_CHANEL_3_MODE; chanel 3 in normal mode

			; switch off all chanal
			LDA #$0;
			STA OPN2_28_KEY_ON_OFF
			LDA #$1;
			STA OPN2_28_KEY_ON_OFF
			LDA #$2;
			STA OPN2_28_KEY_ON_OFF
			LDA #$4;
			STA OPN2_28_KEY_ON_OFF
			LDA #$5;
			STA OPN2_28_KEY_ON_OFF
			LDA #$6;
			STA OPN2_28_KEY_ON_OFF
			;   ADC off
			LDA #$0;
			STA OPN2_2B_ADC_EN
			;   DT1/MUL
			LDA #$71	;
			STA OPN2_30_ADSR__DT1_MUL__CH1_OP1
			STA OPN2_31_ADSR__DT1_MUL__CH2_OP1
			STA OPN2_32_ADSR__DT1_MUL__CH3_OP1
			STA OPN2_30_ADSR__DT1_MUL__CH1_OP5
			STA OPN2_31_ADSR__DT1_MUL__CH2_OP5
			STA OPN2_32_ADSR__DT1_MUL__CH3_OP5
			LDA #$0D	;
			STA OPN2_34_ADSR__DT1_MUL__CH1_OP2
			STA OPN2_35_ADSR__DT1_MUL__CH2_OP2
			STA OPN2_36_ADSR__DT1_MUL__CH3_OP2
			STA OPN2_34_ADSR__DT1_MUL__CH1_OP6
			STA OPN2_35_ADSR__DT1_MUL__CH2_OP6
			STA OPN2_36_ADSR__DT1_MUL__CH3_OP6
			LDA #$33	;
			STA OPN2_38_ADSR__DT1_MUL__CH1_OP3	;
			STA OPN2_39_ADSR__DT1_MUL__CH2_OP3
			STA OPN2_3A_ADSR__DT1_MUL__CH3_OP3
			STA OPN2_38_ADSR__DT1_MUL__CH1_OP7	;
			STA OPN2_39_ADSR__DT1_MUL__CH2_OP7
			STA OPN2_3A_ADSR__DT1_MUL__CH3_OP7
			LDA #$01	;
			STA OPN2_3C_ADSR__DT1_MUL__CH1_OP4	;
			STA OPN2_3D_ADSR__DT1_MUL__CH2_OP4
			STA OPN2_3E_ADSR__DT1_MUL__CH3_OP4
			STA OPN2_3C_ADSR__DT1_MUL__CH1_OP8	;
			STA OPN2_3D_ADSR__DT1_MUL__CH2_OP8
			STA OPN2_3E_ADSR__DT1_MUL__CH3_OP8

			;  	Total Level
			LDA #$23	;
			STA OPN2_40_ADSR__LT__CH1_OP1	;
			STA OPN2_41_ADSR__LT__CH2_OP1
			STA OPN2_42_ADSR__LT__CH3_OP1
			STA OPN2_40_ADSR__LT__CH1_OP5	;
			STA OPN2_41_ADSR__LT__CH2_OP5
			STA OPN2_42_ADSR__LT__CH3_OP5
			LDA #$2D	;
			STA OPN2_44_ADSR__LT__CH1_OP2	;
			STA OPN2_45_ADSR__LT__CH2_OP2
			STA OPN2_46_ADSR__LT__CH3_OP2
			STA OPN2_44_ADSR__LT__CH1_OP6	;
			STA OPN2_45_ADSR__LT__CH2_OP6
			STA OPN2_46_ADSR__LT__CH3_OP6
			LDA #$26	;
			STA OPN2_48_ADSR__LT__CH1_OP3	;
			STA OPN2_49_ADSR__LT__CH2_OP3
			STA OPN2_4A_ADSR__LT__CH3_OP3
			STA OPN2_48_ADSR__LT__CH1_OP7	;
			STA OPN2_49_ADSR__LT__CH2_OP7
			STA OPN2_4A_ADSR__LT__CH3_OP7
			LDA #$00	;
			STA OPN2_4C_ADSR__LT__CH1_OP4	;
			STA OPN2_4D_ADSR__LT__CH2_OP4
			STA OPN2_4E_ADSR__LT__CH3_OP4
			STA OPN2_4C_ADSR__LT__CH1_OP8	;
			STA OPN2_4D_ADSR__LT__CH2_OP8
			STA OPN2_4E_ADSR__LT__CH3_OP8
			;  	RS/AR
			LDA #$5F	;
			STA OPN2_50_ADSR__SR_AR__CH1_OP1	;
			STA OPN2_51_ADSR__SR_AR__CH2_OP1	;
			STA OPN2_52_ADSR__SR_AR__CH3_OP1	;
			STA OPN2_50_ADSR__SR_AR__CH1_OP5	;
			STA OPN2_51_ADSR__SR_AR__CH2_OP5	;
			STA OPN2_52_ADSR__SR_AR__CH3_OP5	;
			LDA #$99	;
			STA OPN2_54_ADSR__SR_AR__CH1_OP2	;
			STA OPN2_55_ADSR__SR_AR__CH2_OP2	;
			STA OPN2_56_ADSR__SR_AR__CH3_OP2	;
			STA OPN2_54_ADSR__SR_AR__CH1_OP6	;
			STA OPN2_55_ADSR__SR_AR__CH2_OP6	;
			STA OPN2_56_ADSR__SR_AR__CH3_OP6	;
			LDA #$5F	;
			STA OPN2_58_ADSR__SR_AR__CH1_OP3	;
			STA OPN2_59_ADSR__SR_AR__CH2_OP3	;
			STA OPN2_5A_ADSR__SR_AR__CH3_OP3	;
			STA OPN2_58_ADSR__SR_AR__CH1_OP7	;
			STA OPN2_59_ADSR__SR_AR__CH2_OP7	;
			STA OPN2_5A_ADSR__SR_AR__CH3_OP7	;
			LDA #$94	;
			STA OPN2_5C_ADSR__SR_AR__CH1_OP4	;
			STA OPN2_5D_ADSR__SR_AR__CH2_OP4	;
			STA OPN2_5E_ADSR__SR_AR__CH3_OP4	;
			STA OPN2_5C_ADSR__SR_AR__CH1_OP8	;
			STA OPN2_5D_ADSR__SR_AR__CH2_OP8	;
			STA OPN2_5E_ADSR__SR_AR__CH3_OP8	;
			; AM/D1R
			LDA #$7 	;
			STA OPN2_60_ADSR__AM_D1R__CH1_OP1	;
			STA OPN2_61_ADSR__AM_D1R__CH2_OP1	;
			STA OPN2_62_ADSR__AM_D1R__CH3_OP1	;
			STA OPN2_60_ADSR__AM_D1R__CH1_OP5	;
			STA OPN2_61_ADSR__AM_D1R__CH2_OP5	;
			STA OPN2_62_ADSR__AM_D1R__CH3_OP5	;
			LDA #$7 	;
			STA OPN2_64_ADSR__AM_D1R__CH1_OP2	;
			STA OPN2_65_ADSR__AM_D1R__CH2_OP2	;
			STA OPN2_66_ADSR__AM_D1R__CH3_OP2	;
			STA OPN2_64_ADSR__AM_D1R__CH1_OP6	;
			STA OPN2_65_ADSR__AM_D1R__CH2_OP6	;
			STA OPN2_66_ADSR__AM_D1R__CH3_OP6	;
			LDA #$5 	;
			STA OPN2_68_ADSR__AM_D1R__CH1_OP3	;
			STA OPN2_69_ADSR__AM_D1R__CH2_OP3	;
			STA OPN2_6A_ADSR__AM_D1R__CH3_OP3	;
			STA OPN2_68_ADSR__AM_D1R__CH1_OP7	;
			STA OPN2_69_ADSR__AM_D1R__CH2_OP7	;
			STA OPN2_6A_ADSR__AM_D1R__CH3_OP7	;
			LDA #$7 	;
			STA OPN2_6C_ADSR__AM_D1R__CH1_OP4	;
			STA OPN2_6D_ADSR__AM_D1R__CH2_OP4	;
			STA OPN2_6E_ADSR__AM_D1R__CH3_OP4	;
			STA OPN2_6C_ADSR__AM_D1R__CH1_OP8	;
			STA OPN2_6D_ADSR__AM_D1R__CH2_OP8	;
			STA OPN2_6E_ADSR__AM_D1R__CH3_OP8	;
			; D2R
			LDA #$2 	;
			STA OPN2_70_ADSR__D2R__CH1_OP1	;
			STA OPN2_71_ADSR__D2R__CH2_OP1	;
			STA OPN2_72_ADSR__D2R__CH3_OP1	;
			STA OPN2_70_ADSR__D2R__CH1_OP5	;
			STA OPN2_71_ADSR__D2R__CH2_OP5	;
			STA OPN2_72_ADSR__D2R__CH3_OP5	;
			LDA #$2 	;
			STA OPN2_74_ADSR__D2R__CH1_OP2	;
			STA OPN2_75_ADSR__D2R__CH2_OP2	;
			STA OPN2_76_ADSR__D2R__CH3_OP2	;
			STA OPN2_74_ADSR__D2R__CH1_OP6	;
			STA OPN2_75_ADSR__D2R__CH2_OP6	;
			STA OPN2_76_ADSR__D2R__CH3_OP6	;
			LDA #$2 	;
			STA OPN2_78_ADSR__D2R__CH1_OP3	;
			STA OPN2_79_ADSR__D2R__CH2_OP3	;
			STA OPN2_7A_ADSR__D2R__CH3_OP3	;
			STA OPN2_78_ADSR__D2R__CH1_OP7	;
			STA OPN2_79_ADSR__D2R__CH2_OP7	;
			STA OPN2_7A_ADSR__D2R__CH3_OP7	;
			LDA #$2 	;
			STA OPN2_7C_ADSR__D2R__CH1_OP4	;
			STA OPN2_7D_ADSR__D2R__CH2_OP4	;
			STA OPN2_7E_ADSR__D2R__CH3_OP4	;
			STA OPN2_7C_ADSR__D2R__CH1_OP8	;
			STA OPN2_7D_ADSR__D2R__CH2_OP8	;
			STA OPN2_7E_ADSR__D2R__CH3_OP8	;
			;  	D1L/RR
			LDA #$11	;
			STA OPN2_80_ADSR__D1L_RR__CH1_OP1	;
			STA OPN2_81_ADSR__D1L_RR__CH2_OP1	;
			STA OPN2_82_ADSR__D1L_RR__CH3_OP1	;
			STA OPN2_80_ADSR__D1L_RR__CH1_OP5	;
			STA OPN2_81_ADSR__D1L_RR__CH2_OP5	;
			STA OPN2_82_ADSR__D1L_RR__CH3_OP5	;
			LDA #$11	;
			STA OPN2_84_ADSR__D1L_RR__CH1_OP2	;
			STA OPN2_85_ADSR__D1L_RR__CH2_OP2	;
			STA OPN2_86_ADSR__D1L_RR__CH3_OP2	;
			STA OPN2_84_ADSR__D1L_RR__CH1_OP6	;
			STA OPN2_85_ADSR__D1L_RR__CH2_OP6	;
			STA OPN2_86_ADSR__D1L_RR__CH3_OP6	;
			LDA #$11	;
			STA OPN2_88_ADSR__D1L_RR__CH1_OP3	;
			STA OPN2_89_ADSR__D1L_RR__CH2_OP3	;
			STA OPN2_8A_ADSR__D1L_RR__CH3_OP3	;
			STA OPN2_88_ADSR__D1L_RR__CH1_OP7	;
			STA OPN2_89_ADSR__D1L_RR__CH2_OP7	;
			STA OPN2_8A_ADSR__D1L_RR__CH3_OP7	;
			LDA #$A6	;
			STA OPN2_8C_ADSR__D1L_RR__CH1_OP4;
			STA OPN2_8D_ADSR__D1L_RR__CH2_OP4;
			STA OPN2_8E_ADSR__D1L_RR__CH3_OP4;
			STA OPN2_8C_ADSR__D1L_RR__CH1_OP8;
			STA OPN2_8D_ADSR__D1L_RR__CH2_OP8;
			STA OPN2_8E_ADSR__D1L_RR__CH3_OP8;

			; Proprietary
			LDA #$0 	;
			STA OPN2_90_ADSR__D1L_RR__CH1_OP1	;
			STA OPN2_91_ADSR__D1L_RR__CH2_OP1	;
			STA OPN2_92_ADSR__D1L_RR__CH3_OP1	;
			STA OPN2_90_ADSR__D1L_RR__CH4_OP1	;
			STA OPN2_91_ADSR__D1L_RR__CH5_OP1	;
			STA OPN2_92_ADSR__D1L_RR__CH6_OP1	;
			LDA #$0 	;
			STA OPN2_94_ADSR__D1L_RR__CH1_OP2	;
			STA OPN2_95_ADSR__D1L_RR__CH2_OP2	;
			STA OPN2_96_ADSR__D1L_RR__CH3_OP2	;
			STA OPN2_94_ADSR__D1L_RR__CH4_OP2	;
			STA OPN2_95_ADSR__D1L_RR__CH5_OP2	;
			STA OPN2_96_ADSR__D1L_RR__CH6_OP2	;
			LDA #$0 	;
			STA OPN2_98_ADSR__D1L_RR__CH1_OP3	;
			STA OPN2_99_ADSR__D1L_RR__CH2_OP3	;
			STA OPN2_9A_ADSR__D1L_RR__CH3_OP3	;
			STA OPN2_98_ADSR__D1L_RR__CH4_OP3	;
			STA OPN2_99_ADSR__D1L_RR__CH5_OP3	;
			STA OPN2_9A_ADSR__D1L_RR__CH6_OP3	;
			LDA #$0 	;
			STA OPN2_9C_ADSR__D1L_RR__CH1_OP4	;
			STA OPN2_9D_ADSR__D1L_RR__CH2_OP4	;
			STA OPN2_9E_ADSR__D1L_RR__CH3_OP4	;
			STA OPN2_9C_ADSR__D1L_RR__CH4_OP4	;
			STA OPN2_9D_ADSR__D1L_RR__CH5_OP4	;
			STA OPN2_9E_ADSR__D1L_RR__CH6_OP4	;

			;  	Feedback/algorithm
			LDA #$32	;
			STA OPN2_B0_CH1_FEEDBACK_ALGO	;
			STA OPN2_B1_CH2_FEEDBACK_ALGO	;
			STA OPN2_B2_CH3_FEEDBACK_ALGO	;
			LDA #$C0	;  	Both speakers on
			STA OPN2_B4_CH1_L_R_AMS_FMS	;
			STA OPN2_B5_CH2_L_R_AMS_FMS	;
			STA OPN2_B6_CH3_L_R_AMS_FMS	;
			LDA #$23	;  	Set frequency
			STA OPN2_A4_CH1_OCTAVE_FRECANCY_H	;
			LDA #$22	;  	Set frequency
			STA OPN2_A5_CH2_OCTAVE_FRECANCY_H	;
			LDA #$22	;  	Set frequency
			STA OPN2_A6_CH3_OCTAVE_FRECANCY_H	;
			LDA #$9C	;
			STA OPN2_A0_CH1_FRECANCY_L	;
			STA OPN2_A1_CH2_FRECANCY_L	;
			LDA #$24	;
			STA OPN2_A2_CH3_FRECANCY_L	;

			LDA #$00	;  	Key off
			STA OPN2_28_KEY_ON_OFF	;
			setxl
YM2612_test_piano__LOOP_FOR_EVER
			LDA #$F0;
			STA OPN2_28_KEY_ON_OFF
			LDA #$F1;
			STA OPN2_28_KEY_ON_OFF
			LDA #$F2;
			STA OPN2_28_KEY_ON_OFF
			LDA #$F4;
			STA OPN2_28_KEY_ON_OFF
			LDA #$F5;
			STA OPN2_28_KEY_ON_OFF
			LDA #$F6;
			STA OPN2_28_KEY_ON_OFF
			LDX #16384      ; 400ms
		 	JSL ILOOP_MS
			LDA #$0;
			STA OPN2_28_KEY_ON_OFF
			LDA #$1;
			STA OPN2_28_KEY_ON_OFF
			LDA #$2;
			STA OPN2_28_KEY_ON_OFF
			LDA #$4;
			STA OPN2_28_KEY_ON_OFF
			LDA #$5;
			STA OPN2_28_KEY_ON_OFF
			LDA #$6;
			STA OPN2_28_KEY_ON_OFF
			LDX #16384      ; 400ms
		 	JSL ILOOP_MS
			;BRA YM2612_test_piano__LOOP_FOR_EVER
			; never gos here
;			PLA
;			PLX
;			PLD
;			PLP
			RTL

			YM2151_test
						setas
						LDA #$90
						STA OPM_0F_NE_NFREQ
						LDA #$55
						STA OPM_18_LFRQ
						; setup the operator routing on each chanel
						LDA #$D7
						STA OPM_20_A_RL_FR_CONNECT
						STA OPM_21_B_RL_FR_CONNECT
						STA OPM_22_C_RL_FR_CONNECT
						STA OPM_23_D_RL_FR_CONNECT
						STA OPM_24_E_RL_FR_CONNECT
						STA OPM_25_F_RL_FR_CONNECT
						STA OPM_26_G_RL_FR_CONNECT
						STA OPM_27_H_RL_FR_CONNECT

						LDA #$D7	; add some feedback for the next 4 chanel
						STA OPM_24_E_RL_FR_CONNECT
						STA OPM_25_F_RL_FR_CONNECT
						STA OPM_26_G_RL_FR_CONNECT
						STA OPM_27_H_RL_FR_CONNECT
						; ADSR
						;		Note on	                                                 Note off
						;    -------------------------------------------------------
						;   ¦	                                                      ¦
						;   ¦	                                                      ¦
						;---	                                                      -----------
						;
						;                   * -V MAX
						;             *         *
						;         *                 *
						;       *                       * - D1L
						;     *                                  *
						;    *                                           *
						;   *                                                     *
						;  *                                                         *
						;---         AT      ¦   DT1    ¦           DT2            ¦ TR  ----

						LDA #$00
						STA OPM_60_A_M1_TL
						STA OPM_61_B_M1_TL
						STA OPM_68_A_M2_TL
						STA OPM_69_B_M2_TL
						STA OPM_70_A_C1_TL
						STA OPM_71_B_C1_TL
						STA OPM_78_A_C2_TL
						STA OPM_79_B_C2_TL

						LDA #$55
						STA OPM_40_A_M1_DT1_MUL
						LDA #$18
						STA OPM_41_B_M1_DT1_MUL
						LDA #$C4
						STA OPM_80_A_M1_KS_AR
						LDA #$C4
						STA OPM_81_B_M1_KS_AR
						LDA #$84
						STA OPM_A0_A_M1_AMS_EN_D1R
						LDA #$85
						STA OPM_A1_B_M1_AMS_EN_D1R
						LDA #$42
						STA OPM_C0_A_M1_DT2_D2R
						STA OPM_C8_A_M2_DT2_D2R
						STA OPM_D0_A_C1_DT2_D2R
						STA OPM_D8_A_C2_DT2_D2R
						LDA #$43
						STA OPM_C1_B_M1_DT2_D2R
						STA OPM_C9_B_M2_DT2_D2R
						STA OPM_D1_B_C1_DT2_D2R
						STA OPM_D9_B_C2_DT2_D2R
						LDA #$24
						STA OPM_E0_A_M1_D1L_RR
						STA OPM_E1_B_M1_D1L_RR
						LDA #$14
						STA OPM_E8_A_M2_D1L_RR
						STA OPM_E9_B_M2_D1L_RR
						LDA #$24
						STA OPM_F0_A_C1_D1L_RR
						STA OPM_F1_B_C1_D1L_RR
						LDA #$44
						STA OPM_F8_A_C2_D1L_RR
						STA OPM_F9_B_C2_D1L_RR

						; Setup the note to play
						LDA #$96 	;	0x20 sellect the octave (0-7), 0x06 sellect the note (0-F)
						STA OPM_28_A_KC	;
						LDA #$1A
						STA OPM_29_B_KC	;
						LDA #$26
						STA OPM_2A_C_KC	;
						LDA #$2A
						STA OPM_2B_D_KC	;
						LDA #$36
						STA OPM_2C_E_KC	;
						LDA #$2A
						STA OPM_2D_F_KC	;
						LDA #$46
						STA OPM_2E_G_KC	;
						LDA #$4A
						STA OPM_2F_H_KC	;
						; phase
						LDA #$45
						STA OPM_30_A_KF	;
						LDA #$80
						STA OPM_31_B_KF	;
						LDA #$45
						STA OPM_32_C_KF	;
						LDA #$80
						STA OPM_33_D_KF	;

			YM2151_test__LOOP_FOR_EVER
						LDA #$78	;  	Key on chanel A all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$79	;  	Key on chanel B all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$7A	;  	Key on chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$7C	;  	Key on chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$7D	;  	Key on chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$7E	;  	Key on chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$7F	;  	Key on chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;

						LDX #32768      ; 400ms
					 	JSL ILOOP_MS
						LDA #$00	;  	Key off chanel A all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$01	;  	Key off chanel B all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$02	;  	Key off chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$03	;  	Key off chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$04	;  	Key off chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$05	;  	Key off chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$06	;  	Key off chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$07	;  	Key off chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDX #32768      ; 100ms
						JSL ILOOP_MS
						;BRA YM2151_test__LOOP_FOR_EVER
						; never gos here
						RTL

			YM2151_test_2_from_Chibisound
						PHP
						PHD
						setaxl
						PHX
						PHA
						setas

						LDA #$90
						STA OPM_0F_NE_NFREQ
						LDA #$55
						STA OPM_18_LFRQ

						LDA OPM_1B_CT_W
						ORA #$02
						STA OPM_1B_CT_W



						LDA #$C0;
						STA OPM_20_A_RL_FR_CONNECT; sellect the mode and active left and  right chanel
						LDX #400     ; 100ms
						JSL ILOOP_MS
						LDA #$43
						STA OPM_28_A_KC;	sellect a note
						LDX #400     ; 100ms
						JSL ILOOP_MS
						LDA #$40
						STA OPM_60_A_M1_TL
						STA OPM_68_A_M2_TL
						STA OPM_70_A_C1_TL
						STA OPM_78_A_C2_TL
						LDX #400     ; 100ms
						JSL ILOOP_MS

						LDA #$0F
						STA OPM_F8_A_C2_D1L_RR
						LDX #400     ; 100ms
						JSL ILOOP_MS

						LDA #$0F
						STA OPM_1B_CT_W; 4Mhz(?) and square
						LDX #400     ; 100ms
						JSL ILOOP_MS

			YM2151_test_2_from_Chibisound__LOOP_FOR_EVER
						LDA #$78	;  	Key on chanel A all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDX #400     ; 100ms
						JSL ILOOP_MS

						LDA #$79	;  	Key on chanel B all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDX #400     ; 100ms
						JSL ILOOP_MS

						LDA #$7A	;  	Key on chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDX #400     ; 100ms
						JSL ILOOP_MS

						LDX #8192      ; 400ms
					 	JSL ILOOP_MS

						LDA #$00	;  	Key off chanel A all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDX #400     ; 100ms
						JSL ILOOP_MS

						LDA #$01	;  	Key off chanel B all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDA #$02	;  	Key off chanel C all OPP
						STA OPM_08_KEY_ON_OFF	;
						LDX #8192     ; 100ms
						JSL ILOOP_MS
						BRA YM2151_test_2_from_Chibisound__LOOP_FOR_EVER

						PLA
						PLX
						PLD
						PLP
						RTL



