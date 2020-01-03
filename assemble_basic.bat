@echo off

md ..\bin
md ..\bin\debug
md ..\bin\debug\roms

:start
del *.lst
64tass --m65816 src\kernel.asm -D TARGET=1 --long-address --flat  -b -o kernel.bin --list kernel.lst --labels=kernel.lbl
64tass --m65816 src\kernel.asm -D TARGET=2 --long-address --flat  --intel-hex -o kernel.hex --list kernel_hex.lst --labels=kernel_hex.lbl
if errorlevel 1 goto fail

COPY kernel.hex+..\BASIC816\basic816.hex kernel_basic.hex

:fail
choice /m "Try again?"
if errorlevel 2 goto end
goto start

:end
echo END OF LINE
