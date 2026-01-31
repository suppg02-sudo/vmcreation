@echo off
echo Checking VM logs with administrator privileges...
echo.

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0check_vm_logs.ps1""' -Verb RunAs -Wait"

echo.
echo VM log check complete.
pause