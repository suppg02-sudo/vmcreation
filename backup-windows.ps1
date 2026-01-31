# backup-windows.ps1 - Windows PowerShell backup script for Ubuntu VM
# This script performs backups from Windows host to remote SSH server

param(
    [Parameter(Mandatory = $true)]
    [string]$BackupType = "borg",
    [string]$RemoteUser = "usdaw",
    [string]$RemoteHost = "srvdocker02",
    [string]$RemotePath = "/home/usdaw/backups",
    [string]$RepositoryName = "ubuntu58-backups",
    [string]$Passphrase = "",
    [switch]$TestRun = $false,
    [switch]$Verbose = $false,
    [int]$BackupThreads = 4
)

# Colors for output
$colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Info    = "Cyan"
}

function Write-Color {
    param([string]$Message, [string]$Color)
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Log $Message
    Write-Color $Message $colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Log $Message
    Write-Color $Message $colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Log $Message
    Write-Color $Message $colors.Error
}

function Test-SSHConnection {
    Write-Log "Testing SSH connection to $RemoteHost..."
    try {
        $result = ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes "$RemoteUser@$RemoteHost" "echo 'SSH connection test successful'"
        if ($LASTEXITCODE -eq 0) {
            Write-Success "SSH connection test passed"
            return $true
        }
        else {
            Write-Error "SSH connection test failed with exit code: $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "SSH connection test failed: $_"
        return $false
    }
}

function Initialize-BorgBackup {
    Write-Log "Initializing BorgBackup repository..."
    
    if (-not $TestRun) {
        $repoUrl = "ssh://" + $RemoteUser + "@" + $RemoteHost + "/" + $RemotePath + "/" + $RepositoryName
        
        if ([string]::IsNullOrEmpty($Passphrase)) {
            $Passphrase = Read-Host -AsSecureString "Enter BorgBackup repository passphrase: "
        }
        
        $env:BORG_PASSPHRASE = $Passphrase
        
        $initCommand = "borg init --encryption=repokey $repoUrl"
        
        if ($Verbose) {
            Write-Log "Executing: $initCommand"
        }
        
        $output = Invoke-Expression $initCommand 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "BorgBackup repository initialized successfully"
        }
        else {
            Write-Error "BorgBackup initialization failed with exit code: $LASTEXITCODE"
            Write-Log "Output: $output"
            exit 1
        }
    }
}

function Initialize-Restic {
    Write-Log "Initializing Restic repository..."
    
    if (-not $TestRun) {
        $repoUrl = "sftp:" + $RemoteUser + "@" + $RemoteHost + ":" + $RemotePath + "/" + $RepositoryName + "-restic"
        
        if ([string]::IsNullOrEmpty($Passphrase)) {
            $Passphrase = Read-Host -AsSecureString "Enter Restic repository password: "
        }
        
        $env:RESTIC_PASSWORD = $Passphrase
        
        $initCommand = "restic init --repo $repoUrl"
        
        if ($Verbose) {
            Write-Log "Executing: $initCommand"
        }
        
        $output = Invoke-Expression $initCommand 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Restic repository initialized successfully"
        }
        else {
            Write-Error "Restic initialization failed with exit code: $LASTEXITCODE"
            Write-Log "Output: $output"
            exit 1
        }
    }
}

function Perform-BorgBackup {
    Write-Log "Starting BorgBackup..."
    
    $repoUrl = "ssh://" + $RemoteUser + "@" + $RemoteHost + "/" + $RemotePath + "/" + $RepositoryName
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $archiveName = "backup-" + $timestamp
    
    $env:BORG_PASSPHRASE = $Passphrase
    
    $borgCommand = "borg create --verbose --filter AME --list --stats --show-rc --compression lz4 --exclude-caches --exclude /tmp --exclude /var/tmp --exclude /var/cache --exclude /home/*/.cache $repoUrl::$archiveName /"
    
    if ($Verbose) {
        Write-Log "Executing: $borgCommand"
    }
    
    $output = Invoke-Expression $borgCommand 2>&1 | Out-String
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "BorgBackup completed successfully: $archiveName"
        
        $pruneCommand = "borg prune --list --show-rc --keep-daily=7 --keep-weekly=4 --keep-monthly=6 $repoUrl"
        $pruneOutput = Invoke-Expression $pruneCommand 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "BorgBackup pruning completed successfully"
        }
        else {
            Write-Warning "BorgBackup pruning completed with warnings (exit code: $LASTEXITCODE)"
        }
    }
    else {
        Write-Error "BorgBackup failed with exit code: $LASTEXITCODE"
        Write-Log "Output: $output"
        exit 1
    }
}

