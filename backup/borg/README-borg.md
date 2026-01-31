# BorgBackup Solution

File-level backup solution running inside the Ubuntu VM with zero Windows host dependency.

## Overview

This solution provides **file-level backup** from within the Ubuntu VM using BorgBackup:
- No VM downtime (runs while VM is active)
- File and directory level restore
- Deduplication and compression
- Remote storage via SSH
- Portable across any hypervisor

## Prerequisites

- Ubuntu VM with SSH access
- Remote SSH server (see `../../config.json`)
- BorgBackup installed in VM
- Sufficient storage on backup server

## Configuration

Configuration is managed through `../../config.json`:

```json
{
  "backup": {
    "server": "srvdocker02",
    "user": "usdaw",
    "passwordEnvVar": "BACKUP_SERVER_PASSWORD",
    "backupRoot": "/media/backup",
    "sshKeyPath": "~/.ssh/id_rsa"
  },
  "borg": {
    "repoPath": "ssh://usdaw@srvdocker02/~/ubuntu58-backups",
    "passphraseFile": "/root/.borg-passphrase",
    "retention": {
      "daily": 7,
      "weekly": 4,
      "monthly": 12
    }
  }
}
```

## Scripts

All scripts run **inside the Ubuntu VM**:

### setup-borg.sh

Initial BorgBackup installation and SSH key setup

```bash
sudo ./setup-borg.sh
```

### backup-borg.sh

Automated full system backup

```bash
sudo ./backup-borg.sh
```

### restore-borg.sh

Full system restore

```bash
sudo ./restore-borg.sh
```

### cron-setup.sh

Configure automated daily backups

```bash
sudo ./cron-setup.sh
```

## Setup Instructions

### 1. Transfer Scripts to VM

From Windows host:

```powershell
scp *.sh root@<VM_IP>:/root/
```

### 2. Install and Configure

SSH into VM and run:

```bash
# Make scripts executable
chmod +x *.sh

# Run setup
sudo ./setup-borg.sh
```

This will:
- Install BorgBackup
- Generate SSH keys
- Configure SSH client
- Test backup server connection

### 3. Initialize Repository

```bash
# Create passphrase file
echo "your_secure_passphrase" > /root/.borg-passphrase
chmod 600 /root/.borg-passphrase

# Initialize repository
borg init --encryption=repokey ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

### 4. Run First Backup

```bash
sudo ./backup-borg.sh
```

### 5. Schedule Automated Backups

```bash
sudo ./cron-setup.sh
```

Sets up daily backups at 2 AM.

## Usage

### Manual Backup

```bash
sudo ./backup-borg.sh
```

### List Backups

```bash
borg list ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

### View Backup Contents

```bash
borg list ssh://usdaw@srvdocker02/~/ubuntu58-backups::backup-name
```

### Restore Specific Files

```bash
# Extract to current directory
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest /path/to/file

# Extract to specific location
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest /etc/nginx/
```

### Full System Restore

```bash
sudo ./restore-borg.sh
```

## Backup Strategy

**What's Backed Up:**
- `/` (root filesystem)
- `/home` (user data)
- `/etc` (configurations)
- `/var` (application data, excluding logs/cache)
- Mounted filesystems

**What's Excluded:**
- `/tmp`, `/var/tmp`
- `/var/cache`, `/var/log`
- `/proc`, `/sys`, `/dev`
- Swap files

**Retention Policy:**
- Keep 7 daily backups
- Keep 4 weekly backups
- Keep 12 monthly backups

## Advantages

✅ **Zero Downtime**: Runs while VM is active  
✅ **Granular Restore**: File and directory level  
✅ **Portable**: Works on any Linux system  
✅ **Efficient**: Deduplication and compression  
✅ **Flexible**: Easy to customize what's backed up  

## Comparison with Restic (Image-level)

| Feature | BorgBackup (This) | Restic (Image-level) |
|---------|-------------------|----------------------|
| **VM Downtime** | None | 5-15 minutes |
| **Restore Granularity** | File-level | Full VHD only |
| **Backup Speed** | Fast (incremental) | Slower (entire VHD) |
| **Storage Efficiency** | Excellent | Good |
| **Hypervisor Lock-in** | None | Hyper-V specific |
| **Bare-metal Recovery** | More steps | Simpler |

**Use Both**: BorgBackup for daily file-level backups, Restic for weekly full-image backups!

## Restore Scenarios

### Scenario 1: Recover Deleted File

```bash
# Find the file in a backup
borg list ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest | grep myfile.txt

# Restore it
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest path/to/myfile.txt
```

### Scenario 2: Restore Configuration Files

```bash
# Restore all nginx configs
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest /etc/nginx/
```

### Scenario 3: Full System Recovery

```bash
# Boot into recovery/new VM
# Install BorgBackup
sudo apt install borgbackup

# Copy passphrase
echo "your_passphrase" > /root/.borg-passphrase
chmod 600 /root/.borg-passphrase

# Restore everything
cd /
borg extract ssh://usdaw@srvdocker02/~/ubuntu58-backups::latest
```

## Monitoring

### Check Backup Status

```bash
# Repository info
borg info ssh://usdaw@srvdocker02/~/ubuntu58-backups

# Verify repository health
borg check ssh://usdaw@srvdocker02/~/ubuntu58-backups

# View logs
tail -f /var/log/borg-backup.log
```

### Verify Cron Job

```bash
# List cron jobs
crontab -l

# Check cron logs
grep CRON /var/log/syslog
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH
ssh usdaw@srvdocker02

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Repository Locked

```bash
# Break lock (if backup crashed)
borg break-lock ssh://usdaw@srvdocker02/~/ubuntu58-backups
```

### Passphrase Issues

```bash
# Verify passphrase file
cat /root/.borg-passphrase
ls -la /root/.borg-passphrase  # Should be -rw-------
```

## Security

- Repository encrypted with passphrase
- SSH key authentication to backup server
- Passphrase stored in `/root/.borg-passphrase` (mode 600)
- Consider using `keyfile` encryption for additional security

## Version History

- **v1.0**: Initial BorgBackup integration

---

**Documentation**: Full guide at [../../borg-backup-guide.md](../../borg-backup-guide.md)  
**Alternative**: For image-level backups, see [../restic/README-restic.md](../restic/README-restic.md)
