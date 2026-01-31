#!/bin/bash
# restore-borg.sh - Restore from BorgBackup

set -e

REPO="ssh://usdaw@srvdocker02/~/ubuntu58-backups"

# Note: Set BORG_PASSPHRASE securely
if [ -f /root/.borg-passphrase ]; then
    export BORG_PASSPHRASE=$(cat /root/.borg-passphrase)
else
    echo "BORG_PASSPHRASE not set. Please create /root/.borg-passphrase with your repository passphrase."
    exit 1
fi

echo "Available backups:"
borg list $REPO

echo "Enter backup name to restore from (or 'latest' for most recent):"
read BACKUP_NAME

if [ "$BACKUP_NAME" = "latest" ]; then
    BACKUP_NAME=$(borg list $REPO | tail -1 | awk '{print $1}')
fi

echo "This will restore the entire system to /. Are you sure? (yes/no)"
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 1
fi

echo "Restoring from $BACKUP_NAME..."
borg extract $REPO::$BACKUP_NAME

echo "Restore completed. You may need to reboot."