;;;
;;; PS/2 keyboard driver
;;;

;;
;; This keyboard driver will be an interrupt driven driver for handling the keyboard
;; of the C256 FMX, U, and U+ models. The driver itself will be a state machine, where
;; feedback from the keyboard controller will adjust the state of the controller during
;; interrupt processing.
;;
;; The keyboard driver will manage a short buffer of keyboard scan codes, which the kernel
;; I/O routines will access and translate into ASCII inputs. Scan codes will be 8-bit integers
;; with the following format:
;;
;; BCCCCCCC
;; B = 0 if the scan code is a "make" code, 1 if the scan code is a "break" code
;; C = the C256 scan code for the key
;;

;;
;; Definitions
;;

KBD_INBUF_SIZE = 16         ; Number of scan codes that can be buffered

KBD_STATE_IDLE = 0          ; Keyboard is IDLE
KBD_STATE_E0 = 1            ; Keyboard has sent E0
KBD_STATE_E02A = 2          ; Keybaord has sent E0 2A (leading to Print Screen E02AE037)
KBD_STATE_E02AE0 = 3
KBD_STATE_E1 = 4            ; Keyboard has sent E1 (leading to Pause/Break)
KBD_STATE_E11D = 5
KBD_STATE_E11D45 = 6
KBD_STATE_E11D45E1 = 7
KBD_STATE_E11D45E19D = 8
KBD_STATE_E0B7 = 9          ; Keyboard has sent E0 B7 (leading to break of Print Screen E0 B7 E0 AA)
KBD_STATE_E0B7E0 = 10

KBD_ACTION_IGNORE = 0       ; State machine action: do nothing with the current byte
KBD_ACTION_EMIT_BASE = 1    ; State machine action: translate scancode from base table and emit it
KBD_ACTION_EMIT_E0 = 2      ; State machine action: translate scancode from E0 prefix table and emit it

KBD_STAT_OBF = $01          ; Keyboard status: Output Buffer is Full
KBD_STAT_IBF = $02          ; Keyboard status: Input Buffer is Full

KBD_CTRL_CMD_DISABLE2 = $A7 ; Keybaord controller command: disable output device #2
KBD_CTRL_CMD_ENABLE2 = $A9  ; Keybaord controller command: enable output device #2
KBD_CTRL_CMD_SELFTEST = $AA ; Keyboard controller command: start self test
KBD_CTRL_CMD_KBDTEST = $AB  ; Keyboard controller command: start keyboard test
KBD_CTRL_CMD_DISABLE1 = $AD ; Keybaord controller command: disable output device #1
KBD_CTRL_CMD_ENABLE1 = $AE  ; Keybaord controller command: enable output device #1
KBD_CTRL_CMD_WRITECMD = $60 ; Keyboard controller command: write to the command register

KBD_CMD_RESET = $FF         ; Keyboard command: reset the keyboard
KBD_CMD_ENABLE = $F4        ; Keyboard command: enable to keyboard
KBD_CMD_SET_LED = $ED       ; Keyboard command: set the LEDs

KBD_RESP_OK = $55           ; Keyboard response: Command was OK
KBD_RESP_ACK = $FA          ; Keyboard response: command acknowledged

KBD_LOCK_SCROLL = $01       ; LED/lock mask for Scroll Lock key
KBD_LOCK_NUMBER = $02       ; LED/lock mask for Num Lock key
KBD_LOCK_CAPS = $04         ; LED/lock mask for Caps Lock key    

KBD_MOD_LSHIFT  = %00000001     ; Left shift is pressed
KBD_MOD_RSHIFT  = %00000010     ; Right shift is pressed
KBD_MOD_LCTRL   = %00000100     ; Left CTRL is pressed
KBD_MOD_RCTRL   = %00001000     ; Right CTRL is pressed
KBD_MOD_LALT    = %00010000     ; Left ALT is pressed
KBD_MOD_RALT    = %00100000     ; Right ALT is pressed
KBD_MOD_OS      = %01000000     ; OS key (e.g. Windows Key) is pressed
KBD_MOD_MENU    = %10000000     ; Menu key is pressed

;
; CONTROL register bits
;

KBD_CTRL_BREAK      = %10000000 ; CONTROL Flag to indicate if keyboard should capture BREAK
KBD_CTRL_MONITOR    = %01000000 ; CONTROL Flag to indicate if keyboard should trap ALT-BREAK to go to the monitor

;
; STATUS bits
;

KBD_STAT_BREAK  = %10000000     ; STATUS flag, BREAK has been pressed recently
KBD_STAT_SCAN   = %00000001     ; STATUS flag to indicate if there are scan codes in the queue
KBD_STAT_CHAR   = %00000010     ; STATUS flag to indicate if there are characters in the queue

;
; Special scan codes
;

KBD_SC_BREAK = $61              ; Scan code for the PAUSE/BREAK key
KBD_SC_CAPSLOCK = $3A           ; Scan code for the CAPS lock key
KBD_SC_NUMLOCK = $45            ; Scan code for the NUM lock key
KBD_SC_SCROLL = $46             ; Scan code for the SCROLL lock key
KBD_SC_LSHIFT = $2A             ; Scan code for the left SHIFT key
KBD_SC_LCTRL = $1D              ; Scan code for the left CTLR key
KBD_SC_LALT = $38               ; Scan code for the left ALT key
KBD_SC_RSHIFT = $36             ; Scan code for the right SHIFT key
KBD_SC_RCTRL = $5E              ; Scan code for the right CTRL key
KBD_SC_RALT = $5C               ; Scan code for the right ALT key

KBD_SC_PIVOT = $38              ; Scan code we will use as a pivot for checking NUM lock

;;
;; Structures
;;

S_KBD_CONTROL       .struct
STATE               .byte ?                     ; The state of the keyboard controller state machine
CONTROL             .byte ?                     ; Control register
STATUS              .byte ?                     ; Status register

SC_BUF              .fill KBD_INBUF_SIZE        ; Buffer for keyboard scancodes read
SC_HEAD             .byte ?                     ; Index of the first scancode cell to write to

CHAR_BUF            .fill KBD_INBUF_SIZE        ; Character buffer
CHAR_HEAD           .byte ?                     ; Number of characters in the character buffer

MODIFIERS           .byte ?                     ; State of the modifier keys
LOCKS               .byte ?                     ; State of the lock keys: Caps, Num, Scroll

TBL_UNMOD           .dword ?                    ; Pointer to the scan code translation table for unmodified keys
TBL_SHIFT           .dword ?                    ; Pointer to the scan code translation table for shifted keys
TBL_CTRL            .dword ?                    ; Pointer to the scan code translation table for keys modified by CTRL
TBL_LOCK            .dword ?                    ; Pointer to the scan code translation table for keys modified by CAPSLOCK or NUMLOCK
TBL_LOCK_SHIFT      .dword ?                    ; Pointer to the scan code translation table for keys modified by CAPSLOCK and SHIFT
TBL_CTRL_SHIFT      .dword ?                    ; Pointer to the scan code translation table for keys modified by CTRL and SHIFT
                    .ends

;;
;; Variables
;;



;;
;; Code
;;


