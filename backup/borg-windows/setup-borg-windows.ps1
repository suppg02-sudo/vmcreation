# BorgBackup for Windows - Setup Script
# Version: 1.0
# Last Updated: 2025-12-27
# Description: Install and configure BorgBackup on Windows for VHD backup

#Requires -RunAsAdministrator

Write-Host "=== BorgBackup Windows Setup ===" -ForegroundColor Green

# Configuration
$BorgInstallPath = "C:\Program Files\Borg"
$BorgDownloadUrl = "https://github.com/borgbackup/borg/releases/download/1.4.0/borg-windows64.exe"
$BorgExePath = "$BorgInstallPath\borg.exe"

# Create installation directory
Write-Host "1. Creating installation directory..." -ForegroundColor Yellow
if (!(Test-Path $BorgInstallPath)) {
    New-Item -ItemType Directory -Path $BorgInstallPath -Force | Out-Null
    Write-Host "   Created: $BorgInstallPath" -ForegroundColor Green
}
else {
    Write-Host "   Directory already exists" -ForegroundColor Cyan
}

# Download BorgBackup
Write-Host "2. Downloading BorgBackup..." -ForegroundColor Yellow
if (!(Test-Path $BorgExePath)) {
    try {
        Invoke-WebRequest -Uri $BorgDownloadUrl -OutFile $BorgExePath -ErrorAction Stop
        Write-Host "   Downloaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "   ERROR: Download failed - $_" -ForegroundColor Red
        Write-Host "   Manual download: $BorgDownloadUrl" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host "   Borg already downloaded" -ForegroundColor Cyan
}

# Verify installation
Write-Host "3. Verifying installation..." -ForegroundColor Yellow
try {
    $version = & $BorgExePath --version 2>&1
    Write-Host "   $version" -ForegroundColor Green
}
catch {
    Write-Host "   ERROR: Borg verification failed" -ForegroundColor Red
    exit 1
}

# Add to PATH (optional)
Write-Host "4. Adding to system PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$BorgInstallPath*") {
    try {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$BorgInstallPath", "Machine")
        Write-Host "   Added to PATH (restart PowerShell to use 'borg' command)" -ForegroundColor Green
    }
    catch {
        Write-Host "   WARNING: Could not add to PATH (not critical)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "   Already in PATH" -ForegroundColor Cyan
}

# Test SSH connection
Write-Host "5. Testing SSH connection to backup server..." -ForegroundColor Yellow
$testServer = "srvdocker02"
$testUser = "usdaw"

try {
    $sshTest = ssh -o ConnectTimeout=5 -o BatchMode=yes "${testUser}@${testServer}" "echo 'Connection OK'" 2>&1
    
    if ($sshTest -like "*Connection OK*") {
        Write-Host "   SSH connection successful (using SSH keys)" -ForegroundColor Green
    }
    else {
        Write-Host "   SSH connection requires password" -ForegroundColor Yellow
        Write-Host "   Consider setting up SSH keys for passwordless authentication" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "   WARNING: Could not test SSH connection" -ForegroundColor Yellow
}

# Create sample configuration
Write-Host "6. Configuration notes..." -ForegroundColor Yellow
Write-Host @"

   Set environment variables before running backups:
   
   PowerShell:
     `$env:BORG_PASSPHRASE = "your_secure_passphrase"
     `$env:BACKUP_SERVER_PASSWORD = "your_ssh_password"  # Or use SSH keys
   
   System-wide (optional):
     [System.Environment]::SetEnvironmentVariable("BORG_PASSPHRASE", "your_passphrase", "User")

"@ -ForegroundColor Cyan

Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host @"

Next steps:
1. Set BORG_PASSPHRASE environment variable
2. Configure SSH key authentication (recommended) or set BACKUP_SERVER_PASSWORD
3. Run your first backup:
   .\backup-borg-windows.ps1 -VM_Name "ubuntu58"

Documentation: See README-borg-windows.md

"@ -ForegroundColor Yellow
