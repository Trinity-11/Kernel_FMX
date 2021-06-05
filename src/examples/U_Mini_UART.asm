;;;
;;; Definitions for the UART for the U and U+
;;;

UART_TRHB 	= $AF18F8       ; Transmit/Receive Hold Buffer
UART_DLL 	= $AF18F8       ; Divisor Latch Low Byte
UART_DLH 	= $AF18F9       ; Divisor Latch High Byte
UART_IER 	= $AF18F9       ; Interupt Enable Register
UART_FCR 	= $AF18FA       ; FIFO Control Register
UART_IIR 	= $AF18FA       ; Interupt Indentification Register
UART_LCR 	= $AF18FB       ; Line Control Register
UART_MCR 	= $AF18FC       ; Modem Control REgister
UART_LSR 	= $AF18FD       ; Line Status Register
UART_MSR 	= $AF18FE       ; Modem Status Register
UART_SR 	= $AF18FF       ; Scratch Register

; Interupt Enable Flags
UINT_LOW_POWER = $20        ; Enable Low Power Mode (16750)
UINT_SLEEP_MODE = $10       ; Enable Sleep Mode (16750)
UINT_MODEM_STATUS = $08     ; Enable Modem Status Interrupt
UINT_LINE_STATUS = $04      ; Enable Receiver Line Status Interupt
UINT_THR_EMPTY = $02        ; Enable Transmit Holding Register Empty interrupt
UINT_DATA_AVAIL = $01       ; Enable Recieve Data Available interupt   

; Interrupt Identification Register Codes
IIR_FIFO_ENABLED = $80      ; FIFO is enabled
IIR_FIFO_NONFUNC = $40      ; FIFO is not functioning
IIR_FIFO_64BYTE = $20       ; 64 byte FIFO enabled (16750)
IIR_MODEM_STATUS = $00      ; Modem Status Interrupt
IIR_THR_EMPTY = $02         ; Transmit Holding Register Empty Interrupt
IIR_DATA_AVAIL = $04        ; Data Available Interrupt
IIR_LINE_STATUS = $06       ; Line Status Interrupt
IIR_TIMEOUT = $0C           ; Time-out Interrupt (16550 and later)
IIR_INTERRUPT_PENDING = $01 ; Interrupt Pending Flag

; Line Control Register Codes
LCR_DLB = $80               ; Divisor Latch Access Bit
LCR_SBE = $60               ; Set Break Enable

LCR_PARITY_NONE = $00       ; Parity: None
LCR_PARITY_ODD = $08        ; Parity: Odd
LCR_PARITY_EVEN = $18       ; Parity: Even
LCR_PARITY_MARK = $28       ; Parity: Mark
LCR_PARITY_SPACE = $38      ; Parity: Space

LCR_STOPBIT_1 = $00         ; One Stop Bit
LCR_STOPBIT_2 = $04         ; 1.5 or 2 Stop Bits

LCR_DATABITS_5 = $00        ; Data Bits: 5
LCR_DATABITS_6 = $01        ; Data Bits: 6
LCR_DATABITS_7 = $02        ; Data Bits: 7
LCR_DATABITS_8 = $03        ; Data Bits: 8

LSR_ERR_RECIEVE = $80       ; Error in Received FIFO
LSR_XMIT_DONE = $40         ; All data has been transmitted
LSR_XMIT_EMPTY = $20        ; Empty transmit holding register
LSR_BREAK_INT = $10         ; Break interrupt
LSR_ERR_FRAME = $08         ; Framing error
LSR_ERR_PARITY = $04        ; Parity error
LSR_ERR_OVERRUN = $02       ; Overrun error
LSR_DATA_AVAIL = $01        ; Data is ready in the receive buffer

INIT_SERIAL	.proc
	
			; Init Baud Rate
			setas
			LDA @l UART_LCR
			ORA #LCR_DLB
			STA @l UART_LCR
	
			LDA #$00
			STA @l UART_DLH
			LDA #8			; (14Mhz / (16 * 115200)) = 7.7
			STA @l UART_DLL
			
			LDA @l UART_LCR
			EOR #LCR_DLB
			STA @l UART_LCR	
			; Init Serial Parameters
			setas
			LDA #LCR_PARITY_NONE | LCR_STOPBIT_1 | LCR_DATABITS_8
			AND #$7F
			STA @l UART_LCR
	
			LDA #%11000001	; FIFO Mode is always On and it has only 14Bytes
			STA @l UART_FCR
			RTS

.pend
;
; Send a byte to the UART
;
; Inputs:
;   A = the character to print
;
UART_PUTC   .proc
            setas
               ; Wait for the transmit FIFO to free up
wait_putc   LDA @l UART_LSR
            AND #LSR_XMIT_EMPTY
            BEQ wait_putc
			LDA UART_CHAR_2_SEND
            STA @l UART_TRHB
            RTS
