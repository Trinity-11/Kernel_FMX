@echo off

md ..\bin
md ..\bin\debug
md ..\bin\debug\roms

REM Generate a date stamp for the boot header
python genversion.py

REM Set the target system (1 = C256 Foenix FMX, 2 = C256 Foenix U, 3 = C256 Foenix U+)
set TARGET_SYS=3

:start
del *.lst
REM COMPILE EVERY MODELS
REM KERNEL FMX 
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=%TARGET_SYS% --long-address --flat  -b -o kernel_U_Plus.bin --list kernel_U_Plus.lst --labels=kernel_U_Plus.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=%TARGET_SYS% --long-address --flat  --intel-hex -o kernel_U_Plus.hex --list kernel_U_Plus_hex.lst --labels=kernel_U_Plus_hex.lbl

if errorlevel 1 goto failas

REM copy kernel.hex ..\bin\debug\roms
REM copy kernel.lst ..\bin\debug\roms

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
