@echo off
REM Upload a binary file to the C256 Foenix

if [%2%]==[] (
    python FoenixMgr.zip --binary %1
) ELSE (
    python FoenixMgr.zip --binary %1 --address %2
)