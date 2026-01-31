# Restic VHD Backup Script
# Version: 1.0
# Last Updated: 2025-12-27
# Description: Image-level VHD backup to remote SSH server using Restic
# 
# Configuration: See ../../config.json for centralized settings
# Environment Variables Required:
#   - RESTIC_PASSWORD: Repository encryption password
#   - BACKUP_SERVER_USER: SSH server username
#   - BACKUP_SERVER_PASSWORD: SSH server password (or use SSH keys)
#
# Usage: .\backup-final.ps1 -VM_Name "ubuntu58"

param([string]$VM_Name = "ubuntu58")

Write-Host "=== Restic VHD Backup v1.0 ===" -ForegroundColor Green
Write-Host "VM: $VM_Name" -ForegroundColor Yellow

# Configuration
$Restic_Path = "C:\Restic\restic.exe"

# Use environment variables set by vmmanager.ps1
if ($env:BACKUP_SERVER_USER) {
    $Remote_User = $env:BACKUP_SERVER_USER
    # Determine server based on user
    if ($Remote_User -eq "suppg02") {
        $Remote_Server = "ubhost"
    }
    elseif ($Remote_User -eq "root") {
        $Remote_Server = "srvdocker02"
    }
    else {
        $Remote_Server = "ubhost"  # Default
    }
}
else {
    $Remote_User = Read-Host "Enter backup server username"
    $Remote_Server = Read-Host "Enter backup server hostname"
}

if ($env:BACKUP_SERVER_PASSWORD) {
    $Remote_Password = $env:BACKUP_SERVER_PASSWORD
}
else {
    $Remote_Password = $null
}

$Backup_Root = if ($Remote_Server -eq "ubhost") { "/media/ubhost-backup" } else { "/media/backup" }
$Repo_Path = "$Backup_Root/$VM_Name-vhd"

Write-Host "Backup server: $Remote_Server" -ForegroundColor Cyan
Write-Host "Backup user: $Remote_User" -ForegroundColor Cyan
Write-Host "Backup root: $Backup_Root" -ForegroundColor Cyan
Write-Host "Repository: $Repo_Path" -ForegroundColor Cyan

# Check Restic
Write-Host "1. Checking Restic..." -ForegroundColor Yellow
if (!(Test-Path $Restic_Path)) {
    Write-Host "   ERROR: Restic not found at $Restic_Path" -ForegroundColor Red
    exit 1
}

$version = & $Restic_Path version
Write-Host "   SUCCESS: $version" -ForegroundColor Green

# Find VM directory and VHD files
Write-Host "2. Finding VM directory and VHD files..." -ForegroundColor Yellow

try {
    $VM = Get-VM -Name $VM_Name -ErrorAction Stop
    $VMPath = $VM.Path
    $VMDir = $VMPath

    Write-Host "   VM Path: $VMPath" -ForegroundColor Cyan
    Write-Host "   VM Directory: $VMDir" -ForegroundColor Green

    # List all files in VM directory for debugging
    Write-Host "   Files in VM directory:" -ForegroundColor Yellow
    Get-ChildItem -Path $VMDir | Format-Table Name, Length -AutoSize

    # Get all .vhdx files in VM directory
    $VHD_Files = Get-ChildItem -Path $VMDir -Filter "*.vhdx" -File

    if ($VHD_Files.Count -eq 0) {
        Write-Host "   No .vhdx files found, checking for .vhd files..." -ForegroundColor Yellow
        $VHD_Files = Get-ChildItem -Path $VMDir -Filter "*.vhd" -File
        if ($VHD_Files.Count -eq 0) {
            Write-Host "   ERROR: No .vhd or .vhdx files found in $VMDir" -ForegroundColor Red
            exit 1
        }
    }

    $VHD_Paths = @()
    foreach ($vhdFile in $VHD_Files) {
        $VHD_Paths += $vhdFile.FullName
        $vhdSize = [math]::Round($vhdFile.Length / 1GB, 2)
        Write-Host "   Found VHD: $($vhdFile.Name) ($vhdSize GB)" -ForegroundColor Green
    }

}
catch {
    Write-Host "   ERROR: VM '$VM_Name' not found" -ForegroundColor Red
    exit 1
}

