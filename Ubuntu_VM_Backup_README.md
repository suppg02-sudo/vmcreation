# Ubuntu VM Backup Strategy with BorgBackup

This document provides a comprehensive backup solution for your Ubuntu VM (ubuntu58) running in Hyper-V on a Windows host. The strategy uses BorgBackup running from within the Ubuntu VM for simplicity, portability, and full control over the backup process.

## Overview

The backup solution uses BorgBackup, a deduplicating backup program that provides:
- Full system image backups
- Incremental/delta backups for efficiency
- Compression and encryption
- Versioning and retention policies
- Granular restore capabilities
- Remote storage via SSH

Backups are stored on a remote SSH server at `usdaw@srvdocker02` with password `3C5x9cfg`.

## Prerequisites

1. Ubuntu VM (ubuntu58) accessible via SSH
2. SSH access to remote server `srvdocker02` with credentials:
   - Username: `usdaw`
   - Password: `3C5x9cfg`
3. Root or sudo access on the Ubuntu VM
4. Internet connection for package installation

## Files Overview

- `setup-borg.sh`: Installs BorgBackup and sets up SSH keys for remote access
- `backup-borg.sh`: Performs automated full system backups
- `restore-borg.sh`: Handles restoration from backups
- `cron-setup.sh`: Sets up automated scheduling via cron

## Step-by-Step Setup

### 1. Initial Setup and Installation

Run the setup script on your Ubuntu VM:

```bash
# Make scripts executable
chmod +x setup-borg.sh backup-borg.sh restore-borg.sh cron-setup.sh

# Run setup
sudo ./setup-borg.sh
```

This script will:
- Install BorgBackup
- Generate SSH keys for passwordless access to the remote server
- Configure SSH client settings
- Test connectivity to the backup server

### 2. Configure Backup Repository

The setup script creates the initial repository. If you need to recreate or modify:

```bash
# Initialize repository (run on Ubuntu VM)
borg init --encryption=repokey ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

You'll be prompted for the repository passphrase. Choose a strong, memorable passphrase.

### 3. Run Initial Backup

Perform your first full backup:

```bash
sudo ./backup-borg.sh
```

This creates a complete system image including:
- All mounted filesystems
- System configurations
- User data
- Installed applications
- Package lists for easy restoration

### 4. Set Up Automated Scheduling

Configure cron for regular backups:

```bash
sudo ./cron-setup.sh
```

This sets up:
- Daily backups at 2 AM
- Weekly full backups on Sundays
- Automatic cleanup of old backups (keeps 7 daily, 4 weekly, 12 monthly)

## Backup Operations

### Manual Backup

Run anytime for immediate backup:

```bash
sudo ./backup-borg.sh
```

### Check Backup Status

List available backups:

```bash
borg list ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

Check repository info:

```bash
borg info ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

### View Backup Contents

List files in a specific backup:

```bash
borg list ssh://usdaw@srvdocker02/~/ubuntu58-backups::backup-name
```

## Restore Operations

### Full System Restore

To restore to a fresh Ubuntu VM:

1. Install Ubuntu on a new VM
2. Install BorgBackup: `sudo apt install borgbackup`
3. Copy SSH keys from original VM or regenerate
4. Run restore script:

```bash
sudo ./restore-borg.sh
```

Select the backup to restore from when prompted.

### Granular Restore

Restore specific files or directories:

```bash
# List contents of a backup
borg list ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest-backup

# Restore specific file
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest-backup path/to/file

# Restore directory
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest-backup path/to/directory
```

### Restore to Different Location

```bash
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest-backup --strip-components 1 /restore/path
```

## Advanced Features

### Compression

Backups use LZ4 compression by default. To change:

```bash
# In backup-borg.sh, modify the create command
borg create --compression lzma ...
```

### Encryption

Repository uses repokey encryption. To change encryption:

```bash
borg init --encryption=keyfile ...
```

### Retention Policy

Current policy (in backup script):
- Keep 7 daily backups
- Keep 4 weekly backups
- Keep 12 monthly backups

Modify in `backup-borg.sh` as needed.

### Offsite Storage

Backups are automatically stored on the remote SSH server. For additional offsite:

```bash
# Mount additional remote storage and copy backups
rsync -av /path/to/backups /additional/remote/path
```

## Testing the Restore Process

### Test Restore Procedure

1. Create a test VM with same Ubuntu version
2. Install BorgBackup
3. Copy SSH keys from production VM
4. Run restore script on test VM
5. Verify system functionality
6. Test application configurations

### Automated Testing

Create a test script:

```bash
#!/bin/bash
# test-restore.sh

# Create test environment
mkdir -p /tmp/test-restore
cd /tmp/test-restore

# Extract latest backup
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest

# Verify key files exist
if [ -f /tmp/test-restore/etc/hostname ]; then
    echo "Restore test passed"
else
    echo "Restore test failed"
fi
```

## Monitoring and Maintenance

### Check Backup Health

```bash
# Run regularly to verify backups
borg check ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

### Monitor Disk Usage

```bash
# Check repository size
borg info ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

### Log Rotation

Backup logs are stored in `/var/log/borg-backup.log`. Rotate as needed:

```bash
sudo logrotate /etc/logrotate.d/borg-backup
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connection
ssh usdaw@srvdocker02

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Repository Errors

```bash
# Repair repository if corrupted
borg repair ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

### Permission Issues

Ensure scripts run with sudo for system-level access:

```bash
sudo ./backup-borg.sh
```

### Out of Space

Monitor remote server space:

```bash
ssh usdaw@srvdocker02 df -h
```

## Security Considerations

- Repository passphrase is stored in `/root/.borg-passphrase`
- SSH keys are generated without passphrase for automation
- Consider additional encryption for sensitive data
- Regularly rotate backup credentials

## Performance Optimization

- Backups run during low-usage hours (2 AM)
- Incremental backups reduce transfer time
- Compression reduces storage requirements
- Exclude unnecessary directories (tmp, cache, logs)

## Alternative Approaches Considered

While running backups from within the VM provides simplicity and portability, Hyper-V tools could offer:
- Integration with Windows backup infrastructure
- Potential performance benefits for large VMs
- Centralized management

However, the VM-based approach provides:
- OS-agnostic backup logic
- Easier migration between hypervisors
- Full control over backup contents
- Better granularity for restores

## Support and Maintenance

- Monitor backup logs: `/var/log/borg-backup.log`
- Test restores quarterly
- Update backup scripts as system changes
- Keep documentation current

For issues or modifications, refer to the BorgBackup documentation: https://borgbackup.readthedocs.io/