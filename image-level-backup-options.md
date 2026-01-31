# Image-Level Backup Options

## Understanding Image-Level vs File-Level Backups

### File-Level Backup (Restic)
- ✅ **Incremental/delta**: Only changed files
- ✅ **Granular restore**: Individual files/folders
- ✅ **Compression**: Reduces storage
- ✅ **Resume**: Can restart interrupted backups
- ❌ **Not true image**: Can't boot directly from backup

### Image-Level Backup (VHD Copy)
- ✅ **True image**: Complete bootable system
- ✅ **Simple restore**: Copy back VHD files
- ❌ **No incremental**: Full copy each time
- ❌ **Large storage**: No deduplication
- ❌ **No resume**: Must restart if interrupted

## Recommended Solution: Hybrid Approach

### Option 1: Restic for Daily Backups (File-Level)
```bash
# Run on Ubuntu VM
sudo ./ubuntu-vm-restic-setup.sh
```
- **Daily incremental backups** (fast after first)
- **Full system restore** capability
- **Granular file restore**
- **Resume capability**

### Option 2: Weekly Image Backup (VHD Copy)
```bash
# Run on Windows host
PowerShell -ExecutionPolicy Bypass -File "C:\Users\Test\Desktop\vmcreation\correct-backup-target.ps1"
```
- **Weekly full image backup**
- **Bootable system restore**
- **Simple and reliable**

## Complete Backup Strategy

### Daily: Restic (File-Level Incremental)
- **Speed**: Fast after initial backup
- **Storage**: Efficient (deduplication)
- **Restore**: Full system or individual files
- **Resume**: Yes

### Weekly: VHD Copy (Image-Level)
- **Speed**: Slower but complete
- **Storage**: Larger but bootable
- **Restore**: Direct VHD replacement
- **Resume**: No

## Implementation

### Step 1: Set Up Restic (Daily)
```bash
# On Ubuntu VM
sudo ./ubuntu-vm-restic-setup.sh
```

### Step 2: Set Up Weekly Image Backup
```powershell
# On Windows host - modify for weekly schedule
# Add to Task Scheduler or run manually weekly
PowerShell -ExecutionPolicy Bypass -File "C:\Users\Test\Desktop\vmcreation\correct-backup-target.ps1"
```

### Step 3: Restore Options

#### Restore from Restic (File-Level)
```bash
# Full system restore
sudo /root/restic-restore.sh restore-latest

# Individual file restore
sudo /root/restic-restore.sh restore-file <snapshot> /path/to/file /restore/location
```

#### Restore from VHD (Image-Level)
```powershell
# Stop VM, replace VHD files, start VM
Stop-VM -Name ubuntu58
# Copy VHD files back from backup
Start-VM -Name ubuntu58
```

## Benefits of This Hybrid Approach

- ✅ **Daily protection** with fast incremental backups
- ✅ **Weekly assurance** with complete bootable images
- ✅ **Best of both worlds**: Speed + reliability
- ✅ **Multiple restore options**
- ✅ **Resume capability** for daily backups

This gives you both incremental efficiency AND image-level recovery capability!