# Ubuntu VM Creator

Automated Ubuntu 24.04 VM creation for Hyper-V with cloud-init SSH configuration.

## Requirements

- Windows 10/11 Pro/Enterprise with Hyper-V enabled
- QEMU tools installed (for image conversion)
- Administrator privileges
- Git (for cloning this repository)

## Quick Start

1. Clone this repository:
   `ash
   git clone <repository-url>
   cd ubuntu-vm-creator
   `

2. Double-click un_vmcreator.bat to create a new VM

   The batch file will:
   - Automatically request administrator privileges
   - Download the Ubuntu cloud image (if not cached or older than 30 days)
   - Create a new VM with automatic numbering (ubuntu1, ubuntu2, etc.)
   - Configure SSH access with cloud-init
   - Pre-install Docker
   - Detect and display the VM's IP address

## Manual Execution

If you prefer to run manually:

`powershell
powershell -ExecutionPolicy Bypass -File .\vm-creation\create_ubuntu_vm_clean.ps1
`

You can also specify a custom root password:

`powershell
powershell -ExecutionPolicy Bypass -File .\vm-creation\create_ubuntu_vm_clean.ps1 -RootPassword "YourPassword"
`

## Features

- Automatic VM numbering
- Cloud-init powered SSH setup
- Docker pre-configured
- Auto IP detection
- 1TB data disk attached
- Enhanced session mode enabled

## Default Credentials

- **Username:** root
- **Password:** UbuntuVM2024! (or custom password specified)

## VM Configuration

- **OS:** Ubuntu 24.04 LTS
- **Memory:** 4GB
- **CPU:** 2 cores
- **OS Disk:** 50GB
- **Data Disk:** 1TB
- **Network:** Hyper-V virtual switch

## After VM Creation

1. SSH to your VM:
   `ash
   ssh root@<VM_IP>
   `

2. Docker is pre-installed and ready to use

3. Choose your Docker build (Personal/Business/Custom)

4. Access your web services via the displayed URLs

## Troubleshooting

### Hyper-V Not Enabled
Open PowerShell as Administrator and run:
`powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
`

### QEMU Tools Not Found
Install QEMU for Windows from: https://qemu.weilnetz.de/w64/

### Cannot Connect to VM
- Check the VM is running in Hyper-V Manager
- Verify the VM has obtained an IP address
- Check firewall settings

## License

See LICENSE file for details.
