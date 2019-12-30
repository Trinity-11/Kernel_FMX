;
; Page 0 Code: interrupt handlers and vectors
;

;
; Interrupt Handlers
;
* = HRESET     ; HRESET
RHRESET         CLC
                XCE
                JML BOOT

* = HCOP       ; HCOP
RHCOP           setaxl
                PHB
                PHD
                PHA
                PHX
                PHY
                JML BREAK

* = HBRK       ; HBRK  - Handle BRK interrupt
RHBRK           setaxl
                PHB
                PHD
                PHA
                PHX
                PHY
                JML BREAK

* = HABORT     ; HABORT
RHABORT         setaxl
                PHB
                PHD
                PHA
                PHX
                PHY
                JML BREAK

* = HNMI       ; HNMI
 RHNMI          setaxl
                PHB
                PHD
                PHA
                PHX
                PHY
                ;
                ; todo: look up IRQ triggered and do stuff
                ;
                JSL NMI_HANDLER
                PLY
                PLX
                PLA
                PLD
                PLB
                RTI

* = HIRQ       ; IRQ handler.
RHIRQ           setaxl
                PHB
                PHD
                PHA
                PHX
                PHY
                ;
                ; todo: look up IRQ triggered and do stuff
                ;
                JSL IRQ_HANDLER

                PLY
                PLX
                PLA
                PLD
                PLB
                RTI

;
; Interrupt Vectors
;
.if TARGET = TARGET_FLASH
* = VECTORS_BEGIN
JUMP_READY      JML IMREADY     ; Kernel READY routine. Rewrite this address to jump to a custom kernel.
RVECTOR_COP     .addr HCOP     ; FFE4
RVECTOR_BRK     .addr HBRK     ; FFE6
RVECTOR_ABORT   .addr HABORT   ; FFE8
RVECTOR_NMI     .addr HNMI     ; FFEA
                .word $0000    ; FFEC
RVECTOR_IRQ     .addr HIRQ    ; FFEE

RRETURN         JML IRETURN

RVECTOR_ECOP    .addr HCOP     ; FFF4
RVECTOR_EBRK    .addr HBRK     ; FFF6
RVECTOR_EABORT  .addr HABORT   ; FFF8
RVECTOR_ENMI    .addr HNMI     ; FFFA
RVECTOR_ERESET  .addr HRESET   ; FFFC
RVECTOR_EIRQ    .addr HIRQ     ; FFFE
.endif