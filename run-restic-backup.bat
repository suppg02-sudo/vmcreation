@echo off
REM run-restic-backup.bat - Batch file to run Restic backup script
REM This batch file runs backup-restic-windows.ps1 PowerShell script
REM for backing up Ubuntu VM to remote SSH server using Restic

setlocal

echo ========================================
echo   Restic Backup Script for Ubuntu VM
echo ========================================
echo.
echo Select Backup Target:
echo [1] srvdocker02 (User: usdaw) - Default
echo [2] ubhost      (User: suppg02)
echo.
set /p TARGET_CHOICE="Enter choice [1-2]: "

set REMOTE_HOST=srvdocker02
set REMOTE_USER=usdaw

if "%TARGET_CHOICE%"=="2" (
    set REMOTE_HOST=ubhost
    set REMOTE_USER=suppg02
)

echo.
echo Target: %REMOTE_HOST% (User: %REMOTE_USER%)
echo.
echo This script will:
echo   1. Stop VM: ubuntu58
echo   2. Backup to: %REMOTE_HOST% via SSH
echo   3. File location: /mnt/sda4
echo   4. Use Restic for backup
echo   5. Restart VM after backup
echo.
echo Press any key to continue...
pause >nul

REM Add Restic to PATH for this session
set PATH=%PATH%;C:\Users\Test\restic

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Run PowerShell script with execution policy
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%backup-restic-windows.ps1" -VMName "ubuntu58" -RemoteHost "%REMOTE_HOST%" -RemoteUser "%REMOTE_USER%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   ERROR: Backup script failed with exit code %ERRORLEVEL%
    echo ========================================
    echo.
    pause
)

endlocal
