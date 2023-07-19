            .al
            .xl
            .autsiz

arp         .namespace

recv
    ; X->packet; packet is ultimately dropped.

      ; Only IPv4 ARPs; IPv6 uses NDP.
      
        lda     pbuf.eth.arp.htype,x
        xba
        cmp     #$0001  ; Ethernet
        bne     _drop
        
        lda     pbuf.eth.arp.ptype,x
        xba
        cmp     #$0800  ; IPv4
        bne     _drop
        
        lda     pbuf.eth.arp.hlen,x ; and plen
        xba
        cmp     #$0604  ; 6 ether, 4 ip
        bne     _drop

      ; Dispatch based on operation and contents
      
        lda     pbuf.eth.arp.oper,x
        xba

        cmp     #$0002      ; reply
        beq     _record
        
        cmp     #$0001      ; request or broadcast
        bne     _drop       ; Invalid arp packet

        lda     kernel.net.pbuf.eth.arp.tpa+0,x 
        eor     kernel.net.pbuf.eth.arp.spa+0,x 
        bne     _request    ; not a broadcast

        lda     kernel.net.pbuf.eth.arp.tpa+2,x 
        eor     kernel.net.pbuf.eth.arp.spa+2,x 
        bne     _request    ; not a broadcast

        ; Broadcast; fall-through to record.

_record 
        jsr     cache_arp_reply
_drop   jmp     kernel.net.pbuf_free_x

_request

      ; Just need to know if this is for us
        lda     kernel.net.pbuf.eth.arp.tpa+0,x
        eor     kernel.net.conf.ip_addr+0
        bne     _drop
        lda     kernel.net.pbuf.eth.arp.tpa+2,x
        eor     kernel.net.conf.ip_addr+2
        bne     _drop

        jsr     arp_reply
        jmp     hardware.lan9221.eth_packet_send
        

arp_request
    ; Y->route entry

        jsr     kernel.net.pbuf_alloc_x
        bne     _good
        rts

_good   lda     #$ffff
        sta     kernel.net.pbuf.eth.d_mac+0,x
        sta     kernel.net.pbuf.eth.d_mac+2,x
        sta     kernel.net.pbuf.eth.d_mac+4,x

        lda     #$0806  ; ARP packet
        xba
        sta     kernel.net.pbuf.eth.type,x

        lda     #1      ; ethernet request
        xba
        sta     kernel.net.pbuf.eth.arp.htype,x

        lda     #$0800  ; ethernet IPv4 type
        xba
        sta     kernel.net.pbuf.eth.arp.ptype,x

        lda     #$0604      ; 6-byte hardware address (MAC)
        xba                 ; 4-byte protocol address (IPv4)
        sta     kernel.net.pbuf.eth.arp.hlen,x
        
        lda     #1      ; ARP request
        xba
        sta     kernel.net.pbuf.eth.arp.oper,x

      ; Broadcast the ARP request
        lda     #$ffff
        sta     kernel.net.pbuf.eth.d_mac+0,x
        sta     kernel.net.pbuf.eth.d_mac+2,x
        sta     kernel.net.pbuf.eth.d_mac+4,x

        lda     kernel.net.conf.eth_mac+0
        sta     kernel.net.pbuf.eth.arp.sha+0,x
        sta     kernel.net.pbuf.eth.s_mac+0,x
        lda     kernel.net.conf.eth_mac+2
        sta     kernel.net.pbuf.eth.arp.sha+2,x
        sta     kernel.net.pbuf.eth.s_mac+2,x
        lda     kernel.net.conf.eth_mac+4
        sta     kernel.net.pbuf.eth.arp.sha+4,x
        sta     kernel.net.pbuf.eth.s_mac+4,x

        lda     kernel.net.conf.ip_addr+0
        sta     kernel.net.pbuf.eth.arp.spa+0,x
        lda     kernel.net.conf.ip_addr+2
        sta     kernel.net.pbuf.eth.arp.spa+2,x

        lda     entry.ip+0,b,y
        sta     kernel.net.pbuf.eth.arp.tpa+0,x
        lda     entry.ip+2,b,y
        sta     kernel.net.pbuf.eth.arp.tpa+2,x

        lda     #eth_t.arp.size
        sta     kernel.net.pbuf.length,x

        jmp     hardware.lan9221.eth_packet_send

