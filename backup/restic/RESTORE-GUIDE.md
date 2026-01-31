# Restic Restore Guide

Comprehensive guide for testing and performing restore operations with Restic backups.

## Table of Contents

1. [Pre-Restore Checklist](#pre-restore-checklist)
2. [Test Restore Procedures](#test-restore-procedures)
3. [Production Restore Scenarios](#production-restore-scenarios)
4. [Bare-Metal Recovery](#bare-metal-recovery)
5. [Troubleshooting](#troubleshooting)

---

## Pre-Restore Checklist

Before attempting any restore:

- [ ] Verify backup repository is accessible
- [ ] Confirm snapshot exists and is complete
- [ ] Have environment variables set (`RESTIC_PASSWORD`, `BACKUP_SERVER_PASSWORD`)
- [ ] Sufficient disk space for restore target
- [ ] Backup current state (if applicable)
- [ ] Note VM configuration (memory, CPUs, network settings)

---

## Test Restore Procedures

### Test 1: Verify Repository Access

```powershell
# Set environment variables
$env:RESTIC_PASSWORD = "your_restic_password"
$env:BACKUP_SERVER_PASSWORD = "your_backup_password"

# List available snapshots
& "C:\Restic\restic.exe" snapshots --repo sftp://usdaw@srvdocker02/media/backup/ubuntu58-vhd

# Expected output: List of snapshots with dates and sizes
```

✅ **Success**: Snapshots listed  
❌ **Failure**: See [Troubleshooting](#repository-access-errors)

### Test 2: Restore to Test Location

```powershell
# Create test directory
New-Item -ItemType Directory -Path "C:\RestoreTest" -Force

# Restore latest snapshot to test location
$repoUrl = "sftp://usdaw@srvdocker02/media/backup/ubuntu58-vhd"
& "C:\Restic\restic.exe" restore latest --repo $repoUrl --target "C:\RestoreTest"

# Verify files
Get-ChildItem "C:\RestoreTest" -Recurse
```

✅ **Success**: VHD files appear in C:\RestoreTest\  
❌ **Failure**: See [Troubleshooting](#restore-failures)

### Test 3: Verify VHD Integrity

```powershell
# Test VHD file can be mounted
Test-VHD -Path "C:\RestoreTest\path\to\restored.vhdx"

# Expected output: No errors
```

✅ **Success**: VHD passes integrity check  
❌ **Failure**: VHD may be corrupted, try different snapshot

### Test 4: Create Test VM from Restored VHD

```powershell
# Create test VM
$TestVMName = "ubuntu58-restore-test"
New-VM -Name $TestVMName -MemoryStartupBytes 4GB -Generation 1 -VHDPath "C:\RestoreTest\path\to\os.vhdx"

# Start VM
Start-VM -Name $TestVMName

# Monitor boot
Connect-VM -VMName $TestVMName

# After testing, cleanup
Stop-VM -Name $TestVMName -Force
Remove-VM -Name $TestVMName -Force
```

✅ **Success**: VM boots successfully  
❌ **Failure**: Check VHD compatibility, VM settings

---

## Production Restore Scenarios

### Scenario 1: Restore to New VM (Different Name)

**Use Case**: Create a clone or test environment

```powershell
# 1. Restore VHD files
$env:RESTIC_PASSWORD = "your_password"
$repoUrl = "sftp://usdaw@srvdocker02/media/backup/ubuntu58-vhd"
New-Item -ItemType Directory -Path "C:\VMs\ubuntu58-clone" -Force

& "C:\Restic\restic.exe" restore latest --repo $repoUrl --target "C:\VMs\ubuntu58-clone"

# 2. Create new VM
$NewVMName = "ubuntu58-clone"
$VHDPath = "C:\VMs\ubuntu58-clone\VirtualMachines\...\os.vhdx"

New-VM -Name $NewVMName -MemoryStartupBytes 4GB -Generation 1 -VHDPath $VHDPath -SwitchName "External Switch"
Set-VMProcessor -VMName $NewVMName -Count 2

# 3. Start new VM
Start-VM -Name $NewVMName
```

### Scenario 2: Restore to Existing VM (Replace Corrupted VHD)

**Use Case**: Original VM VHD corrupted, restore from backup

```powershell
# 1. Stop existing VM
Stop-VM -Name "ubuntu58" -Force

# 2. Backup current (corrupted) VHD
$VMPath = (Get-VM "ubuntu58").Path
Copy-Item "$VMPath\*.vhdx" "$VMPath\corrupted_backup\" -Recurse

# 3. Remove corrupted VHD from VM
$VM = Get-VM "ubuntu58"
$VHDs = Get-VMHardDiskDrive -VMName "ubuntu58"
foreach ($vhd in $VHDs) {
    Remove-VMHardDiskDrive -VMHardDiskDrive $vhd
}

# 4. Restore from backup
$env:RESTIC_PASSWORD = "your_password"
$repoUrl = "sftp://usdaw@srvdocker02/media/backup/ubuntu58-vhd"
& "C:\Restic\restic.exe" restore latest --repo $repoUrl --target $VMPath

# 5. Re-attach restored VHDs
$RestoredVHD = Get-ChildItem "$VMPath\*.vhdx" -Recurse | Select-Object -First 1
Add-VMHardDiskDrive -VMName "ubuntu58" -Path $RestoredVHD.FullName

# 6. Start VM
Start-VM -Name "ubuntu58"
```

### Scenario 3: Restore Specific Snapshot (Point-in-Time)

**Use Case**: Rollback to specific date

```powershell
# 1. List snapshots with dates
$env:RESTIC_PASSWORD = "your_password"
$repoUrl = "sftp://usdaw@srvdocker02/media/backup/ubuntu58-vhd"
& "C:\Restic\restic.exe" snapshots --repo $repoUrl

# Example output:
# ID        Time                 Host        Tags
# abc123    2025-12-20 02:00:00  DESKTOP     vhd-backup
# def456    2025-12-21 02:00:00  DESKTOP     vhd-backup
# ghi789    2025-12-27 02:00:00  DESKTOP     vhd-backup

# 2. Restore specific snapshot (e.g., from 2025-12-20)
New-Item -ItemType Directory -Path "C:\VMs\ubuntu58-dec20" -Force
& "C:\Restic\restic.exe" restore abc123 --repo $repoUrl --target "C:\VMs\ubuntu58-dec20"

# 3. Create VM from restored snapshot
# (Follow steps from Scenario 1)
```

---

## Bare-Metal Recovery

**Complete disaster recovery**: Windows host crashed, rebuilding from scratch

### Prerequisites

- New Windows 10/11 Pro/Enterprise with Hyper-V
- Access to backup server
- Restic installer
- Original VM configuration notes

### Step-by-Step Recovery

#### 1. Install Restic on New Host

```powershell
# Download Restic
$ResticURL = "https://github.com/restic/restic/releases/latest/download/restic_0.16.4_windows_amd64.zip"
Invoke-WebRequest -Uri $ResticURL -OutFile "C:\Temp\restic.zip"

# Extract
Expand-Archive -Path "C:\Temp\restic.zip" -DestinationPath "C:\Restic"

# Verify
& "C:\Restic\restic.exe" version
```

#### 2. Set Environment Variables

```powershell
[System.Environment]::SetEnvironmentVariable("RESTIC_PASSWORD", "your_restic_password", "User")
[System.Environment]::SetEnvironmentVariable("BACKUP_SERVER_PASSWORD", "your_backup_password", "User")

# Reload environment
$env:RESTIC_PASSWORD = [System.Environment]::GetEnvironmentVariable("RESTIC_PASSWORD", "User")
```

#### 3. Test Repository Access

```powershell
$repoUrl = "sftp://usdaw@srvdocker02/media/backup/ubuntu58-vhd"
& "C:\Restic\restic.exe" snapshots --repo $repoUrl
```

#### 4. Restore Latest Backup

```powershell
# Create VM directory
New-Item -ItemType Directory -Path "C:\VMs\ubuntu58" -Force

# Restore
& "C:\Restic\restic.exe" restore latest --repo $repoUrl --target "C:\VMs\ubuntu58"
```

#### 5. Recreate VM

```powershell
# Find restored VHD
$OSVHD = Get-ChildItem "C:\VMs\ubuntu58" -Filter "*os*.vhdx" -Recurse | Select-Object -First 1
$DataVHD = Get-ChildItem "C:\VMs\ubuntu58" -Filter "*data*.vhdx" -Recurse | Select-Object -First 1

# Create VM with original specs
New-VM -Name "ubuntu58" -MemoryStartupBytes 4GB -Generation 1 -VHDPath $OSVHD.FullName -Path "C:\VMs" -SwitchName "External Switch"

Set-VMProcessor -VMName "ubuntu58" -Count 2

# Add data disk if exists
if ($DataVHD) {
    Add-VMHardDiskDrive -VMName "ubuntu58" -ControllerType SCSI -Path $DataVHD.FullName
}

# Start VM
Start-VM -Name "ubuntu58"
```

#### 6. Verify Recovery

```powershell
# Check VM status
Get-VM "ubuntu58" | Select-Object Name, State, Status, Uptime

# Connect to console
Connect-VM -VMName "ubuntu58"

# SSH into VM (once booted)
ssh root@<VM_IP>
```

---

## Troubleshooting

### Repository Access Errors

**Error**: `Fatal: unable to open config file`

```powershell
# Test SSH connection
ssh usdaw@srvdocker02

# Verify repository exists
ssh usdaw@srvdocker02 "ls -la /media/backup/ubuntu58-vhd"

# Check environment variable
echo $env:RESTIC_PASSWORD
```

### Restore Failures

**Error**: `unable to create dir`

```powershell
# Ensure target directory exists and is writable
New-Item -ItemType Directory -Path "C:\RestoreTarget" -Force
icacls "C:\RestoreTarget" /grant "$env:USERNAME:(OI)(CI)F"
```

**Error**: `partial file`

```powershell
# Try with --verify
& "C:\Restic\restic.exe" restore latest --repo $repoUrl --target "C:\Restore" --verify

# Check repository integrity
& "C:\Restic\restic.exe" check --repo $repoUrl
```

### VHD Mount Failures

**Error**: VHD won't mount or fails integrity check

```powershell
# Try different snapshot
& "C:\Restic\restic.exe" snapshots --repo $repoUrl
& "C:\Restic\restic.exe" restore <snapshot-id> --repo $repoUrl --target "C:\Restore"

# Repair VHD (if needed)
Resize-VHD -Path "C:\Path\to\restored.vhdx" -SizeBytes 50GB
```

### VM Boot Failures

**Issue**: VM doesn't boot from restored VHD

- Verify VM Generation (should be 1 for cloud images)
- Check boot order in VM settings
- Ensure VHD is attached to correct controller (IDE for Gen 1)
- Try booting in Hyper-V console to see error messages

---

## Best Practices

1. **Test Restores Quarterly**: Don't wait for disaster to test
2. **Document VM Config**: Keep notes on memory, CPUs, network settings
3. **Multiple Snapshots**: Don't rely on just the latest
4. **Verify After Restore**: Always boot and test restored VMs
5. **Keep Backups Offsite**: Store credentials securely but accessibly

---

## Recovery Time Objectives

| Scenario | Expected Time | Notes |
|----------|---------------|-------|
| Test restore | 10-20 min | Depends on VHD size, network speed |
| Same-host restore | 20-30 min | Includes VM recreation |
| Different host restore | 30-60 min | Includes Restic installation |
| Bare-metal recovery | 1-2 hours | Includes Windows setup, Hyper-V config |

---

**Last Updated**: 2025-12-27  
**Script Version**: backup-final.ps1 v1.0

For additional help, see [README-restic.md](README-restic.md) or consult [../../docs/operational-notes.md](../../docs/operational-notes.md)
