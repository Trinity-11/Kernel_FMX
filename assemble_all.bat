@echo off

REM Assemble the kernel for all versions of the C256 Foenix

md ..\bin
md ..\bin\debug
md ..\bin\debug\roms

REM Generate a date stamp for the boot header
python genversion.py

REM Set the target system (1 = C256 Foenix FMX, 2 = C256 Foenix U, 3 = C256 Foenix U+)

:start
del *.lst

REM Kernel for the FMX
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=1 --long-address --flat  -b -o kernel_FMX.bin --list kernel_FMX.lst --labels=kernel_FMX.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=1 --long-address --flat  --intel-hex -o kernel_FMX.hex --list kernel_FMX_hex.lst --labels=kernel_FMX_hex.lbl

if errorlevel 1 goto failas

REM Kernel for the U
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=2 --long-address --flat  -b -o kernel_U.bin --list kernel_U.lst --labels=kernel_U.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=2 --long-address --flat  --intel-hex -o kernel_U.hex --list kernel_U_hex.lst --labels=kernel_U_hex.lbl

if errorlevel 1 goto failas

REM Kernel for the U+
64tass --m65816 src\kernel.asm -D TARGET=1 -D TARGET_SYS=3 --long-address --flat  -b -o kernel_U_Plus.bin --list kernel_U_Plus.lst --labels=kernel_U_Plus.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 -D TARGET_SYS=3 --long-address --flat  --intel-hex -o kernel_U_Plus.hex --list kernel_U_Plus_hex.lst --labels=kernel_U_Plus_hex.lbl

if errorlevel 1 goto failas

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
