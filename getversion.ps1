Get-Date -UFormat ".text ""%B %d, %Y""" | Out-File -FilePath src/version.asm -Encoding ASCII
