# Create shortcut with Ctrl+Shift+T keyboard shortcut for connect-ubuntu58-1-opencode.bat

$batchFile = "connect-ubuntu58-1-opencode.bat"
$shortcutPath = "connect-ubuntu58-1-opencode - Shortcut.lnk"

# Create WScript.Shell object
$WshShell = New-Object -ComObject WScript.Shell

# Create shortcut
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = (Resolve-Path $batchFile).Path
$Shortcut.WorkingDirectory = (Get-Location).Path
$Shortcut.Description = "SSH to ubuntu58-1 and run opencode"

# Set keyboard shortcut to Ctrl+Shift+T
# Hotkey format: (modifier * 256) + key_code
# Ctrl = 2, Shift = 4, Ctrl+Shift = 6
# T = 84
$Shortcut.Hotkey = 1620  # Ctrl+Shift+T ((6 * 256) + 84)

# Save shortcut
$Shortcut.Save()

# Release COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null

Write-Host "Shortcut created successfully: $shortcutPath"
Write-Host "Keyboard shortcut: Ctrl+Shift+T"
Write-Host ""
Write-Host "You can now press Ctrl+Shift+T to connect to ubuntu58-1 and run opencode."
Write-Host ""
Write-Host "Note: If the shortcut doesn't work immediately, try:"
Write-Host "  1. Moving the shortcut to your Desktop"
Write-Host "  2. Logging out and back in"
Write-Host "  3. Restarting your computer"
