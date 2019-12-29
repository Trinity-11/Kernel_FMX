;;;
;;; Line printer example code (not yet incorporated into Kernel)
;;;

LPT_DATA_PORT = $AF1378
LPT_STATUS_PORT = $AF1379
LPT_CTRL_PORT = $AF137A

ppt_Main_loop
                setdbr `LPT_DATA_PORT

                ; write the data in the PPT port
                setas
                LDA #$55
                STA LPT_DATA_PORT
                setas
                LDX #2000
                JSL ILOOP_MS

                ;------------------
                ; read the status bits
                setas
                LDA LPT_STATUS_PORT

                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                setas
                LDX #2000
                JSL ILOOP_MS

                ;------------------
                ; send the strop  signal
                setas
                LDA LPT_CTRL_PORT     ; get the register content
                ORA #$01        ; set the strob bit
                STA LPT_CTRL_PORT
                LDX #200
                JSL ILOOP_MS
                setas

                LDA LPT_CTRL_PORT     ; get the register content
                AND #$FE        ; clear the strob bit
                STA LPT_CTRL_PORT
                LDX #2000
                JSL ILOOP_MS


                ;--------------
                ;--------------
                ;--------------

                setas
                LDA #$AA
                STA LPT_DATA_PORT
                setas
                LDX #2000
                JSL ILOOP_MS

                ;------------------
                ; read the status bits
                setas
                LDA LPT_STATUS_PORT

                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                setas
                LDX #2000
                JSL ILOOP_MS

                ;------------------
                ; send the strop  signal
                setas
                LDA LPT_CTRL_PORT     ; get the register content
                ;JSL UART_PUTHEX
               ;LDA #$A
                ;JSL UART_PUTC
                ;LDA #$D
                ;JSL UART_PUTC
                LDA LPT_CTRL_PORT     ; get the register content
                ORA #$01        ; set the strob bit
                STA LPT_CTRL_PORT
                LDA LPT_CTRL_PORT     ; get the register content
                ;JSL UART_PUTHEX
                ;LDA #$A
                ;JSL UART_PUTC
                ;LDA #$D
                ;JSL UART_PUTC
                ;LDA #$A
                ;JSL UART_PUTC
                ;LDA #$D
                ;JSL UART_PUTC
                LDX #200
                JSL ILOOP_MS
                setas
                LDA LPT_CTRL_PORT     ; get the register content
                AND #$FE        ; clear the strob bit
                STA LPT_CTRL_PORT
                LDX #2000
                JSL ILOOP_MS

                ;setdbr `minus_line
                ;LDX #<>minus_line
                ;JSL UART_PUTS

                BRL ppt_Main_loop