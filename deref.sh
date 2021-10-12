# Print the contents of memory, given the label of a pointer to the start address
# usage: deref {label}

if [ -n "$2" ]
then
    python3 C256Mgr/c256mgr.py --port /dev/ttyXRUSB0 --deref $1 --count $2
else
    python3 C256Mgr/c256mgr.py --port /dev/ttyXRUSB0 --deref $1
fi

