# BorgBackup Strategy for Ubuntu VM

This guide provides a comprehensive backup solution for your Ubuntu VM using BorgBackup.

## Overview

- **Tool**: BorgBackup (deduplicating backup program)
- **Storage**: Remote SSH server (srvdocker02)
- **Features**: Full system images, incremental backups, compression, encryption, versioning, granular restores

## Prerequisites

- Ubuntu VM with SSH access
- Remote SSH server accessible at usdaw@srvdocker02 with password 3C5x9cfg
- BorgBackup installed on VM

## Setup

1. Run `setup-borg.sh` to install BorgBackup and configure SSH
2. Set up passphrase: `echo "your_passphrase" > /root/.borg-passphrase && chmod 600 /root/.borg-passphrase`
3. Initialize repository: `borg init --encryption=repokey ssh://usdaw@srvdocker02/~/ubuntu58-backups`

## Usage

- **Backup**: Run `backup-borg.sh` (automated via cron)
- **Restore**: Run `restore-borg.sh` for full system restore
- **Granular Restore**: Use `borg mount` or `borg extract` with specific paths

## Scheduling

Run `cron-setup.sh` to set up daily backups at 2 AM.

## Testing Restore

1. Create a test VM
2. Install BorgBackup
3. Set passphrase
4. Run restore script pointing to test repo

### Detailed Testing Steps

1. **Create a Test Environment**:
   - Create a new Ubuntu VM in Hyper-V
   - Install BorgBackup: `sudo apt update && sudo apt install borgbackup`
   - Copy the restore script to the test VM

2. **Prepare Test Repository**:
   - On the test VM, set the passphrase: `echo "your_passphrase" > /root/.borg-passphrase && chmod 600 /root/.borg-passphrase`
   - Initialize a test repository: `borg init --encryption=repokey /tmp/test-repo`

3. **Run a Test Backup**:
   - Modify backup-borg.sh to use the test repo: Change REPO to `/tmp/test-repo`
   - Run the backup script: `./backup-borg.sh`

4. **Simulate System Failure**:
   - Delete some files or directories from the test VM
   - Or create a new VM for restore testing

5. **Test Restore**:
   - Modify restore-borg.sh to use the test repo
   - Run the restore script: `./restore-borg.sh`
   - Verify that files are restored correctly

6. **Test Granular Restore**:
   - Use `borg list /tmp/test-repo` to see archives
   - Use `borg extract /tmp/test-repo::archive-name /path/to/file` to restore specific files

## Security Notes

- Store passphrase securely
- Use SSH key authentication
- Encrypt backups with strong passphrase

## Advantages over Hyper-V tools

- Portability: Works on any Linux system
- Granular restores: File-level recovery
- Compression and deduplication: Efficient storage
- Encryption: Secure offsite storage