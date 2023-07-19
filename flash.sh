# Reprogram the flash memory on the C256 Foenix

if [ -n "$2" ]
then
    python3 FoenixMgr.zip --port /dev/ttyXRUSB0 --flash $1 --address $2
else
    python3 FoenixMgr.zip --port /dev/ttyXRUSB0 --flash $1
fi

