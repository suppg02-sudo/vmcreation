@echo off
REM setup-restic.bat - Batch file to run Restic setup script
REM This batch file runs setup-restic-windows.ps1 PowerShell script
REM to download and install Restic on Windows

echo ========================================
echo   Restic Setup for Windows
echo ========================================
echo.
echo This script will:
echo   1. Download latest Restic for Windows
echo   2. Extract to user profile directory
echo   3. Add to system PATH
echo.
echo Press any key to continue...
pause >nul

REM Run PowerShell script with execution policy
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& '%~dp0\setup-restic-windows.ps1'"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   ERROR: Setup script failed with exit code %ERRORLEVEL%
    echo ========================================
    echo.
    pause
)
