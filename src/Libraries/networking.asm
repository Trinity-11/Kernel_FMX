; Networking support includes three functions and two structures below.
; All networking kernel calls are processor mode agnostic, return status 
; in the condition codes, and leave all other registers unchanged. The
; calls are neither re-entrant nor thread-safe; don't attempt to call
; any of them concurrently.

; The stack will respond to pings (ICMP ECHO requests), but only so long
; as UDP_SEND and/or UDP_RECV is being called regularly.  The stack does
; nothing in the background and does not use interrupts.  The ARP timer
; works by polling the NIC's internal timer-expired flag.
; 
; IP_INIT
;   IN:     B:Y->ip_info (below)
;   OUT:    Carry set on error (ethernet card not found or won't init)
;   NOTES:  A default route in the 0.x.x.x range is formally unroutable.
;
; UDP_SEND
;   IN:     0:X->udp_info (below)
;   OUT:    Carry set on error (not initialized, no route to host, EOM)
;   NOTES:  "No route to host" is usually temporary while the stack is 
;           awaiting an ARP response from the target or the router;
;           callers are expected to retry the send.  The stack rate-
;           limits ARP requests to approximately 2/s per address.
;           Sends to your IPv4 broadcast address will be sent to the
;           broadcast MAC (ff:ff:ff:ff:ff:ff).  An EOM should only occur 
;           if you aren't calling UDP_RECV often enough to drain the 
;           incoming UDP packet queue.  
;
; UDP_RECV
;   IN:     0:X->udp_info (below)
;   OUT:    Carry set on error (not initialized), Z set on queue empty.
;   NOTES:  You MUST call UDP_RECV semi-regularly; if you don't, the
;           receive queue will eventually fill with garbage.  The net
;           is a messy place, and random devices on your lan are always
;           spamming the local network.  Broadcast UDP packets are
;           accepted and queued like any other UDP packets.

ip_info     .struct
ip          .fill   4   ; Local ipv4 address in network order
mask        .fill   4   ; Local ipv4 netmask in network order
default     .fill   4   ; Default ipv4 route in network order
size        .ends

udp_info    .struct
local_port  .word   ?   ; local port #, little-endian
remote_ip   .fill   4   ; ipv4 address of remote machine, network order
remote_port .word   ?   ; remote port #, little endian
buffer      .dword  ?   ; 24-bit address of your data
buflen      .word   ?   ; length of the above buffer in bytes
copied      .word   ?   ; number of bytes copied in/out of the above buffer
size        .ends
