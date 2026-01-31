# Windows Restic Backup for Ubuntu VM

Complete backup solution for Ubuntu VM running in Hyper-V on Windows host using Restic.

## Overview

This solution provides automated backups of Ubuntu VM (ubuntu58) to a remote SSH server using Restic. The backup is performed from the Windows host by stopping the VM, backing up the VM's virtual hard disk (VHD/VHDX) files, and restarting the VM.

## Prerequisites

1. **Windows 10/11** with Hyper-V enabled
2. **Administrator privileges** (required for Hyper-V operations)
3. **SSH client** installed (OpenSSH Client - included in Windows 10/11)
4. **Remote SSH server** accessible at:
   - `usdaw@srvdocker02` (Primary)
   - `suppg02@ubhost` (Alternative)
5. **Restic** backup tool (install using setup-restic.bat)

## Installation

### Step 1: Install Restic

Run setup script to download and install Restic:

```batch
setup-restic.bat
```

This will:
- Download the latest Restic binary for Windows
- Extract it to your user profile directory
- Add it to your system PATH
- Verify the installation

### Step 2: Verify Installation

After installation, restart your terminal and verify Restic is installed:

```batch
restic version
```

You should see output like:
```
restic 0.16.5 compiled with go1.21.1 on windows/amd64
```

## Usage

### Basic Backup

Run the backup script:

```batch
run-restic-backup.bat
```

The script will prompt you to choose between:
1. **srvdocker02** (User: usdaw)
2. **ubhost** (User: suppg02)

Then it will:
1. Stop VM: ubuntu58
2. Backup to the selected host via SSH
3. File location: /mnt/sda4
4. Use Restic for backup (with real-time progress bar)
5. Restart VM after backup

### Advanced Options

You can run the PowerShell script directly with custom parameters:

```powershell
.\backup-restic-windows.ps1 -VMName ubuntu58 -RemoteUser usdaw -RemoteHost srvdocker02 -RemotePath /mnt/sda4
```

### Parameters

| Parameter | Default | Description |
|-----------|----------|-------------|
| `-VMName` | ubuntu58 | Name of the VM to backup |
| `-RemoteUser` | usdaw | SSH username for the remote server |
| `-RemoteHost` | srvdocker02 | Remote server hostname |
| `-RemotePath` | /mnt/sda4 | Remote backup path |
| `-RepositoryName` | ubuntu58-restic-backup | Restic repository name |
| `-Password` | (prompt) | Restic repository password |
| `-SSHPassword` | (prompt) | SSH password for remote server |
| `-TestRun` | false | Test mode without actual backup |
| `-VerboseOutput` | false | Enable verbose output |
| `-BackupThreads` | 4 | Number of concurrent uploads |

## Features

### Backup Features

- **Full System Backup**: Backs up complete VM VHD files
- **Incremental Backups**: Restic automatically performs deduplication
- **Compression**: Automatic compression for efficient storage
- **Encryption**: All backups are encrypted with AES-256
- **Versioning**: Keeps multiple backup versions with a retention policy
- **Error Handling**: Graceful error handling with VM recovery

### Retention Policy

The script automatically prunes old backups:
- **7 daily backups** (last 7 days)
- **4 weekly backups** (last 4 weeks)
- **6 monthly backups** (last 6 months)

### VM Management

- **Automatic VM Shutdown**: Stops VM before backup for consistency
- **Automatic VM Restart**: Restarts VM after backup completes
- **Error Recovery**: Attempts to restart VM if backup fails

## Restore Procedure

### Full VM Restore

To restore an entire VM from a backup:

1. Stop the VM (if running)
2. Download the VHD file from the backup repository
3. Replace the existing VHD file
4. Start the VM

### Using Restic to Restore

```bash
# List available snapshots
restic snapshots --repo sftp:usdaw@srvdocker02:/mnt/sda4/ubuntu58-restic-backup

# Restore a specific snapshot
restic restore <snapshot-id> --repo sftp:usdaw@srvdocker02:/mnt/sda4/ubuntu58-restic-backup --target /path/to/restore
```

