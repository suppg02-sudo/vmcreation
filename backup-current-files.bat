@echo off
REM backup-current-files.bat - Backup current Restic backup files
REM This script creates a backup of the current working backup files

echo ========================================
echo   Backup Current Restic Backup Files
echo ========================================
echo.
echo This script will backup:
echo   1. backup-restic-windows.ps1
echo   2. run-restic-backup.bat
echo   3. setup-restic-windows.ps1
echo   4. setup-restic.bat
echo   5. README-Windows-Restic-Backup.md
echo.
echo Backups will be saved to: C:\Users\Test\Desktop\vmcreation\backup-files\
echo.

REM Create backup directory
set BACKUP_DIR=C:\Users\Test\Desktop\vmcreation\backup-files
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
)

REM Use PowerShell to get a safe timestamp for the folder name
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set TIMESTAMP=%%i

set TARGET_DIR=%BACKUP_DIR%\%TIMESTAMP%
mkdir "%TARGET_DIR%"

echo Backing up files to %TARGET_DIR%...

copy "C:\Users\Test\Desktop\vmcreation\backup-restic-windows.ps1" "%TARGET_DIR%\" >nul 2>&1
if %ERRORLEVEL% EQU 0 (echo   [OK] backup-restic-windows.ps1) else (echo   [FAIL] backup-restic-windows.ps1)

copy "C:\Users\Test\Desktop\vmcreation\run-restic-backup.bat" "%TARGET_DIR%\" >nul 2>&1
if %ERRORLEVEL% EQU 0 (echo   [OK] run-restic-backup.bat) else (echo   [FAIL] run-restic-backup.bat)

copy "C:\Users\Test\Desktop\vmcreation\setup-restic-windows.ps1" "%TARGET_DIR%\" >nul 2>&1
if %ERRORLEVEL% EQU 0 (echo   [OK] setup-restic-windows.ps1) else (echo   [FAIL] setup-restic-windows.ps1)

copy "C:\Users\Test\Desktop\vmcreation\setup-restic.bat" "%TARGET_DIR%\" >nul 2>&1
if %ERRORLEVEL% EQU 0 (echo   [OK] setup-restic.bat) else (echo   [FAIL] setup-restic.bat)

copy "C:\Users\Test\Desktop\vmcreation\README-Windows-Restic-Backup.md" "%TARGET_DIR%\" >nul 2>&1
if %ERRORLEVEL% EQU 0 (echo   [OK] README-Windows-Restic-Backup.md) else (echo   [FAIL] README-Windows-Restic-Backup.md)

echo.
echo ========================================
echo   Backup Complete
echo ========================================
echo.
