@echo off
REM Connect to ubuntu58-1 via SSH as root and run opencode
REM Keyboard Shortcut: Ctrl+Shift+T (set via shortcut properties)
REM SSH keys should be configured for passwordless authentication
REM Password authentication is used only as fallback

REM Try SSH connection with keys (passwordless) - use -t for interactive session
REM Change to /media/docker directory before listing opencode sessions
REM Fallback to bash shell after listing sessions
ssh -t -o BatchMode=yes -o ConnectTimeout=2 root@ubuntu58-1 "cd /media/docker && ls -la .opencode/sessions 2>/dev/null || echo 'No sessions found'; bash"

REM If SSH keys failed, try with password authentication
if %ERRORLEVEL% NEQ 0 (
    ssh -t root@ubuntu58-1 "cd /media/docker && ls -la .opencode/sessions 2>/dev/null || echo 'No sessions found'; bash"
)
