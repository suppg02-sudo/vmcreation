@echo off
:: VM Manager Launcher
:: Runs vmmanager.ps1 with administrator privileges

echo Starting VM Manager...
powershell -ExecutionPolicy Bypass -File "%~dp0vmmanager.ps1"
pause
