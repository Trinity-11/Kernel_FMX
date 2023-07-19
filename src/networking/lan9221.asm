            .al
            .xl
            .mansiz

hardware    .namespace
lan9221     .namespace       

        ; On the FMX, U, and U+, the hardware glitches if the code
        ; accessing the NIC isn't in an even page.
        .align 512

        ; The seemingly strange need to reserve and preserve X comes
        ; from the fact that in the kernel from which this code is
        ; taken, X is reserved for the device descriptor pointer.

eth_read:
    ; IN: Y=Reg#
    ; OUT: Y:A = data
        phx
        tyx
        php
        sei
        lda @l  LAN + 2,x
        tay
        lda @l  LAN + 0,x
        plp
        plx        
        rts

eth_write:
    ; IN: TOS=register, Y:A = value
        phx
        pha                     ; MSB in y, LSB on stack.
        lda     7,s
        tax
        pla
        php
        sei
        sta @l  LAN + 0,x
        tya
        sta @l  LAN + 2,x
        plp      
        plx
        lda     1,s     ; load the return address
        sta     3,s     ; store it atop the register arg
        pla             ; drop the return address
        rts

rx_status:
    ; OUT: Y:A = RX fifo status
        php
        sei
        lda @l  LAN + hardware.lan9221.RX_STATUS_FIFO + 0
        tay
        lda @l  LAN + hardware.lan9221.RX_STATUS_FIFO + 2
        plp
        rts

copy_buffer
    ; OUT: A->received packet, X is unchanged (points to instance)
        phx
        jsr     kernel.net.pbuf_alloc_x

        ; If we're out of packets, pubf_alloc_x will return zero;
        ; There's an unused pbuf at zero, so we'll just read into it,
        ; effectively dropping the packet.  Would be nicer to tell
        ; the NIC to drop it, but this is fine for a simple, single
        ; threaded kernel.

        ; Get packet size
        jsr     rx_status   ; Already local
        and     #$3fff
        sta @l  kernel.net.pbuf.length,x
        
        ; Round up to total # of 32bit words for reading from the buffer.
        clc
        adc     #3
        lsr     a
        lsr     a
        clc
        tay
        phx
_loop   lda     LAN + hardware.lan9221.RX_DATA_FIFO + 0
        sta @l  kernel.net.pbuf.eth,x
        inx
        inx
        lda     LAN + hardware.lan9221.RX_DATA_FIFO + 2
        sta @l  kernel.net.pbuf.eth,x
        inx
        inx
        dey
        bne     _loop
        pla
        plx
        rts

send_buffer:
    ; X->packet buffer

        ; Send command "A"

        lda     kernel.net.pbuf.length,x
        ora     #4096+8192  ; first and last segment.
        sta     LAN + hardware.lan9221.TX_DATA_FIFO + 0
        
        lda     #0
        sta     LAN + hardware.lan9221.TX_DATA_FIFO + 2

        ; Send command "B"

        lda     kernel.net.pbuf.length,x
        sta     LAN + hardware.lan9221.TX_DATA_FIFO + 0
        
        lda     #0
        sta     LAN + hardware.lan9221.TX_DATA_FIFO + 2

        ; Send the bytes
        lda     kernel.net.pbuf.length,x
        clc
        adc     #3
        lsr     a
        lsr     a
        tay
        phx
_loop   lda     kernel.net.pbuf.eth,x
        sta     LAN + hardware.lan9221.TX_DATA_FIFO + 0
        inx
        inx
        lda     kernel.net.pbuf.eth,x
        sta     LAN + hardware.lan9221.TX_DATA_FIFO + 2
        inx
        inx
        dey
        bne     _loop
        plx     ; Packet

        rts


eth_open:
    ; should prolly wake by initializing the byte order
    
    ; Confirm that the device is "up".
    ; This should be on a timer.
    ; Docs say 100ms.
        jsr     eth_is_up
        bcs     _out

    ; Issue a soft reset.
        jsr     eth_reset

    ; Status check
        ldy     #ETH_ID_REV
        jsr     eth_read
        cmp     #$9221
        ; bne     _error
        
        ldy     #ETH_BYTE_TEST
        jsr     eth_read
        ; OPT check endian config
                
    ; Enable the socket LEDs
        ldy     #$7700  ; was 7000
        lda     #$0000
        pea     #ETH_GPIO_CFG
        jsr     eth_write

        jsr     set_mac

        ;jsr     get_phy_speed  ; Nowhere to report it...

        ldy     #$0010  ; full-duplex (broadcast on by default)
        lda     #$000c  ; rx+tx
        pea     #1  ; MAC CONTROL REGISTER
        jsr     mac_write

    ; Enable interrupts: GP Timer.
    ; Does NOT configure the hardware signal.
    ; We will poll the interrupt register.
        ldy     #$0008
        lda     #$0000
        pea     #ETH_INT_EN
        jsr     eth_write

    ; Enable and reset the general purpose timer
    ; This gives us a crude pollable timer which
    ; won't be used by any other code on the system.
        jsr     eth_timer_reset

    ; Enable the transmitter
        ldy     #0
        lda     #6  ; tx enabled, allow status overrun.
        pea     #ETH_TX_CFG
        jsr     eth_write

        clc
_out    rts
_err    sec
        jmp     _out

eth_tick:

      ; See if the GP timer has expired
        ldy     #ETH_INT_STS
        jsr     eth_read
        tya
        and     #$0008
        beq     _out

      ; clear the associated interrupt flag
        tay
        lda     #0
        pea     #ETH_INT_STS
        jsr     eth_write

      ; Reset the timer
        jsr     eth_timer_reset

_out    rts        

eth_timer_reset
        ldy     #$2000
        lda     #1000   ; 100ms
        pea     #ETH_GPT_CFG
        jsr     eth_write
        rts

