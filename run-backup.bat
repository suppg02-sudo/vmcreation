@echo off
REM run-backup.bat - Batch file to run Windows backup script
REM This batch file runs backup-windows.ps1 PowerShell script
REM for backing up Ubuntu VM to remote SSH server

echo ========================================
echo   Windows Backup Script for Ubuntu VM
echo ========================================
echo.
echo This script will run backup-windows.ps1 to perform
echo automated backups of your Ubuntu VM to remote server.
echo.
echo Usage:
echo   .\run-backup.bat -BackupType borg
echo   .\run-backup.bat -BackupType restic
echo.
echo Default backup type is: borg
echo.
echo Press any key to continue...
pause >nul

REM Run PowerShell script with execution policy
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0\backup-windows.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   ERROR: Backup script failed with exit code %ERRORLEVEL%
    echo ========================================
    echo.
    pause
)