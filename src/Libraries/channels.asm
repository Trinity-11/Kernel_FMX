;;
;; Support code and structures to implement a common I/O channel system
;; Channels will support basic character or byte channel level I/O.
;;
;; Each channel will consist of a channel type number and a block of channel-specific data:
;; A set of functions can be called on channels:
;;      CLOSE -- shuts the channel down, flushes any written data to the endpoint, and frees resources
;;      READBUF size, buffer --> count -- Attempt to read SIZE bytes into BUFFER, return the COUNT of bytes read
;;      WRITEBUF size, buffer --> count -- Attempt to write SIZE bytes from BUFFER, return COUNT of bytes written
;;      FLUSH -- Attempt to commit all written bytes to the channel's endpoint
;;      COMMAND cmd, argument --> response -- Issue a command to the channel
;;      GETSTATUS --> status -- Get the status of the channel
;;
;; Each channel type will have its own "OPEN" function which allocates and returns a channel, but the nature
;; of that call will be specific to that type.
;;
;; Some channels will be open by default and will not be closable:
;;      0 = the main console (screen and keyboard)
;;      1 = The COM1 serial port
;;      2 = The COM2 serial port
;;      3 = Reserved for the LPT port in the future (not implemented)
;;      4 = The second screen (EVID)
;;      5 - 7 = Reserved for future use
;;
;; Channels 8 - 255 will be for dynamic allocation
;;

;
; Structure defining a channel type
;
S_CHANNEL_TYPE      .struct
NAME                .fill 8         ; Name of the channel (space padded... e.g. "CON     ", "SERIAL  ", "FILE    ")
DIRECTPAGE          .word ?         ; The value of the direct page to assume before running a function of this type
DATABANK            .byte ?         ; The value of the data bank register to assume before running a function of this type
CODEBANK            .byte ?         ; The code bank holding all the functions
CLOSE               .word ?         ; 24-bit pointer to the CLOSE function
READBUF             .word ?         ; 24-bit pointer to the READBUF function
WRITEBUF            .word ?         ; 24-bit pointer to the WRITEBUF function
FLUSH               .word ?         ; 24-bit pointer to the FLUSH function
COMMAND             .word ?         ; 24-bit pointer to the COMMAND function
GETSTATUS           .word ?         ; 24-bit pointer to the GETSTATUS function
                    .ends

;
; Structure defining a channel. Each open 
;
S_CHANNEL           .struct
TYPE                .byte ?         ; Number of the channel type ($FF = closed)
DATA                .fill 31        ; Data bytes available for channel specific state data.
                    .ends