eth_reset:
        ldy     #$0000
        lda     #$0001
        pea     #ETH_HW_CFG
        jsr     eth_write
        jmp     eth_is_up

eth_is_up:
        ; This code originally used a kernel service to yield
        ; while waiting; since X is no longer used as a device
        ; descriptor pointer, we use it here as a retry counter.
        ldx     #100    ; ms ish
_loop   ldy     #ETH_PMT_CTRL
        jsr     eth_read
        and     #1
        beq     _retry
        clc
_out    rts
_retry  sec
        dex
        beq     _out
        lda     #10000
_delay  nop
        nop
        nop
        nop
        dec     a
        bne     _delay        
        jmp     _loop

eth_packet_send
    ; Packet base in X
    
        jsr     send_buffer
        jmp     kernel.net.pbuf_free_x

eth_packet_recv
    ; Packet base in A; zero if no packets can be read.
    ; Either b/c nothing has come in, or b/c there are
    ; no free packet buffers available.
    
        jsr     get_rx_count
        beq     _done
        jsr     copy_buffer 
_done   rts

get_rx_count
        ldy     #ETH_RX_FIFO_INF
        jsr     eth_read
        tya
        and     #$ff
        rts

set_mac:
        ldy     #0
        lda     kernel.net.conf.eth_mac+4
        pea     #ETH_MAC_ADDRH
        jsr     mac_write
        
        lda     kernel.net.conf.eth_mac+2
        tay
        lda     kernel.net.conf.eth_mac+0
        pea     #ETH_MAC_ADDRL
        jsr     mac_write
        rts


ETH_PHY_SPECIAL = 31

get_phy_speed:
        ldy     #ETH_PHY_SPECIAL
        jsr     phy_read
        lsr     a
        lsr     a
        clc
        and     #7
        rts

phy_read:
    ; IN: X = struct, Y=register
    ; OUT: Y:A = data

        jsr     phy_wait

        tya
        ldy     #0              ; MSB
        and     #31
        xba
        lsr     a
        lsr     a
        ora     #2049           ; LSB: PHY #1 + MIIBZY

        pea     #ETH_MAC_MII_ACC
        jsr     mac_write       ; Request the read.
        
        jsr     phy_wait        ; Data should now be in MAC's MII_DATA.
        
        ldy     #ETH_MAC_MII_DATA
        jmp     mac_read
        
phy_wait:
        phy
_loop   ldy     #ETH_MAC_MII_ACC
        jsr     mac_read
        and     #1
        bne     _loop
        ply
        rts

mac_read:
    ; IN: Y = register
    ; OUT: Y:A = value

    ; Write the transfer address and begin the transfer
        tya             ; Register.
        ldy     #$c000  ; Read operation.
        pea     #ETH_MAC_CSR_CMD
        jsr     eth_write

    ; Wait for the operation to complete.
        jsr     mac_wait

    ; Collect the results
        ldy     #ETH_MAC_CSR_DATA
        jmp     eth_read

mac_write:
    ; IN: TOS = MAC register, Y:A = value
    ; OUT: A,Y trashed.

    ; Write the value to send (in Y:A) to the MAC
        pea     #ETH_MAC_CSR_DATA
        jsr     eth_write

    ; Initiate the transfer
        lda     3,s     ; Register to write
        ldy     #$8000  ; Write operation
        pea     #ETH_MAC_CSR_CMD
        jsr     eth_write

    ; Nip the arg word on the stack
        lda     1,s
        sta     3,s
        pla

    ; Return when the transfer has completed.
        jmp     mac_wait        

mac_wait:
_loop   ldy     #ETH_MAC_CSR_CMD
        jsr     eth_read
        cpy     #$8000
        bpl     _loop
        rts        

RX_DATA_FIFO    = $00   ; Through $1f
TX_DATA_FIFO    = $20   ; Through $3f

RX_STATUS_FIFO  = $40
TX_STATIS_FIFO  = $48

ETH_ID_REV      = $50
ETH_IRQ_CFG     = $54
ETH_INT_STS     = $58
ETH_INT_EN      = $5c
;RESERVED       = $60
ETH_BYTE_TEST   = $64
ETH_FIFO_INT    = $68
ETH_RX_CFG      = $6c
ETH_TX_CFG      = $70
ETH_HW_CFG      = $74
ETH_RX_DP_CTL   = $78
ETH_RX_FIFO_INF = $7c
ETH_TX_FIFO_INF = $80
ETH_PMT_CTRL    = $84
ETH_GPIO_CFG    = $88
ETH_GPT_CFG     = $8c
ETH_GPT_CNT     = $90
;RESERVED       = $94
ETH_WORD_SWAP   = $98
ETH_FREE_RUN    = $9c
ETH_RX_DROP     = $a0
ETH_MAC_CSR_CMD = $a4
ETH_MAC_CSR_DATA= $a8
ETH_AFC_CFG     = $ac
ETH_E2P_CMD     = $b0
ETH_E2P_DATA    = $b4
;RESERVED       = $b8 - $fc

ETH_MAC_MAC_CR  = $1
ETH_MAC_ADDRH   = $2
ETH_MAC_ADDRL   = $3
ETH_MAC_HASHH   = $4
ETH_MAC_HASHL   = $5
ETH_MAC_MII_ACC = $6
ETH_MAC_MII_DATA= $7
ETH_MAC_FLOW    = $8
ETH_MAC_VLAN1   = $9
ETH_MAC_VLAN2   = $a
ETH_MAC_WUFF    = $b
ETH_MAC_WUCSR   = $c
ETH_MAC_COE_CR  = $d
ETH_MAC_MAX     = $e

        .endn
        .endn
