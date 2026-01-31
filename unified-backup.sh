#!/bin/bash
# unified-backup.sh - Unified backup script supporting both BorgBackup and Restic
# This script can use either BorgBackup or Restic based on configuration

set -e

# Configuration
BACKUP_TYPE="${BACKUP_TYPE:-borg}"  # Default to borg, can be set to 'restic'
REMOTE_USER="usdaw"
REMOTE_HOST="srvdocker02"
REMOTE_PATH="/home/usdaw/backups"
LOG_FILE="/var/log/unified-backup.log"

# BorgBackup Configuration
BORG_REPO="ssh://${REMOTE_USER}@${REMOTE_HOST}/ubuntu58-borg-backups"
BORG_PASSPHRASE_FILE="/root/.borg-passphrase"

# Restic Configuration
RESTIC_REPO="sftp:${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/ubuntu58-restic-backup"
RESTIC_PASSWORD_FILE="/root/.restic-password"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

# Check dependencies
check_dependencies() {
    if [[ "$BACKUP_TYPE" == "borg" ]]; then
        if ! command -v borg &> /dev/null; then
            error_exit "BorgBackup is not installed. Run: sudo apt install borgbackup"
        fi
    elif [[ "$BACKUP_TYPE" == "restic" ]]; then
        if ! command -v restic &> /dev/null; then
            error_exit "Restic is not installed. Run: sudo apt install restic"
        fi
    else
        error_exit "Invalid BACKUP_TYPE. Use 'borg' or 'restic'"
    fi
}

# Initialize repository
init_repository() {
    if [[ "$BACKUP_TYPE" == "borg" ]]; then
        if ! borg list "$BORG_REPO" &>/dev/null; then
            log "Initializing BorgBackup repository..."
            if [[ ! -f "$BORG_PASSPHRASE_FILE" ]]; then
                error_exit "BorgBackup passphrase file not found: $BORG_PASSPHRASE_FILE"
            fi
            export BORG_PASSPHRASE="$(cat "$BORG_PASSPHRASE_FILE")"
            borg init --encryption=repokey "$BORG_REPO"
            log "BorgBackup repository initialized"
        fi
    elif [[ "$BACKUP_TYPE" == "restic" ]]; then
        if ! restic list "$RESTIC_REPO" &>/dev/null; then
            log "Initializing Restic repository..."
            if [[ ! -f "$RESTIC_PASSWORD_FILE" ]]; then
                error_exit "Restic password file not found: $RESTIC_PASSWORD_FILE"
            fi
            export RESTIC_PASSWORD="$(cat "$RESTIC_PASSWORD_FILE")"
            restic init --repo "$RESTIC_REPO"
            log "Restic repository initialized"
        fi
    fi
}

# Perform backup
do_backup() {
    local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    
    if [[ "$BACKUP_TYPE" == "borg" ]]; then
        log "Starting BorgBackup: $timestamp"
        
        borg create \
            --verbose \
            --filter AME \
            --list \
            --stats \
            --show-rc \
            --compression lz4 \
            --exclude-caches \
            --exclude '/tmp' \
            --exclude '/var/tmp' \
            --exclude '/var/cache' \
            --exclude '/home/*/.cache' \
            "$BORG_REPO::backup-$timestamp" \
            /
        
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            log "${GREEN}BorgBackup successful: $timestamp${NC}"
        else
            error_exit "BorgBackup failed with exit code: $exit_code"
        fi
        
    elif [[ "$BACKUP_TYPE" == "restic" ]]; then
        log "Starting Restic backup: $timestamp"
        
        restic backup \
            --repo "$RESTIC_REPO" \
            --tag "backup-$timestamp" \
            --compression auto \
            --exclude='/tmp' \
            --exclude='/var/tmp' \
            --exclude='/var/cache' \
            --exclude='/home/*/.cache' \
            --exclude='/var/log/journal' \
            --exclude='/snap' \
            /
        
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            log "${GREEN}Restic backup successful: $timestamp${NC}"
        else
            error_exit "Restic backup failed with exit code: $exit_code"
        fi
    fi
}

# Prune old backups
do_prune() {
    if [[ "$BACKUP_TYPE" == "borg" ]]; then
        log "Pruning old BorgBackup archives..."
        
        borg prune \
            --list \
            --show-rc \
            --keep-daily=7 \
            --keep-weekly=4 \
            --keep-monthly=6 \
            "$BORG_REPO"
        
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            log "${GREEN}BorgBackup pruning successful${NC}"
        else
            error_exit "BorgBackup pruning failed with exit code: $exit_code"
        fi
        
    elif [[ "$BACKUP_TYPE" == "restic" ]]; then
        log "Pruning old Restic backups..."
        
        restic forget \
            --repo "$RESTIC_REPO" \
            --keep-daily=7 \
            --keep-weekly=4 \
            --keep-monthly=6 \
            --prune
        
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            log "${GREEN}Restic pruning successful${NC}"
        else
            error_exit "Restic pruning failed with exit code: $exit_code"
        fi
    fi
}

# Show repository info
show_info() {
    if [[ "$BACKUP_TYPE" == "borg" ]]; then
        log "BorgBackup repository info:"
        borg info "$BORG_REPO"
    elif [[ "$BACKUP_TYPE" == "restic" ]]; then
        log "Restic repository info:"
        restic snapshots --repo "$RESTIC_REPO"
    fi
}

# Main function
main() {
    log "Unified Backup Script - Using: $BACKUP_TYPE"
    log "Repository: $([[ "$BACKUP_TYPE" == "borg" ]] && echo "$BORG_REPO" || echo "$RESTIC_REPO")"
    
    check_dependencies
    
    case "${1:-backup}" in
        backup)
            init_repository
            do_backup
            do_prune
            ;;
        init)
            init_repository
            ;;
        prune)
            do_prune
            ;;
        info)
            show_info
            ;;
        *)
            echo "Usage: $0 {backup|init|prune|info}"
            echo ""
            echo "Commands:"
            echo "  backup  - Perform full backup"
            echo "  init    - Initialize repository"
            echo "  prune   - Prune old backups"
            echo "  info    - Show repository information"
            echo ""
            echo "Environment Variables:"
            echo "  BACKUP_TYPE - Backup type to use (borg or restic)"
            echo "                Default: borg"
            echo ""
            echo "Examples:"
            echo "  # Use BorgBackup (default)"
            echo "  $0 backup"
            echo ""
            echo "  # Use Restic"
            echo "  $0 backup BACKUP_TYPE=restic"
            exit 1
            ;;
    esac
    
    log "Backup process completed"
}

# Run main function
main "$@"