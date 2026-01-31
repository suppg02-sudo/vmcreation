#!/bin/bash

# Restore script for BorgBackup
# This script can be used for granular restores or full system restores

# Configuration
REPO="ssh://usdaw@srvdocker02/~/ubuntu58-backup"
PASSPHRASE="your_secure_passphrase_here"  # Same as backup
LOGFILE="/var/log/borg-restore.log"

# Set passphrase
export BORG_PASSPHRASE="$PASSPHRASE"

# Function to log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Usage
if [ $# -lt 2 ]; then
    echo "Usage: $0 <archive_name> <restore_path> [file_path]"
    echo "For full restore: $0 <archive_name> /"
    echo "For granular: $0 <archive_name> /path/to/restore file/to/restore"
    exit 1
fi

ARCHIVE_NAME=$1
RESTORE_PATH=$2
FILE_PATH=$3

log "Starting restore from archive: $ARCHIVE_NAME to $RESTORE_PATH"

if [ -n "$FILE_PATH" ]; then
    # Granular restore
    borg extract --list --verbose "$REPO::$ARCHIVE_NAME" "$FILE_PATH" --strip-components 0 -C "$RESTORE_PATH"
else
    # Full restore (use with caution)
    borg extract --list --verbose "$REPO::$ARCHIVE_NAME" -C "$RESTORE_PATH"
fi

if [ $? -eq 0 ]; then
    log "Restore successful"
else
    log "Restore failed"
    exit 1
fi