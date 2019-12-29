@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -UFormat \"%B %d, %Y\"" >version.txt
