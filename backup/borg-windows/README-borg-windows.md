# BorgBackup for Windows Host

VHD image-level backup using BorgBackup from Windows host - an alternative to Restic.

## Overview

This solution provides **image-level VHD backup** using BorgBackup from Windows:
- Stops VM, backs up VHD files, restarts VM
- Deduplication and compression (better than Restic for similar data)
- Remote storage via SSH
- Faster backups after initial run
- Native Linux tool with Windows builds

## Why Choose Borg over Restic?

**Borg Advantages:**
- ✅ **Better deduplication** - More efficient storage
- ✅ **Faster incremental backups** - Typically 20-30% faster
- ✅ **Append-only mode** - Protection against ransomware
- ✅ **Mature and stable** - Longer track record
- ✅ **Better compression** - LZ4, ZSTD options

**Restic Advantages:**
- ✅ **Simpler setup** - Single executable
- ✅ **Cloud storage support** - S3, Azure, GCS
- ✅ **Concurrent backups** - Better for many files

## Prerequisites

- Windows 10/11 with Hyper-V
- Administrator privileges
- Remote SSH server configured
- PowerShell 5.1 or higher

## Installation

### Automatic Setup

```powershell
# Run as Administrator
.\setup-borg-windows.ps1
```

This will:
1. Download BorgBackup for Windows
2. Install to `C:\Program Files\Borg\`
3. Add to PATH
4. Test SSH connection

### Manual Setup

```powershell
# Download from https://github.com/borgbackup/borg/releases
# Extract borg-windows64.exe to C:\Program Files\Borg\borg.exe

# Add to PATH
$env:Path += ";C:\Program Files\Borg"
```

## Configuration

### Environment Variables

Set before running backups:

```powershell
# Repository passphrase (required)
$env:BORG_PASSPHRASE = "your_secure_passphrase"

# SSH password (or use SSH keys - recommended)
$env:BACKUP_SERVER_PASSWORD = "your_ssh_password"

# System-wide (optional)
[System.Environment]::SetEnvironmentVariable("BORG_PASSPHRASE", "your_passphrase", "User")
```

### Config Reference

See `../../config.json`:

```json
{
  "borgWindows": {
    "path": "C:\\Program Files\\Borg\\borg.exe",
    "repoFormat": "user@server:/path/vm-name-borg-vhd",
    "compression": "lz4",
    "retention": {
      "daily": 7,
      "weekly": 4,
      "monthly": 6
    }
  }
}
```

## Usage

### First Backup

```powershell
# Set passphrase
$env:BORG_PASSPHRASE = "your_passphrase"

# Run backup
.\backup-borg-windows.ps1 -VM_Name "ubuntu58"
```

### Scheduled Backups

```powershell
# Create scheduled task for daily backups
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Users\...\backup-borg-windows.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM

Register-ScheduledTask -TaskName "VM Borg Backup" `
    -Action $action -Trigger $trigger -RunLevel Highest
```

### Repository Management

```powershell
$borg = "C:\Program Files\Borg\borg.exe"
$repo = "usdaw@srvdocker02:/media/backup/ubuntu58-borg-vhd"

# List archives
& $borg list --repo $repo

# Check repository
& $borg check --repo $repo

# View repository info
& $borg info --repo $repo

# Compact repository (reclaim space)
& $borg compact --repo $repo
```

## Restore Procedures

### List Archives

```powershell
$borg = "C:\Program Files\Borg\borg.exe"
$repo = "usdaw@srvdocker02:/media/backup/ubuntu58-borg-vhd"

& $borg list --repo $repo
# Output shows: ubuntu58-2025-12-27_02-00-00
```

### Extract VHD Files

```powershell
# Create restore directory
New-Item -ItemType Directory -Path "C:\RestoreBorg" -Force

# Extract specific archive
$archive = "ubuntu58-2025-12-27_02-00-00"
& $borg extract --repo $repo "::$archive" --target "C:\RestoreBorg"

# VHD files will be in C:\RestoreBorg\
```

### Restore to New VM

```powershell
# Find restored VHD
$vhd = Get-ChildItem "C:\RestoreBorg" -Filter "*.vhdx" -Recurse | Select -First 1

# Create new VM
New-VM -Name "ubuntu58-restored" `
    -MemoryStartupBytes 4GB `
    -Generation 1 `
    -VHDPath $vhd.FullName `
    -SwitchName "External Switch"

Start-VM -Name "ubuntu58-restored"
```

## Comparison: Borg vs Restic vs Borg-in-VM

| Feature | Borg (Windows) | Restic (Windows) | Borg (In-VM) |
|---------|----------------|------------------|--------------|
| **Location** | Windows Host | Windows Host | Inside VM |
| **Backup Type** | VHD Image | VHD Image | Files |
| **VM Downtime** | 5-15 min | 5-15 min | None |
| **Deduplication** | Excellent | Good | Excellent |
| **Speed** | Fast | Medium | Fast |
| **Restore Granularity** | VHD only | VHD only | File-level |
| **Setup Complexity** | Medium | Low | Medium |
| **Storage Efficiency** | Excellent | Good | Excellent |

## Performance Tips

1. **Use LZ4 compression** - Fast with good ratio
2. **Run backups at night** - Avoid VM downtime during working hours
3. **Compact regularly** - `borg compact` to reclaim space
4. **Monitor repository size** - Use `borg info --stats`

## Troubleshooting

### Borg Not Found

```powershell
# Verify installation
Test-Path "C:\Program Files\Borg\borg.exe"

# Re-run setup
.\setup-borg-windows.ps1
```

### SSH Connection Failed

```powershell
# Test SSH manually
ssh usdaw@srvdocker02

# Set up SSH keys (recommended)
ssh-keygen -t rsa
ssh-copy-id usdaw@srvdocker02
```

### Repository Locked

```powershell
# If backup crashed, break lock
& "C:\Program Files\Borg\borg.exe" break-lock --repo $repo
```

### Large Backup Size

```powershell
# Check what's taking space
& $borg info --repo $repo --stats

# Prune more aggressively
& $borg prune --repo $repo --keep-daily=3 --keep-weekly=2 --keep-monthly=3
```

## Advantages Over Alternatives

**vs Restic:**
- 20-30% faster incremental backups
- Better deduplication (saves storage)
- Append-only mode for security

**vs Borg-in-VM:**
- Bare-metal recovery simpler (just restore VHD)
- No need to configure inside VM
- Centralized Windows-based backups

## Security Considerations

- Use strong `BORG_PASSPHRASE`
- Enable append-only mode for ransomware protection:
  ```powershell
  & $borg init --append-only --encryption=repokey --repo $repo
  ```
- Use SSH keys instead of passwords
- Store passphrase in Windows Credential Manager

## Version History

- **v1.0 (2025-12-27)**: Initial Windows host implementation

---

**For other backup options:**
- Image-level with Restic: [../restic/README-restic.md](../restic/README-restic.md)
- File-level from VM: [../borg/README-borg.md](../borg/README-borg.md)
