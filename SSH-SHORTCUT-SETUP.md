# SSH Shortcut Setup Documentation

## Overview
This documentation describes the complete setup for creating a Ctrl+Shift+T global keyboard shortcut that connects via SSH to ubuntu58-1 and runs opencode.

## Files Involved

### 1. [`setup-ubuntu-shortcut.bat`](setup-ubuntu-shortcut.bat)
**Purpose:** Main setup batch file that orchestrates the shortcut creation process.

**What it does:**
- Changes to the script directory
- Displays setup instructions
- Launches the PowerShell registration script with bypass execution policy
- Shows completion message and instructions

**How to use:**
```batch
.\setup-ubuntu-shortcut.bat
```

**Output:** Creates a desktop shortcut and may prompt to restart the computer.

---

### 2. [`register-shortcut.ps1`](register-shortcut.ps1)
**Purpose:** PowerShell script that creates the Windows shortcut with Ctrl+Shift+T hotkey.

**What it does:**
- Resolves the path to `connect-ubuntu58-1-opencode.bat`
- Creates a COM object for Windows shell shortcuts
- Creates `Ubuntu-OpenCode.lnk` on the Desktop
- Sets the target to the batch file
- Assigns `CTRL+SHIFT+T` as the hotkey
- Sets working directory to the script directory
- Saves the shortcut configuration

**Configuration:**
- **Target Path:** `connect-ubuntu58-1-opencode.bat`
- **Window Style:** 0 (Normal window - visible)
- **Hotkey:** CTRL+SHIFT+T

---

### 3. [`connect-ubuntu58-1-opencode.bat`](connect-ubuntu58-1-opencode.bat)
**Purpose:** Batch file that establishes the SSH connection and runs opencode.

**What it does:**
1. Attempts SSH connection to root@ubuntu58-1 with:
   - `-t` flag for interactive TTY allocation
   - `-o BatchMode=yes` for key-based authentication (passwordless)
   - `-o ConnectTimeout=2` for quick timeout on key failure
2. Changes directory to `/media/docker/commands` on the remote machine
3. Executes `/root/.opencode/bin/opencode` for interactive development
4. Falls back to password authentication if SSH keys fail
5. Starts a bash shell after opencode exits (allows continued CLI work after Ctrl+C)

**SSH Connection Details:**
```bash
ssh -t -o BatchMode=yes -o ConnectTimeout=2 root@ubuntu58-1 "cd /media/docker/commands && /root/.opencode/bin/opencode; bash"
```

**What it does:**
1. Connects to ubuntu58-1 as root with interactive TTY support
2. Changes to `/media/docker/commands` directory
3. Runs `opencode` for interactive development
4. Provides bash shell fallback for additional commands after exiting opencode

**Features:**
- SSH key authentication as primary method (passwordless)
- Password authentication as fallback
- Interactive terminal support
- Automatic bash shell fallback after opencode exit
- Fast timeout (2 seconds) for connection attempts

---

### 4. [`ubuntu-opencode.vbs`](ubuntu-opencode.vbs)
**Purpose:** VBScript helper for launching the batch file without showing console window.

**Note:** This file is created for reference but is not used in the current setup. The shortcut directly targets the batch file.

---

## Setup Instructions

### Prerequisites
- Windows 11
- SSH client installed and configured
- SSH keys configured for passwordless authentication to ubuntu58-1 as root
- PowerShell execution policy allows script execution (or bypassed via `-ExecutionPolicy Bypass`)

### Installation Steps

1. **Open Command Prompt or PowerShell**
   - Navigate to the vmcreation directory
   - Or run the batch file from wherever it's located

2. **Run the setup script**
   ```bash
   .\setup-ubuntu-shortcut.bat
   ```

3. **Review the output**
   - The script will create `Ubuntu-OpenCode.lnk` on your Desktop
   - It will display the keyboard shortcut assignment (Ctrl+Shift+T)

4. **Restart your computer (optional but recommended)**
   - While the shortcut may work immediately, restarting ensures the global hotkey is properly registered
   - This is especially important for system-wide hotkey support

5. **Test the shortcut**
   - Press **Ctrl+Shift+T** anywhere on your desktop
   - A terminal window should open and SSH into ubuntu58-1
   - The working directory will be `/media/docker/commands`
   - Opencode should launch automatically

### Post-Setup

After the setup completes, you can:
- Press **Ctrl+Shift+T** from anywhere to connect to ubuntu58-1 and run opencode
- Use the desktop shortcut `Ubuntu-OpenCode.lnk` to launch the connection
- Exit opencode with **Ctrl+C** to return to bash shell for additional commands
- Type `exit` in bash to close the terminal

---

## Troubleshooting

### Shortcut doesn't work after pressing Ctrl+Shift+T

**Solution:**
1. Restart your computer for the system to register the global hotkey
2. Check that the shortcut file exists: `C:\Users\Test\Desktop\Ubuntu-OpenCode.lnk`
3. Right-click the shortcut and verify the Hotkey is set to `Ctrl+Shift+T`

### SSH connection times out or fails

**Check:**
1. SSH keys are properly configured: `ssh root@ubuntu58-1 echo "test"`
2. ubuntu58-1 is reachable and online
3. The SSH server is running on port 22 (or adjust in the batch file)
4. User has appropriate permissions on ubuntu58-1

### Opencode command not found

**Check:**
1. `/root/.opencode/bin/opencode` exists on ubuntu58-1
2. The path is correct and executable: `ssh root@ubuntu58-1 /root/.opencode/bin/opencode --version`

### Terminal opens but closes immediately

**Check:**
1. Modify `connect-ubuntu58-1-opencode.bat` and remove the last line to prevent automatic close
2. Or use Task Scheduler to run the batch with "Run whether user is logged in or not" option

---

## File Backup

All files have been committed to the git repository:
```bash
git commit -m "Add SSH connection shortcut with Ctrl+Shift+T for ubuntu58-1 opencode"
```

---

## Customization

### Change the hotkey

Edit [`register-shortcut.ps1`](register-shortcut.ps1) line 32:
```powershell
$shortcut.Hotkey = "CTRL+SHIFT+T"  # Change to desired hotkey
```

### Change the opencode arguments

Edit [`connect-ubuntu58-1-opencode.bat`](connect-ubuntu58-1-opencode.bat):
```batch
ssh -t -o BatchMode=yes -o ConnectTimeout=2 root@ubuntu58-1 "cd /media/docker && /root/.opencode/bin/opencode; bash"
```

Replace with other opencode commands or arguments as needed.

### Change the working directory

Edit [`connect-ubuntu58-1-opencode.bat`](connect-ubuntu58-1-opencode.bat):
```batch
ssh -t -o BatchMode=yes -o ConnectTimeout=2 root@ubuntu58-1 "cd /media/docker/commands && /root/.opencode/bin/opencode; bash"
```

Replace `/media/docker/commands` with your desired working directory.

### Change the target host or user

Edit [`connect-ubuntu58-1-opencode.bat`](connect-ubuntu58-1-opencode.bat):
```batch
ssh -t -o BatchMode=yes -o ConnectTimeout=2 youruser@yourhost "cd /media/docker && /root/.opencode/bin/opencode; bash"
```

---

## Summary

The complete setup provides a seamless global keyboard shortcut (Ctrl+Shift+T) that:
- Connects to ubuntu58-1 as root via SSH (using key authentication)
- Automatically changes to `/media/docker/commands` directory
- Launches opencode for interactive development
- Provides bash shell fallback for additional commands
- Falls back to password authentication if needed

This enables rapid SSH-based development workflow with a single keypress from anywhere on the Windows desktop.
