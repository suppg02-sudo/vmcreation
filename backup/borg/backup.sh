#!/bin/bash

# Backup script for Ubuntu VM using BorgBackup
# This script creates a full system backup to a remote SSH repository

# Configuration
REPO="ssh://usdaw@srvdocker02/~/ubuntu58-backup"
PASSPHRASE="your_secure_passphrase_here"  # Change this to a strong passphrase
LOGFILE="/var/log/borg-backup.log"
HOSTNAME=$(hostname)

# Set passphrase for Borg
export BORG_PASSPHRASE="$PASSPHRASE"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Create backup archive name with timestamp
ARCHIVE_NAME="${HOSTNAME}-$(date +%Y-%m-%d_%H-%M-%S)"

log "Starting backup: $ARCHIVE_NAME"

# Create the backup
borg create \
    --verbose \
    --filter AME \
    --list \
    --stats \
    --show-rc \
    --compression lz4 \
    --exclude '/proc' \
    --exclude '/sys' \
    --exclude '/dev' \
    --exclude '/tmp' \
    --exclude '/mnt' \
    --exclude '/media' \
    --exclude '/lost+found' \
    --exclude '/var/cache' \
    --exclude '/var/tmp' \
    --exclude '/var/log/journal' \
    --exclude '/home/*/.cache' \
    "$REPO::$ARCHIVE_NAME" \
    /

if [ $? -eq 0 ]; then
    log "Backup successful: $ARCHIVE_NAME"
else
    log "Backup failed: $ARCHIVE_NAME"
    exit 1
fi

# Prune old archives to maintain versioning
log "Pruning old archives"
borg prune \
    --list \
    --show-rc \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    "$REPO"

if [ $? -eq 0 ]; then
    log "Pruning successful"
else
    log "Pruning failed"
fi

log "Backup process completed"