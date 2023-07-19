@echo off
REM Print the contents of memory, given the label of a pointer to the start address
REM usage: deref {label}
if [%2%]==[] (
    python FoenixMgr.zip --deref %1
) ELSE (
    python FoenixMgr.zip --deref %1 --count %2
)

