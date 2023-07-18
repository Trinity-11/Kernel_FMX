            .al
            .xl
            .autsiz

lib         .namespace
            .endn
            .include    "lib_deque.asm"

            .include    "lan9221.asm"

kernel      .namespace
net         .namespace

            .include    "user.asm"
            .include    "packet.asm"
            .include    "arp.asm"
            .include    "net_ip.asm"
            .include    "net_udp.asm"


conf        .namespace
init        .word   0   ; NZ if init has succeeded
eth_mac     .byte   $c2 ; NIC's MAC prefix; the rest is the IP address.
            .byte   $56 ; c2:56: just happens to be a "local assignment" prefix :).
ip_addr     .fill   4   ; Local IP address, MUST IMMEDIATELY FOLLOW THE MAC!
ip_mask     .fill   4   ; Local netmask
broadcast   .fill   4   ; Broadcast address
default     .dword  0   ; Default route (0 = local only)
ticks       .word   0   ; virtual timer
            .endn
        
cp_ip       .macro  src, dest
            lda     0+\src,y
            sta @l  0+\dest
            lda     2+\src,y
            sta @l  2+\dest
            .endm

init
            lda     HAS_ETHERNET
            bne     _init
            sec
            rts
_init            
          ; Shouldn't be needed.
            lda     #0
            sta     rx_queue+0
            sta     rx_queue+2

            #cp_ip  user.ip_info.ip,        conf.ip_addr
            #cp_ip  user.ip_info.mask,      conf.ip_mask
            #cp_ip  user.ip_info.default,   conf.default

          ; Compute the broadcast address
            lda     conf.ip_mask+0
            eor     #$ffff
            ora     conf.ip_addr+0
            sta     conf.broadcast+0
            lda     conf.ip_mask+2
            eor     #$ffff
            ora     conf.ip_addr+2
            sta     conf.broadcast+2

            phk
            plb
            jsr     pbuf_init
            jsr     hardware.lan9221.eth_open

            lda     #1
            sta     conf.init
            clc
            rts

rx_queue    .dstruct    lib.deque_t

rx_enqueue
        #lib.deque_enque rx_queue, x, kernel.net.pbuf.deque, @l
        rts 

packet_recv    
    ; Read and process packets from the lan until its queue is empty.

_loop   jsr     hardware.lan9221.eth_tick   ; NZ if the 100ms timer has reset.
        beq     _recv
        lda     conf.ticks
        inc     a
        sta     conf.ticks

_recv   jsr     hardware.lan9221.eth_packet_recv
        tax
        beq     _done

        lda     pbuf.eth.type,x
        xba

        cmp     #$0800
        beq     _ipv4

        cmp     #$0806
        beq     _arp

        jsr     kernel.net.pbuf_free_x  ; We don't handle anything else.
        jmp     _loop
        
_arp    jsr     arp.recv
        jmp     _loop

_ipv4   jsr     ip_check
        jmp     _loop

_done   rts


udp_send
    ; IN: X -> udp_info in bank 0
    ; On success: carry clear and all registers preserved
    ; On failure: carry set, A=error, X and Y preserved

            lda     conf.init
            beq     _error

            phk
            plb

          ; Drain the NIC's queue
            jsr     packet_recv

          ; Construct the packet
          ; Could check for valid routing /first/, but meh.
            jsr     udp_make
            bcs     _out

          ; Forward self-addressed packets directly to ip_check.
            lda     pbuf.ipv4.dest+0,x
            cmp     conf.ip_addr+0
            bne     _extern
            lda     pbuf.ipv4.dest+2,x
            cmp     conf.ip_addr+2
            bne     _extern
            jsr     ip_check
            bra     _done

          ; Bind the ethernet 
_extern     jsr     arp.bind
            bcs     _fail

            jsr     hardware.lan9221.eth_packet_send
_done       clc
_out        rts        

_fail       jsr     kernel.net.pbuf_free_x
_error      sec
            rts


udp_recv
    ; IN: D -> udp_info in bank 0
    ; If a packet is available, Z is clear (bne)
    ; If no packets were available, Z is set (beq)
    ; Carry set on error (uninitialized); clear otherwise.

            lda     conf.init
            bne     _recv
            lda     #0
            sec
            rts

_recv
            phk
            plb
            
          ; Drain the NIC's queue
            jsr     packet_recv

            stz     user.udp_info.copied,d

          ; See if any UDP packets are available
            #lib.deque_deque rx_queue, x, kernel.net.pbuf.deque, @l
            beq     _out

          ; Update our ARP cache with the mac of the source
            jsr     arp.cache_ip

          ; Copy the data out of the packet
            lda     pbuf.ipv4.src+0,x
            sta     user.udp_info.remote_ip,d
            lda     pbuf.ipv4.src+2,x
            sta     user.udp_info.remote_ip+2,d
            
            lda     pbuf.ipv4.udp.sport,x
            xba
            sta     user.udp_info.remote_port,d
            
            lda     pbuf.ipv4.udp.dport,x
            xba
            sta     user.udp_info.local_port,d
            
          ; Determine the copy size
            lda     pbuf.ipv4.udp.length,x
            xba
            sec
            sbc     #udp_t.size
            cmp     user.udp_info.buflen,d
            bcc     _length
            beq     _length
            lda     user.udp_info.buflen,d    ; Limit copy to buflen.
_length     sta     user.udp_info.copied,d    ; copied = # of bytes to copy    
 
            phx

          ; Set Y->user buffer offset
            ldy     #0
    
          ; Copy the data
            lsr     a
            bcc     _even
    
          ; Odd length, copy exactly one byte.
_odd        sep     #$20
            lda     pbuf.ipv4.udp.data,x
            sta     [user.udp_info.buffer],y
            inx
            iny
            rep     #$20
            jmp     _next
    
_even       lda     pbuf.ipv4.udp.data,x
            sta     [user.udp_info.buffer],y
            inx
            inx
            iny
            iny
_next       cpy     user.udp_info.copied,d
            bne     _even
    
            plx
            jsr     kernel.net.pbuf_free_x
            txa     ; Set the NZ condition code.
    
_out
            clc
            rts

.if 0
            .autsiz
tick_reset
    sep #$20
    pha
    lda #'0'
    sta $afa010
    pla
    rep #$20
    rts

tick
    sep #$20
    pha
    lda $afa010
    inc a
    sta $afa010
    pla
    rep #$20
    rts


dump_args
 pha
 phy
 ldy #0
 jsr print_hex_word
 ldy #5
 lda user.udp_info.buflen,d
 jsr print_hex_word
 ldy #10
 lda user.udp_info.buffer+0,d
 jsr print_hex_word
 ldy #14
 lda user.udp_info.buffer+2,d
 jsr print_hex_word
 ply
 pla
 rts

print_hex_word:
            pha
            xba
            jsr     print_hex_byte
            lda     1,s
            jsr     print_hex_byte
            pla
            rts
            
print_hex_byte
            pha
            lsr     a
            lsr     a
            lsr     a
            lsr     a
            jsr     print_hex_nibble
            pla
            jmp     print_hex_nibble
            
print_hex_nibble
            and     #$0f
            phx
            tax
            lda     _tab,x
            tyx
            and     #$ff
            ora     #$2000
            sta     $afa000,x
            iny
            plx
            rts
_tab        .null   "0123456789ABCDEF"            


.endif
            .endn
            .endn

