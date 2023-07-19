        .al
        .xl
        .autsiz

ip_udp
        jsr     udp_checksum
        inc     a
        bne     _done
        jmp     rx_enqueue
_done   jmp     pbuf_free_x

        
update_udp_checksum
        lda     #0
        sta     pbuf.ipv4.udp.check,x
        jsr     udp_checksum
        eor     #$ffff
        xba
        sta     pbuf.ipv4.udp.check,x
        rts

udp_checksum
        phy

      ; Make sure the last byte is zero
      ; Should move to the ip layer.
        phx
        lda     pbuf.ipv4.len,x
        xba
        clc
        adc     1,s
        tax
        lda     #0
        sta     pbuf.ipv4,x
        plx

        ; Compute size of UDP header + data.
        lda     pbuf.ipv4.len,x
        xba
        sec
        sbc     #ip_t.size
        pha                 ; Save for pseudo-header.
        bit     #1
        beq     _aligned
        inc     a
_aligned

        ; Compute the initial checksum, result in A.
        tay
        lda     #ip_t.size
        jsr     header_checksum
        
        ; Add in "UDP Length" from the pseudo-header
        clc
        adc     1,s
        sta     1,s
        
        ; Add in the protocol.
        lda     pbuf.ipv4.proto,x
        and     #$ff
        adc     1,s
        sta     1,s
        
        ; Add in the source address.
        lda     pbuf.ipv4.src+0,x
        jsr     _sum
        lda     pbuf.ipv4.src+2,x
        jsr     _sum
        
        ; Add in the destination address.
        lda     pbuf.ipv4.dest+0,x
        jsr     _sum
        lda     pbuf.ipv4.dest+2,x
        jsr     _sum
        
        ; Complete the one's complement
        pla
        adc     #0
        
        ply
        rts

_sum    xba
        adc     3,s
        sta     3,s
        rts

udp_make:
    ; D->kernel.net.user.udp_info

        jsr     pbuf_alloc_x
        bne     _fill
        sec
        rts
    
_fill
        lda     #$45                ; Version=4, IHL=5, TOS=0
        sta     pbuf.ipv4.ihl,x 
        ; Total length TBD
        lda     #0                  ; Frag ID=0 (no fragmentation)
        sta     pbuf.ipv4.id,x
        lda     #$40                ; May fragment
        sta     pbuf.ipv4.flags,x
        lda     #$1140              ; Protocol=UDP, TTL=$40
        sta     pbuf.ipv4.ttl,x

        ; Copy source address
        lda     conf.ip_addr+0
        sta     pbuf.ipv4.src+0,x
        lda     conf.ip_addr+2
        sta     pbuf.ipv4.src+2,x

        ; Copy dest address
        lda     user.udp_info.remote_ip+0,d
        sta     pbuf.ipv4.dest+0,x
        lda     user.udp_info.remote_ip+2,d
        sta     pbuf.ipv4.dest+2,x

      ; Copy the source and dest ports
        lda     user.udp_info.local_port,d
        xba
        sta     pbuf.ipv4.udp.sport,x
        lda     user.udp_info.remote_port,d
        xba
        sta     pbuf.ipv4.udp.dport,x
        
      ; Copy the data
        jsr     copy_msg_data
        
      ; Set the UDP length
        lda     user.udp_info.buflen,d
        cmp     #1500 - eth_t.ipv4.udp.size ; Max data size
        bcc     _size
        lda     #1500 - eth_t.ipv4.udp.size ; limit to max data size
_size   sta     user.udp_info.copied,d        

        clc
        adc     #udp_t.size
        xba
        sta     pbuf.ipv4.udp.length,x
        xba
        
      ; Set the IP length
        clc
        adc     #ip_t.size
        xba
        sta     pbuf.ipv4.len,x

      ; Update the checksums
        jsr     update_udp_checksum
        jsr     update_ip_checksum

        rts

copy_msg_data
        ldy     #0
        phx
_loop   cpy     user.udp_info.copied,d
        bcs     _done
        lda     [user.udp_info.buffer],y
        sta     kernel.net.pbuf.ipv4.udp.data,x
        inx
        inx
        iny
        iny
        jmp     _loop
_done   plx
        rts

