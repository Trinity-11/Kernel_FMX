; Set 8-bit accumulator
setaxs          .macro
                SEP #$30        ; set A&X short
                .as
                .xs 
                .endm
                
; Set 16-bit accumulator
setaxl          .macro
                REP #$30        ; set A&X long 
                .al
                .xl
                .endm

; Set 8-bit accumulator
setas           .macro
                SEP #$20        ; set A short 
                .as
                .endm
                
; Set 16-bit accumulator
setal           .macro
                REP #$20        ; set A long 
                .al
                .endm

; Set 8 bit index registers               
setxs           .macro
                SEP #$10        ; set X short 
                .xs
                .endm
                
; Set 16-bit index registers
setxl           .macro
                REP #$10        ; set X long 
                .xl
                .endm

; Set the direct page. 
; Note: This uses the accumulator and leaves A set to 16 bits. 
setdp           .macro
                PEA #\1         ; set DP to page 0
                PLD             
                .dpage \1
                .endm 

setdbr          .macro          ; Set the B (Data bank) register 
                PEA #((\1) * 256) + (\1)
                PLB
                PLB
                .databank \1
                .endm 

TRACE           .macro message
;                 PHA
;                 PHX
;                 PHY
;                 PEA #`txt_message
;                 PEA #<>txt_message
;                 JSL ITRACE
;                 BRA continue

; txt_message     .null 13,\message

; continue        PLY
;                 PLX
;                 PLA
                .endm