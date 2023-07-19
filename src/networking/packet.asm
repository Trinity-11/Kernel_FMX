            .al
            .xl
            .autsiz



udp_t   .struct
sport   .word   ?
dport   .word   ?
length  .word   ?
check   .word   ?
data
size    .ends

icmp_t  .struct
type    .byte   ?
code    .byte   ?
check   .fill   2
ident   .word   ?
seq     .fill   2
        .ends

ip_t    .struct
ihl     .fill   1
tos     .byte   ?
len     .fill   2
id      .fill   2
flags   .fill   2
ttl     .byte   ?
proto   .byte   ?
check   .fill   2
src     .fill   4
dest    .fill   4
size
        .union
          .struct
sport       .word   ?
dport       .word   ?
          .ends
udp       .dstruct    udp_t
icmp      .dstruct    icmp_t
        .endu
        .ends

arp_t   .struct
htype   .word   ?
ptype   .word   ?
hlen    .byte   ?
plen    .byte   ?
oper    .word   ?
sha     .fill   6
spa     .fill   4
tha     .fill   6
tpa     .fill   4
size    .ends

eth_t   .struct
d_mac   .fill   6
s_mac   .fill   6
type    .word   ?
size
        .union
arp         .dstruct  arp_t
ipv4        .dstruct  ip_t
        .endu
        .ends

pbuf_t  .struct
stack
deque   .dstruct lib.deque_t
length  .word   ?
        .union
eth     .dstruct eth_t
        .struct
        .fill       14      ; ethernet header
ipv4    .dstruct    ip_t
        .ends
        .endu
        .ends

        .virtual    PACKETS
pbuf    .dstruct    pbuf_t
        .endv

pbufs   .word   0   ; Free-pbufs stack.

pbuf_init
        jsr     pbank_init
    ; Free all of the pbufs in the packet bank. 
        clc
        lda     #2048       ; 1st 2k normally reserved for socket descriptors...
_loop   tax
        jsr     pbuf_free_x
        txa
        adc     #2048
        bne     _loop
_done   rts        

pbank_init
      ; Zero the packet bank.
        lda     #0
        sta     @l PACKETS
        tax
        tay
        iny
        dec     a
        phb
        mvn     `PACKETS,`PACKETS
        plb
        rts
        
pbuf_alloc_x:
        php
        sei
        ldx     <>pbufs,b
        beq     _done
        lda     pbuf.stack,x
        sta     <>pbufs,b
_done   plp
        txa
        rts        
        
pbuf_free_x:
        php
        sei
        lda     <>pbufs,b
        sta     pbuf.stack,x
        stx     <>pbufs,b
        plp
        rts
      
