# backup-restic-windows.ps1 - Windows PowerShell Restic backup script for Ubuntu VM
# This script shuts down Ubuntu VM, backs up via Restic to remote SSH server, and restarts VM

param(
    [Parameter(Mandatory = $false)]
    [string]$VMName = "ubuntu58",
    [string]$RemoteUser = "usdaw",
    [string]$RemoteHost = "srvdocker02",
    [string]$RemotePath = "/mnt/sda4",
    [string]$RepositoryName = "ubuntu58-restic-backup",
    [string]$Password = "",
    [string]$SSHPassword = "",
    [switch]$UseSSHKeys = $false,
    [switch]$AutoFallback = $true,
    [switch]$TestRun = $false,
    [switch]$VerboseOutput = $false,
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
    $fgColor = if ($colors.ContainsKey($Color)) { $colors[$Color] } else { "White" }
    Write-Host $Message -ForegroundColor $fgColor
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Log $Message
    Write-Color $Message "Success"
}

function Write-Warning {
    param([string]$Message)
    Write-Log $Message
    Write-Color $Message "Warning"
}

function Write-Error {
    param([string]$Message)
    Write-Log $Message
    Write-Color $Message "Error"
}

function Test-SSHConnection {
    Write-Log "Testing SSH connection to $RemoteHost..."
    
    # Try SSH Keys first if requested or if AutoFallback is on
    if ($UseSSHKeys -or $AutoFallback) {
        Write-Log "Attempting SSH connection using keys..."
        try {
            $sshCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes ""$RemoteUser@$RemoteHost"" ""echo 'SSH Key test successful'"""
            $result = Invoke-Expression $sshCommand
            if ($LASTEXITCODE -eq 0) {
                Write-Success "SSH connection successful using keys"
                $script:SSHAuthMethod = "keys"
                return $true
            }
            Write-Warning "SSH connection using keys failed (Exit code: $LASTEXITCODE)"
        }
        catch {
            Write-Warning "SSH connection using keys failed: $_"
        }
    }

    # Fallback to password
    if ($AutoFallback -or -not $UseSSHKeys) {
        Write-Log "Attempting SSH connection using password..."
        try {
            $sshCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o PasswordAuthentication=yes ""$RemoteUser@$RemoteHost"" ""echo 'SSH Password test successful'"""
            $result = Invoke-Expression $sshCommand
            if ($LASTEXITCODE -eq 0) {
                Write-Success "SSH connection successful using password"
                $script:SSHAuthMethod = "password"
                return $true
            }
            Write-Error "SSH connection using password failed (Exit code: $LASTEXITCODE)"
        }
        catch {
            Write-Error "SSH connection using password failed: $_"
        }
    }

    return $false
}

function Initialize-Restic {
    Write-Log "Checking Restic repository..."
    
    if (-not $TestRun) {
        $repoUrl = "sftp:" + $RemoteUser + "@" + $RemoteHost + ":" + $RemotePath + "/" + $RepositoryName
        
        if ([string]::IsNullOrEmpty($Password)) {
            $Password = Read-Host "Enter Restic repository password: "
        }
        
        # Convert SecureString to plain text if needed
        if ($Password -is [System.Security.SecureString]) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR, [System.Runtime.InteropServices.Marshal]::UnmanagedType, [System.Runtime.InteropServices.Marshal]::Bool, [System.Runtime.InteropServices.Marshal]::Zero, [System.Runtime.InteropServices.Marshal]::Normal)
        }
        
        $env:RESTIC_PASSWORD = $Password
        Write-Log "Restic password set in environment."
        
        # Check if repository already exists
        Write-Log "Checking if repository already exists at $repoUrl..."
        $output = & C:\Users\Test\restic\restic.exe snapshots --repo $repoUrl 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Repository already initialized."
            return
        }
        else {
            Write-Log "Snapshots check failed (Exit code: $LASTEXITCODE). Output: $output"
        }

        Write-Log "Initializing new Restic repository..."
        $initCommand = "restic init --repo $repoUrl"
        
        if ($VerboseOutput) {
            Write-Log "Executing: $initCommand"
        }
        
        $output = & C:\Users\Test\restic\restic.exe init --repo $repoUrl 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Restic repository initialized successfully"
        }
        else {
            # If it failed, maybe it's because it already exists but snapshots failed for some other reason
            if ($output -like "*already initialized*") {
                Write-Log "Repository already initialized (detected from output)."
                return
            }
            Write-Error "Restic initialization failed with exit code: $LASTEXITCODE"
            Write-Log "Output: $output"
            exit 1
        }
    }
}

