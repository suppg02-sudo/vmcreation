#!/bin/bash
# backup-borg.sh - Perform automated BorgBackup of Ubuntu system

set -e

REPO="ssh://usdaw@srvdocker02/~/ubuntu58-backups"

# Note: Set BORG_PASSPHRASE securely, e.g., in /root/.borg-passphrase
if [ -f /root/.borg-passphrase ]; then
    export BORG_PASSPHRASE=$(cat /root/.borg-passphrase)
else
    echo "BORG_PASSPHRASE not set. Please create /root/.borg-passphrase with your repository passphrase."
    exit 1
fi

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="/var/log/borg-backup.log"

echo "Starting backup at $TIMESTAMP" >> $LOG_FILE

borg create --verbose --filter AME --list --stats --show-rc \
    --compression lz4 \
    --exclude-caches \
    --exclude '/tmp' \
    --exclude '/var/tmp' \
    --exclude '/var/cache' \
    --exclude '/var/log' \
    --exclude '/home/*/.cache' \
    $REPO::backup-$TIMESTAMP / 2>> $LOG_FILE

borg prune --list --show-rc --keep-daily 7 --keep-weekly 4 --keep-monthly 12 $REPO 2>> $LOG_FILE

echo "Backup completed successfully at $(date)" >> $LOG_FILE