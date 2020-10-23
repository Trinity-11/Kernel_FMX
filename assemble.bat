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
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=%TARGET_SYS% --long-address --flat  -b -o kernel.bin --list kernel.lst --labels=kernel.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=%TARGET_SYS% --long-address --flat  --intel-hex -o kernel.hex --list kernel_hex.lst --labels=kernel_hex.lbl
if errorlevel 1 goto failas

REM copy kernel.hex ..\bin\debug\roms
REM copy kernel.lst ..\bin\debug\roms

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
