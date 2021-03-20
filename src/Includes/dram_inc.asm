;
; Memory Map
;
SCREEN_PAGE0     = $AFA000 ;8192 Bytes First page of display RAM. This is used at boot time to display the welcome screen and the BASIC or MONITOR command screens.
SCREEN_PAGE1     = $AFC000 ;8192 Bytes Additional page of display RAM. This can be used for page flipping or to handle multiple edit buffers.
;SCREEN_PAGE2     = $AFE000 ;8192 Bytes Additional page of display RAM. This can be used for page flipping or to handle multiple edit buffers.
;SCREEN_PAGE3     = $B00000 ;8192 Bytes Additional page of display RAM. This can be used for page flipping or to handle multiple edit buffers.
SCREEN_END       = $B00000 ;End of display memory
