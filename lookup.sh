# Print the contents of memory at the labeled address
# usage: lookup {label}

if [ -n "$2" ]
then
    python3 FoenixMgr.zip --port /dev/ttyXRUSB0 --lookup $1 --count $2
else
    python3 FoenixMgr.zip --port /dev/ttyXRUSB0 --lookup $1
fi