function Stop-HyperVVM {
    param([string]$VMName)
    Write-Log "Stopping VM: $VMName..."
    
    try {
        $VM = Get-VM -Name $VMName -ErrorAction Stop
        
        if ($VM.State -eq "Running") {
            Stop-VM -Name $VMName -Force
            Write-Log "VM stop command sent..."
            
            # Wait for VM to stop
            $maxWait = 120
            $waited = 0
            $VM = Get-VM -Name $VMName -ErrorAction Stop
            
            while ($VM.State -ne "Off" -and $waited -lt $maxWait) {
                Start-Sleep -Seconds 5
                $waited += 5
                $VM = Get-VM -Name $VMName -ErrorAction Stop
                Write-Log "Waiting for VM to stop... ($waited/$maxWait seconds)"
            }
            
            $VM = Get-VM -Name $VMName -ErrorAction Stop
            if ($VM.State -eq "Off") {
                Write-Success "VM stopped successfully"
                return $true
            }
            else {
                Write-Error "VM failed to stop after $maxWait seconds"
                return $false
            }
        }
        else {
            Write-Log "VM is already stopped (State: $($VM.State))"
            return $true
        }
    }
    catch {
        Write-Error "Failed to stop VM: $_"
        return $false
    }
}

function Start-HyperVVM {
    param([string]$VMName)
    Write-Log "Starting VM: $VMName..."
    
    try {
        Start-VM -Name $VMName
        Write-Log "VM start command sent..."
        
        # Wait for VM to start
        $maxWait = 120
        $waited = 0
        $VM = Get-VM -Name $VMName -ErrorAction Stop
        
        while ($VM.State -ne "Running" -and $waited -lt $maxWait) {
            Start-Sleep -Seconds 5
            $waited += 5
            $VM = Get-VM -Name $VMName -ErrorAction Stop
            Write-Log "Waiting for VM to start... ($waited/$maxWait seconds)"
        }
        
        $VM = Get-VM -Name $VMName -ErrorAction Stop
        if ($VM.State -eq "Running") {
            Write-Success "VM started successfully"
            return $true
        }
        else {
            Write-Error "VM failed to start after $maxWait seconds (State: $($VM.State))"
            return $false
        }
    }
    catch {
        Write-Error "Failed to start VM: $_"
        return $false
    }
}

function Perform-ResticBackup {
    Write-Log "Starting Restic backup..."
    
    # Find VHD files for the VM
    try {
        $vhdPaths = Get-VM -Name $VMName | Get-VMHardDiskDrive | Select-Object -ExpandProperty Path
        if (-not $vhdPaths) {
            Write-Error "No VHD files found for VM: $VMName"
            return $false
        }
        Write-Log "Found VHD files: $($vhdPaths -join ', ')"
    }
    catch {
        Write-Error "Failed to find VHD files for VM: $VMName. Error: $_"
        return $false
    }

    $repoUrl = "sftp:" + $RemoteUser + "@" + $RemoteHost + ":" + $RemotePath + "/" + $RepositoryName
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $tag = "backup-" + $timestamp
    
    $env:RESTIC_PASSWORD = $Password
    
    # Set up SSH password environment variable for Restic
    if (-not [string]::IsNullOrEmpty($SSHPassword)) {
        $env:RESTIC_PASSWORD_COMMAND = "echo $SSHPassword"
    }
    
    # Build the backup command with VHD paths
    $sourcePaths = $vhdPaths | ForEach-Object { """$_""" }
    $sourcePathsStr = $sourcePaths -join " "
    
    $resticCommand = "restic backup --repo $repoUrl --tag $tag --compression auto --limit-upload 0 --max-concurrent-uploads $BackupThreads --verbose $sourcePathsStr"
    
    Write-Log "Executing backup command..."
    if ($VerboseOutput) {
        Write-Log "Command: $resticCommand"
    }
    
    # Use direct execution to allow real-time progress reporting
    Write-Log "Starting backup with real-time progress..."
    
    # We call restic directly so it can print its progress to the console
    & C:\Users\Test\restic\restic.exe backup --repo $repoUrl --tag $tag --compression auto --limit-upload 0 --verbose $vhdPaths
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Restic backup completed successfully: $tag"
        
        # Prune old backups
        Write-Log "Pruning old Restic backups..."
        $pruneCommand = "restic forget --repo $repoUrl --keep-daily=7 --keep-weekly=4 --keep-monthly=6 --prune"
        
        $pruneOutput = & C:\Users\Test\restic\restic.exe forget --repo $repoUrl --keep-daily=7 --keep-weekly=4 --keep-monthly=6 --prune 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Restic pruning completed successfully"
        }
        else {
            Write-Warning "Restic pruning completed with warnings (exit code: $LASTEXITCODE)"
            Write-Log "Prune Output: $pruneOutput"
        }
        
        # Show repository info
        Write-Log "Repository statistics:"
        $statsCommand = "restic stats --repo $repoUrl"
        Invoke-Expression $statsCommand
        
    }
    else {
        Write-Error "Restic backup failed with exit code: $LASTEXITCODE"
        Write-Log "Output: $output"
        return $false
    }
    
    return $true
}

