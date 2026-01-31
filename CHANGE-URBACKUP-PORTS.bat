@echo off
echo UrBackup Port Change Script
echo ===========================
echo.
echo This will change UrBackup ports to:
echo   Web Interface: 8080 (from 55414)
echo   Server: 55513 (from 55413)
echo   Internet: 55515 (from 55415)
echo.
echo This requires ADMINISTRATOR privileges.
echo.
pause

PowerShell.exe -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell.exe -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0change-urbackup-ports.ps1""' -Verb RunAs}"
