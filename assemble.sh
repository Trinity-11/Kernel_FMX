mkdir -p ../bin/roms

rm ./*.lst ./*.exe ./*.bin

# Generate a date stamp for the boot header
python3 genversion.py

# Set the target system (1 = C256 Foenix FMX, 2 = C256 Foenix U)
export TARGET_SYS=1

64tass --m65816 src/kernel.asm -D TARGET=1 -D TARGET_SYS=${TARGET_SYS} --long-address --flat  -b -o kernel.bin --list kernel.lst --labels=kernel.lbl
64tass --m65816 src/kernel.asm -D TARGET=2 -D TARGET_SYS=${TARGET_SYS} --long-address --flat  --intel-hex -o kernel.hex --list kernel_hex.lst --labels=kernel_hex.lbl

cp kernel.hex kernel_hex.lst ../bin/roms

