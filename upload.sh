# Upload a binary file to the C256 Foenix

if [ -n "$2" ]
then
    python3 C256Mgr/c256mgr.py --port /dev/ttyXRUSB0 --binary $1 --address $2
else
    python3 C256Mgr/c256mgr.py --port /dev/ttyXRUSB0 --binary $1
fi

