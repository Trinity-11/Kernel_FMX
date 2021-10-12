mkdir -p ../bin/roms

find . -maxdepth 1 -regextype posix-extended -regex '^./kernel_(FMX|U|U_Plus)(_bin|_hex|).{4}$' -delete

# Generate a date stamp for the boot header
python3 genversion.py

# Target
export FLASH=1
export RAM=2

# Target System
export SYS_FMX=1
export SYS_U=2
export SYS_U_PLUS=3

# Kernel for the C256 Foenix FMX
64tass --m65816 -D TARGET=${FLASH} -D TARGET_SYS=${SYS_FMX} --long-address --flat          -b -o kernel_FMX.bin --list kernel_FMX_bin.lst --labels=kernel_FMX_bin.lbl src/kernel.asm
64tass --m65816 -D TARGET=${RAM}   -D TARGET_SYS=${SYS_FMX} --long-address --flat --intel-hex -o kernel_FMX.hex --list kernel_FMX_hex.lst --labels=kernel_FMX_hex.lbl src/kernel.asm
cp kernel_FMX.hex     ../bin/roms/
cp kernel_FMX_hex.lst ../bin/roms/kernel_FMX.lst

# Kernel for the C256 Foenix U
64tass --m65816 -D TARGET=${FLASH} -D TARGET_SYS=${SYS_U} --long-address --flat          -b -o kernel_U.bin --list kernel_U_bin.lst --labels=kernel_U_bin.lbl src/kernel.asm
64tass --m65816 -D TARGET=${RAM}   -D TARGET_SYS=${SYS_U} --long-address --flat --intel-hex -o kernel_U.hex --list kernel_U_hex.lst --labels=kernel_U_hex.lbl src/kernel.asm
cp kernel_U.hex     ../bin/roms/
cp kernel_U_hex.lst ../bin/roms/kernel_U.lst

# Kernel for the C256 Foenix U+
64tass --m65816 -D TARGET=${FLASH} -D TARGET_SYS=${SYS_U_PLUS} --long-address --flat          -b -o kernel_U_Plus.bin --list kernel_U_Plus_bin.lst --labels=kernel_U_Plus_bin.lbl src/kernel.asm
64tass --m65816 -D TARGET=${RAM}   -D TARGET_SYS=${SYS_U_PLUS} --long-address --flat --intel-hex -o kernel_U_Plus.hex --list kernel_U_Plus_hex.lst --labels=kernel_U_Plus_hex.lbl src/kernel.asm
cp kernel_U_Plus.hex     ../bin/roms/
cp kernel_U_Plus_hex.lst ../bin/roms/kernel_U_Plus.lst

