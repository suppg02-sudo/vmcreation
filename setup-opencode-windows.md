# Open Code Installation Guide for Windows

This guide provides step-by-step instructions for installing Open Code on Windows and setting up the Open Agents Control plugin.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install Open Code on Windows](#install-opencode-on-windows)
3. [Install Open Agents Control Plugin](#install-open-agents-control-plugin)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before proceeding, ensure you have:

- Windows 10 or Windows 11
- Administrator privileges (required for installation)
- Internet connection for downloading Open Code
- At least 500 MB of free disk space

---

## Install Open Code on Windows

### Method 1: Download and Install (Recommended)

1. **Download Open Code**
   - Visit the official Open Code website: https://opencode.dev/download
   - Select the Windows version (x64 recommended for most systems)
   - Download the installer (typically `.exe` or `.msi` file)

2. **Run the Installer**
   - Locate the downloaded installer file
   - Right-click and select "Run as administrator"
   - Follow the installation wizard:
     - Accept the license agreement
     - Choose installation location (default: `C:\Program Files\Open Code`)
     - Select additional tasks:
       - [x] Create a desktop shortcut
       - [x] Add Open Code to PATH (recommended)
       - [x] Register Open Code as default editor for supported files

3. **Complete Installation**
   - Click "Install" and wait for the installation to complete
   - Click "Finish" to exit the installer

### Method 2: Using PowerShell (Automated)

Save the following script as `install-opencode.ps1` and run it:

```powershell
# Open Code Automated Installation Script
# Run as Administrator

$ErrorActionPreference = "Stop"
Write-Host "Starting Open Code installation..." -ForegroundColor Green

# Define download URL and paths
$downloadUrl = "https://opencode.dev/latest/win32-x64-user/OpenCodeSetup.exe"
$installerPath = "$env:TEMP\OpenCodeSetup.exe"

# Download installer
Write-Host "Downloading Open Code installer..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing

# Install silently
Write-Host "Installing Open Code..." -ForegroundColor Yellow
Start-Process -FilePath $installerPath -ArgumentList "/silent", "/mergetasks=!runcode" -Wait

# Clean up
Remove-Item $installerPath -Force

Write-Host "Open Code installation completed successfully!" -ForegroundColor Green
Write-Host "You can now launch Open Code from the Start menu." -ForegroundColor Cyan
```

**To run the script:**
```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install-opencode.ps1
```

### Method 3: Using Chocolatey

If you have Chocolatey package manager installed:

```powershell
# Open PowerShell as Administrator
choco install opencode -y
```

---

## Install Open Agents Control Plugin

### Method 1: Using Open Code Extensions Marketplace

1. **Launch Open Code**
   - Open Open Code from the Start menu or desktop shortcut

2. **Open Extensions View**
   - Press `Ctrl+Shift+X` or click the Extensions icon (square puzzle piece) in the left sidebar
   - Alternatively, go to `View` > `Extensions`

3. **Search for Open Agents Control**
   - In the search box, type: `Open Agents Control`
   - Look for the official extension by the Open Code team

4. **Install the Plugin**
   - Click the "Install" button on the Open Agents Control extension
   - Wait for the installation to complete
   - Click "Reload" when prompted to restart Open Code

### Method 2: Using Command Line

```powershell
# Using Open Code command line (opencode)
opencode --install-extension openagents.open-agents-control
```

### Method 3: Manual Installation (.vsix file)

1. **Download the Extension**
   - Visit: https://opencode.dev/marketplace
   - Search for "Open Agents Control"
   - Download the `.vsix` file

2. **Install the Extension**
   ```powershell
   # Navigate to the directory containing the .vsix file
   cd "path\to\downloaded\extension"
   
   # Install using opencode command
   opencode --install-extension open-agents-control.vsix
   ```

---

## Verification

### Verify Open Code Installation

1. **Check Version**
   ```powershell
   opencode --version
   ```

2. **Launch Open Code**
   - Press `Win + R`, type `opencode`, and press Enter
   - Or double-click the desktop shortcut

### Verify Open Agents Control Plugin

1. **Check Installed Extensions**
   - Open Open Code
   - Press `Ctrl+Shift+X` to open Extensions view
   - Click "Installed" tab
   - Look for "Open Agents Control" in the list

2. **Test Plugin Functionality**
   - Open Open Code
   - Press `Ctrl+Shift+P` to open Command Palette
   - Type "Open Agents" and verify available commands appear

---

## Configuration

### Open Agents Control Settings

After installation, configure the plugin:

1. Open Open Code Settings (`Ctrl+,`)
2. Search for "openagents"
3. Configure the following settings:

```json
{
  "openagents.server.enabled": true,
  "openagents.server.port": 3000,
  "openagents.server.host": "localhost",
  "openagents.logging.level": "info"
}
```

### Environment Variables (Optional)

Set environment variables for advanced configuration:

```powershell
# Set Open Agents server port
[System.Environment]::SetEnvironmentVariable('OPENAGENTS_PORT', '3000', 'User')

# Set Open Agents log level
[System.Environment]::SetEnvironmentVariable('OPENAGENTS_LOG_LEVEL', 'debug', 'User')
```

---

## Troubleshooting

### Issue: Installation Fails

**Symptom:** Installer crashes or fails to complete

**Solutions:**
1. Run the installer as Administrator
2. Temporarily disable antivirus software
3. Check Windows Event Viewer for error logs:
   ```powershell
   Get-WinEvent -LogName Application | Where-Object {$_.Message -like "*Open Code*"} | Select-Object TimeCreated, Message
   ```

### Issue: Extension Won't Install

**Symptom:** Extension installation hangs or fails

**Solutions:**
1. Check internet connection
2. Verify Open Code is running with administrator privileges
3. Clear extension cache:
   ```powershell
   # Close Open Code first
   Remove-Item -Path "$env:USERPROFILE\.opencode\extensions" -Recurse -Force
   ```

### Issue: Plugin Not Detected

**Symptom:** Open Agents Control doesn't appear in Extensions list

**Solutions:**
1. Restart Open Code
2. Check if extension is disabled:
   - Open Extensions view
   - Click "Installed" tab
   - Look for "Open Agents Control" and ensure it's enabled
3. Reinstall the extension:
   ```powershell
   opencode --uninstall-extension openagents.open-agents-control
   opencode --install-extension openagents.open-agents-control
   ```

### Issue: Plugin Commands Not Working

**Symptom:** Open Agents commands don't appear in Command Palette

**Solutions:**
1. Reload Open Code window: `Ctrl+Shift+P` > "Developer: Reload Window"
2. Check Open Code output logs:
   - Press `Ctrl+Shift+U` to open Output panel
   - Select "Open Agents Control" from the dropdown
3. Verify plugin settings are correct

### Issue: Port Already in Use

**Symptom:** Open Agents server fails to start due to port conflict

**Solutions:**
1. Find process using the port:
   ```powershell
   netstat -ano | findstr :3000
   ```
2. Kill the conflicting process or change the port in settings

---

## Uninstallation

### Uninstall Open Code

1. **Using Windows Settings**
   - Go to `Settings` > `Apps` > `Installed apps`
   - Search for "Open Code"
   - Click "Uninstall" and follow the prompts

2. **Using PowerShell**
   ```powershell
   # Find Open Code in registry
   Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | 
       Get-ItemProperty | 
       Where-Object {$_.DisplayName -like "*Open Code*"} | 
       Select-Object DisplayName, UninstallString
   ```

### Uninstall Open Agents Control Plugin

```powershell
opencode --uninstall-extension openagents.open-agents-control
```

---

## Additional Resources

- Open Code Documentation: https://opencode.dev/docs
- Open Agents Control Documentation: https://opencode.dev/docs/extensions/open-agents-control
- Open Code Community Forum: https://forum.opencode.dev
- Issue Tracker: https://github.com/opencode/opencode/issues

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-31 | Initial version |

---

## Notes

- This guide assumes Open Code is actively maintained and available at the URLs provided
- If URLs change, please update this document accordingly
- Always download software from official sources to avoid security risks
