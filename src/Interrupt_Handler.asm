;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
; Interrupt Handler
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////

;
; Macro to test the accumulator for a bit. If it is set, clear the bit in
; the pending interrupt register provided, and JSL to the provided handler
;
; NOTE: Accumulator must be 8-bits only!
;
IRQ_DISPATCH    .macro irq_bit, irq_pending, handler
                .as
                BIT #\irq_bit           ; Check to see if the bit is set
                BEQ continue            ; If not: skip the rest of this macro

                AND #\irq_bit           ; Mask out all other pending interrupts
                STA @l \irq_pending     ; Drop the pending bit for this interrupt
                JSL \handler            ; And call its handler
                setas                   ; Make sure the accumulator is 8-bits in case the handler screwed it up
continue
                .endm

;
; Set the handler for an interrupt vector
;
; Inputs:
;   A = the number of the interrupt vector to change:
;       A[7]..A[4] = the interrupt block (0, 1, 2)
;       A[3]..A[0] = the interrupt number within the block (0 -- 7)
;   Y:X = the address of the interrupt handler:
;       Y[7]..Y[0] = the program bank
;       X[15]..X[0] = the address within the bank
;
; Outputs: nothing
;
ISETHANDLER     .proc
                PHB
                PHP

                setdbr 0                ; We will work in bank 0

                setas
                setxl
                PHA                     ; Save the interrupt number
                PHY                     ; Save the handler's bank
                PHX                     ; Save the handler's address
                PEA #0                  ; Make room for the offset to the vector

LOCALS          .virtual 1,S
l_vector        .word ?                 ; Address of vector in bank 0
l_handler       .dword ?                ; The address of the handler (only 24 bits, really)
l_number        .byte ?                 ; The interrupt number
                .endv

                AND #$30                ; Isolate the block #
                ASL A                   ; Multiply by 2 to get the offset to the first vector of the block
                STA l_vector

                LDA l_number            ; Get the number bank
                AND #$07                ; Isolate the interrupt number
                ASL A                   ; Multiply by four to get the first byte of that interrupt's vector
                ASL A
                ORA l_vector            ; Add it to the offset to the block
                STA l_vector            ; Store back to the vector address

                CLC                     ; Add the address of the start of the interrupt vector table
                LDA #<VEC_INT_START
                ADC l_vector
                STA l_vector
                LDA #>VEC_INT_START
                ADC l_vector+1
                STA l_vector+1

                SEI                     ; Disable the interrupts while we update the vector

                LDY #0
                LDA #$5C                ; Opcode for JML
                STA (l_vector),Y        ; Make sure the first byte is a JML instruction

                INY                     ; Move to the low byte of the vector address
                LDA l_handler
                STA (l_vector),Y        ; And save it to the vector

                INY                     ; Move to the high byte of the vector address
                LDA l_handler+1
                STA (l_vector),Y        ; And save it to the vector

                INY                     ; Move to the bank of the vector address
                LDA l_handler+2
                STA (l_vector),Y        ; And save it to the vector

                setal
                CLC                     ; Clean up the locals off the stack
                TSC
                ADC #SIZE(LOCALS)
                TCS

                PLP
                PLB
                RTL
                .pend

;
; Handler for IRQs... this checks for pending interrupt status bits in the interrupt controller.
; If it finds a particular interrupt has been triggered, it clears the interrupt pending flag
; for that interrupt and calls it associated interrupt handler through the interrupt handler vector
; table located in page $0017xx near the kernel routine jump table.
;
; Programs wanting to take control of an interrupt, should patch their handlers into that vector
; table, although of course they can just replace this handler routine, if they desire.
;
IRQ_HANDLER     .proc
                PHP
                setas 					; Set 8bits

                ;
                ; Interrupt Block 0
                ;

                LDA @l INT_PENDING_REG0     ; Get the block 0 pending interrupts
                BNE process_reg0
                BRL CHECK_PENDING_REG1      ; If nothing: skip to block 1