arp_reply
    ; Converts an ARP request to an ARP response.
    ; X -> ARP request packet

      ; Set operation to "reply"
        lda     #$0002
        xba
        sta     pbuf.eth.arp.oper,x

      ; Copy source MAC to dest MAC
        lda     pbuf.eth.s_mac+0,x
        sta     pbuf.eth.d_mac+0,x
        sta     pbuf.eth.arp.tha+0,x    

        lda     pbuf.eth.s_mac+2,x
        sta     pbuf.eth.d_mac+2,x
        sta     pbuf.eth.arp.tha+2,x    

        lda     pbuf.eth.s_mac+4,x
        sta     pbuf.eth.d_mac+4,x
        sta     pbuf.eth.arp.tha+4,x 
        
      ; swap source IP with dest IP
        jsr     swap_ip

      ; Insert our source MAC
        lda     kernel.net.conf.eth_mac+0
        sta     pbuf.eth.arp.sha+0,x        
        sta     pbuf.eth.s_mac+0,x
       
        lda     kernel.net.conf.eth_mac+2
        sta     pbuf.eth.arp.sha+2,x        
        sta     pbuf.eth.s_mac+2,x
       
        lda     kernel.net.conf.eth_mac+4
        sta     pbuf.eth.arp.sha+4,x        
        sta     pbuf.eth.s_mac+4,x
       
        rts

swap_ip
        phy

        lda     pbuf.eth.arp.spa+0,x
        tay
        lda     pbuf.eth.arp.tpa+0,x
        sta     pbuf.eth.arp.spa+0,x
        tya
        sta     pbuf.eth.arp.tpa+0,x

        lda     pbuf.eth.arp.spa+2,x
        tay
        lda     pbuf.eth.arp.tpa+2,x
        sta     pbuf.eth.arp.spa+2,x
        tya
        sta     pbuf.eth.arp.tpa+2,x

        ply
        rts


entry   .struct
ip      .fill   4
mac     .fill   6
pending .word   ?
last    .word   ?
size    .ends

count   .word   0
entries .fill   8*entry.size,0
entries_end
target  .fill   4

cache_arp_reply
    ; Create a dummy IP packet that looks like it came from
    ; a machine with the given ARP stats, then call cache_ip.
    
      ; Copy the IP (into dummy packet x=0)
        lda     kernel.net.pbuf.eth.arp.spa+0,x
        sta     kernel.net.pbuf.ipv4.src+0
        lda     kernel.net.pbuf.eth.arp.spa+2,x
        sta     kernel.net.pbuf.ipv4.src+2

      ; Copy the MAC (into dummy packet x=0)
        lda     kernel.net.pbuf.eth.arp.sha+0,x
        sta     kernel.net.pbuf.eth.s_mac+0
        lda     kernel.net.pbuf.eth.arp.sha+2,x
        sta     kernel.net.pbuf.eth.s_mac+2
        lda     kernel.net.pbuf.eth.arp.sha+4,x
        sta     kernel.net.pbuf.eth.s_mac+4

        phx
        ldx     #0
        jsr     cache_ip
        plx
        rts

cache_ip
    ; Insert or update an arp entry for a
    ; local sender of the IP packet in X.

      ; Search for the src ip
        lda     kernel.net.pbuf.ipv4.src+0,x
        sta     target+0
        lda     kernel.net.pbuf.ipv4.src+2,x
        sta     target+2

        jsr     find
        bcc     _update         ; Found; update MAC.

        jsr     find_oldest     ; Not found, make new entry.

      ; Copy the sender's IP address
        lda     kernel.net.pbuf.ipv4.src+0,x
        sta     entry.ip+0,b,y
        lda     kernel.net.pbuf.ipv4.src+2,x
        sta     entry.ip+2,b,y

_update
      ; Copy the MAC
        lda     kernel.net.pbuf.eth.s_mac+0,x
        sta     entry.mac+0,b,y
        lda     kernel.net.pbuf.eth.s_mac+2,x
        sta     entry.mac+2,b,y
        lda     kernel.net.pbuf.eth.s_mac+4,x
        sta     entry.mac+4,b,y
        
        lda     #0
        sta     entry.pending,b,y

        jsr     touch
_out    rts


touch
      ; Update stats.
        lda     kernel.net.conf.ticks
        sta     entry.last,b,y
        rts

local:
    ; IN: X->packet
    ; OUT: NZ if the dest ip is non-local
    
        lda     kernel.net.pbuf.ipv4.dest+2,x
        eor     kernel.net.conf.ip_addr+2
        and     kernel.net.conf.ip_mask+2
        bne     _out
        
        lda     kernel.net.pbuf.ipv4.dest+0,x
        eor     kernel.net.conf.ip_addr+0
        and     kernel.net.conf.ip_mask+0

_out    rts

