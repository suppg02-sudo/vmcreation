@echo off
REM add-restic-to-path.bat - Add Restic to current session PATH
REM This batch file adds Restic to the PATH for the current session

echo Adding Restic to PATH for current session...
set PATH=%PATH%;C:\Users\Test\restic
echo.
echo Restic has been added to PATH for this session.
echo.
echo Testing Restic installation...
restic version
echo.
echo Note: To make this change permanent, run setup-restic.bat again
echo       or manually add C:\Users\Test\restic to your system PATH.
echo.
pause
