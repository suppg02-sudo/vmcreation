@echo off
REM Setup script to create Ctrl+Shift+T keyboard shortcut for ubuntu58-1 opencode
REM This script launches the PowerShell script to register the global hotkey

cd /d "%~dp0"

echo Setting up Ctrl+Shift+T keyboard shortcut for ubuntu58-1 opencode...
echo.

powershell -ExecutionPolicy Bypass -File register-shortcut.ps1

echo.
echo Shortcut setup complete!
echo A shortcut has been created on your Desktop: Ubuntu-OpenCode.lnk
echo.
echo Note: You may need to restart for the Ctrl+Shift+T global hotkey to take effect.
echo.
pause
