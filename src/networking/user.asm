            .al
            .xl
            .autsiz

user        .namespace

            ; See this file for structs and docs.
            .include    "../Libraries/networking.asm"

nfunc       .macro  vector
            jsr     call
            rtl
            .word   <>\vector
            .endm

; Unless otherwise noted, all calls are mx agnostic and preserve all registers.

; Initialize the NIC, arp, and route tables.
; B:Y points to an ip_info structure containing the configuration.
; Carry set if no network card is found.
init    
            #nfunc  net.init

; Send a UDP packet 
; X points to the associated udp_info structure in bank0.
; On success, X->copied is set to the number of bytes sent.
; Carry set (bcs) on error (no route to host).
udp_send    
            #nfunc  net.udp_send

; Receive a UDP packet
; X points to a udp_info structure in bank0.
; On success, the udp_info structure and its buffer are updated.
; Z set (beq) if no packets are waiting to be processed.
udp_recv
            #nfunc  net.udp_recv


call
    ; Calls the address at (2,s) in 16/16 mode w/ D=X and B=K.
    ; Preserves all registers and modes.  The
    ; czvn flags are returned as the remote call
    ; left them.

        czvn = 1+2+64+128 

        rep     #czvn       ; Clear czvn
        php
        rep     #255-8      ; Clear all but i
        phy
        phx
        phd
        phb
        pha                 ; [a:b:d:x:y:p:rts:rtl]

      ; Set X to the rts value (two before the vector in bank k)
        lda     11,s        ; return vector
        tax

      ; Set D to the original X value
        lda     6,s         ; X (new D)
        tcd

        .byte   $fc,2,0   ; jsr (2,x), but the assembler won't let me...

      ; Propagate the czvn condition codes.
        php
        sep     #$20
        lda     1,s
        and     #czvn
        ora     11,s
        sta     11,s
        plp
        
        pla
        plb
        pld
        plx
        ply
        plp
        rts

.if 0
        .autsiz

test
          ; 16/16
            php
            rep     #$30

          ; Init the IP/ethernet stack.
            phk
            plb
            ldy     #<>_ip
            jsl     IP_INIT

_loop
            lda     #<>buffer
            sta @l  <>packet.buffer+0
            lda     #`buffer
            sta @l  <>packet.buffer+2
            lda     #10
            sta @l  <>packet.buflen

            ldx     #<>packet
            jsl     UDP_RECV
            bcs     _next
            beq     _next

            ldx     #1
            jsr     tick

          ; Return the payload to the sender.
            lda @l  <>packet.copied
            sta @l  <>packet.buflen
            ldx     #<>packet
            jsl     UDP_SEND
            
_next
            ldx     #0
            jsr     tick
            bra     _loop

            plb
            plp
            rts

_ip         .byte   192,168,1,229
            .byte   255,255,255,0
            .byte   192,168,1,1

            
            .virtual    $8000
packet      .dstruct    udp_info
            .endv
buffer      = $afa000
            
spin
            ldx     #0
            jsr     tick
            bra     spin
tick
            sep #$20
            lda     $afa000+80*4+20,x
            inc a
            sta     $afa000+80*4+20,x
            rep #$20
            rts
.endif
            .endn

