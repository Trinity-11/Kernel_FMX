@echo off

md ..\bin
md ..\bin\debug
md ..\bin\debug\roms

REM Generate a date stamp for the boot header
python genversion.py

REM Set the target system (1 = C256 Foenix FMX, 2 = C256 Foenix U)
set TARGET_SYS=2

:start
del *.lst
REM COMPILE EVERY MODELS
REM KERNEL FMX 
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=2 --long-address --flat  -b -o kernel_U.bin --list kernel_U.lst --labels=kernel_U.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=2 --long-address --flat  --intel-hex -o kernel_U.hex --list kernel_U_hex.lst --labels=kernel_U_hex.lbl

if errorlevel 1 goto failas

REM copy kernel.hex ..\bin\debug\roms
REM copy kernel.lst ..\bin\debug\roms

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