function Perform-ResticBackup {
    Write-Log "Starting Restic backup..."
    
    $repoUrl = "sftp:" + $RemoteUser + "@" + $RemoteHost + ":" + $RemotePath + "/" + $RepositoryName + "-restic"
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $tag = "backup-" + $timestamp
    
    $env:RESTIC_PASSWORD = $Passphrase
    
    $resticCommand = "restic backup --repo $repoUrl --tag $tag --compression auto --limit-upload 0 --max-concurrent-uploads $BackupThreads --verbose --exclude /tmp --exclude /var/tmp --exclude /var/cache --exclude /home/*/.cache --exclude /var/log/journal --exclude /snap /"
    
    if ($Verbose) {
        Write-Log "Executing: $resticCommand"
    }
    
    $output = Invoke-Expression $resticCommand 2>&1 | Out-String
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Restic backup completed successfully: $tag"
    }
    else {
        Write-Error "Restic backup failed with exit code: $LASTEXITCODE"
        Write-Log "Output: $output"
        exit 1
    }
}

function Show-Usage {
    Write-Host "Windows Backup Script for Ubuntu VM" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\backup-windows.ps1 -BackupType <borg|restic> [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -BackupType: Backup tool to use (default: borg)" -ForegroundColor White
    Write-Host "  -RemoteUser: SSH username (default: usdaw)" -ForegroundColor White
    Write-Host "  -RemoteHost: Remote server hostname (default: srvdocker02)" -ForegroundColor White
    Write-Host "  -RemotePath: Remote backup path (default: /home/usdaw/backups)" -ForegroundColor White
    Write-Host "  -RepositoryName: Repository name (default: ubuntu58-backups)" -ForegroundColor White
    Write-Host "  -Passphrase: Backup repository password (will prompt if not provided)" -ForegroundColor White
    Write-Host "  -TestRun: Test mode without actual backup (default: false)" -ForegroundColor White
    Write-Host "  -Verbose: Enable verbose output (default: false)" -ForegroundColor White
    Write-Host "  -BackupThreads: Number of concurrent uploads (default: 4)" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  # Basic BorgBackup backup:" -ForegroundColor White
    Write-Host "  .\backup-windows.ps1 -BackupType borg" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Basic Restic backup:" -ForegroundColor White
    Write-Host "  .\backup-windows.ps1 -BackupType restic" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Test SSH connection only:" -ForegroundColor White
    Write-Host "  .\backup-windows.ps1 -BackupType borg -TestRun" -ForegroundColor Cyan
}

try {
    Write-Host "Windows Backup Script for Ubuntu VM" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Error "SSH is not installed on this system. Please install OpenSSH or use WSL."
        exit 1
    }
    
    if ($BackupType -eq "borg") {
        if (-not (Get-Command borg -ErrorAction SilentlyContinue)) {
            Write-Error "BorgBackup is not installed. Please install it via WSL: wsl --install borgbackup"
            exit 1
        }
    }
    
    if ($BackupType -eq "restic") {
        if (-not (Get-Command restic -ErrorAction SilentlyContinue)) {
            Write-Error "Restic is not installed. Please download from: https://restic.readthedocs.io/en/latest.html"
            exit 1
        }
    }
    
    if (-not $TestRun) {
        Write-Log "Testing SSH connection to $RemoteHost..."
        $sshTest = Test-SSHConnection
        
        if (-not $sshTest) {
            Write-Error "SSH connection test failed. Cannot proceed with backup."
            exit 1
        }
    }
    
    switch ($BackupType) {
        "borg" {
            Initialize-BorgBackup
            Perform-BorgBackup
        }
        "restic" {
            Initialize-Restic
            Perform-ResticBackup
        }
        default {
            Write-Error "Invalid backup type: $BackupType. Use 'borg' or 'restic'."
            Show-Usage
            exit 1
        }
    }
    
    Write-Host ""
    Write-Success "Backup process completed successfully!" -ForegroundColor Green
    
}
catch {
    Write-Error "An error occurred: $_" -ForegroundColor Red
    Write-Log "Script execution failed"
    exit 1
}