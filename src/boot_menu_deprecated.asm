;
; Display the boot menu / splash screen and give the user some time to respond
;
; Outputs:
;   A = 0 for no response
;       CR for boot to BASIC
;       F1 for boot to floppy
;       F2 for boot to SDC
;       F3 for boot to IDE
;
; February 6th Changes, this is depracated till somebody decides that they don't like the SplashScreen Code ;)
; I will keep this in case
.comment
BOOT_MENU       .proc
                PHB
                PHP

                setas
                setxl
                LDA #`bootmenu          ; Point DBR:X to the boot menu
                PHA
                PLB
                LDX #<>bootmenu         

                JSL PUTS                ; Display the boot menu
                                        ; TODO: replace with the splash screen

                setxl
                LDY #1000               ; Number of cycles we'll wait... total wait time is about 30s (ish)

                setas
wait_key        LDX #100
                JSL ILOOP_MS            ; Wait ...
                DEY                     ; Count down the tenths of seconds
                BEQ timeout             ; If we've got to 0, we're done

                JSL GETSCANCODE         ; Try to get a character
                CMP #0                  ; Did we get anything
                BEQ wait_key            ; No: keep waiting until timeout

                CMP #CHAR_F1            ; Did the user press F1?
                BEQ return              ; Yes: return it
                CMP #CHAR_F2            ; Did the user press F2?
                BEQ return              ; Yes: return it
                CMP #CHAR_F3            ; Did the user press F3?
                BEQ return              ; Yes: return it
                CMP #SCAN_CR            ; Did the user press CR?
                BEQ return              ; Yes: return it
                CMP #SCAN_SP            ; Did the user press SPACE?
                BNE wait_key            ; No: keep waiting

timeout         LDA #0                  ; Return 0 for a timeout / SPACE

return          PLP
                PLB
                RTL

.if TARGET_SYS == SYS_C256_FMX                
  bootmenu        .null "F1=FDC, F2=SDC, F3=IDE, RETURN=BASIC, SPACE=DEFAULT", CHAR_CR
.else
  bootmenu        .null "F2=SDC, F3=IDE, RETURN=BASIC, SPACE=DEFAULT", CHAR_CR
.endif
                .pend
.endc