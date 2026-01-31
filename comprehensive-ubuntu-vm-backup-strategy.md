# Comprehensive Ubuntu VM Backup Strategy

## Overview
This document outlines a comprehensive backup strategy for your Ubuntu VM (ubuntu58) running in Hyper-V on a Windows host. The strategy focuses on running backups from within the Ubuntu VM for simplicity and portability, using BorgBackup as the primary tool.

## VM Identification
To avoid confusion:
- **Target VM for Backup**: The Ubuntu VM named "ubuntu58" (this is the VM being backed up).
- **Host System**: The Windows host running Hyper-V (not a VM itself).
- If you have other VMs like "ubunt58-1" or "ubhost", this strategy applies specifically to "ubuntu58". For other VMs, adapt the scripts accordingly by changing the VM name references.

## Recommended Approach: VM-Internal Backup with BorgBackup
While Hyper-V tools (e.g., Export-VM in PowerShell or Hyper-V Manager) can create VM-level images, the VM-internal approach with BorgBackup offers significant advantages for your requirements:

- **Full System Image**: Backs up the entire `/` filesystem, allowing restoration to a fresh Ubuntu VM
- **Granular Restores**: Extract individual files or directories from any backup version
- **Incremental/Deduplicating**: Only stores changes, reducing storage and time
- **Compression**: Built-in lz4 compression
- **Encryption**: AES-256 with passphrase
- **Versioning**: Retains multiple snapshots with configurable pruning
- **Offsite Storage**: Stores on your remote SSH server (srvdocker02)
- **Scheduling**: Automate with cron
- **Reliability**: Handles errors gracefully, resumable, minimal downtime
- **Portability**: Runs entirely within the VM, no host dependencies

Hyper-V exports are simpler for basic VM cloning but lack incremental backups, encryption, and remote storage without additional scripting.

## Step-by-Step Implementation

### 1. Install BorgBackup on the VM
```bash
sudo apt update
sudo apt install borgbackup
```

### 2. Set Up SSH Key for Remote Access
```bash
ssh-keygen -t rsa -b 4096 -C "ubuntu58-backup"
ssh-copy-id usdaw@srvdocker02  # Enter password: 3C5x9cfg
```

### 3. Initialize Repository
```bash
export BORG_PASSPHRASE="your_secure_passphrase_here"
borg init --encryption=repokey ssh://usdaw@srvdocker02/~/ubuntu58-backup
```

### 4. Backup Script (backup.sh)
```bash
#!/bin/bash
export BORG_PASSPHRASE="your_passphrase"
REPO="ssh://usdaw@srvdocker02/~/ubuntu58-backup"
ARCHIVE_NAME="ubuntu58-$(date +%Y-%m-%d_%H-%M-%S)"

borg create --progress --stats --compression lz4 $REPO::$ARCHIVE_NAME /

# Prune old backups (keep daily for 7 days, weekly for 4 weeks, monthly for 6 months)
borg prune --keep-daily=7 --keep-weekly=4 --keep-monthly=6 $REPO
```

### 5. Restore Script (restore.sh)
```bash
#!/bin/bash
export BORG_PASSPHRASE="your_passphrase"
REPO="ssh://usdaw@srvdocker02/~/ubuntu58-backup"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <archive_name> <restore_path> [file_to_restore]"
    exit 1
fi

ARCHIVE=$1
RESTORE_PATH=$2
FILE_TO_RESTORE=$3

if [ -z "$FILE_TO_RESTORE" ]; then
    borg extract $REPO::$ARCHIVE --strip-components 0 $RESTORE_PATH
else
    borg extract $REPO::$ARCHIVE $FILE_TO_RESTORE --strip-components 0 $RESTORE_PATH
fi
```

### 6. Schedule Backups
```bash
crontab -e
# Add: 0 2 * * * /path/to/backup.sh
```

### 7. Full System Restore to Fresh VM
- Create new Ubuntu VM
- Boot from live USB, mount repository, and extract to `/`:
```bash
export BORG_PASSPHRASE="your_passphrase"
borg mount ssh://usdaw@srvdocker02/~/ubuntu58-backup /mnt/backup
cp -a /mnt/backup/<latest_archive>/* /
```

### 8. Testing Restore
- Test granular restore on a small directory
- For full restore, set up a test VM and verify integrity with `borg check`

## Security and Reliability Notes
- Use a strong, unique passphrase for encryption
- Store passphrase securely (consider using a password manager)
- Monitor backup logs for errors
- Test restores regularly
- Ensure SSH access is secure (use key-based auth, disable password auth if possible)
- This solution minimizes downtime and handles errors gracefully through BorgBackup's resumable features