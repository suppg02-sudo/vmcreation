@echo off
echo UrBackup Web Interface Fix
echo ===========================
echo.
echo This will:
echo  1. Create Windows Firewall rules for UrBackup
echo  2. Restart the UrBackup service
echo  3. Test if the web interface is accessible
echo.
echo This requires ADMINISTRATOR privileges.
echo.
pause

PowerShell.exe -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell.exe -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0fix-urbackup-web-interface.ps1""' -Verb RunAs}"
