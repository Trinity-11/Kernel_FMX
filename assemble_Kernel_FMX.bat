@echo off

md ..\bin
md ..\bin\debug
md ..\bin\debug\roms

REM Generate a date stamp for the boot header
python genversion.py

REM Set the target system (1 = C256 Foenix FMX, 2 = C256 Foenix U)
set TARGET_SYS=1

:start
del *.lst
REM COMPILE EVERY MODELS
REM KERNEL FMX 
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=1 --long-address --flat  -b -o kernel_FMX.bin --list kernel_FMX.lst --labels=kernel_FMX.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=1 --long-address --flat  --intel-hex -o kernel_FMX.hex --list kernel_FMX_hex.lst --labels=kernel_FMX_hex.lbl

if errorlevel 1 goto failas

REM copy kernel.hex ..\bin\debug\roms
REM copy kernel.lst ..\bin\debug\roms

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
