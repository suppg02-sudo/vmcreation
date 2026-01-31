#!/bin/bash
# cron-setup.sh - Set up cron jobs for automated backups

SCRIPT_DIR=$(dirname "$(realpath "$0")")

CRON_JOB="0 2 * * * $SCRIPT_DIR/backup-borg.sh"

(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Cron job added for daily backups at 2 AM"

# Also add weekly full backup on Sunday
CRON_JOB_WEEKLY="0 2 * * 0 $SCRIPT_DIR/backup-borg.sh"

(crontab -l 2>/dev/null; echo "$CRON_JOB_WEEKLY") | crontab -

echo "Weekly backup on Sunday added"