# Ubuntu VM Creator

Automated Ubuntu 24.04 VM creation for Hyper-V with cloud-init SSH configuration.

## Requirements

- Windows 10/11 Pro/Enterprise with Hyper-V enabled
- QEMU tools installed (for image conversion)
- Administrator privileges
- Git (for cloning this repository)

## Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd ubuntu-vm-creator
   ```

2. Double-click `run_vmcreator.bat` to create a new VM

   The batch file will:
   - Automatically request administrator privileges
   - Download the Ubuntu cloud image (if not cached or older than 30 days)
   - Create a new VM with automatic numbering (ubuntu1, ubuntu2, etc.)
   - Configure SSH access with cloud-init
   - Pre-install Docker
   - Detect and display the VM's IP address

## Manual Execution

If you prefer to run manually:

```powershell
powershell -ExecutionPolicy Bypass -File .\vm-creation\create_ubuntu_vm_clean.ps1
```

You can also specify a custom root password:

```powershell
powershell -ExecutionPolicy Bypass -File .\vm-creation\create_ubuntu_vm_clean.ps1 -RootPassword "YourPassword"
```

## Features

- Automatic VM numbering
- Cloud-init powered SSH setup
- Docker pre-configured
- Auto IP detection
- 1TB data disk attached
- Enhanced session mode enabled

## Default Credentials

- **Username:** root
- **Password:** Passw0rd (change immediately after first login)

## VM Configuration

- **OS:** Ubuntu 24.04 LTS
- **Memory:** 4GB
- **CPU:** 2 cores
- **OS Disk:** 50GB
- **Data Disk:** 1TB
- **Network:** Hyper-V virtual switch

## After VM Creation

1. SSH to your VM:
   ```bash
   ssh root@<VM_IP>
   ```

2. Docker is pre-installed and ready to use

3. Access your web services via the displayed URLs

## Troubleshooting

### Hyper-V Not Enabled
Open PowerShell as Administrator and run:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### QEMU Tools Not Found
Install QEMU for Windows from: https://qemu.weilnetz.de/w64/

### Cannot Connect to VM
- Check the VM is running in Hyper-V Manager
- Verify the VM has obtained an IP address
- Check firewall settings

## License

See LICENSE file for details.

---

## AI Assistant Instructions

If you are an AI coding assistant (like Kilo Code, GitHub Copilot, etc.) and have been asked to set up and run this VM creation system, follow these steps:

### Prerequisites Check
1. Verify the system has Hyper-V enabled:
   ```powershell
   Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
   ```
   If not enabled, enable it:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```

2. Verify QEMU tools are installed at `C:\Program Files\qemu\qemu-img.exe`
   - If not found, inform the user to install from: https://qemu.weilnetz.de/w64/

3. Verify Git is installed:
   ```powershell
   Get-Command git
   ```

### Setup Steps
1. Navigate to the project directory (if not already there)
2. Verify the required files exist:
   - `run_vmcreator.bat` - Main launcher
   - `vm-creation/create_ubuntu_vm_clean.ps1` - VM creation script
   - `vm-creation/user-data-simple` - Cloud-init configuration

3. Check for existing VMs to determine the next VM number:
   ```powershell
   Get-VM | Where-Object { $_.Name -like "ubuntu*" }
   ```

4. Execute the VM creation:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\vm-creation\create_ubuntu_vm_clean.ps1
   ```
   Optionally specify a custom root password:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\vm-creation\create_ubuntu_vm_clean.ps1 -RootPassword "YourSecurePassword"
   ```
   Note: Always use a strong, unique password.

### Post-Creation Verification
1. Monitor the VM creation log at `vm-creation\create_ubuntu_vm_clean_log.txt`
2. Wait for the VM to boot and initialize (approximately 30 seconds)
3. The script will display:
   - VM name (e.g., ubuntu1, ubuntu2, etc.)
   - IP address (if detected)
   - SSH command
   - Default credentials

4. Verify VM is running:
   ```powershell
   Get-VM -Name "<VM_NAME>" | Select-Object Name, State, CPUUsage, MemoryAssigned
   ```

5. Test SSH connectivity (if IP was detected):
   ```powershell
   ssh root@<VM_IP>
   ```
   Default password: Passw0rd (change immediately after first login)

### Troubleshooting
- If Hyper-V is not enabled, run the enable command and restart the system
- If QEMU tools are missing, inform the user to install them
- If the script fails, check the log file for specific errors
- If IP detection fails, use Hyper-V Manager to find the VM's IP address

### Expected Output
The script will create a VM with:
- Automatic numbering (ubuntu1, ubuntu2, etc.)
- 4GB RAM, 2 CPU cores
- 50GB OS disk + 1TB data disk
- SSH access with cloud-init
- Docker pre-installed
- Enhanced session mode enabled

### Success Criteria
- VM is created and running
- IP address is detected (or user can find it via Hyper-V Manager)
- SSH connection is successful
- Docker is installed and functional
