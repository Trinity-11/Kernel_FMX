@echo off
REM Print the contents of memory at the labeled address
REM usage: lookup {label}

if [%2%]==[] (
    python FoenixMgr.zip --lookup %1
) ELSE (
    python FoenixMgr.zip --lookup %1 --count %2
)