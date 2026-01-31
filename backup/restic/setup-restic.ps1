# Simple PowerShell Setup for Restic Backup
# Usage: .\setup-restic-backup.ps1 -VM_IP "192.168.1.100"

param(
    [string]$VM_IP = ""
)

# Configuration
$VM_User = "root"
$Remote_Server = "srvdocker02"
$Remote_User = "usdaw"

Write-Host "=== Restic Backup Setup ===" -ForegroundColor Green

if (-not $VM_IP) {
    Write-Host "Usage: .\setup-restic-backup.ps1 -VM_IP 'YOUR_VM_IP'" -ForegroundColor Yellow
    Write-Host "Example: .\setup-restic-backup.ps1 -VM_IP '192.168.1.100'" -ForegroundColor Yellow
    exit
}

Write-Host "Setting up Restic backup for VM: $VM_IP" -ForegroundColor Yellow

# 1. Generate SSH key
if (!(Test-Path "$env:USERPROFILE\.ssh\id_rsa")) {
    ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa" -N ""
}

# 2. Copy key to VM and set up SSH
$keyContent = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub" -Raw
ssh $VM_User@$VM_IP "mkdir -p ~/.ssh && echo '$keyContent' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# 3. Install Restic
ssh $VM_User@$VM_IP "apt update && apt install -y restic"

# 4. Create password file
ssh $VM_User@$VM_IP "mkdir -p /etc/restic && echo 'YourSecurePassword123!' > /etc/restic/password && chmod 600 /etc/restic/password"

# 5. Copy scripts
scp "C:\Users\Test\Desktop\vmcreation\restic-backup-optimized.sh" "$VM_User@$VM_IP:/root/"
scp "C:\Users\Test\Desktop\vmcreation\restic-restore-optimized.sh" "$VM_User@$VM_IP:/root/"
ssh $VM_User@$VM_IP "chmod +x /root/*.sh"

# 6. Initialize repository
$repoInit = "export RESTIC_PASSWORD_FILE='/etc/restic/password' && restic init --repo ssh://$Remote_User@$Remote_Server/~/ubuntu58-backup --password-file /etc/restic/password --crypt-key aes-256-gcm --compression none"
ssh $VM_User@$VM_IP $repoInit

# 7. Update script paths
ssh $VM_User@$VM_IP "sed -i 's|REPO=.*|REPO=\""ssh://$Remote_User@$Remote_Server/~/ubuntu58-backup\""|g' /root/restic-backup-optimized.sh"

# 8. Test backup
ssh $VM_User@$VM_IP "export RESTIC_PASSWORD_FILE='/etc/restic/password' && cd /root && ./restic-backup-optimized.sh"

Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "VM: $VM_IP" -ForegroundColor Yellow
Write-Host "Backup Repository: $Remote_Server" -ForegroundColor Yellow
Write-Host "Logs: /var/log/restic-backup.log" -ForegroundColor Yellow