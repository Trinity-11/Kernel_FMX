.cpu "65816"

;Cmd   Command      Params
;A     ASSEMBLE     [Start] [Assembly code]
;C     COMPARE      Start1 Start2 [Len (1 if blank)]
;D     DISASSEMBLE  Start [End]
;F     FILL         Start End Byte
;G     GO           [Address]
;J                  [Address]
;H     HUNT (find)  Start End Byte [Byte]...
;L     LOAD         "File" [Device] [Start]
;M     MEMORY       [Start] [End]
;R     REGISTERS    Register [Value]  (A 1234, F 00100011)
;;                  PC A X Y SP DBR DP NVMXDIZC
;S     SAVE         "File" Device Start End
;T     TRANSFER     Start End Destination
;V     VERIFY       "File" [Device] [Start]
;X     EXIT
;>     MODIFY       Start Byte [Byte]...
;@     DOS          [Command] Returns drive status if no params.
;?     HELP         Display a short help screen

;Monitor.asm
;Jump Table
* = $398000
MONITOR         JML IMONITOR
MSTATUS         JML IMSTATUS
MREADY          JML IMREADY
MRETURN         JML IMRETURN
MPARSE          JML IMPARSE
MPARSE1         JML IMPARSE1
MEXECUTE        JML IMEXECUTE
MASSEMBLE       JML IMASSEMBLE
MASSEMBLEA      JML IMASSEMBLEA
MCOMPARE        JML IMCOMPARE
MDISASSEMBLE    JML IMDISASSEMBLE
MFILL           JML IMFILL

MJUMP           JML IMJUMP
MHUNT           JML IMHUNT
MLOAD           JML IMLOAD
MMEMORY         JML IMMEMORY
MREGISTERS      JML IMREGISTERS
MSAVE           JML IMSAVE
MTRANSFER       JML IMTRANSFER
MVERIFY         JML IMVERIFY
MEXIT           JML IMEXIT
MMODIFY         JML IMMODIFY
MDOS            JML IMDOS

;
; IMONITOR
; monitor entry point. This initializes the monitor
; and prints the prompt.
; Make sure 16 bit mode is turned on
;
IMONITOR        CLC           ; clear the carry flag
                XCE           ; move carry to emulation flag.
                setal
                LDA #STACK_END ; Reset the stack
                TAS
                JML IMREADY

;
; IMREADY
; Print the status prompt, then wait for input
;
IMREADY         ;set the READY handler to jump here instead of BASIC
                setaxl
                LDA #<>IMREADY
                STA JMP_READY+1
                setas
                LDA #`IMREADY
                STA JMP_READY+3

                ;set the RETURN vector and then wait for keyboard input
                setal
                LDA #<>IMRETURN
                STA RETURN+1
                setas
                LDA #`IMRETURN
                STA RETURN+3

                JML IMSTATUS

;
; IMSTATUS
; Prints the regsiter status
; Reads the saved register values at CPU_REGISTERS
;
; PC     A    X    Y    SP   DBR DP   NVMXDIZC
; 000000 0000 0000 0000 0000 00  0000 00000000
;
; Arguments: none
; Modifies: A,X,Y
IMSTATUS        ; Print the MONITOR prompt (registers header)
                setdbr `mregisters_msg
                LDX #<>mregisters_msg
                JSL IPRINT

                setas
                LDA #';'
                JSL IPUTC

                setaxl
                setdbr $0
                ; print Program Counter
                LDY #3
                LDX #CPUPC+2
                JSL IPRINTH

                ; print A register
                LDA ' '
                JSL IPUTC
                LDY #2
                LDX #CPUA+1
                JSL IPRINTH

                ; print X register
                LDA ' '
                JSL IPUTC
                LDY #2
                LDX #CPUX+1
                JSL IPRINTH

                ; print Y register
                LDA ' '
                JSL IPUTC
                LDY #2
                LDX #CPUY+1
                JSL IPRINTH

                ; print Stack Pointer
                LDA ' '
                JSL IPUTC
                LDY #2
                LDX #CPUSTACK+1
                JSL IPRINTH

                ; print DBR
                LDA ' '
                JSL IPUTC
                LDY #1
                LDX #CPUDBR
                JSL IPRINTH

                ; print Direct Page
                LDA ' '
                JSL IPUTC
                JSL IPUTC
                LDY #2
                LDX #CPUDP+1
                JSL IPRINTH

                ; print Flags
                LDA ' '
                JSL IPUTC
                LDY #1
                LDX #CPUFLAGS
                JSL IPRINTH

                JSL IPRINTCR

                JML IREADYWAIT

IMRETURN        RTL ; Handle RETURN key (ie: execute command)
IMPARSE         BRK ; Parse the current command line
IMPARSE1        BRK ; Parse one word on the current command line
IMEXECUTE       BRK ; Execute the current command line (requires MCMD and MARG1-MARG8 to be populated)
IMASSEMBLE      BRK ; Assemble a line of text.
IMASSEMBLEA     BRK ; Assemble a line of text.
IMCOMPARE       BRK ; Compare memory. len=1
IMDISASSEMBLE   BRK ; Disassemble memory. end=1 instruction
IMFILL          BRK ; Fill memory with specified value. Start and end must be in the same bank.
IMGO            BRK ; Execute from specified address
IMJUMP          BRK ; Execute from spefified address
IMHUNT          BRK ; Hunt (find) value in memory
IMLOAD          BRK ; Load data from disk. Device=1 (internal floppy) Start=Address in file
IMMEMORY        BRK ; View memory
IMREGISTERS     BRK ; View/edit registers
IMSAVE          BRK ; Save memory to disk
IMTRANSFER      BRK ; Transfer (copy) data in memory
IMVERIFY        BRK ; Verify memory and file on disk
IMEXIT          BRK ; Exit monitor and return to BASIC command prompt
IMMODIFY        BRK ; Modify memory
IMDOS           BRK ; Execute DOS command

;
; MMESSAGES
; MONITOR messages and responses.
MMESSAGES
MMERROR         .text "Error", $00

mregisters_msg  .null $0D," PC     A    X    Y    SP   DBR DP   NVMXDIZC"
