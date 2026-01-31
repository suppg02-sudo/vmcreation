# Register global Ctrl+Shift+T keyboard shortcut via Windows Registry
# This creates a registry entry that Windows recognizes as a global shortcut

$batchPath = (Resolve-Path "connect-ubuntu58-1-opencode.bat").Path
$batchDir = Split-Path -Parent $batchPath

# Create registry path
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HotKey"

# Ensure registry path exists
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Register the shortcut
# Note: Global hotkeys via registry can be tricky. This creates the entry but may require restart
$hotKeyValue = @{
    Name     = "Ctrl+Shift+T"
    Path     = "cmd.exe"
    IconPath = "cmd.exe"
}

Write-Host "Creating desktop shortcut with Ctrl+Shift+T hotkey..."

$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = "$env:USERPROFILE\Desktop\Ubuntu-OpenCode.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $batchPath
$shortcut.Arguments = ""
$shortcut.WorkingDirectory = $batchDir
$shortcut.Description = "SSH to ubuntu58-1 and run opencode"
$shortcut.Hotkey = "CTRL+SHIFT+T"
$shortcut.WindowStyle = 0  # Normal window
$shortcut.Save()

Write-Host "Shortcut created at: $shortcutPath"
Write-Host "Keyboard shortcut: Ctrl+Shift+T"
Write-Host ""
Write-Host "Note: You may need to restart for the global hotkey to take effect."