;
; Initialize the keyboard driver and controller
;
; Outputs:
;   A = status of the initilialization (0 = success)
;
IINITKEYBOARD       .proc
                    PHX
                    PHY
                    PHD
                    PHP

                    setdp <>KBD_VARS

                    setas
                    setxl
                    LDA @l INT_MASK_REG1                        ; Disable the keyboard interrupts while we get things started
                    ORA #FNX1_INT00_KBD
                    LDA @l INT_MASK_REG1

                    LDA #KBD_STATE_IDLE                         ; Set the state machine to the starting IDLE state
                    STA #S_KBD_CONTROL.STATE,D

                    STZ #S_KBD_CONTROL.SC_HEAD,D                ; Mark the scancode buffer as empty
                    STZ #S_KBD_CONTROL.CHAR_HEAD,D              ; Mark the character buffer as empty
                    STZ #S_KBD_CONTROL.MODIFIERS,D              ; Default to modifiers being off
                    STZ #S_KBD_CONTROL.STATUS,D                 ; Clear the status register

                    LDA #KBD_CTRL_BREAK                         ; Enable BREAK processing
                    STA #S_KBD_CONTROL.CONTROL,D

                    ; Set pointers to translation tables...

                    setal
                    LDA #<>SC_US_UNMOD
                    STA #S_KBD_CONTROL.TBL_UNMOD,D
                    LDA #<>SC_US_SHFT
                    STA #S_KBD_CONTROL.TBL_SHIFT,D
                    LDA #<>SC_US_CTRL
                    STA #S_KBD_CONTROL.TBL_CTRL,D
                    LDA #<>SC_US_LOCK
                    STA #S_KBD_CONTROL.TBL_LOCK,D
                    LDA #<>SC_US_LOCK_SHFT
                    STA #S_KBD_CONTROL.TBL_LOCK_SHIFT,D
                    LDA #<>SC_US_CTRL_SHFT
                    STA #S_KBD_CONTROL.TBL_CTRL_SHIFT,D

                    setas
                    LDA #`SC_US_UNMOD
                    STA #S_KBD_CONTROL.TBL_UNMOD+2,D
                    LDA #`SC_US_SHFT
                    STA #S_KBD_CONTROL.TBL_SHIFT+2,D
                    LDA #`SC_US_CTRL
                    STA #S_KBD_CONTROL.TBL_CTRL+2,D
                    LDA #`SC_US_LOCK
                    STA #S_KBD_CONTROL.TBL_LOCK+2,D
                    LDA #`SC_US_LOCK_SHFT
                    STA #S_KBD_CONTROL.TBL_LOCK_SHIFT+2,D
                    LDA #`SC_US_CTRL_SHFT
                    STA #S_KBD_CONTROL.TBL_CTRL_SHIFT,D

                    ; Disable outputs

                    LDA #KBD_CTRL_CMD_DISABLE1  ; Disable the keyboard sending data
                    JSL KBD_WAIT_IN             ; Send the command to the controller
                    STA @l KBD_CMD_BUF

                    ; Flush the keyboard controller's output buffer

flush_output        LDA @l KBD_DATA_BUF         ; We just throw that away

                    LDA #KBD_CTRL_CMD_SELFTEST  ; Send the self test command
                    JSL KBD_CTRL_SND_CMD
                    CMP #KBD_RESP_OK            ; Did we get an OK?
                    BEQ test_AB

                    LDA #2                      ; Return error #2
                    BRL done

test_AB             LDA #KBD_CTRL_CMD_KBDTEST   ; Send the keyboard test command
                    JSL KBD_CTRL_SND_CMD
                    CMP #0                      ; Did we get a good response?
                    BEQ write_command
                    LDA #3                      ; Return error #3
                    BRL done

write_command       LDA #KBD_CTRL_CMD_WRITECMD
                    LDX #%01000011              ; Translate to set 1, no interrupts
                    JSL KBD_CTRL_SND_CMD_P

enable_dev1         LDA #KBD_CTRL_CMD_ENABLE1   ; Re-enable the keyboard sending data
                    JSL KBD_WAIT_IN             ; Send the command to the controller
                    STA @l KBD_CMD_BUF

reset_kbd           LDA #KBD_CMD_RESET          ; Send a reset command to the keyboard
                    LDX #$FFFF                  ; And wait a while for it to complete the reset
                    JSL KBD_SND_CMD

                    ; TODO: check error conditions?

                    LDY #128                    ; Attemp enabling the keyboard 128 times

