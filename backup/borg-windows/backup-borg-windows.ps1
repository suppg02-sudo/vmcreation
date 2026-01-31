# BorgBackup VHD Backup Script (Windows Host)
# Version: 1.0
# Last Updated: 2025-12-27
# Description: Image-level VHD backup to remote SSH server using BorgBackup from Windows
# 
# Configuration: See ../../config.json for centralized settings
# Environment Variables Required:
#   - BORG_PASSPHRASE: Repository encryption passphrase
#   - BACKUP_SERVER_USER: SSH server username
#   - BACKUP_SERVER_PASSWORD: SSH server password (or use SSH keys)
# 
# Usage: .\backup-borg-windows.ps1 -VM_Name "ubuntu58"

param([string]$VM_Name = "ubuntu58")

Write-Host "=== BorgBackup VHD Backup v1.0 (Windows Host) ===" -ForegroundColor Green
Write-Host "VM: $VM_Name" -ForegroundColor Yellow

# Configuration
$Borg_Path = "C:\Program Files\Borg\borg.exe"
$Remote_Server = "srvdocker02"
$Remote_User = "usdaw"

# Use explicit user/server override if provided
if ($env:BACKUP_SERVER_USER) {
    $Remote_User = $env:BACKUP_SERVER_USER
}
if ($Remote_User -eq "suppg02") {
    $Remote_Server = "ubhost"
}
elseif ($Remote_User -eq "root") {
    $Remote_Server = "srvdocker02"
}

$Backup_Root = if ($Remote_Server -eq "ubhost") { "/media/ubhost-backup" } else { "/media/backup" }
$Repo_Path = "${Remote_User}@${Remote_Server}:${Backup_Root}/${VM_Name}-borg-vhd"

# Check Borg
Write-Host "1. Checking BorgBackup installation..." -ForegroundColor Yellow
if (!(Test-Path $Borg_Path)) {
    Write-Host "   ERROR: Borg not found at $Borg_Path" -ForegroundColor Red
    Write-Host "   Run setup-borg-windows.ps1 to install BorgBackup" -ForegroundColor Yellow
    exit 1
}

$version = & $Borg_Path --version
Write-Host "   SUCCESS: $version" -ForegroundColor Green

# Find VM directory and VHD files
Write-Host "2. Finding VM directory and VHD files..." -ForegroundColor Yellow

try {
    $VM = Get-VM -Name $VM_Name -ErrorAction Stop
    $VMPath = $VM.Path
    $VMDir = $VMPath

    Write-Host "   VM Path: $VMPath" -ForegroundColor Cyan
    Write-Host "   VM Directory: $VMDir" -ForegroundColor Green

    # Get all .vhdx files in VM directory
    $VHD_Files = Get-ChildItem -Path $VMDir -Filter "*.vhdx" -Recurse -File

    if ($VHD_Files.Count -eq 0) {
        Write-Host "   No .vhdx files found, checking for .vhd files..." -ForegroundColor Yellow
        $VHD_Files = Get-ChildItem -Path $VMDir -Filter "*.vhd" -Recurse -File
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

# Set environment variables
if ($env:BORG_PASSPHRASE) {
    $env:BORG_PASSPHRASE = $env:BORG_PASSPHRASE
}
Remove-Item Env:BACKUP_SERVER_PASSWORD -ErrorAction SilentlyContinue

# Test repository connection
Write-Host "3. Testing repository connection..." -ForegroundColor Yellow

try {
    # Try to list archives
    $listResult = & $Borg_Path list --repo $Repo_Path 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Repository exists and is accessible" -ForegroundColor Green
    }
    elseif ($listResult -like "*repository*not*found*") {
        # Initialize repository
        Write-Host "   Repository not found, initializing..." -ForegroundColor Yellow
        & $Borg_Path init --encryption=repokey --repo $Repo_Path
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Repository initialized successfully" -ForegroundColor Green
        }
        else {
            Write-Host "   ERROR: Failed to initialize repository" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "   ERROR: Could not access repository" -ForegroundColor Red
        Write-Host "   $listResult" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "   ERROR: Repository access failed - $_" -ForegroundColor Red
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
    Write-Host "   VM stopped successfully" -ForegroundColor Green
}
else {
    Write-Host "   VM already stopped" -ForegroundColor Cyan
}

# Run backup
Write-Host "5. Running BorgBackup..." -ForegroundColor Yellow

$startTime = Get-Date
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$archiveName = "${VM_Name}-${timestamp}"

# Build Borg command arguments
$borgArgs = @(
    "create",
    "--repo", $Repo_Path,
    "--compression", "lz4",
    "--stats",
    "--progress",
    "::$archiveName"
)

# Add VHD paths
$borgArgs += $VHD_Paths

Write-Host "   Archive name: $archiveName" -ForegroundColor Cyan
Write-Host "   Starting backup..." -ForegroundColor Yellow

try {
    & $Borg_Path $borgArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Backup successful!" -ForegroundColor Green
        
        # Prune old backups
        Write-Host "   Pruning old backups..." -ForegroundColor Yellow
        & $Borg_Path prune --repo $Repo_Path --keep-daily=7 --keep-weekly=4 --keep-monthly=6 --stats
        
        # Show repository info
        Write-Host "   Repository statistics:" -ForegroundColor Yellow
        & $Borg_Path info --repo $Repo_Path
    }
    else {
        Write-Host "   ERROR: Backup failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Start-VM -Name $VM_Name
        exit 1
    }
}
catch {
    Write-Host "   ERROR: Backup failed - $_" -ForegroundColor Red
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
Write-Host "`n=== Backup Complete ===" -ForegroundColor Green

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
Write-Host "Repository: $Repo_Path" -ForegroundColor Yellow
Write-Host "Archive: $archiveName" -ForegroundColor Yellow
Write-Host "Duration: $durationStr" -ForegroundColor Yellow
Write-Host "Total VHD Size: $totalSizeGB GB" -ForegroundColor Yellow

Write-Host "`n=== Success ===" -ForegroundColor Green
Write-Host "Image-level backup with BorgBackup completed!" -ForegroundColor Green
Write-Host "Deduplication and compression applied for efficient storage." -ForegroundColor Cyan
