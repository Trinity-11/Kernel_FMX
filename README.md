# Kernel_FMX #

This is the latest KERNEL that will support the Foenix computers: FMX, U, and U+.

## Build Process ##

This project is coded for the 64TASS assembler and includes the assembler package for convenience. To build the kernel, run one of the `ASSEMBLE_*.BAT` files included. There is one batch file for each target computer as well as one that builds for all target machines.

If there is a new kernel call provided, an entry must be added to the template file `src/kernel_inc.txt`. After the project has been built, the Python script `genjumptable.py` should be run. This will update the `src/kernel_inc.asm` file, to include an entry for the new entry point. This include file may be used by programs to access the kernel subroutines.

When building, it is handy to have Python 3 available so that the Python script `genversion.py` can run, which automatically updates the version build number on each build.

## Changes ##

See [CHANGELOG.MD](docs/changelog.md) for a list of changes.
