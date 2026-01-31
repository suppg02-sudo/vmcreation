# VM Creation Runbook

## Overview
This runbook describes how to create Ubuntu VMs using the automated scripts, following the infrastructure standards outlined in AGENTS.md.

## Prerequisites

### System Requirements
- Windows 10/11 with Hyper-V enabled
- Administrator privileges
- QEMU tools installed (`C:\Program Files\qemu\qemu-img.exe`)
- At least 50GB free disk space
- Internet connection for downloading Ubuntu cloud images

### Network Requirements
- Virtual switch: "New Virtual Switch" (created manually in Hyper-V Manager)
- Network connectivity for VM internet access

## VM Creation Process

### Step 1: Pre-Flight Checks
```powershell
# Run as Administrator
Get-VMHost | Format-Table Name, VirtualSwitchPath, VirtualMachinePath
Get-VMSwitch -Name "New Virtual Switch"
Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
```

### Step 2: Execute VM Creation
```batch
# Method 1: Using batch file (recommended)
run_vm_creator.bat

# Method 2: Direct PowerShell execution
powershell -ExecutionPolicy Bypass -File "create_ubuntu_vm_simple.ps1"
```

### Step 3: Monitor Progress
- Script will run for 10-15 minutes
- Progress updates every 30 seconds
- Watch for IP detection and SSH verification
- Check log file: `create_ubuntu_vm_improved_log.txt`

### Step 4: Verify Success
- Script will display success message with SSH command
- VM should be accessible via SSH
- Password: `Passw0rd`

### Step 5: Troubleshooting (if needed)
- If IP detection fails, run: `powershell -ExecutionPolicy Bypass -File diagnose_vm_ip.ps1`
- If SSH fails, check cloud-init logs: `ssh root@<IP> 'cat /var/log/ssh-setup.log'`
- If root password issues, run: `powershell -ExecutionPolicy Bypass -File fix_root_password.ps1`

## Post-Creation Steps

### 1. Initial SSH Connection
```bash
ssh root@<VM_IP_ADDRESS>
# Password: Passw0rd
```

### 2. Verify Cloud-Init Completion
```bash
# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Verify services
sudo systemctl status ssh
sudo systemctl status cloud-init
```

### 3. Security Hardening
```bash
# Change root password immediately
sudo passwd root

# Create non-root user
sudo adduser deploy
sudo usermod -aG sudo deploy

# Disable root SSH (optional but recommended)
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

## Troubleshooting

### Common Issues

#### VM Won't Start
```powershell
# Check VM status
Get-VM -Name "ubuntu*"

# Check Hyper-V logs
Get-WinEvent -LogName Microsoft-Windows-Hyper-V-Compute-Operational
```

#### IP Not Detected
```bash
# Manual IP detection
arp -a | findstr <VM_MAC_ADDRESS>

# Check VM network adapter
Get-VMNetworkAdapter -VMName "ubuntu1"
```

#### SSH Connection Refused
- Wait 5-10 more minutes for cloud-init completion
- Check cloud-init logs inside VM
- Verify VM has internet connectivity

### Emergency Recovery
```powershell
# Connect to VM console
vmconnect localhost "ubuntu1"

# Force stop and restart VM
Stop-VM -Name "ubuntu1" -Force
Start-VM -Name "ubuntu1"
```

### Cleanup Failed VM
```powershell
# Remove VM and all files
Remove-VM -Name "ubuntu1" -Force
Remove-Item -Path "C:\VMs\ubuntu1" -Recurse -Force
```

## Rollback Procedures

### Complete Cleanup
```powershell
# Stop VM if running
Stop-VM -Name "ubuntu*" -Force -PassThru | Remove-VM -Force

# Remove VM files
Get-ChildItem -Path "C:\VMs" -Directory -Filter "ubuntu*" | Remove-Item -Recurse -Force

# Clear VM from Hyper-V registry (if needed)
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\VMSMP\Parameters\VMList" -Name "ubuntu*" -ErrorAction SilentlyContinue
```

## Maintenance

### Regular Tasks
- Monitor disk usage on host
- Update Ubuntu cloud images monthly
- Review VM logs for issues
- Backup VM configurations

### Performance Optimization
- Adjust VM memory based on workload
- Monitor network performance
- Consider switching to Generation 2 VMs for newer Ubuntu versions

## Security Considerations

### Default Credentials
- **Username**: `root`
- **Password**: `Passw0rd`
- **Change immediately after first login**

### Network Security
- VMs isolated on virtual switch
- No default firewall rules (Ubuntu default)
- Consider implementing network segmentation

### Data Protection
- VM disks stored on host filesystem
- No encryption by default
- Consider BitLocker for sensitive data

## Monitoring & Observability

### Log Locations
- VM Creation: `create_ubuntu_vm_improved_log.txt`
- Cloud-init: `/var/log/cloud-init-output.log`
- SSH Access: `/var/log/auth.log`

### Key Metrics
- VM creation time (target: <15 minutes)
- SSH availability time (target: <10 minutes after VM start)
- Network connectivity status
- Resource utilization

## Support & Escalation

### Self-Service
1. Check this runbook
2. Review log files
3. Try manual VM creation via Hyper-V Manager

### Escalation Path
1. Check operational notes: `docs/operational-notes.md`
2. Review architecture decisions: `docs/decisions.md`
3. Contact infrastructure team with logs

## Compliance Notes

This process follows AGENTS.md standards:
- ✅ Idempotent (safe to re-run)
- ✅ Observable (comprehensive logging)
- ✅ Reversible (rollback procedures)
- ✅ Documented (this runbook)
- ✅ Secure defaults (password change required)