;
; Simulator commands
;  These use the WDM opcode. Execute WDM, followed by this number to perform a
;  simulator action.
;

; Yeild the thread and wait for a keypress or interrupt. 
; The simulator will resume operating instructions when 
; a key is pressed or an interrupt is sent.
sim_wait        .macro
                .byte $42, $00
                .endm

                
; Tell the simulator the screen needs to be refreshed.           
; this will cause the screen to be redrawn on the next screen           
; update, rather than waiting for a cursor blink.          
sim_refresh     .macro
                .byte $42, $01
                .endm