bind:
    ; IN: X->packet to send

      ; Check for broadcasts
        lda     kernel.net.pbuf.ipv4.dest+2,x
        eor     kernel.net.conf.broadcast+2
        bne     _lookup
        lda     kernel.net.pbuf.ipv4.dest+0,x
        eor     kernel.net.conf.broadcast+0
        bne     _lookup

      ; Broadcast packets use the broadcast MAC
        lda     #$ffff
        sta     kernel.net.pbuf.eth.d_mac+0,x
        sta     kernel.net.pbuf.eth.d_mac+2,x
        sta     kernel.net.pbuf.eth.d_mac+4,x
        jmp     _finish

_lookup

      ; Send to router?
        jsr     local
        bne     _router

      ; Local; search for the mac of the dest ip
        lda     kernel.net.pbuf.ipv4.dest+0,x
        sta     target+0
        lda     kernel.net.pbuf.ipv4.dest+2,x
        sta     target+2
        jmp     _find
        
_router
      ; Search for the mac of the router
        lda     kernel.net.conf.default+2
        cmp     #$0100
        bcc     _fail   ; No default route
        sta     target+2
        lda     kernel.net.conf.default+0
        sta     target+0

_find   
        jsr     find
        bcs     _arp
        
        lda     entry.pending,b,y
        beq     _found
        jmp     _retry

_found
        lda     entry.mac+0,b,y
        sta     kernel.net.pbuf.eth.d_mac+0,x
        lda     entry.mac+2,b,y
        sta     kernel.net.pbuf.eth.d_mac+2,x
        lda     entry.mac+4,b,y
        sta     kernel.net.pbuf.eth.d_mac+4,x

        jsr     touch   ; Keep this arp entry :).

_finish

      ; Set the ethernet frame type to ipv4
        lda     #$0800
        xba
        sta     kernel.net.pbuf.eth.type+0,x
        
      ; Set the packet's source MAC to our MAC.
        lda     kernel.net.conf.eth_mac+0
        sta     kernel.net.pbuf.eth.s_mac+0,x
        lda     kernel.net.conf.eth_mac+2
        sta     kernel.net.pbuf.eth.s_mac+2,x
        lda     kernel.net.conf.eth_mac+4
        sta     kernel.net.pbuf.eth.s_mac+4,x

      ; Set the raw (ethernet) packet length
        lda     pbuf.ipv4.len,x
        xba
        clc
        adc     #eth_t.size
        sta     pbuf.length,x

      ; Return success
        clc
        rts

_fail   sec
        rts

_retry  lda     kernel.net.conf.ticks
        sec
        sbc     entry.last,b,y
        cmp     #5
        bcc     _fail    ; Too soon.
        jmp     _request

_arp
        jsr     find_oldest
        lda     target+0
        sta     entry.ip+0,b,y
        lda     target+2
        sta     entry.ip+2,b,y
        lda     #1
        sta     entry.pending,b,y
        lda     kernel.net.conf.ticks
        sta     entry.last,b,y

_request
        jsr     arp_request
        jsr     touch
        jmp     _fail

find:
    ; Searches the arp table for an entry matching the packet's dest ip.
    ; IN: X->packet, OUT: Y->entry
    ; Carry clear on success
        ldy     #<>entries
_loop   cpy     #<>entries_end
        beq     _none
        jsr     compare
        beq     _done
        tya
        clc
        adc     #entry.size
        tay
        jmp     _loop
_none   sec
        rts
_done   lda     kernel.net.conf.ticks
        sta     entry.last,b,y
        clc
        rts

compare:
    ; Compares the packet's dest ip to the arp entry's ip
    ; X -> packet, Y -> arp entry
    ; Z set if the entries match.
        lda     target+0
        eor     entry.ip+0,b,y
        bne     _done
        lda     target+2
        eor     entry.ip+2,b,y
_done   rts



find_oldest:
    ; Finds the next "free" arp entry, where free means
    ; either "unused" or "oldest".
    ; OUT: y->entry
        phx
        pea     #0              ; Max age
        ldy     #<>entries
        tyx
_loop   lda     entry.ip+0,b,y  ; Empty is free.
        beq     _done

        lda     kernel.net.conf.ticks
        sec
        sbc     entry.last,b,y  ; Age of this entry in A. 
        cmp     1,s
        bcc     _next
        tyx                     ; X = new oldest
        
_next   tya
        clc
        adc     #entry.size
        tay
        cpy     #<>entries_end
        bne     _loop
        txy                     ; Y = X = oldest

_done   pla                     ; Max age
        plx                     ; Original
        rts

        .endn