enable_loop         LDA #KBD_CMD_ENABLE         ; Try to enable the keyboard
                    LDX #0
                    JSL KBD_SND_CMD

                    ; NOTE: the keyboard controller on the U and U+ does not seem to communicate
                    ; well here with every keyboard (some don't get a response through). So...
                    ; the FMX will check for a response, the U and U+ will just have to trust that
                    ; the keyboard was re-enabled correctly.

.if TARGET_SYS == SYS_C256_FMX
                    CMP #KBD_RESP_ACK           ; Did the keyboard acknowledge the command?
                    BEQ set_led                 ; Yes: try to set the LEDs
                    DEY                         ; No: try again... counting down
                    BNE enable_loop             ; If we are out of attempts...
                    LDA #5                      ; Return error #5
                    BRA done
.endif

set_led             LDA #"6"
                    JSL PUTC
                    
                    LDA #0                      ; Set the state of the locks
                    JSL KBD_SETLOCKS

                    LDA @l INT_PENDING_REG1     ; Read the Pending Register &
                    AND #FNX1_INT00_KBD
                    STA @l INT_PENDING_REG1     ; Writing it back will clear the Active Bit

                    ; Disable the Mask
                    LDA @l INT_MASK_REG1
                    AND #~FNX1_INT00_KBD
                    STA @l INT_MASK_REG1

return_0            LDA #0                      ; Return status code for success

done                PLP
                    PLD
                    PLY
                    PLX
                    RTL
                    .pend

;
; Wait for the keyboard to be ready to send data to the CPU
;
KBD_WAIT_OUT        .proc
                    PHA
wait                LDA @l KBD_STATUS       ; Get the keyboard status
                    BIT #KBD_STAT_OBF       ; Check to see if the output buffer is full
                    BEQ wait                ; If it isn't, keep waiting
                    PLA
                    RTL
                    .pend

;
; Wait for the keyboard to be ready to receive data from the CPU
;
KBD_WAIT_IN         .proc
                    PHA
wait                LDA @l KBD_STATUS       ; Get the keyboard status
                    BIT #KBD_STAT_IBF       ; Check to see if the input buffer has data
                    BNE wait                ; If not, wait for it to have something
                    PLA
                    RTL
                    .pend

;
; Send a command byte to the keyboard controller
;
; Inputs:
;   A = the command byte to send
;
; Outputs:
;   A = the response from the keyboard
;
KBD_CTRL_SND_CMD    .proc
                    JSL KBD_WAIT_IN         ; Send the command to the controller
                    STA @l KBD_CMD_BUF

                    JSL KBD_WAIT_OUT        ; Wait for and read the response byte
                    LDA @l KBD_DATA_BUF

                    RTL
                    .pend

;
; Send a commmand to the keyboard
;
; Inputs:
;   A = the command code to send to the keyboard
;   X = number of delay cycles required before checking for a response
;
; Outputs:
;   A = the response code
;
KBD_SND_CMD         .proc
                    JSL KBD_WAIT_IN         ; Send the command to the keyboard
                    STA @l KBD_DATA_BUF

                    setxl
delay               CPX #0                  ; Check how many delay loops are left to do
                    BEQ get_response        ; If 0, check for a response

                    DEX                     ; Count down
                    NOP                     ; And do a delay
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    BRA delay

get_response        JSL KBD_WAIT_OUT        ; Wait for and read the response byte
                    LDA @l KBD_DATA_BUF

                    RTL
                    .pend

;
; Send a commmand to the keyboard with a parameter
;
; Inputs:
;   A = the command code to send to the keyboard
;   X = the parameter to send
;
; Outputs:
;   A = the response code
;
KBD_SND_CMD_P       .proc
                    JSL KBD_WAIT_IN         ; Send the command to the keyboard
                    STA @l KBD_DATA_BUF

                    TXA                     ; Send the parameter to the keyboard

                    setxl
                    LDX #1000
delay               CPX #0                  ; Check how many delay loops are left to do
                    BEQ send_data           ; If 0, check for a response

                    DEX                     ; Count down
                    NOP                     ; And do a delay
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    BRA delay

send_data           JSL KBD_WAIT_IN         
                    STA @l KBD_DATA_BUF

get_response       ; JSL KBD_WAIT_OUT        ; Wait for and read the response byte
;                     LDA @l KBD_DATA_BUF
                    RTL
                    .pend

;
; Send a command with a parameter to the keyboard controller
;
; Inputs:
;   A = the command byte to send
;   X = the parameter byte to send
;
; Outputs:
;   A = the response from the keyboard
;
KBD_CTRL_SND_CMD_P  .proc
                    JSL KBD_WAIT_IN         ; Send the command to the controller
                    STA @l KBD_CMD_BUF

                    TXA
                    JSL KBD_WAIT_IN         ; Send the parameter to the controller
                    STA @l KBD_DATA_BUF

                    ; JSL KBD_WAIT_OUT        ; Wait for and read the response byte
                    ; LDA @l KBD_DATA_BUF

                    RTL
                    .pend

;
; FAR: Get and process a scancode from the keyboard.
;
; This routine will be called by the interrupt handler to process a keyboard interupt.
; The scancodes are assumed to be in Set1.
; This implements a state machine using the transition table at KBD_STATE_MACH
;
KBD_PROCESS_BYTE    .proc
                    PHB
                    PHD
                    PHP

                    setdbr `KBD_STATE_MACH
                    setdp <>KBD_VARS

                    setaxs
                    LDA #0
                    STA @l MOUSE_IDX                    ; A bit of a hack to try to stabilize the mouse

                    LDA @l KBD_DATA_BUF                 ; Get the current scancode byte
                    BNE save_scancode

                    BRL done                            ; If it's 0, just ignore it

LOCALS              .virtual 1,S
l_break             .byte ?                             ; The make/break bit of the scancode
l_code              .byte ?                             ; The scancode
                    .endv

save_scancode       PHA
                    PHA                       
                    AND #$80
                    STA l_break                         ; Save the make/break bit

                    ; Find the first transition for the current state
                    LDX #0                              ; Start from the beginning
chk_transition      LDA @l KBD_STATE_MACH,X             ; Get the tranition's start state
                    CMP #$FF
                    BNE compare_state
                    BRL done                            ; If $FF: we've reached the end... this is an error... just ignore it?

compare_state       CMP #S_KBD_CONTROL.STATE,D          ; Compare it to the current state
                    BNE next_transition                 ; If they don't match, go to the next transition

                    ; Check if this transition matches the scancode
                    LDA @l KBD_STATE_MACH+1,X           ; Get the tranition's test byte
                    BEQ apply                           ; Is it 0? Yes: the default applies

                    LDA l_code                          ; Otherwise: get the scan code back
                    CMP @l KBD_STATE_MACH+1,X           ; Compare it to the transition's test byte
                    BEQ apply                           ; If equal: this matches, apply the transition

next_transition     INX                                 ; Move to the next transition
                    INX
                    INX
                    INX

                    BRA chk_transition                  ; Check to see if the next transition applies

apply               LDA @l KBD_STATE_MACH+2,X           ; Get the tranition's destination state
                    STA #S_KBD_CONTROL.STATE,D          ; And save it as our new state

                    LDA @l KBD_STATE_MACH+3,X           ; Get the tranition's action
                    CMP #KBD_ACTION_IGNORE              ; Is it IGNORE?
                    BEQ done                            ; Yes: we're done for now
                    CMP #KBD_ACTION_EMIT_BASE           ; Is it EMIT_BASE?
                    BEQ emit_base                       ; Yes: emit the translation of the base byte
                    CMP #KBD_ACTION_EMIT_E0             ; Is it EMIT_E0?
                    BEQ emit_e0                         ; Yes: emit the translation of the E0 prefixed byte
                    BRA emit_A                          ; Otherwise: just emit the action byte as the new scan code

emit_base           LDA l_code
                    AND #$7F                            ; Strip off the make/break bit
                    TAX
                    LDA @l TBL_SET1,X                   ; Get the translation of the base scan code
                    ORA l_break                         ; Add the make/break bit back
                    BRA emit_A                          ; Emit the translation

emit_e0             LDA l_code
                    AND #$7F                            ; Strip off any make/break bit
                    TAX
                    LDA @l TBL_SET1_E0,X                ; Get the translation of the E0 prefixed scan code
                    ORA l_break                         ; Add in the make/break flag
emit_A              CMP #0                              ; Is the code NUL?
                    BEQ done                            ; If so, skip enqueuing it

enqueue             JSL KBD_SC_ENQUEUE                  ; Enqueue the scancode
                    LDA #KBD_STATE_IDLE                 ; Set the state machine to the initial state
                    STA #S_KBD_CONTROL.STATE,D

done                setas
                    PLA                                 ; Clean the scan code byte from the stack
                    PLA
                    PLP
                    PLD
                    PLB
                    RTL
                    .pend

;
; FAR: Add a scancode to the end of the queue
;
; Inputs:
;   A = the scancode to enqueue
;
KBD_SC_ENQUEUE      .proc
                    PHD
                    PHP

                    SEI                             ; Disable IRQs for the duration of this routine to avoid race conditions

                    setdp <>KBD_VARS
                    setaxs

                    CMP #0                          ; Is the scan code a NUL?
                    BEQ done                        ; Yes: just ignore

                    CMP #KBD_SC_BREAK               ; Is it the BREAK key?
                    BNE chk_locks                   ; No: check the various lock keys

                    LDA #S_KBD_CONTROL.CONTROL,D
                    BIT #KBD_CTRL_BREAK                 ; Are we processing BREAK?
                    BEQ enqueue_break                   ; No: enqueue it as normal

                    LDA #KBD_STAT_BREAK                 ; Yes: turn on the BREAK bit
                    ORA #S_KBD_CONTROL.STATUS,D
                    STA #S_KBD_CONTROL.STATUS,D
                    BRA done                            ; And we're done

enqueue_break       LDA #KBD_SC_BREAK

chk_locks           CMP #KBD_SC_CAPSLOCK            ; Is it the CAPS lock?
                    BEQ toggle_caps                 ; Yes: toggle the CAPS lock bits

                    CMP #KBD_SC_NUMLOCK             ; Is it the NUM lock?
                    BEQ toggle_num                  ; Yes: toggle the NUM lock bits

                    CMP #KBD_SC_SCROLL              ; Is it the SCROLL lock?
                    BEQ toggle_scroll               ; Yes: toggle the SCROLL lock bits

                    LDX #S_KBD_CONTROL.SC_HEAD,D    ; Get the index of the next free spot
                    CPX #KBD_INBUF_SIZE             ; Is it at the end?
                    BEQ done                        ; Yes: we're full... ignore the scancode

                    STA #S_KBD_CONTROL.SC_BUF,D,X   ; No: we have room, write the scan code to the buffer
                    INX                             ; Advance to the next location
                    STX #S_KBD_CONTROL.SC_HEAD,D

                    LDA #KBD_STAT_SCAN              ; Set the KBD_STAT_SCAN bit
                    TSB #S_KBD_CONTROL.STATUS,D

done                PLP
                    PLD
                    RTL

toggle_caps         LDA #S_KBD_CONTROL.LOCKS,D
                    EOR #KBD_LOCK_CAPS              ; Toggle the CAPS lock
save_locks          JSL KBD_SETLOCKS                ; Set the locks
                    BRA done

toggle_num          LDA #S_KBD_CONTROL.LOCKS,D
                    EOR #KBD_LOCK_NUMBER            ; Toggle the NUM lock
                    BRA save_locks

toggle_scroll       LDA #S_KBD_CONTROL.LOCKS,D
                    EOR #KBD_LOCK_SCROLL            ; Toggle the SCROLL lock
                    BRA save_locks
                    .pend


;
; FAR: Add a character to the end of the queue
;
; Inputs:
;   A = the character to enqueue
;
KBD_CHAR_ENQUEUE    .proc
                    PHD
                    PHP

                    SEI                             ; Disable IRQs for the duration of this routine to avoid race conditions

                    setdp <>KBD_VARS
                    setaxs

                    CMP #0                          ; Is the character a NUL?
                    BEQ done                        ; Yes: just ignore

                    LDX #S_KBD_CONTROL.CHAR_HEAD,D  ; Get the index of the next free spot
                    CPX #KBD_INBUF_SIZE             ; Is it at the end?
                    BEQ done                        ; Yes: we're full... ignore the scancode

                    STA #S_KBD_CONTROL.CHAR_BUF,D,X ; No: we have room, write the scan code to the buffer
                    INX                             ; Advance to the next location
                    STX #S_KBD_CONTROL.CHAR_HEAD,D

                    LDA #KBD_STAT_CHAR              ; Set the KBD_STAT_CHAR bit
                    TSB #S_KBD_CONTROL.STATUS,D

done                PLP
                    PLD
                    RTL
                    .pend

;
; FAR: Dequeue and return a character from the queue
;
; Outputs:
;   A = 0 if no character present, contains the character otherwise
;
KBD_CHAR_DEQUEUE    .proc
                    PHX
                    PHD
                    PHP

                    setdp <>KBD_VARS

                    SEI                                 ; Disable IRQ for the duration of this routine to avoid race conditions

                    setaxs

                    LDX #S_KBD_CONTROL.CHAR_HEAD,D      ; Get the index of the next free spot
                    BEQ return_empty                    ; If it's 0, we have no data

                    LDA #S_KBD_CONTROL.CHAR_BUF,D       ; Get the character at the head of the queue
                    PHA                                 ; Save it

                    LDX #S_KBD_CONTROL.CHAR_HEAD,D      ; How many bytes were there?
                    CPX #1                              ; Is it one?
                    BNE copy_down                       ; No: we need to copy down the remaining bytes

                    STZ #S_KBD_CONTROL.CHAR_HEAD,D      ; Yes: mark that we have no data in the queue now

                    LDA #KBD_STAT_CHAR                  ; Clear the KBD_STAT_CHAR bit
                    TRB #S_KBD_CONTROL.STATUS,D

                    BRA return_head                     ; And return the character we found

copy_down           LDX #0                              ; Starting at the beginning of the buffer...
loop                LDA #S_KBD_CONTROL.CHAR_BUF+1,D,X   ; Get the next byte
                    STA #S_KBD_CONTROL.CHAR_BUF,D,X     ; Move it down

                    INX                                 ; And move to the next byte
                    CPX #S_KBD_CONTROL.CHAR_HEAD,D      ; Have we reached the end?
                    BNE loop                            ; No: keep copying bytes

                    DEC #S_KBD_CONTROL.CHAR_HEAD,D      ; Decrement the index

return_head         PLA                                 ; Get the character back
                    BRA done                            ; And return it

return_empty        LDA #0                              ; Return: 0 for no character

done                PLP
                    PLD
                    PLX
                    RTL
                    .pend

;
; FAR: Dequeue and return a scan code from the queue
;
; Outputs:
;   A = 0 if no scancode present, contains the scancode otherwise
;
KBD_GET_SCANCODE    .proc
                    PHX
                    PHD
                    PHP

                    setdp <>KBD_VARS

                    SEI                             ; Disable IRQ for the duration of this routine to avoid race conditions

                    setaxs
                    LDX #S_KBD_CONTROL.SC_HEAD,D    ; Get the index of the next free spot
                    BEQ return_empty                ; If it's 0, we have no data

                    LDA #S_KBD_CONTROL.SC_BUF,D     ; Get the scan code at the head of the queue
                    PHA                             ; Save it

                    LDX #S_KBD_CONTROL.SC_HEAD,D    ; How many bytes were there?
                    CPX #1                          ; Is it one?
                    BNE copy_down                   ; No: we need to copy down the remaining bytes

                    STZ #S_KBD_CONTROL.SC_HEAD,D    ; Yes: mark that we have no data in the queue now

                    LDA #KBD_STAT_SCAN              ; Clear the KBD_STAT_SCAN bit
                    TRB #S_KBD_CONTROL.STATUS,D

                    BRA return_head                 ; And return the scan code we found

copy_down           LDX #0                          ; Starting at the beginning of the buffer...
loop                LDA #S_KBD_CONTROL.SC_BUF+1,D,X ; Get the next byte
                    STA #S_KBD_CONTROL.SC_BUF,D     ; Move it down

                    INX                             ; And move to the next byte
                    CPX #S_KBD_CONTROL.SC_HEAD,D    ; Have we reached the end?
                    BNE loop                        ; No: keep copying bytes

                    DEC #S_KBD_CONTROL.SC_HEAD,D    ; Reduce the index to the next free byte

return_head         PLA                             ; Get the scan code back
                    BRA done                        ; And return it

return_empty        LDA #0                          ; Return: 0 for no scan code

done                PLP
                    PLD
                    PLX
                    RTL
                    .pend

;;
;; Character Input Stream
;;

;
; FAR: Return the current state of the modifier keys (SHIFT, CTRL, ALT, OS, MENU)
;
; Outputs:
;   A = the modifier bit flags (bits 0 .. 7)
;   
KBD_GETMODS     .proc
                PHD
                PHP

                setdp <>KBD_VARS
                setas
                LDA #S_KBD_CONTROL.MODIFIERS,D

                PLP
                PLD
                RTL
                .pend

;
; FAR: Return the current status of the keyboard driver
;
; Outputs:
;   A = the status bits
;       A[7] = BREAK was pressed since last call to KBD_TEST_BREAK
;       A[1] = characters are enqueued in the character level queue
;       A[0] = scan codes are enqueued in the scan code queue
;
; NOTE: Either A[1] or A[0] being set suggests that there is data for the caller
;   
KBD_GET_STAT    .proc
                PHD
                PHP

                setdp <>KBD_VARS
                setas
                LDA #S_KBD_CONTROL.STATUS,D

                PLP
                PLD
                RTL
                .pend

;
; FAR: Check if BREAK has been pressed recently and clear the BREAK flag if it has.
;
; Inputs:
;   None
;
; Outputs:
;   C set if BREAK was pressed, clear otherwise
;
KBD_TEST_BREAK  .proc
                PHD
                PHP

                setdp <>KBD_VARS
                setas
                LDA #KBD_STAT_BREAK             ; Check the BREAK bit in STATUS
                TRB #S_KBD_CONTROL.STATUS,D     ; ... and clear it
                BNE ret_true                    ; If it was set, return TRUE

ret_false       PLP                             ; Otherwise, return false
                PLD
                CLC
                RTL

ret_true        PLP
                PLD
                SEC
                RTL
                .pend

;
; FAR: Return the modifiers as an ANSI compatible bit field:
;
; Outputs:
;   A = modifiers: A[0] = 0, A[1] = Shift, A[2] = Alt, A[3] = Ctrl
;
KBD_GETMODS_ANSI    .proc
                    PHD
                    PHP

                    setdp <>KBD_VARS
                    setaxs

                    LDA #0                      ; Make space for the result code
                    PHA

                    .virtual 1,S
l_result            .byte ?
                    .endv

                    LDA #S_KBD_CONTROL.MODIFIERS,D
                    BIT #KBD_MOD_LSHIFT | KBD_MOD_RSHIFT
                    BEQ check_alt
                    LDA l_result
                    ORA #%00000010
                    STA l_result

check_alt           LDA #S_KBD_CONTROL.MODIFIERS,D
                    BIT #KBD_MOD_LALT | KBD_MOD_RALT
                    BEQ check_ctrl
                    LDA l_result
                    ORA #%00000100
                    STA l_result

check_ctrl          LDA #S_KBD_CONTROL.MODIFIERS,D
                    BIT #KBD_MOD_LCTRL | KBD_MOD_RCTRL
                    BEQ return_result
                    LDA l_result
                    ORA #%00001000
                    STA l_result

return_result       PLA
                    PLP
                    PLD
                    RTL
                    .pend

;
; FAR: Return the current state of the lock keys (CAPS, NUM, SCROLL)
;
; Outputs:
;   A = the modifier bit flags: A[2] = CAPS, A[1] = NUM, A[0] = SCROLL
;   
KBD_GETLOCKS    .proc
                PHD
                PHP

                setdp <>KBD_VARS
                setas
                LDA #S_KBD_CONTROL.LOCKS,D

                PLP
                PLD
                RTL
                .pend

;
; FAR: Set the current state of the lock keys (CAPS, NUM, SCROLL), including the LEDs on the keyboard
;
; Outputs:
;   A = the modifier bit flags: A[2] = CAPS, A[1] = NUM, A[0] = SCROLL
;   
KBD_SETLOCKS    .proc
                PHD
                PHP

                setdp <>KBD_VARS
                setas
                STA #S_KBD_CONTROL.LOCKS,D
                
                ; For the moment, disable this on U/U+, where it doesn't seem to work
.if TARGET_SYS == SYS_C256_FMX
                TAX                         ; Move the new status to X...
                LDA #KBD_CMD_SET_LED        ; Set the LEDs...
                JSL KBD_SND_CMD_P
.endif
                PLP
                PLD
                RTL
                .pend

;
; FAR: Return the control bits
;
; Outputs:
;   A = the control bits
;   
KBD_GET_CONTROL .proc
                PHD
                PHP

                setdp <>KBD_VARS
                setas
                LDA #S_KBD_CONTROL.CONTROL,D

                PLP
                PLD
                RTL
                .pend

;
; FAR: Set the control bits
;
; Inputs:
;   A = the control bits
;   
KBD_SET_CONTROL .proc
                PHD
                PHP

                setdp <>KBD_VARS
                setas
                STA #S_KBD_CONTROL.CONTROL,D

                PLP
                PLD
                RTL
                .pend

;
; Try to read a character from the keyboard.
; Waits until a character is present.
;
; Outputs:
;   A = the ASCII code if it is.
;
KBD_GETCW       .proc
                JSL KBD_GETC
                CMP #0
                BEQ wait
                RTL

wait            WAI
                BRA KBD_GETCW
                .pend

;
; Try to read a character from the keyboard.
;
; Outputs:
;   A = 0 if there is nothing available, or the ASCII code if it is.
;
KBD_GETC        .proc
                PHD
                PHP

                setdp <>KBD_VARS

                setaxs

                ; Check first to see if there is character already in the queue...
                JSL KBD_CHAR_DEQUEUE        ; Try to fetch a character from the character queue
                CMP #0                      ; Did we get anything back?
                BEQ get_scancode            ; No: try to get a scan code
                BRL done                    ; Yes: return the character we had queued

get_scancode    JSL KBD_GET_SCANCODE        ; Fetch the next scancode
                CMP #0                      ; Is it NUL?
                BNE chk_make_break
                
                PLP                         ; Yes: return 0... we got nothin
                SEC
                PLD
                RTL

chk_make_break  BIT #$80                    ; Is it a break scan code?
                BNE handle_break            ; Yes: process the break

                ; Interleaved chain of tests...
                ; Handle make and break scan codes for the modifier keys: SHIFT, CTRL, ALT
                ; Left and right modifiers are treated separately to avoid issue where someone might
                ; press both but release only one.

handle_make     CMP #KBD_SC_LSHIFT          ; Is it a make LSHIFT?
                BNE not_make_ls
                LDA #KBD_MOD_LSHIFT
                BRA set_modifier

handle_break    CMP #KBD_SC_LSHIFT | $80    ; Is it a break LSHIFT?
                BNE not_break_ls
                LDA #KBD_MOD_LSHIFT
                BRA clr_modifier

not_make_ls     CMP #KBD_SC_LCTRL           ; Is it a make LCTRL?
                BNE not_make_lc
                LDA #KBD_MOD_LCTRL
                BRA set_modifier

not_break_ls    CMP #KBD_SC_LCTRL | $80     ; Is it a break LCTRL?
                BNE not_break_lc
                LDA #KBD_MOD_LCTRL
                BRA clr_modifier

not_make_lc     CMP #KBD_SC_LALT            ; Is it a make LALT?
                BNE not_make_la
                LDA #KBD_MOD_LALT
                BRA set_modifier

not_break_lc    CMP #KBD_SC_LALT | $80      ; Is it a break LALT?
                BNE not_break_la
                LDA #KBD_MOD_LALT
                BRA clr_modifier

not_make_la     CMP #KBD_SC_RSHIFT          ; Is it a make RSHIFT?
                BNE not_make_rs
                LDA #KBD_MOD_RSHIFT
                BRA set_modifier

not_break_la    CMP #KBD_SC_RSHIFT | $80    ; Is it a break RSHIFT?
                BNE not_break_rs
                LDA #KBD_MOD_RSHIFT
                BRA clr_modifier

not_make_rs     CMP #KBD_SC_RCTRL           ; Is it a make RCTRL?
                BNE not_make_rc
                LDA #KBD_MOD_RCTRL
                BRA set_modifier

not_break_rs    CMP #KBD_SC_RCTRL | $80     ; Is it a break RCTRL?
                BNE not_break_rc
                LDA #KBD_MOD_RCTRL
                BRA clr_modifier

not_make_rc     CMP #KBD_SC_RALT            ; Is it a make RALT?
                BNE not_make_ra
                LDA #KBD_MOD_RALT
set_modifier    TSB #S_KBD_CONTROL.MODIFIERS,D  ; Set the indicated modifier bit
                BRA return_null

not_break_rc    CMP #KBD_SC_RALT | $80          ; Is it a break RALT?
                BNE return_null                 ; No: we don't use any other break scan codes
                LDA #KBD_MOD_RALT
clr_modifier    TRB #S_KBD_CONTROL.MODIFIERS,D  ; Clear the indicated modifier bit
return_null     LDA #0
                BRA done

not_make_ra     TAY                                     ; Use the scan code as an index...

                ; We will pivot on $38... 
                ; If the scan code is >=$38, we'll only look at NUMLOCK
                ; Otherwise, we look at CTRL, CAPSLOCK, and SHIFT

                CMP #KBD_SC_PIVOT
                BLT below_38

                ; The scan code corresponds to the right side of the keyboard (numeric keypad and so on)
                ; Translation will be unaffected by SHIFT or CTRL, so just look at NUMLOCK

                LDA #S_KBD_CONTROL.LOCKS,D              ; Check the NUM lock
                BIT #KBD_LOCK_NUMBER
                BEQ fetch_unmod                         ; No: translate the keys as unmodified

chk_num_shift   LDA #S_KBD_CONTROL.MODIFIERS,D
                BIT #KBD_MOD_LSHIFT | KBD_MOD_RSHIFT    ; Check for a shift key being pressed
                BNE fetch_unmod                         ; If so: translate the keys as modified
                BRA fetch_caps                          ; No: translate the key using the lock table

                ; The scan code corresponds to the main section of the keyboard...
                ; First we check to see if CTRL is pressed, if so, only SHIFT will affect things,
                ; and we can ignore CAPSLOCK (all letters will be converted to control codes).
                ; If not, we will want to check CAPSLOCK and SHIFT to determine the correct character.

below_38        LDA #S_KBD_CONTROL.MODIFIERS,D
                BIT #KBD_MOD_LCTRL | KBD_MOD_RCTRL      ; Is either control key pressed?
                BEQ chk_capslock                        ; No: check for capslock

                BIT #KBD_MOD_LSHIFT | KBD_MOD_RSHIFT    ; Is either shift key pressed?
                BEQ fetch_control                       ; No: translate just based off of control

                ; Yes: translate based on ctrl and shift

                LDA [#S_KBD_CONTROL.TBL_CTRL_SHIFT,D],Y ; Look up the key modfified by CTRL and SHIFT
                BRA chk_ansi

                ; Translate based on the CTRL key

fetch_control   LDA [#S_KBD_CONTROL.TBL_CTRL,D],Y       ; Look up the key modified by CONTROL
                BRA chk_ansi

                ; Control key is not pressed... so look first at the CAPS lock

chk_capslock    LDA #S_KBD_CONTROL.LOCKS,D              ; Check the CAPS lock
                BIT #KBD_LOCK_CAPS
                BNE chk_caps_shift                      ; Yes: check the state of the SHIFT key

                LDA #S_KBD_CONTROL.MODIFIERS,D
                BIT #KBD_MOD_LSHIFT | KBD_MOD_RSHIFT    ; Is either shift key pressed?
                BEQ fetch_unmod                         ; No: translate just based off of control

fetch_shifted   LDA [#S_KBD_CONTROL.TBL_SHIFT,D],Y      ; Look up the key modified by SHIFT
                BRA chk_ansi

fetch_unmod     LDA [#S_KBD_CONTROL.TBL_UNMOD,D],Y      ; Look up the unmodified key
                BRA chk_ansi

chk_caps_shift  LDA #S_KBD_CONTROL.MODIFIERS,D
                BIT #KBD_MOD_LSHIFT | KBD_MOD_RSHIFT    ; Is either shift key pressed?
                BEQ fetch_caps                          ; No: translate just based off of control

                LDA [#S_KBD_CONTROL.TBL_LOCK_SHIFT,D],Y ; Look up the key modified by CAPS and SHIFT
                BRA chk_ansi

fetch_caps      LDA [#S_KBD_CONTROL.TBL_LOCK,D],Y       ; Look up the key modified by CAPSLOCK
                BRA chk_ansi

chk_ansi        CMP #$80                                ; Check to see if we have an ANSI escape sequence to send
                BLT done                                ; If not, just return the character
                CMP #$96
                BGE done

                JSL KBD_ENQ_ANSI                        ; Expand and enqueue the ANSI sequence
                LDA #CHAR_ESC                           ; And return the ESC key to start the sequence
        
done            PLP
                PLD
                CLC
                RTL
                .pend

;
; Enqueue a BCD number into the keyboard's character buffer
;
; Inputs:
;   A = the BCD number to enqueue
;
KBD_ENQUEUE_BCD .proc
                PHP
                setaxs

                PHA                     ; Save the value

                LSR A                   ; Get the 10s digit
                LSR A
                LSR A
                LSR A

                CMP #0                  ; If it's 0, move to the 1s digit
                BEQ enqueue_1
                CMP #$0A                ; If it's out of range, ignore this whole call
                BGE done_A

                CLC                     ; Enqueue the tens digit
                ADC #'0'
                JSL KBD_CHAR_ENQUEUE

enqueue_1       PLA                     ; Enqueue the ones digit
                AND #$0F
                CLC
                ADC #'0'
                JSL KBD_CHAR_ENQUEUE   

done            PLP
                RTL

done_A          PLA
                BRA done
                .pend

;
; Convert the value in A to BCD
;
; Inputs:
;   A = value in binary
;
; Outputs:
;   B = value in BCD
;
KBD_BIN_TO_BCD  .proc
                PHX
                PHP

                setaxs

                TAX
                LDA #$99                ; Start with -1 in BCD form
                SED                     ; Switch to Decimal arithmetic

loop            CLC
                ADC #1                  ; Add 1 with BCD arithmetic
                DEX                     ; Decrement input value in X
                BPL loop                ; loop until input value < 0
                CLD                     ; Switch back to Binary arithmetic

                PLP
                PLX
                RTL
                .pend

;
; Convert special "ASCII" codes $80 - $95 to ANSI escape sequences and
; enqueue them in the keyboard character buffer.
;
; Inputs:
;   A = the code point to convert
;
; Outputs:
;   None... this updates the character buffer in the keyboard data block
;
KBD_ENQ_ANSI    .proc
                PHP

                setaxs
                CMP #$80                        ; check to make sure the code is within range
                BGE chk_high_end
                BRL done                        ; Out of range, just ignore it
chk_high_end    CMP #$96          
                BLT save_value
                BRL done                        ; Out of range, just ignore it

save_value      PHA

                ; Make sure there is room
                ; Enqueue "["
                LDA #'['
                JSL KBD_CHAR_ENQUEUE

                ; Find and enqueue the main contol number

                PLA
                SEC
                SBC #$80                ; Convert to an offset
                TAX                     ; And use it as an index to...
                LDA @l ENCODE_CODE,X    ; Get the number
                BPL send_number         ; If MSB is not set, send the number as-is

                ; Otherwise, it's a cursor key and needs to be 'A' .. 'D'

                AND #$7F                ; Remove the MSB
                CLC
                ADC #'A'                ; Convert to 'A' .. 'D'
                JSL KBD_CHAR_ENQUEUE    ; Enqueue the code
                BRA done

send_number     JSL KBD_BIN_TO_BCD      ; Convert A to BCD
                JSL KBD_ENQUEUE_BCD     ; Enqueue the BCD value

                ; Is a modifier active?
chk_modifier    JSL KBD_GETMODS_ANSI    ; Get the modifiers
                CMP #0                  ; Are there any?
                BEQ close               ; No: close the sequence

                PHA
                LDA #';'                ; Enqueue the separator
                JSL KBD_CHAR_ENQUEUE
                PLA

                JSL KBD_BIN_TO_BCD      ; Convert A to BCD
                JSL KBD_ENQUEUE_BCD     ; Enqueue the BCD value
                
close           LDA #'~'                ; Enqueue closing code
                JSL KBD_CHAR_ENQUEUE

done            PLP
                RTL
ENCODE_CODE     .byte 1, 2, 3, 4, 5, 6      ; Insert, etc...
                .byte $80, $81, $82, $83    ; Cursor keys
                .byte 11, 12, 13, 14, 15    ; F1 - F5
                .byte 17, 18, 19, 20, 21    ; F6 - F10
                .byte 23, 24                ; F11 - F12
                .pend

;
; Set the scan code translation tables.
;
; There are six translation tables. Each table is 128 bytes long, and they
; must be arranged consecutively. Each table maps the make scan code (0 - 127) to an
; ASCII or ISO-8859 character. For instance, the second position of a table will provide the
; character for scan code $01 (ESC, usually), the third position will provide the character for
; scan code $02 ('1', on US keyboards), and so on. The tables must be provided in the following
; order:
;
;   UNMOD -- used when no lock key or modifier is in use
;   SHIFT -- used when SHIFT is the only modifier
;   CONTROL -- used when CONTROL is the only modifier
;   LOCK -- used when CAPSLOCK is down but SHIFT is not
;   LOCK+SHIFT -- used when CAPSLOCK is down and SHIFT is pressed
;   CONTROL+SHIFT -- used when CONTROL and SHIFT are pressed together
;
; Note: for scan codes < $38, LOCK and LOCK+SHIFT will be consulted if CAPS lock is down.
;       For scan codes >= $38, LOCK and LOCK+SHIFT will be consulted if NUM lock is down.
;       Another way to look at that is that CAPS lock will be the LOCK modifier for keys on 
;       the left side of the keyboard, and NUM lock will be the LOCK modifier for keys on the
;       right side of the keyboard. Neither SHIFT nor CONTROL will be checked for the keys
;       on the right side of the keyboard.
;
; Inputs:
;   B:X = pointer to the first byte of the first translation table.
;
; Outputs:
;   None
;   
KBD_SETTABLE    .proc
                PHA
                PHB
                PHD
                PHP

                setdp <>KBD_VARS
                setas

                PHB                 ; Get the data bank into A
                PLA

                setal
                AND #$00FF
                STA #S_KBD_CONTROL.TBL_UNMOD+2,D
                STA #S_KBD_CONTROL.TBL_SHIFT+2,D
                STA #S_KBD_CONTROL.TBL_CTRL+2,D
                STA #S_KBD_CONTROL.TBL_LOCK+2,D
                STA #S_KBD_CONTROL.TBL_LOCK_SHIFT+2,D
                STA #S_KBD_CONTROL.TBL_CTRL_SHIFT+2,D

                STX #S_KBD_CONTROL.TBL_UNMOD,D
                STX #S_KBD_CONTROL.TBL_SHIFT,D
                STX #S_KBD_CONTROL.TBL_CTRL,D
                STX #S_KBD_CONTROL.TBL_LOCK,D
                STX #S_KBD_CONTROL.TBL_LOCK_SHIFT,D
                STX #S_KBD_CONTROL.TBL_CTRL_SHIFT,D

                PLP
                PLD
                PLB
                PLA
                RTL
                .pend

;;
;; Data
;;

;
; Table mapping main Set1 scancodes to C256 scancodes
; 
.align 256
TBL_SET1        .byte $00, $01, $02, $03, $04, $05, $06, $07    ; $00 - $07
                .byte $08, $09, $0A, $0B, $0C, $0D, $0E, $0F    ; $08 - $0F
                .byte $10, $11, $12, $13, $14, $15, $16, $17    ; $10 - $17
                .byte $18, $19, $1A, $1B, $1C, $1D, $1E, $1F    ; $18 - $1F
                .byte $20, $21, $22, $23, $24, $25, $26, $27    ; $20 - $27
                .byte $28, $29, $2A, $2B, $2C, $2D, $2E, $2F    ; $28 - $2F
                .byte $30, $31, $32, $33, $34, $35, $36, $37    ; $30 - $37
                .byte $38, $39, $3A, $3B, $3C, $3D, $3E, $3F    ; $38 - $3F
                .byte $40, $41, $42, $43, $44, $45, $46, $47    ; $40 - $47
                .byte $48, $49, $4A, $4B, $4C, $4D, $4E, $4F    ; $48 - $4F
                .byte $50, $51, $52, $53, $54, $55, $56, $57    ; $50 - $57
                .byte $58, $00, $00, $00, $00, $00, $00, $00    ; $58 - $5F
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $60 - $67
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $78 - $7F

;
; Table mapping E0 prefixed Set1 scancodes to C256 scancodes
;
TBL_SET1_E0     .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $00 - $07
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $08 - $0F
                .byte $70, $00, $00, $00, $00, $00, $00, $00    ; $10 - $17
                .byte $00, $71, $00, $00, $6D, $5E, $00, $00    ; $18 - $1F
                .byte $72, $00, $6E, $00, $6F, $00, $00, $00    ; $20 - $27
                .byte $00, $00, $00, $00, $00, $00, $73, $00    ; $28 - $2F
                .byte $74, $00, $00, $00, $00, $6C, $00, $00    ; $30 - $37
                .byte $5C, $00, $00, $00, $00, $00, $00, $00    ; $38 - $3F
                .byte $00, $00, $00, $00, $00, $00, $61, $63    ; $40 - $47
                .byte $68, $64, $00, $69, $00, $6B, $00, $66    ; $48 - $4F
                .byte $6A, $67, $62, $65, $00, $00, $00, $00    ; $50 - $57
                .byte $00, $00, $00, $00, $00, $5D, $00, $00    ; $58 - $5F
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $60 - $67
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00    ; $78 - $7F

KBD_STATE_MACH  ; State: IDLE... translate base scancodes, watch for E0 or E1 prefixes

                .byte KBD_STATE_IDLE, $E0, KBD_STATE_E0, 0                          ; IDLE =[E0]=> STATE_E0
                .byte KBD_STATE_IDLE, $E1, KBD_STATE_E1, 0                          ; IDLE =[E1]=> STATE_E1
                .byte KBD_STATE_IDLE, 0, KBD_STATE_IDLE, KBD_ACTION_EMIT_BASE       ; IDLE =[default]=> IDLE / emit(TBL_SET1[x])

                ; State E0... translate prefixed scancodes, watch for make/break of PrintScreen

                .byte KBD_STATE_E0, $2A, KBD_STATE_E02A, 0                          ; STATE_E0 =[2A]=> STATE_E02A
                .byte KBD_STATE_E0, $B7, KBD_STATE_E0B7, 0                          ; STATE_E0 =[B7]=> STATE_E0B7
                .byte KBD_STATE_E0, 0, KBD_STATE_IDLE, KBD_ACTION_EMIT_E0           ; STATE_E0 =[default]=> IDLE, emit(TBL_SET1_E0[x])

                ; State E02A... watch for make of PrintScreen

                .byte KBD_STATE_E02A, $E0, KBD_STATE_E02AE0, 0                      ; STATE_E02A =[E0]=> STATE_E02AE0
                .byte KBD_STATE_E02A, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE          ; STATE_E02A =[default]=> IDLE, ignore(x)

                ; State E02AE0... watch for make of PrintScreen

                .byte KBD_STATE_E02AE0, $37, KBD_STATE_IDLE, $60                    ; STATE_E02AE0 =[37]=> IDLE, emit(make{PrintScreen})
                .byte KBD_STATE_E02AE0, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE        ; STATE_E02AE0 =[default]=> IDLE, ignore(x)

                ; State E0B7... watch for break of PrintScreen

                .byte KBD_STATE_E0B7, $E0, KBD_STATE_E0B7E0, 0                      ; STATE_E0B7 =[E0]=> STATE_E0B7E0
                .byte KBD_STATE_E0B7, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE          ; STATE_E0B7 =[default]=> IDLE, ignore(x)

                ; State E0B7E0... watch for break of PrintScreen

                .byte KBD_STATE_E0B7E0, $AA, KBD_STATE_IDLE, $E0                    ; STATE_E0B7E0 =[AA]=> IDLE, emit(break{PrintScreen})
                .byte KBD_STATE_E0B7E0, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE        ; STATE_E0B7E0 =[default]=> IDLE, ignore(x)

                ; State E1... watch for PAUSE

                .byte KBD_STATE_E1, $1D, KBD_STATE_E11D, 0                          ; STATE_E1 =[1D]=> STATE_E11D
                .byte KBD_STATE_E1, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE            ; STATE_E1 =[default]=> IDLE, ignore(x)

                ; State E11D... watch for PAUSE

                .byte KBD_STATE_E11D, $45, KBD_STATE_E11D45, 0                      ; STATE_E11D =[45]=> STATE_E11D45
                .byte KBD_STATE_E11D, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE          ; STATE_E11D =[default]=> IDLE, ignore(x)

                ; State E11D45... watch for PAUSE

                .byte KBD_STATE_E11D45, $E1, KBD_STATE_E11D45E1, 0                  ; STATE_E11D45 =[E1]=> STATE_E11D45E1
                .byte KBD_STATE_E11D45, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE        ; STATE_E11D45 =[default]=> IDLE, ignore(x)

                ; State E11D45E1... watch for PAUSE

                .byte KBD_STATE_E11D45E1, $9D, KBD_STATE_E11D45E19D, 0              ; STATE_E11D45E1 =[9D]=> STATE_E11D45E19D
                .byte KBD_STATE_E11D45E1, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE      ; STATE_E11D45E1 =[default]=> IDLE, ignore(x)

                ; State E11D45E19D... watch for PAUSE

                .byte KBD_STATE_E11D45E19D, $C5, KBD_STATE_IDLE, $61                ; STATE_E11D45E19D =[C5]=> IDLE, emit(make{Pause})
                .byte KBD_STATE_E11D45E19D, 0, KBD_STATE_IDLE, KBD_ACTION_IGNORE    ; STATE_E11D45E19D =[default]=> IDLE, ignore(x)

                .byte $FF, $FF, $FF, $FF                                            ; End of state machine

.align 256
;
; Table mapping unmodified scancodes to ASCII characters
;
SC_US_UNMOD     .byte $00, $1B, '1', '2', '3', '4', '5', '6'                        ; $00 - $07
                .byte '7', '8', '9', '0', '-', '=', $08, $09                        ; $08 - $0F
                .byte 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'                        ; $10 - $17
                .byte 'o', 'p', '[', ']', $0D, $00, 'a', 's'                        ; $18 - $1F
                .byte 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'                        ; $20 - $27
                .byte $27, '`', $00, '\', 'z', 'x', 'c', 'v'                        ; $28 - $2F
                .byte 'b', 'n', 'm', ',', '.', '/', $00, '*'                        ; $30 - $37
                .byte $00, ' ', $00, $8A, $8B, $8C, $8D, $8E                        ; $38 - $3F
                .byte $8F, $90, $91, $92, $93, $00, $00, $80                        ; $40 - $47
                .byte $86, $84, '-', $89, '5', $88, '+', $83                        ; $48 - $4F
                .byte $87, $85, $81, $82, $00, $00, $00, $94                        ; $50 - $57
                .byte $95, $00, $00, $00, $00, $00, $00, $00                        ; $58 - $5F
                .byte $00, $00, $81, $80, $84, $82, $83, $85                        ; $60 - $67
                .byte $86, $89, $87, $88, '/', $0D, $00, $00                        ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $78 - $7F

;
; Table mapping shifted scancodes to ASCII characters
;
SC_US_SHFT      .byte $00, $1B, '!', '@', '#', '$', '%', '^'                        ; $00 - $07
                .byte '&', '*', '(', ')', '_', '+', $08, $09                        ; $08 - $0F
                .byte 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I'                        ; $10 - $17
                .byte 'O', 'P', '{', '}', $0A, $00, 'A', 'S'                        ; $18 - $1F
                .byte 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':'                        ; $20 - $27
                .byte $22, '~', $00, '|', 'Z', 'X', 'C', 'V'                        ; $28 - $2F
                .byte 'B', 'N', 'M', '<', '>', '?', $00, $00                        ; $30 - $37
                .byte $00, ' ', $00, $8A, $8B, $8C, $8D, $8E                        ; $38 - $3F
                .byte $8F, $90, $91, $92, $93, $00, $00, $80                        ; $40 - $47
                .byte $86, $84, '-', $89, '5', $88, '+', $83                        ; $48 - $4F
                .byte $87, $85, $81, $82, $00, $00, $00, $94                        ; $50 - $57
                .byte $95, $00, $00, $00, $00, $00, $00, $00                        ; $58 - $5F
                .byte $00, $00, $81, $80, $84, $82, $83, $85                        ; $60 - $67
                .byte $86, $89, $87, $88, '/', $0D, $00, $00                        ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $78 - $7F

;
; Table mapping scancodes modified by CTRL to ASCII characters
;
SC_US_CTRL      .byte $00, $1B, '1', '2', '3', '4', '5', $1E                        ; $00 - $07
                .byte '7', '8', '9', '0', $1F, '=', $08, $09                        ; $08 - $0F
                .byte $11, $17, $05, $12, $14, $19, $15, $09                        ; $10 - $17
                .byte $0F, $10, $1B, $1D, $0A, $00, $01, $13                        ; $18 - $1F
                .byte $04, $06, $07, $08, $0A, $0B, $0C, ';'                        ; $20 - $27
                .byte $22, '`', $00, '\', $1A, $18, $03, $16                        ; $28 - $2F
                .byte $02, $0E, $0D, ',', '.', $1C, $00, $00                        ; $30 - $37
                .byte $00, ' ', $00, $8A, $8B, $8C, $8D, $8E                        ; $38 - $3F
                .byte $8F, $90, $91, $92, $93, $00, $00, $80                        ; $40 - $47
                .byte $86, $84, '-', $89, '5', $88, '+', $83                        ; $48 - $4F
                .byte $87, $85, $81, $82, $00, $00, $00, $94                        ; $50 - $57
                .byte $95, $00, $00, $00, $00, $00, $00, $00                        ; $58 - $5F
                .byte $00, $00, $81, $80, $84, $82, $83, $85                        ; $60 - $67
                .byte $86, $89, $87, $88, '/', $0D, $00, $00                        ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $78 - $7F


;
; Table mapping keys modified by capslock (<=$37) or numlock (>$37)
;
SC_US_LOCK      .byte $00, $1B, '1', '2', '3', '4', '5', '6'                        ; $00 - $07
                .byte '7', '8', '9', '0', '-', '=', $08, $09                        ; $08 - $0F
                .byte 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I'                        ; $10 - $17
                .byte 'O', 'P', '[', ']', $0D, $00, 'A', 'S'                        ; $18 - $1F
                .byte 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';'                        ; $20 - $27
                .byte $27, '`', $00, '\', 'Z', 'X', 'C', 'V'                        ; $28 - $2F
                .byte 'B', 'N', 'M', ',', '.', '/', $00, $00                        ; $30 - $37
                .byte $00, ' ', $00, $8A, $8B, $8C, $8D, $8E                        ; $38 - $3F
                .byte $8F, $90, $91, $92, $93, $00, $00, '7'                        ; $40 - $47
                .byte '8', '9', '-', '4', '5', '6', '+', '1'                        ; $48 - $4F
                .byte '2', '3', '0', '.', $00, $00, $00, $94                        ; $50 - $57
                .byte $95, $00, $00, $00, $00, $00, $00, $00                        ; $58 - $5F
                .byte $00, $00, $81, $80, $84, $82, $83, $85                        ; $60 - $67
                .byte $86, $89, $87, $88, '/', $0D, $00, $00                        ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $78 - $7F

;
; Table mapping scancodes to ASCII characters when CAPSLOCK and SHIFT are both active
;
SC_US_LOCK_SHFT .byte $00, $1B, '!', '@', '#', '$', '%', '^'                        ; $00 - $07
                .byte '&', '*', '(', ')', '_', '+', $08, $09                        ; $08 - $0F
                .byte 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'                        ; $10 - $17
                .byte 'o', 'p', '{', '}', $0A, $00, 'a', 's'                        ; $18 - $1F
                .byte 'd', 'f', 'g', 'h', 'j', 'k', 'l', ':'                        ; $20 - $27
                .byte $22, '~', $00, '|', 'z', 'x', 'c', 'v'                        ; $28 - $2F
                .byte 'b', 'n', 'm', '<', '>', '?', $00, $00                        ; $30 - $37
                .byte $00, ' ', $00, $00, $00, $00, $00, $00                        ; $38 - $3F
                .byte $8F, $90, $91, $92, $93, $00, $00, '7'                        ; $40 - $47
                .byte '8', '9', '-', '4', '5', '6', '+', '1'                        ; $48 - $4F
                .byte '2', '3', '0', '.', $00, $00, $00, $94                        ; $50 - $57
                .byte $95, $00, $00, $00, $00, $00, $00, $00                        ; $58 - $5F
                .byte $00, $00, $81, $80, $84, $82, $83, $85                        ; $60 - $67
                .byte $86, $89, $87, $88, '/', $0D, $00, $00                        ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $78 - $7F

;
; Table mapping scancodes to ASCII characters when CTRL and SHIFT are both active
;
SC_US_CTRL_SHFT .byte $00, $1B, '!', '@', '#', '$', '%', '^'                        ; $00 - $07
                .byte '&', '*', '(', ')', '_', '+', $08, $09                        ; $08 - $0F
                .byte $11, $17, $05, $12, $14, $19, $15, $09                        ; $10 - $17
                .byte $0F, $10, $1B, $1D, $0A, $00, $01, $13                        ; $18 - $1F
                .byte $04, $06, $07, $08, $0A, $0B, $0C, ';'                        ; $20 - $27
                .byte $22, '`', $00, '\', $1A, $18, $03, $16                        ; $28 - $2F
                .byte $02, $0E, $0D, ',', '.', $1C, $00, $00                        ; $30 - $37
                .byte $00, ' ', $00, $8A, $8B, $8C, $8D, $8E                        ; $38 - $3F
                .byte $8F, $90, $91, $92, $93, $00, $00, $80                        ; $40 - $47
                .byte $86, $84, '-', $89, '5', $88, '+', $83                        ; $48 - $4F
                .byte $87, $85, $81, $82, $00, $00, $00, $94                        ; $50 - $57
                .byte $95, $00, $00, $00, $00, $00, $00, $00                        ; $58 - $5F
                .byte $00, $00, $81, $80, $84, $82, $83, $85                        ; $60 - $67
                .byte $86, $89, $87, $88, '/', $0D, $00, $00                        ; $68 - $6F
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $70 - $77
                .byte $00, $00, $00, $00, $00, $00, $00, $00                        ; $78 - $7F
