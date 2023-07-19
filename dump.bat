@echo off
REM Print the contents of memory
REM usage: dump {start address} [{byte count}]

if [%2%]==[] (
    python FoenixMgr.zip --dump %1
) ELSE (
    python FoenixMgr.zip --dump %1 --count %2
)