# Set password environment variable if present
if ($Remote_Password) {
    $env:RESTIC_PASSWORD = $Remote_Password
}

# Ensure backup root exists on remote server (for suppg02@ubhost)

# Test repository connection
Write-Host "3. Testing repository connection..." -ForegroundColor Yellow

$sftpUrls = @(
    "sftp:" + $Remote_User + "@" + $Remote_Server + ":" + $Repo_Path
)

$repoUrl = $null
foreach ($url in $sftpUrls) {
    Write-Host "   Testing: $url" -ForegroundColor Cyan

    try {
        $testResult = & $Restic_Path list snapshots --repo $url 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Repository exists" -ForegroundColor Green
            $repoUrl = $url
            break
        }
        else {
            # Try to initialize
            $initResult = & $Restic_Path init --repo $url 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   Repository initialized" -ForegroundColor Green
                $repoUrl = $url
                break
            }
            else {
                Write-Host "   Failed to init: $($initResult -join ' ')" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "   Error with $url" -ForegroundColor Yellow
    }
}

if (-not $repoUrl) {
    Write-Host "   ERROR: Could not access repository" -ForegroundColor Red
    Write-Host "   If you are stuck at SSH key authentication, try running 'ssh suppg02@ubhost' in a separate terminal to accept the host key, then re-run this script."
    exit 1
}

# Stop VM
Write-Host "4. Stopping VM..." -ForegroundColor Yellow

$VMState = $VM.State
if ($VMState -eq "Running") {
    Stop-VM -Name $VM_Name -Force
    Start-Sleep -Seconds 10

    $VM = Get-VM -Name $VM_Name
    if ($VM.State -ne "Off") {
        Write-Host "   ERROR: VM did not stop" -ForegroundColor Red
        exit 1
    }
    Write-Host "   VM stopped" -ForegroundColor Green
}

# Run backup
Write-Host "5. Running Restic backup..." -ForegroundColor Yellow

$startTime = Get-Date

$backupArgs = @(
    "backup",
    "--repo", $repoUrl,
    "--tag", "vhd-backup",
    "--compression", "auto",
    "--verbose"
)

foreach ($vhdPath in $VHD_Paths) {
    $backupArgs += $vhdPath
}

Write-Host "   Starting backup..." -ForegroundColor Yellow
$backupResult = & $Restic_Path $backupArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "   Backup successful" -ForegroundColor Green

    # Prune old backups
    & $Restic_Path forget --repo $repoUrl --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
    & $Restic_Path stats --repo $repoUrl --mode raw-data

}
else {
    Write-Host "   ERROR: Backup failed" -ForegroundColor Red
    Write-Host "   $backupResult" -ForegroundColor Yellow
    Start-VM -Name $VM_Name
    exit 1
}

# Start VM
Write-Host "6. Starting VM..." -ForegroundColor Yellow
Start-VM -Name $VM_Name
Start-Sleep -Seconds 10

$VM = Get-VM -Name $VM_Name
Write-Host "   VM State: $($VM.State)" -ForegroundColor Green

# Summary
Write-Host "=== Backup Complete ===" -ForegroundColor Green

$endTime = Get-Date
$totalDuration = $endTime - $startTime
$durationStr = $totalDuration.ToString('mm\:ss')

$totalSize = 0
foreach ($vhdPath in $VHD_Paths) {
    if (Test-Path $vhdPath) {
        $totalSize += (Get-Item $vhdPath).Length
    }
}

$totalSizeGB = [math]::Round($totalSize / 1GB, 2)

Write-Host "VM: $VM_Name" -ForegroundColor Yellow
Write-Host "Repository: $repoUrl" -ForegroundColor Yellow
Write-Host "Duration: $durationStr" -ForegroundColor Yellow
Write-Host "Total Size: $totalSizeGB GB" -ForegroundColor Yellow

Write-Host "`n=== Success ===" -ForegroundColor Green
Write-Host "Image-level incremental backup completed!" -ForegroundColor Green
Write-Host "Future backups will be much faster." -ForegroundColor Yellow