.pend
;
; IPRINTH
; Prints data from memory in hexadecimal format
; Inputs:
;   X: 16-bit address of the LAST BYTE of data to print.
;   Y: Length in bytes of data to print
; Modifies:
;   X,Y, results undefined
IPRINTH  .proc
iprinth1        setas
                LDA #0,b,x      ; Read the value to be printed
                LSR
                LSR
                LSR
                LSR
                JSR iprint_digit
                LDA #0,b,x
                JSR iprint_digit
                DEX
                DEY
                BNE iprinth1
                RTS
.pend

iprint_digit    .proc
				PHX
                setal
                AND #$0F
                TAX
                ; Use the value in AL to
                LDA hex_digits,X
				STA UART_CHAR_2_SEND
                JSR UART_PUTC       ; Print the digit
                PLX
                RTS
.pend
;
; IPRINTAH
; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
;
; Inputs:
;   A: 8 or 16 bit value to print
;
IPRINTAH        .proc
                PHA
                PHP
                STA @lCPUA            ; Save A where we can use it multiple times
                PHP                   ; Get the processor status into A
                setas
                setxl
                PLA
                AND #%00100000        ; Is M = 1?
                CMP #%00100000
                BEQ eight_bit

                LDA @lCPUA+2          ; Get nibble [15..12]
                .rept 4
                LSR A
                .next
                JSR iprint_digit      ; And print it
                LDA @lCPUA+2          ; Get nibble [11..8]
                JSR iprint_digit      ; And print it

eight_bit       LDA @lCPUA            ; Get nibble [7..4]
                .rept 4
                LSR A
                .next
                JSR iprint_digit      ; And print it
                LDA @lCPUA            ; Get nibble [3..0]
                JSR iprint_digit      ; And print it
                PLP
                PLA
                RTS
                .pend
;
; IPRINT
; Print a string, followed by a carriage return
; DBR: bank containing string
; X: address of the string in data bank
; Modifies: X
;
IPRINT          .proc
				JSR IPUTS
                JSR IPRINTCR
                RTS
.pend
; IPUTS
; Print a null terminated string
; DBR: bank containing string
; X: address of the string in data bank
; Modifies: X.
;  X will be set to the location of the byte following the string
;  So you can print multiple, contiguous strings by simply calling
;  IPUTS multiple times.
IPUTS           .proc
				PHA
                PHP
                setas
                setxl
iputs1          LDA $0,b,x      ; read from the string
                BEQ iputs_done
				STA UART_CHAR_2_SEND
iputs2          JSR UART_PUTC
iputs3          INX
                JMP iputs1
iputs_done      INX
                PLP
                PLA
                RTS
.pend

IPRINTCR		.proc 
				setas
                LDA #$0D
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                LDA #$0A
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
				RTS
.pend

BREAK_SRV       .proc
				setdp 0
                PLA             ; Pull .Y and stuff it in the CPUY variable
                STA CPUY
                PLA             ; Pull .X and stuff it in the CPUY variable
                STA CPUX
                PLA             ; Pull .A and stuff it in the CPUY variable
                STA CPUA
                PLA
                STA CPUDP       ; Pull Direct page
                setas
                PLA             ; Pull Data Bank (8 bits)
                STA CPUDBR
                PLA             ; Pull Flags (8 bits)
                STA CPUFLAGS
                setal
                PLA             ; Pull Program Counter (16 bits)
                STA CPUPC
                setas
                PLA             ; Pull Program Bank (8 bits)
                STA CPUPBR

                setal
                TSA             ; Get the stack
                STA CPUSTACK    ; Store the stack at immediately before the interrupt was asserted
				CLC           ; clear the carry flag
                XCE           ; move carry to emulation flag.
                LDA #STACK_END ; Reset the stack
                TAS
       			setaxl 

				setdbr `mregisters_msg
         		LDX #<>mregisters_msg
        		JSR IPRINT
				setas
                LDA #';'
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                setaxl
                setdbr $0
                ; print Program Counter
                LDY #3
                LDX #CPUPC+2
                JSR IPRINTH
                ; print A register
                LDA #' '
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                LDY #2
                LDX #CPUA+1
                JSR IPRINTH

                ; print X register
                LDA #' '
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                LDY #2
                LDX #CPUX+1
                JSR IPRINTH

                ; print Y register
                LDA #' '
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                LDY #2
                LDX #CPUY+1
                JSR IPRINTH

                ; print Stack Pointer
                LDA #' '
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                LDY #2
                LDX #CPUSTACK+1
                JSR IPRINTH

                ; print DBR
                LDA #' '
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                LDY #1
                LDX #CPUDBR
                JSR IPRINTH

                ; print Direct Page
                LDA #' '
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                JSR UART_PUTC
                LDY #2
                LDX #CPUDP+1
                JSR IPRINTH

                ; print Flags
                LDA #' '
				STA UART_CHAR_2_SEND
                JSR UART_PUTC
                LDY #1
                LDX #CPUFLAGS
                JSR IPRINTH

                JSR IPRINTCR

ENDLESS:		JMP ENDLESS
.pend
hex_digits      .text "0123456789ABCDEF",0
;
; MMESSAGES
; MONITOR messages and responses.
MMESSAGES
MMERROR         .text "Error", $00

mregisters_msg  .null $0D," PC     A    X    Y    SP   DBR DP   NVMXDIZC"