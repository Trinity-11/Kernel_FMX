---------------------------------------------------------------
                 ; MIDI test code START

                 ;;LDA #$A
                 ;;JSL UART_PUTC
                 ;;LDA #$D
                 ;;JSL UART_PUTC
                 ; the command are listed in "MIDI PROCESSING UNIT - MPU-401 - TECHNICAL REFERENCE MANUAL" from Roland
                 setas
                 ;;LDA #$89        ; MIDI THRU on
                 ;;STA MIDI_MPU_COMMAND
                 ;;LDX #20000      ; 2s
                 ;;JSL ILOOP_MS
                 ;;BRA Loop_MIDI
                 LDA #$FF        ; reset the module
                 STA MIDI_MPU_COMMAND
                 LDX #100
                 JSL ILOOP_MS
                 LDA MIDI_DATA  ; get the 0xFE out of the way after the resaet if on the module was in MIDI mode
                 LDA #$3F        ; set the module in UART mode
                 STA MIDI_MPU_COMMAND
                 LDX #100
                 JSL ILOOP_MS
                 LDA MIDI_DATA  ; get the 0xFE out of the way
                 LDX #100
                 JSL ILOOP_MS
                 ;;LDX #100
                 ;;JSL ILOOP_MS
                 ;;LDA #$90        ; Note ON  90 50 7F => 9x | Note | Velocity
                 ;;STA MIDI_MPU_COMMAND
               ;;  LDX #100
                 ;;JSL ILOOP_MS
                 ;;LDA #$50
                 ;;STA MIDI_MPU_COMMAND
                 ;;LDX #100
                 ;;JSL ILOOP_MS
                 ;;LDA #$7F
                 ;;STA MIDI_MPU_COMMAND
                 ;;LDX #100
                 ;;JSL ILOOP_MS
 Loop_MIDI       ; this code will acte as a MIDI thru
                 LDA MIDI_MPU_STATUS
                 CMP 0
                 BNE Loop_MIDI     ; no data recieved
                 LDA MIDI_DATA    ; read the byte crecieved
                 STA MIDI_DATA    ; dent it on the midi output

                 JSL UART_PUTHEX_2 ; print the recieved command on  the uart console
                 LDA #$A
                 JSL UART_PUTC
                 LDA #$D
                 JSL UART_PUTC
                 ;;;;;;;;;;;;;;;;;;;;BRA Loop_MIDI