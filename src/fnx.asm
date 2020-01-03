;;;
;;; FNX Parser
;;;

;;
;; Structures to support the various DT types
;;

DT_UNION    .union
; DT00 is the first DT in the file
DT00        .struct
SIGNATURE   .fill 3     ; 3 character signature (always "FNX")
VER         .byte ?     ; Version code for the entire file
NEXT        .dword ?    ; Offset in file to the next DT
COUNT       .word ?     ; Number of DTs in the file
MACHINE     .word ?     ; Code designating the target machine
            .ends

; This structure is for most DTs
DTxx        .struct
HEADER      .byte ? ; Should always be $55
TYPE        .byte ? ; Type of the DT: "A", "B", "C", or "D"
FUNC        .byte ? ; Function code for the DT
VER         .byte ? ; Version code
NEXT        .dword ?    ; Offset in file to the next DT
SIZE        .dword ?    ; Number of bytes in the payload
DEST        .dword ?    ; Destination address for the payload
            .ends

; This structure is for the last DT in the file
DTFF        .struct
HEADER      .byte ?     ; Should always be $FF
LINK        .byte ?     ; Code to indicate if we need to link to another file
FILENAME    .fill 8     ; File name of the linked file
FILEEXT     .fill 3     ; File extension of the linked file
LRC         .byte ?     ; LRC for the file (XOR of all bytes except LRC and CRC)
CRC         .byte ?     ; CRC for the file (sum of all bytes except CRC)
            .ends
            .endu

;;
;; Allocate variables
;;

FILE_BUFFER .fill 512               ; Buffer for File I/O
BUFF_IDX    .word ?                 ; Index to the current byte from the File I/O buffer
FNX_DT      .dunion DT_UNION        ; Buffer to hold the DT header
FNX_LRC     .byte ?                 ; Running LRC
FNX_CRC     .word ?                 ; Running CRC
FNX_POS     .dword ?                ; Current file offset for the current byte we're processing

;;
;; Routines
;;

; To parse FNX:
;   LRC := 0
;   CRC := 0
;   CURRENT_POSITION := 0
;
;   LOAD DT structure from file
;   Verify DT structure is "FNX" with VER = 0
;       If not: print error and return

;   SEEK TO NEXT
;   REPEAT:
;       LOAD DT structure from file
;       FIND HANDLER for the DT
;           If found: CALL HANDLER
;       SEEK to NEXT
;   UNTIL DT TYPE = FF
;
;   VERIFY LRC
;       If mismatch: print error message and return
;   VERIFY CRC
;       If mismatch: print error message and return
;
;   If there is a saved execution pointer:
;       JUMP to the pointer

; TO SEEK TO NEXT:
;   REPEAT:
;       READ A BYTE FROM FNX
;   UNTIL CURRENT_POSITION = NEXT

; TO LOAD DT:
;   FOR 16 bytes:
;       READ A BYTE FROM FNX
;       STORE BYTE X to the DT[X]

; TO READ A BYTE FROM FNX:
;   Read the byte from the file
;   LRC := LRC (+) the byte
;   CRC += the byte

; TO READ A BYTE FROM THE FILE:
;   If CURRENT_POSITION is outside the file:
;       display an error and quit
;   If CURRENT_POSITION is outside the file BUFFER:
;       Grab the next block from the file
;       If there are no more blocks:
;           display an error and quit
;       BUFFER_INDEX := 0
;   BYTE := BUFFER[BUFFER_INDEX]
;   BUFFER_INDEX++
;   CURRENT_POSITION++