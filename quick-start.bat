@echo off
:: Quick Start - Clone and Setup Open Code
:: Run this in Command Prompt or PowerShell
:: Version: 1.0
:: Last Updated: 2026-01-31

setlocal enabledelayedexpansion

cls
echo ==========================================
echo   Open Code Quick Start
echo ==========================================
echo.
echo This will:
echo   1. Clone the vmcreation repository
echo   2. Run the automated Open Code setup
echo.
echo Repository URL:
echo   https://github.com/suppg02-sudo/vmcreation.git
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

:: Clone the repository
cls
echo ==========================================
echo   Step 1: Cloning Repository
echo ==========================================
echo.

if exist "vmcreation" (
    echo WARNING: vmcreation directory already exists.
    set "action=update"
    echo Updating existing repository...
    cd vmcreation
    git pull
    cd ..
) else (
    set "action=clone"
    echo Cloning repository...
    git clone https://github.com/suppg02-sudo/vmcreation.git
)

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to !action! repository.
    echo.
    echo Please ensure Git is installed and you have internet access.
    echo.
    pause
    exit /b 1
)

echo.
echo Press any key to continue with setup...
pause >nul

:: Run the setup
cls
echo ==========================================
echo   Step 2: Running Open Code Setup
echo ==========================================
echo.
echo The setup will automatically:
echo   - Request administrator privileges
echo   - Download and install Open Code
echo   - Install the Open Agents Control plugin
echo   - Create a desktop shortcut
echo   - Refresh environment variables
echo   - Launch Open Code (optional)
echo.

cd vmcreation
setup-opencode.bat

if %errorlevel% neq 0 (
    echo.
    echo Setup encountered errors. Please check the output above.
    echo.
)

cd ..
pause
