@echo off
:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    :: Running as admin, execute the script
    powershell -ExecutionPolicy Bypass -File "%~dp0vm-creation\create_ubuntu_vm_clean.ps1"
) else (
    :: Not running as admin, request elevation
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c cd /d %~dp0 && powershell -ExecutionPolicy Bypass -File \"%~dp0vm-creation\create_ubuntu_vm_clean.ps1\"' -Verb RunAs"
)
