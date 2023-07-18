        .al
        .xl

        .namespace lib

mkdeque .segment
head    .word   0
tail    .word   0
        .endm
        
deque_t .struct
        #lib.mkdeque
end     .ends

link_t  .struct
next    .word   ?
size    .ends

deque_deque   .macro  base, r, link, m
        ld\r    <>\base+lib.deque_t.head,b
        beq     _done
        lda \m  \link,\r
        sta     <>\base+lib.deque_t.head,b
        bne     _okay
        sta     <>\base+lib.deque_t.tail,b
_okay   t\2a
_done   .endm

deque_unque   .macro  base, r, link, m
        lda     <>\base+lib.deque_t.head,b
        bne     _okay
        st\r    <>\base+lib.deque_t.tail,b
_okay   sta \m  \link,\r        
        st\r    <>\base+lib.deque_t.head,b
        .endm
        
deque_enque   .macro  base, r, link, m
        lda     <>\base+lib.deque_t.head  ; or tail
        bne     _ins
        sta \m  \link,\r
        st\r    <>\base+lib.deque_t.head,b
        st\r    <>\base+lib.deque_t.tail,b
        jmp     _done
_ins    lda     #0
        sta \m  \link,\r
        t\2a
        ld\r    <>\base+lib.deque_t.tail,b
        sta \m  \link,\r
        sta     <>\base+lib.deque_t.tail,b
_done   .endm        
        
        .endn
