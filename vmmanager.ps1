# VM Manager - Interactive Menu System
# Version: 1.0
# Last Updated: 2025-12-27

param()

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

# Load config for backup user and targets
$configPath = Join-Path $ScriptRoot "config.json"
$backupTargets = @(
    @{ name = "srvdocker02"; user = "root"; root = "/media/backup" },
    @{ name = "ubhost"; user = "suppg02"; root = "/media/ubhost-backup" }
)
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    $backupTargets[0].root = $config.backup.backupRoot
    # Optionally add more targets from config if needed
}

function Select-BackupTarget {
    Write-Host ""
    Write-Host "Select backup target:"
    for ($i = 0; $i -lt $backupTargets.Count; $i++) {
        $t = $backupTargets[$i]
        Write-Host " $($i+1)) $($t.name)  (user: $($t.user), root: $($t.root))"
    }
    $sel = Read-Host "Enter number (default: 1)"
    if ([string]::IsNullOrWhiteSpace($sel)) { $sel = "1" }
    $idx = [int]$sel - 1
    if ($idx -lt 0 -or $idx -ge $backupTargets.Count) { $idx = 0 }
    return $backupTargets[$idx]
}

function Show-Header {
    Clear-Host
    Write-Host "==============================================="
    Write-Host "             VM MANAGER v1.0"
    Write-Host "      Ubuntu VM Creation, Backup, Restore"
    Write-Host "==============================================="
    Write-Host ""
}

function Show-MainMenu {
    Show-Header
    Write-Host "MAIN MENU"
    Write-Host ""
    Write-Host "  VM Operations:"
    Write-Host "   1) Create New Ubuntu VM"
    Write-Host "   2) List VMs"
    Write-Host "   3) Start/Stop VM"
    Write-Host "   4) Delete VM"
    Write-Host ""
    Write-Host "  Backup:"
    Write-Host "   5) Restic Backup"
    Write-Host "   6) Borg-Windows Backup"
    Write-Host "   7) Borg-in-VM Backup"
    Write-Host ""
    Write-Host "  Restore:"
    Write-Host "   8) Restore from Restic"
    Write-Host "   9) Restore from Borg-Windows"
    Write-Host "  10) Restore from Borg-in-VM"
    Write-Host ""
    Write-Host "   0) Exit"
    Write-Host ""
    Write-Host -NoNewline "Select option: "
}

function Pause-Menu {
    Write-Host ""
    Write-Host "Press Enter to return to the main menu..."
    [void][System.Console]::ReadLine()
}

function Set-BackupAuth($target) {
    # Default: SSH key only (do not set password env var)
    Remove-Item Env:BACKUP_SERVER_PASSWORD -ErrorAction SilentlyContinue
    $env:BACKUP_SERVER_USER = $target.user
    Write-Host "Attempting SSH key authentication for $($target.user)@$($target.name)..."
    
    # Use Start-Process with timeout for more reliable SSH testing
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "ssh"
    $psi.Arguments = "-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no $($target.user)@$($target.name) echo ok"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    
    # Wait up to 8 seconds for completion
    if ($process.WaitForExit(8000)) {
        $sshTest = $process.StandardOutput.ReadToEnd().Trim()
        if ($sshTest -eq "ok") {
            Write-Host "SSH key authentication succeeded."
            return
        }
    }
    else {
        # Timeout - kill the process
        $process.Kill()
        Write-Host "SSH connection timed out after 8 seconds."
    }
    
    # If we get here, SSH key auth failed
    Write-Host "SSH key authentication failed. Falling back to password authentication."
    $pw = Read-Host "Enter password for $($target.user)@$($target.name)"
    $env:BACKUP_SERVER_PASSWORD = $pw
}

function Backup-Restic {
    Write-Host ""
    $target = Select-BackupTarget
    $vmName = Read-Host "Enter VM name for backup (default: ubuntu58)"
    if ([string]::IsNullOrWhiteSpace($vmName)) { $vmName = "ubuntu58" }
    $repo = "$($target.root)/$vmName-vhd"
    Write-Host "Restic backup will use user: $($target.user)"
    Write-Host "Restic backup target: $repo"
    Set-BackupAuth $target
    # Force correct user for repo URL
    $env:BACKUP_SERVER_USER = $target.user
    $resticScript = Join-Path $ScriptRoot "backup\\restic\\backup-final.ps1"
    if (Test-Path $resticScript) {
        & $resticScript -VM_Name $vmName
    }
    else {
        Write-Host "Restic backup script not found: $resticScript"
    }
    Pause-Menu
}
function Backup-BorgWindows {
    Write-Host ""
    $target = Select-BackupTarget
    $vmName = Read-Host "Enter VM name for backup (default: ubuntu58)"
    if ([string]::IsNullOrWhiteSpace($vmName)) { $vmName = "ubuntu58" }
    $repo = "$($target.user)@$($target.name):$($target.root)/$vmName-borg-vhd"
    Write-Host "Borg-Windows backup will use user: $($target.user)"
    Write-Host "Borg-Windows backup target: $repo"
    Set-BackupAuth $target
    $env:BACKUP_SERVER_USER = $target.user
    $borgWinScript = Join-Path $ScriptRoot "backup\\borg-windows\\backup-borg-windows.ps1"
    if (Test-Path $borgWinScript) {
        & $borgWinScript -VM_Name $vmName
    }
    else {
        Write-Host "Borg-Windows backup script not found: $borgWinScript"
    }
    Pause-Menu
}
function Backup-BorgVM {
    Write-Host ""
    Write-Host "To run Borg-in-VM backup, SSH into your Ubuntu VM and run the backup script inside the VM."
    Write-Host "See backup/borg/README-borg.md for details."
    Pause-Menu
}

# Placeholder functions for other menu actions
function Create-VM { Write-Host "Create VM selected"; Pause-Menu }
function List-VMs { Write-Host "List VMs selected"; Pause-Menu }
function StartStop-VM { Write-Host "Start/Stop VM selected"; Pause-Menu }
function Delete-VM { Write-Host "Delete VM selected"; Pause-Menu }
function Restore-Restic { Write-Host "Restore from Restic selected"; Pause-Menu }
function Restore-BorgWindows { Write-Host "Restore from Borg-Windows selected"; Pause-Menu }
function Restore-BorgVM { Write-Host "Restore from Borg-in-VM selected"; Pause-Menu }

# Main Loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host

    switch ($choice) {
        "1" { Create-VM }
        "2" { List-VMs }
        "3" { StartStop-VM }
        "4" { Delete-VM }
        "5" { Backup-Restic }
        "6" { Backup-BorgWindows }
        "7" { Backup-BorgVM }
        "8" { Restore-Restic }
        "9" { Restore-BorgWindows }
        "10" { Restore-BorgVM }
        "0" {
            Write-Host "Goodbye!"
            break
        }
        default {
            Write-Host "Invalid option. Please select a valid menu number."
            Pause-Menu
        }
    }
}