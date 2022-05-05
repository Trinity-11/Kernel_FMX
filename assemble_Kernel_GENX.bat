@echo off

md ..\bin
md ..\bin\debug
md ..\bin\debug\roms

REM Generate a date stamp for the boot header
python genversion.py

REM Set the target system (1 = C256 Foenix FMX, 2 = C256 Foenix U, 4 = GenX)
set TARGET_SYS=4

:start
del *.lst
REM COMPILE EVERY MODELS
REM KERNEL FMX 
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=%TARGET_SYS% --long-address --flat  -b -o kernel_GENX.bin --list kernel_GENX.lst --labels=kernel_GENX.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=%TARGET_SYS% --long-address --flat  --intel-hex -o kernel_GENX.hex --list kernel_GENX_hex.lst --labels=kernel_GENX_hex.lbl

if errorlevel 1 goto failas

REM copy kernel.hex ..\bin\debug\roms
REM copy kernel.lst ..\bin\debug\roms

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
