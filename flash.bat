@echo off
REM Reprogram the flash memory on the C256 Foenix

if [%2%]==[] (
    python FoenixMgr.zip --flash %1
) ELSE (
    python FoenixMgr.zip --flash %1 --address %2
)