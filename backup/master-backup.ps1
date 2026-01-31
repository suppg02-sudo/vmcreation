# Master Backup Script
# Version: 1.0
# Last Updated: 2025-12-27
# Description: Unified entry point for all backup solutions
#
# Options:
#   1. Restic (Image-level, Windows Host) - Recommended for full VM backups
#   2. Borg-Windows (Image-level, Windows Host) - Better deduplication
#   3. Borg-VM (File-level, Inside VM) - Zero downtime, granular restore
#
# Usage: .\master-backup.ps1

Write-Host "=== Master Backup Script ===" -ForegroundColor Green
Write-Host "Choose your backup solution:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Restic (Image-level VHD backup)" -ForegroundColor Cyan
Write-Host "   - Full VM image backup to remote server"
Write-Host "   - Incremental, fast after first backup"
Write-Host "   - Recommended for disaster recovery"
Write-Host ""
Write-Host "2. Borg-Windows (Image-level VHD backup)" -ForegroundColor Cyan
Write-Host "   - Better deduplication than Restic"
Write-Host "   - Windows-native BorgBackup"
Write-Host "   - Excellent for long-term storage"
Write-Host ""
Write-Host "3. Borg-VM (File-level backup inside VM)" -ForegroundColor Cyan
Write-Host "   - Zero downtime backups"
Write-Host "   - Granular file/folder restore"
Write-Host "   - Run from within the Ubuntu VM"
Write-Host ""
Write-Host "4. Setup/Configure Backup Servers" -ForegroundColor Cyan
Write-Host "   - Install and configure backup tools"
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host "Starting Restic backup..." -ForegroundColor Green
        $vmName = Read-Host "Enter VM name (default: ubuntu58)"
        if (-not $vmName) { $vmName = "ubuntu58" }
        & "$PSScriptRoot\restic\backup-final.ps1" -VM_Name $vmName
    }
    "2" {
        Write-Host "Starting Borg-Windows backup..." -ForegroundColor Green
        $vmName = Read-Host "Enter VM name (default: ubuntu58)"
        if (-not $vmName) { $vmName = "ubuntu58" }
        & "$PSScriptRoot\borg-windows\backup-borg-windows.ps1" -VMName $vmName
    }
    "3" {
        Write-Host "Borg-VM backup must be run from within the Ubuntu VM" -ForegroundColor Yellow
        Write-Host "SSH into your VM and run:" -ForegroundColor Cyan
        Write-Host "sudo ./backup/borg/setup-borg.sh" -ForegroundColor White
        Write-Host "sudo ./backup/borg/backup-borg.sh" -ForegroundColor White
        Write-Host ""
        Write-Host "For restore:" -ForegroundColor Cyan
        Write-Host "sudo ./backup/borg/restore-borg.sh" -ForegroundColor White
    }
    "4" {
        Write-Host "Backup Setup Options:" -ForegroundColor Green
        Write-Host "1. Setup Restic" -ForegroundColor Cyan
        Write-Host "2. Setup Borg-Windows" -ForegroundColor Cyan
        $setupChoice = Read-Host "Enter setup choice (1-2)"
        switch ($setupChoice) {
            "1" {
                & "$PSScriptRoot\restic\setup-restic.ps1"
            }
            "2" {
                & "$PSScriptRoot\borg-windows\setup-borg-windows.ps1"
            }
            default {
                Write-Host "Invalid choice" -ForegroundColor Red
            }
        }
    }
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host "Backup operation complete." -ForegroundColor Green