process_reg0    IRQ_DISPATCH FNX0_INT00_SOF, INT_PENDING_REG0, VEC_INT00_SOF
                IRQ_DISPATCH FNX0_INT01_SOL, INT_PENDING_REG0, VEC_INT01_SOL
                IRQ_DISPATCH FNX0_INT02_TMR0, INT_PENDING_REG0, VEC_INT02_TMR0
                IRQ_DISPATCH FNX0_INT03_TMR1, INT_PENDING_REG0, VEC_INT03_TMR1
                IRQ_DISPATCH FNX0_INT04_TMR2, INT_PENDING_REG0, VEC_INT04_TMR2
                IRQ_DISPATCH FNX0_INT05_RTC, INT_PENDING_REG0, VEC_INT05_RTC
                IRQ_DISPATCH FNX0_INT06_FDC, INT_PENDING_REG0, VEC_INT06_FDC
                IRQ_DISPATCH FNX0_INT07_MOUSE, INT_PENDING_REG0, VEC_INT07_MOUSE

                ;
                ; Interrupt Block 1
                ;

CHECK_PENDING_REG1
                LDA @l INT_PENDING_REG1
                BNE process_reg1
                BRL CHECK_PENDING_REG2

process_reg1    IRQ_DISPATCH FNX1_INT00_KBD, INT_PENDING_REG1, VEC_INT10_KBD
                IRQ_DISPATCH FNX1_INT01_COL0, INT_PENDING_REG1, VEC_INT11_COL0
                IRQ_DISPATCH FNX1_INT02_COL1, INT_PENDING_REG1, VEC_INT12_COL1
                IRQ_DISPATCH FNX1_INT03_COM2, INT_PENDING_REG1, VEC_INT13_COM2
                IRQ_DISPATCH FNX1_INT04_COM1, INT_PENDING_REG1, VEC_INT14_COM1
                IRQ_DISPATCH FNX1_INT05_MPU401, INT_PENDING_REG1, VEC_INT15_MIDI
                IRQ_DISPATCH FNX1_INT06_LPT, INT_PENDING_REG1, VEC_INT16_LPT
                IRQ_DISPATCH FNX1_INT07_SDCARD, INT_PENDING_REG1, VEC_INT17_SDC

                ;
                ; Interrupt Block 2
                ;

CHECK_PENDING_REG2
                LDA @l INT_PENDING_REG2
                BNE process_reg2
                BRL CHECK_PENDING_REG3

process_reg2    IRQ_DISPATCH FNX2_INT00_OPL3, INT_PENDING_REG1, VEC_INT20_OPL
                IRQ_DISPATCH FNX2_INT01_GABE_INT0, INT_PENDING_REG1, VEC_INT21_GABE0
                IRQ_DISPATCH FNX2_INT02_GABE_INT1, INT_PENDING_REG1, VEC_INT22_GABE1
                IRQ_DISPATCH FNX2_INT03_VDMA, INT_PENDING_REG1, VEC_INT23_VDMA
                IRQ_DISPATCH FNX2_INT04_COL2, INT_PENDING_REG1, VEC_INT24_COL2
                IRQ_DISPATCH FNX2_INT05_GABE_INT2, INT_PENDING_REG1, VEC_INT25_GABE2
                IRQ_DISPATCH FNX2_INT06_EXT, INT_PENDING_REG1, VEC_INT26_EXT
                IRQ_DISPATCH FNX2_INT07_SDCARD_INS, INT_PENDING_REG1, VEC_INT17_SDINS

                ;
                ; Interrupt Block 3
                ;

CHECK_PENDING_REG3
                LDA @l INT_PENDING_REG3
                BEQ EXIT_IRQ_HANDLE

                IRQ_DISPATCH FNX3_INT00_OPN2, INT_PENDING_REG1, VEC_INT30_OPN2
                IRQ_DISPATCH FNX3_INT01_OPM, INT_PENDING_REG1, VEC_INT31_OPM
                IRQ_DISPATCH FNX3_INT02_IDE, INT_PENDING_REG1, VEC_INT32_IDE

EXIT_IRQ_HANDLE
                ; Exit Interrupt Handler
                PLP
                RTL
                .pend

;
; Handler for NMI... we don't do anything here at the moment
; 
NMI_HANDLER     RTL

