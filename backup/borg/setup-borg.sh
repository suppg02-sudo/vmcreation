#!/bin/bash
# setup-borg.sh - Install BorgBackup and set up SSH for remote backups

set -e

echo "Installing BorgBackup..."
sudo apt update
sudo apt install -y borgbackup openssh-client

echo "Generating SSH key for backup server..."
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

echo "Copying SSH key to backup server..."
ssh-copy-id -i ~/.ssh/id_rsa.pub usdaw@srvdocker02

echo "Testing SSH connection..."
ssh usdaw@srvdocker02 "echo 'SSH connection successful'"

echo "Initializing Borg repository..."
borg init --encryption=repokey ssh://usdaw@srvdocker02/~/ubuntu58-backups

echo "Setup complete. Please remember your repository passphrase."