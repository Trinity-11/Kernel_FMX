;MONITOR_INC.asm
;MONITOR ROM jump table
MONITOR          = $198000 ; Cold boot routine
MBREAK           = $198004 ; Warm boot routine
MSTATUS          = $198008 ; Print status message
MREADY           = $19800C ; Prints status message and waits for input
MRETURN          = $198010 ; Handle RETURN key (ie: execute command)
MPARSE           = $198014 ; Parse the current command line
MPARSE1          = $198018 ; Parse one word on the current command line
MEXECUTE         = $19801C ; Execute the current command line (requires MCMD and MARG1-MARG8 to be populated)
MASSEMBLE        = $198020 ; Assemble a line of text.
MASSEMBLEA       = $198024 ; Assemble a line of text.
MCOMPARE         = $198028 ; Compare memory. len=1
MDISASSEMBLE     = $19802C ; Disassemble memory. end=1 instruction
MFILL            = $198030 ; Fill memory with specified value. Start and end must be in the same bank.

MJUMP            = $198038 ; Execute from spefified address
MHUNT            = $19803C ; Hunt (find) value in memory
MLOAD            = $198040 ; Load data from disk. Device=1 (internal floppy) Start=Address in file
MMEMORY          = $198044 ; View memory
MREGISTERS       = $198048 ; View/edit registers
MSAVE            = $19804C ; Save memory to disk
MTRANSFER        = $198050 ; Transfer (copy) data in memory
MVERIFY          = $198054 ; Verify memory and file on disk
MEXIT            = $198058 ; Exit monitor and return to BASIC command prompt
MMODIFY          = $19805C ; Modify memory
MDOS             = $198060 ; Execute DOS command