function Show-Usage {
    Write-Host "Restic Backup Script for Ubuntu VM (Windows Host)" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\backup-restic-windows.ps1 [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -VMName: Name of the VM to backup (default: ubuntu58)" -ForegroundColor White
    Write-Host "  -RemoteUser: SSH username (default: usdaw)" -ForegroundColor White
    Write-Host "  -RemoteHost: Remote server hostname (default: srvdocker02)" -ForegroundColor White
    Write-Host "  -RemotePath: Remote backup path (default: /mnt/sda4)" -ForegroundColor White
    Write-Host "  -RepositoryName: Repository name (default: ubuntu58-restic-backup)" -ForegroundColor White
    Write-Host "  -Password: Restic repository password (will prompt if not provided)" -ForegroundColor White
    Write-Host "  -SSHPassword: SSH password for remote server (will prompt if not provided)" -ForegroundColor White
    Write-Host "  -UseSSHKeys: Use SSH keys instead of password (default: false)" -ForegroundColor White
    Write-Host "  -AutoFallback: Automatically fallback to password if keys fail (default: true)" -ForegroundColor White
    Write-Host "  -TestRun: Test mode without actual backup (default: false)" -ForegroundColor White
    Write-Host "  -VerboseOutput: Enable verbose output (default: false)" -ForegroundColor White
    Write-Host "  -BackupThreads: Number of concurrent uploads (default: 4)" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  # Basic backup to srvdocker02:" -ForegroundColor White
    Write-Host "  .\backup-restic-windows.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Backup to ubhost:" -ForegroundColor White
    Write-Host "  .\backup-restic-windows.ps1 -RemoteHost ubhost -RemoteUser suppg02" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Test SSH connection only:" -ForegroundColor White
    Write-Host "  .\backup-restic-windows.ps1 -TestRun" -ForegroundColor Cyan
}

# Main script logic
try {
    Write-Host "Restic Backup Script for Ubuntu VM (Windows Host)" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if Hyper-V module is available
    if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
        Write-Error "Hyper-V module is not available. Please run as Administrator."
        exit 1
    }
    
    # Check if SSH is available
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Error "SSH is not installed on this system. Please install OpenSSH."
        exit 1
    }
    
    # Check if Restic is available
    if (-not (Get-Command restic -ErrorAction SilentlyContinue)) {
        Write-Error "Restic is not installed. Please run setup-restic.bat to install it."
        Write-Log "Download from: https://restic.readthedocs.io/en/latest.html"
        exit 1
    }
    
    # Test SSH connection first
    if (-not $TestRun) {
        Write-Log "Testing SSH connection to $RemoteHost..."
        $sshTest = Test-SSHConnection
        
        if (-not $sshTest) {
            Write-Error "SSH connection test failed. Cannot proceed with backup."
            exit 1
        }
    }
    
    # Get initial VM state
    $VM = Get-VM -Name $VMName -ErrorAction Stop
    $initialState = $VM.State
    Write-Log "Initial VM state: $initialState"
    
    # Stop VM if running
    $vmWasRunning = ($initialState -eq "Running")
    if ($vmWasRunning -and (-not $TestRun)) {
        $stopResult = Stop-HyperVVM -VMName $VMName
        
        if ($stopResult -is [bool] -and -not $stopResult) {
            Write-Error "Failed to stop VM. Cannot proceed with backup."
            exit 1
        }
    }
    
    # Perform backup
    if (-not $TestRun) {
        Initialize-Restic
        $backupResult = Perform-ResticBackup
        
        if (-not $backupResult) {
            Write-Error "Backup failed. Attempting to restart VM..."
            $null = Start-HyperVVM -VMName $VMName
            exit 1
        }
    }
    
    # Restart VM if it was running
    if ($vmWasRunning -and (-not $TestRun)) {
        $startResult = Start-HyperVVM -VMName $VMName
        
        if ($startResult -is [bool] -and -not $startResult) {
            Write-Warning "VM was stopped but failed to restart. Please check VM status."
        }
    }
    
    Write-Host ""
    Write-Success "Backup process completed successfully!"
    
}
catch {
    Write-Error "An error occurred: $_"
    Write-Log "Script execution failed"
    
    # Try to restart VM if it was running
    if ($vmWasRunning) {
        Write-Log "Attempting to restart VM after error..."
        Start-HyperVVM -VMName $VMName | Out-Null
    }
    
    exit 1
}
