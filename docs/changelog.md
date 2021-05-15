# Change Log #

## Version: 0.4.0-alpha+274 (2021-05-13) ##

### Kernel Changes ###

1. ANSI terminal escape codes implemented for the main console screen.
1. EVID expansion card support added to kernel PUTC call, including ANSI terminal escape code support.
1. Keyboard input restructured to provide character level access (and ANSI escape codes) as well as scan code level access with the new kernel call `GETSCANCODE`.
1. Keyboard now supports translation tables from scan codes to ASCII or ISO-8859-1. A program can provide its own translation tables to support different keyboard layouts (kernel call `SETTABLE`).
1. Kernel call (`TESTBREAK`) added to test if a user has pressed the PAUSE/BREAK key.
1. Kernel calls `F_LOAD` and `F_RUN` now support the new PGZ multi-segement binary file format.
1. Expanded the kernel's interrupt handler vector table to allow a program to intercept specific interrupts without needing to take over the entire interrupt handling process.
1. Updated mouse driver code on the Foenix U and U+ so that a mouse is not required to boot or use the machine.

## BASIC816 Changes ##

1. Numerous bugfixes (see Github)
1. Added rwiker's transcendental math functions and operators for floating point, including: `SIN`, `COS`, `TAN`, `ACOS`, `ASIN`, `ATAN`, `EXP`, `SQR`, "`^`".
1. Added functions `INT` and `RND`.
1. Added function `INKEY` to return a C256 scan code.

