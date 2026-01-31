# Restic Backup Solution

Restic-based VHD backup solution for Hyper-V VMs with incremental snapshots to remote SSH server.

## Overview

This solution provides **image-level backup** of Hyper-V VM VHD files using Restic:
- Stops VM, backs up VHD files, restarts VM
- Incremental backups with deduplication
- Remote storage via SFTP
- Automated retention policies

## Prerequisites

- Restic installed at `C:\Restic\restic.exe`
- Remote SSH server configured (see `../config.json`)
- PowerShell with Hyper-V module
- Administrator privileges

## Configuration

All configuration is centralized in `../../config.json`:

```json
{
  "backup": {
    "server": "srvdocker02",
    "user": "usdaw",
    "passwordEnvVar": "BACKUP_SERVER_PASSWORD",
    "backupRoot": "/media/backup"
  },
  "restic": {
    "path": "C:\\Restic\\restic.exe",
    "passwordEnvVar": "RESTIC_PASSWORD",
    "retention": {
      "daily": 7,
      "weekly": 4,
      "monthly": 6
    }
  }
}
```

### Required Environment Variables

Set these before running backups:

```powershell
# Windows PowerShell
$env:BACKUP_SERVER_PASSWORD = "your_password"
$env:RESTIC_PASSWORD = "your_restic_password"

# Or set system-wide:
[System.Environment]::SetEnvironmentVariable("BACKUP_SERVER_PASSWORD", "your_password", "User")
[System.Environment]::SetEnvironmentVariable("RESTIC_PASSWORD", "your_restic_password", "User")
```

## Scripts

### backup-final.ps1 (v1.0 - 2025-12-27)

**Current working version** - Image-level VHD backup

```powershell
.\backup-final.ps1 -VM_Name "ubuntu58"
```

**What it does:**
1. Validates Restic installation
2. Locates VM VHD files
3. Tests repository connection (creates if needed)
4. Stops the VM
5. Backs up all VHD files
6. Applies retention policy
7. Restarts the VM

**Features:**
- Automatic VM stop/start
- Multiple VHD support
- Progress reporting
- Error handling with VM restart
- Compression and deduplication

### setup-restic.ps1

Initial Restic setup and repository initialization

```powershell
.\setup-restic.ps1 -VM_Name "ubuntu58"
```

### test-restic-connection.ps1

Test connection to Restic repository

```powershell
.\test-restic-connection.ps1
```

## Usage

### First Time Setup

1. Install Restic:
   ```powershell
   # Download from https://github.com/restic/restic/releases
   # Extract to C:\Restic\
   ```

2. Set environment variables (see Configuration above)

3. Run setup:
   ```powershell
   .\setup-restic.ps1 -VM_Name "ubuntu58"
   ```

### Regular Backups

```powershell
# Manual backup
.\backup-final.ps1 -VM_Name "ubuntu58"

# Scheduled via Task Scheduler
schtasks /create /tn "VM Backup" /tr "powershell C:\...\backup-final.ps1" /sc daily /st 02:00 /ru SYSTEM
```

### Repository Management

```powershell
# List snapshots
& "C:\Restic\restic.exe" snapshots --repo sftp://user@server/path

# Check repository
& "C:\Restic\restic.exe" check --repo sftp://user@server/path

# View statistics
& "C:\Restic\restic.exe" stats --repo sftp://user@server/path
```

## Restore Procedures

See [RESTORE-GUIDE.md](RESTORE-GUIDE.md) for detailed restore instructions.

### Quick Restore

```powershell
# List snapshots
restic -r sftp://user@server/path snapshots

# Restore specific snapshot
restic -r sftp://user@server/path restore <snapshot-id> --target C:\Restore

# Copy restored VHD to VM
Copy-Item C:\Restore\path\to\file.vhdx C:\VMs\NewVM\
```

## Advantages

✅ **Incremental**: Only changed blocks transferred  
✅ **Deduplication**: Efficient storage usage  
✅ **Encryption**: Data encrypted at rest  
✅ **Compression**: Automatic compression  
✅ **Versioning**: Multiple snapshots retained  
✅ **Remote Storage**: Offsite backup protection  

## Limitations

⚠️ **VM Downtime**: VM stopped during backup (typically 5-15 minutes)  
⚠️ **Block-Level**: Cannot restore individual files (see BorgBackup alternative)  
⚠️ **Network Dependent**: Requires reliable connection to backup server  

## Troubleshooting

### Repository Access Errors
```powershell
# Test SSH connection
ssh user@server

# Verify environment variables
echo $env:BACKUP_SERVER_PASSWORD
echo $env:RESTIC_PASSWORD
```

### VM Won't Stop
```powershell
# Force stop
Stop-VM -Name "ubuntu58" -Force -TurnOff
```

### Backup Failures
Check logs and verify:
- Restic is installed at correct path
- Repository is accessible
- Environment variables are set
- Sufficient disk space on backup server

## Version History

- **v1.0 (2025-12-27)**: Renamed from backup-final-fixed.ps1, uses config.json
- Previous versions archived to `../../archive/2025-12-27/`

---

For file-level backup alternative, see [../borg/README-borg.md](../borg/README-borg.md)
