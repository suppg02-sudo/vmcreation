@echo off
:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    PowerShell -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList ''"
    exit /b
)
echo Running VM creation script with administrator privileges...
echo This script creates a Ubuntu VM with fully automated SSH configuration.
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0create_ubuntu_vm_clean.ps1"