### Granular File Restore

If you need to restore specific files from within the VM:

1. Mount the backup repository
2. Copy individual files
3. Unmount the repository

```bash
# Mount the repository
restic mount /tmp/restic-mount --repo sftp:usdaw@srvdocker02:/mnt/sda4/ubuntu58-restic-backup

# Copy files from /tmp/restic-mount
cp /tmp/restic-mount/snapshots/<id>/path/to/file /destination

# Unmount
fusermount -u /tmp/restic-mount
```

## Scheduling

### Windows Task Scheduler

To schedule automatic backups:

1. Open Task Scheduler (`taskschd.msc`)
2. Create a new task
3. Set the trigger (e.g., daily at 2:00 AM)
4. Set the action to run `C:\Users\Test\Desktop\vmcreation\run-restic-backup.bat`
5. Run with highest privileges
6. Configure to run whether user is logged on or not

### Example Task Scheduler Command

```
Program: C:\Windows\System32\cmd.exe
Arguments: /c "C:\Users\Test\Desktop\vmcreation\run-restic-backup.bat"
Start in: C:\Users\Test\Desktop\vmcreation
```

## Troubleshooting

### Restic Not Found

If you get "Restic is not installed" error:

1. Run `setup-restic.bat` to install Restic
2. Restart your terminal
3. Verify with `restic version`

### SSH Connection Failed

If the SSH connection fails:

1. Verify the remote server is accessible: `ssh usdaw@srvdocker02`
2. Check firewall settings
3. Verify credentials (username: usdaw, password: 3C5x9cfg)
4. If password authentication fails, the script will prompt for SSH password

### VM Not Found

If the VM is not found:

1. Verify the VM name: `Get-VM`
2. Check that Hyper-V is enabled
3. Run as Administrator

### Backup Fails

If the backup fails:

1. Check available disk space on the remote server
2. Verify the SSH connection
3. Check that the VM is properly stopped
4. Review the error logs

## Security

- **Encryption**: All backups are encrypted with AES-256
- **Password Protection**: Repository password required for all operations
- **SSH**: Secure transfer to remote server
- **Access Control**: Only authorized users can access backups

## Performance

- **Concurrent Uploads**: Configurable number of threads (default: 4)
- **Compression**: Automatic compression reduces transfer size
- **Deduplication**: Only changed data is transferred
- **Incremental**: Fast subsequent backups

## Maintenance

### Check Repository Health

```bash
restic check --repo sftp:usdaw@srvdocker02:/mnt/sda4/ubuntu58-restic-backup
```

### View Repository Statistics

```bash
restic stats --repo sftp:usdaw@srvdocker02:/mnt/sda4/ubuntu58-restic-backup
```

### List Snapshots

```bash
restic snapshots --repo sftp:usdaw@srvdocker02:/mnt/sda4/ubuntu58-restic-backup
```

## Files

| File | Description |
|------|-------------|
| `setup-restic.bat` | Batch file to run Restic setup |
| `setup-restic-windows.ps1` | PowerShell script to download and install Restic |
| `run-restic-backup.bat` | Batch file to run backup script |
| `backup-restic-windows.ps1` | Main PowerShell backup script |
| `add-restic-to-path.bat` | Helper to add Restic to PATH |

## Support

For issues or questions:
1. Check the error messages in the console output
2. Verify all prerequisites are met
3. Review the troubleshooting section
4. Check the Restic documentation: https://restic.readthedocs.io/

## License

This backup solution is provided as-is for use with Ubuntu VM backups.

## Changelog

### Version 1.0
- Initial release
- VM shutdown and restart automation
- Restic backup integration
- SSH remote storage
- Error handling and recovery

### Version 1.1
- Updated remote host to srvdocker02
- Added SSH password parameter
- Fixed Restic installation script
- Added PATH helper script
