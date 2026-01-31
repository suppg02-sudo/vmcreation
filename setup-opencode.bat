@echo off
:: Open Code Setup Launcher
:: This script launches the Open Code installation and plugin setup
:: Version: 1.0
:: Last Updated: 2026-01-31

setlocal enabledelayedexpansion

:: Set script directory
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ==========================================
    echo   Open Code Setup
    echo ==========================================
    echo.
    echo ERROR: This script requires administrator privileges.
    echo.
    echo Please:
    echo   1. Right-click on this file
    echo   2. Select "Run as administrator"
    echo.
    pause
    exit /b 1
)

cls
echo ==========================================
echo   Open Code Setup
echo ==========================================
echo.
echo This script will:
echo   1. Install Open Code on Windows
echo   2. Install the Open Agents Control plugin
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

:: Step 1: Install Open Code
cls
echo ==========================================
echo   Step 1: Installing Open Code
echo ==========================================
echo.

if exist "%SCRIPT_DIR%\install-opencode.ps1" (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\install-opencode.ps1"
    if !errorlevel! neq 0 (
        echo.
        echo ERROR: Open Code installation failed.
        echo.
        pause
        exit /b 1
    )
) else (
    echo ERROR: install-opencode.ps1 not found in: %SCRIPT_DIR%
    echo.
    pause
    exit /b 1
)

echo.
echo Press any key to continue with plugin installation...
pause >nul

:: Step 2: Install Open Agents Control plugin
cls
echo ==========================================
echo   Step 2: Installing Open Agents Control Plugin
echo ==========================================
echo.

if exist "%SCRIPT_DIR%\install-openagents-plugin.ps1" (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\install-openagents-plugin.ps1"
    if !errorlevel! neq 0 (
        echo.
        echo WARNING: Plugin installation encountered errors.
        echo You may need to install the plugin manually from Open Code.
        echo.
    )
) else (
    echo ERROR: install-openagents-plugin.ps1 not found in: %SCRIPT_DIR%
    echo.
    pause
    exit /b 1
)

:: Complete
cls
echo ==========================================
echo   Setup Complete!
echo ==========================================
echo.
echo Open Code and the Open Agents Control plugin have been installed.
echo.
echo Next Steps:
echo   1. Launch Open Code from the Start menu
echo   2. Press Ctrl+Shift+X to open Extensions view
echo   3. Verify "Open Agents Control" is installed
echo   4. Press Ctrl+Shift+P and type "Open Agents" to see available commands
echo.
echo For more information, see: setup-opencode-windows.md
echo.
pause
