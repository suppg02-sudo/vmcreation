@echo off
REM Connect to ubuntu58-1 via SSH as root and run opencode
REM Keyboard Shortcut: Ctrl+Shift+T (set via shortcut properties)
REM SSH keys should be configured for passwordless authentication
REM Password authentication is used only as fallback

REM Try SSH connection with keys (passwordless) - use -t for interactive session
REM Change to /media/docker directory before running opencode
REM Fallback to bash shell after opencode exits (including Ctrl+C)
ssh -t -o BatchMode=yes -o ConnectTimeout=2 root@ubuntu58-1 "cd /media/docker && /root/.opencode/bin/opencode; bash"

REM If SSH keys failed, try with password authentication
if %ERRORLEVEL% NEQ 0 (
    ssh -t root@ubuntu58-1 "cd /media/docker && /root/.opencode/bin/opencode; bash"
)
