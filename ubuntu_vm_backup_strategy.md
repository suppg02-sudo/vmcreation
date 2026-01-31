# Comprehensive Backup Strategy for Ubuntu VM (ubuntu58) in Hyper-V

## Overview
This guide provides a complete backup solution for your Ubuntu VM using BorgBackup. The approach runs from within the VM for simplicity and portability, offering full system images, incremental backups, compression, encryption, scheduling, and offsite storage.

## Why BorgBackup?
- **Full System Image**: Backs up the entire filesystem for complete restoration.
- **Incremental/Deduplicating**: Efficient storage with delta backups.
- **Compression**: Built-in lz4 compression.
- **Encryption**: AES-256 encryption with passphrase.
- **Versioning**: Keeps multiple versions with pruning.
- **Granular Restores**: Extract individual files or directories.
- **Offsite Storage**: Stores on remote SSH server.
- **Reliability**: Handles errors gracefully, resumable backups.
- **Minimal Downtime**: Runs while VM is active.

Compared to Hyper-V export: This provides incremental, encrypted, remote storage with granular restores.

## Prerequisites
- Ubuntu VM with SSH access.
- Remote SSH server (srvdocker02) with sufficient storage.
- BorgBackup installed on VM.

## Installation and Setup

### 1. Install BorgBackup on Ubuntu VM
```bash
sudo apt update
sudo apt install borgbackup
```

### 2. Set Up SSH Key for Remote Access
Generate SSH key pair:
```bash
ssh-keygen -t rsa -b 4096 -C "ubuntu58-backup"
```
Copy public key to remote server:
```bash
ssh-copy-id usdaw@srvdocker02
```
(Enter password when prompted: 3C5x9cfg)

### 3. Initialize Borg Repository
On the VM:
```bash
export BORG_PASSPHRASE="your_secure_passphrase_here"  # Choose a strong passphrase
borg init --encryption=repokey ssh://usdaw@srvdocker02/~/ubuntu58-backup
```

## Backup Script
Transfer `backup.sh` to the VM and make executable:
```bash
chmod +x backup.sh
```
Edit the script to set your passphrase.

## Restore Script
Transfer `restore.sh` to the VM and make executable:
```bash
chmod +x restore.sh
```
Edit to set passphrase.

## Scheduling Backups
Use cron for automation:
```bash
crontab -e
```
Add line for daily backup at 2 AM:
```
0 2 * * * /path/to/backup.sh
```

## Full System Restore
To restore to a fresh Ubuntu VM:
1. Create a new Ubuntu VM with same specs.
2. Boot from Ubuntu live USB.
3. Mount the repository and extract:
   ```bash
   export BORG_PASSPHRASE="your_passphrase"
   borg mount ssh://usdaw@srvdocker02/~/ubuntu58-backup /mnt/backup
   # Then copy files to new VM's /
   ```
   Or use the restore script on the new VM after setting up SSH.

## Granular Restore
Use the restore script:
```bash
./restore.sh <archive_name> /restore/path /file/to/restore
```

## Testing the Restore Process
1. Create a test backup of a small directory.
2. Restore to a different location.
3. Verify files integrity.
4. For full restore: Set up a test VM and perform complete restoration.

## Error Handling and Reliability
- Borg logs errors and can resume interrupted backups.
- Run `borg check` periodically to verify integrity.
- Monitor logs in `/var/log/borg-backup.log`.
- Schedule during low-usage times to minimize impact.

## Offsite Storage Configuration
- Repository is on srvdocker02 via SSH.
- Ensure server has adequate storage and backup its own data.
- Optionally install BorgBackup on srvdocker02 for better performance.

## Maintenance
- Regularly update BorgBackup.
- Monitor repository size.
- Test restores quarterly.
- Rotate passphrases if needed (borg key export/import).

This strategy ensures reliable, efficient backups with all requested features.