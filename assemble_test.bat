@echo off

echo THIS ASSEMBLES CODE FOR THE PROTOTYPE. ASSEMBLES TO BANK 00

del *.lst
64tass src\boot_test.asm --long-address --intel-hex -o kernel.hex --list kernel.lst
if errorlevel 1 goto end

copy kernel.hex ..\bin\debug\roms
copy kernel.lst ..\bin\debug\roms

:end
pause

