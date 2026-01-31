# Ubuntu VM Backup Strategy using Restic

## Overview

This comprehensive backup strategy for your Ubuntu VM (ubuntu58) running in Hyper-V uses Restic, a modern, secure, and efficient backup program. The backup runs from the Windows host, backing up the VHDX file directly, which provides better performance, integration with Hyper-V, and simplicity compared to in-VM backups.

## Why This Approach

- **Advantages over in-VM backups**: Direct access to VHDX eliminates the need for VM resources, reduces complexity, and allows backing up the VM in a stopped state for consistency.
- **Hyper-V integration**: Uses PowerShell cmdlets for VM management, ensuring reliable start/stop operations.
- **Performance**: Faster backups without VM overhead.
- **Portability**: Script can be run from any Windows machine with Hyper-V access.

## Selected Tool: Restic

Restic was chosen for its:
- Deduplicating incremental backups
- Built-in compression and encryption
- Snapshot-based versioning
- Support for SSH backends
- Cross-platform compatibility
- Active development and community support

## Features Implemented

- **Full system image**: Backs up the entire VHDX file, allowing complete VM restoration.
- **Incremental/delta backups**: Only changed data is backed up after the first full backup.
- **Compression**: Automatic compression reduces storage needs.
- **Encryption**: All data is encrypted with AES-256.
- **Versioning**: Multiple snapshots allow restoring to different points in time.
- **Scheduling**: Automated via Windows Task Scheduler.
- **Granular restores**: Individual files can be restored by mounting the VHDX.
- **Offsite storage**: Backups stored on remote SSH server.
- **Error handling**: Comprehensive logging and graceful failure handling.
- **Minimal downtime**: VM only stopped during backup/restore operations.

## Requirements

- Windows 10/11 with Hyper-V enabled
- PowerShell 5.1 or later
- SSH access to srvdocker02 with user usdaw and password 3C5x9cfg
- Sufficient disk space on remote server

## Step-by-Step Setup

1. **Download and Install Restic**
   The script automatically downloads and installs Restic if not present.

2. **Configure the Script**
   Edit `ubuntu-vm-backup-restic.ps1` if needed:
   - VMName: "ubuntu58"
   - RemoteHost: "srvdocker02"
   - RemoteUser: "usdaw"
   - RemotePath: "/home/usdaw/ubuntu-vm-backup"
   - Password: "3C5x9cfg"

3. **Initialize the Repository**
   Run: `.\ubuntu-vm-backup-restic.ps1 -InitializeRepo`
   This creates the encrypted repository on the remote server.

4. **Run Initial Backup**
   Run: `.\ubuntu-vm-backup-restic.ps1`
   This performs the first full backup.

## Running Automated Backups

### Manual Execution
- Run the script: `.\ubuntu-vm-backup-restic.ps1`

### Scheduling
Use Windows Task Scheduler:
1. Open Task Scheduler
2. Create new task
3. Set trigger (e.g., daily at 2 AM)
4. Set action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\ubuntu-vm-backup-restic.ps1"`
5. Run with highest privileges
6. Save

## Restore Procedures

### Full VM Restore
To restore the entire VM to a previous state:
1. Identify the snapshot ID: Run `restic snapshots` (set env vars first)
2. Run: `.\ubuntu-vm-backup-restic.ps1 -Restore -SnapshotID <snapshot-id>`
   Use "latest" for most recent.
This stops the VM, restores the VHDX, and restarts the VM.

### Granular File Restore
To restore individual files or directories:
1. Restore VHDX to temporary location:
   Set environment variables:
   `$env:RESTIC_REPOSITORY = 'sftp:usdaw@srvdocker02:/home/usdaw/ubuntu-vm-backup'`
   `$env:RESTIC_PASSWORD = '3C5x9cfg'`
   Then: `restic restore <snapshot-id> --target C:\temp\vhdx-restore --include "C:\path\to\ubuntu58.vhdx"`
2. Mount the restored VHDX:
   `Mount-VHD -Path C:\temp\vhdx-restore\ubuntu58.vhdx`
3. The VHDX will appear as a new drive (e.g., F:\)
4. Navigate to the mounted drive and copy desired files.
5. Dismount: `Dismount-VHD -Path C:\temp\vhdx-restore\ubuntu58.vhdx`
6. Clean up temporary files.

### Creating a New VM from Backup
For testing or disaster recovery:
1. Restore VHDX as above to a new location.
2. Create new VM in Hyper-V Manager.
3. Attach the restored VHDX as the virtual hard disk.
4. Start the new VM.

## Testing the Restore Process

1. **Basic Test**: Run `.\ubuntu-vm-backup-restic.ps1 -TestRestore`
   This restores the latest VHDX to a temp directory and verifies the file exists.

2. **Full Test**:
   - Create a new VM with the restored VHDX.
   - Boot the VM and verify functionality.
   - Test applications and data integrity.

3. **Granular Test**:
   - Restore a test file using the granular restore process.
   - Verify the file contents.

## Error Handling and Reliability

- **Logging**: All operations logged to `ubuntu-vm-backup.log`
- **Timeouts**: VM operations have 60-second timeouts to prevent hanging.
- **Exit Codes**: Script exits with 1 on errors, 0 on success.
- **Graceful Failures**: VM is restarted even if backup fails.
- **Network Issues**: SSH connection handled by Restic, with retries.

## Security Considerations

- Backups are encrypted at rest.
- SSH password is stored in script (consider using SSH keys for better security).
- Remote server should have proper access controls.

## Maintenance

- Monitor log files for errors.
- Periodically test restores.
- Clean old snapshots if needed: `restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12`
- Check repository integrity: `restic check`

## Troubleshooting

- **VM won't stop/start**: Check Hyper-V permissions.
- **SSH connection fails**: Verify credentials and network.
- **Backup fails**: Check disk space and permissions.
- **Restore fails**: Ensure snapshot exists and paths are correct.

This strategy provides a robust, automated backup solution for your Ubuntu VM with comprehensive features and reliable operation.