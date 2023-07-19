        .al
        .xl
        .autsiz

ip_check:
    ; X->buf
    
        ldy     #0  ; for now.
    ; Note: the size is checked in the lower level driver.

    ; Check the version and IHL.
        lda     pbuf.ipv4.ihl,x
        and     #255            ; little endian version/ihl
        cmp     #$45            ; Version 4, minimal header.
        bne     _bad

    ; Check the header checksum.
        jsr     compute_ip_checksum
        inc     a
        bne     _bad
        
    ; Check the TTL (at some point)
    ; Consider ICMP Time-Exceeded
        lda     pbuf.ipv4.ttl,x
        dec     a
        bit     #$ff
        beq     _bad
        sta     pbuf.ipv4.ttl,x
    
    ; Consider checking the dest address.
                
    ; Reject fragments.
        lda     pbuf.ipv4.flags,x
        and     #65536-$4000
        bne     _bad
        
    ; dispatch
        lda     pbuf.ipv4.proto,x
        and     #255
        
        cmp     #17
        beq     _udp
        
        cmp     #1
        beq     ip_icmp
        
_bad    jmp     pbuf_free_x
_udp    jmp     ip_udp


ip_icmp:
        lda     pbuf.ipv4.icmp.type,x
        and     #255
        cmp     #8
        bne     _drop

        jsr     compute_icmp_checksum
        inc     a
        beq     _good
_drop   jmp     pbuf_free_x

_good        

    ; Echo reply

        ; Change response to Echo Reply
        lda     pbuf.ipv4.icmp.type,x
        and     #$ff00
        sta     pbuf.ipv4.icmp.type,x
       
        ; Swap the source and dest IP addresses.
        jsr     swap_ip_addrs

        ; Recompute the checksums.
        jsr update_ip_checksum
        jsr update_icmp_checksum

        jsr swap_mac
        jmp hardware.lan9221.eth_packet_send


swap_ip_addrs

        lda     pbuf.ipv4.src+0,x
        pha
        lda     pbuf.ipv4.src+2,x
        pha
        
        lda     pbuf.ipv4.dest+0,x
        sta     pbuf.ipv4.src+0,x
        lda     pbuf.ipv4.dest+2,x
        sta     pbuf.ipv4.src+2,x

        pla
        sta     pbuf.ipv4.dest+2,x
        pla
        sta     pbuf.ipv4.dest+0,x
        
        rts

swap_mac
        phy

        lda     pbuf.eth.s_mac+0,x
        tay
        lda     pbuf.eth.d_mac+0,x
        sta     pbuf.eth.s_mac+0,x
        tya
        sta     pbuf.eth.d_mac+0,x

        lda     pbuf.eth.s_mac+2,x
        tay
        lda     pbuf.eth.d_mac+2,x
        sta     pbuf.eth.s_mac+2,x
        tya
        sta     pbuf.eth.d_mac+2,x

        lda     pbuf.eth.s_mac+4,x
        tay
        lda     pbuf.eth.d_mac+4,x
        sta     pbuf.eth.s_mac+4,x
        tya
        sta     pbuf.eth.d_mac+4,x

        ply
        rts

compute_ip_checksum:
        phy
        ldy     #ip_t.size      ; size of header
        lda     #0              ; starting from 0
        jsr     header_checksum
        ply
        rts

update_ip_checksum:
        lda     #0
        sta     pbuf.ipv4.check,x
        jsr     compute_ip_checksum
        eor     #$ffff
        xba
        sta     pbuf.ipv4.check,x
        rts
                
compute_icmp_checksum
        phy
        lda     pbuf.ipv4.len,x
        xba
        bit     #1
        beq     _check
        inc     a       ; driver ensures a trailing zero.
_check  sec
        sbc     #ip_t.size
        tay
        lda     #ip_t.size
        jsr     header_checksum
        ply
        rts

update_icmp_checksum:

    ; Clear the old checksum:
        lda     #0
        sta     pbuf.ipv4.icmp.check,x

        jsr     compute_icmp_checksum

        xba
        eor     #$ffff
        sta     pbuf.ipv4.icmp.check,x
        rts
                
header_checksum:
    ; X -> packet
    ; A := start relative to ipv4
    ; Y := count; on return, A = checksum

        phx
        clc
        adc     1,s
        tax        

        pea     #0
        clc
_loop   lda     pbuf.ipv4,x
        xba
        adc     1,s
        sta     1,s
        inx
        inx
        dey
        dey
        bne     _loop
        pla
        adc     #0
        
        plx
        rts

