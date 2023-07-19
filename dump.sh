# Print the contents of memory
# usage: dump {start address} [{byte count}]

if [ -n "$2" ]
then
    python3 FoenixMgr.zip --port /dev/ttyXRUSB0 --dump $1 --count $2
else
    python3 FoenixMgr.zip --port /dev/ttyXRUSB0 --dump $1
fi

