# Ubuntu VM Creator for Hyper-V

Automated Ubuntu 24.04 VM creation with fully automated SSH configuration.

## Prerequisites

1. **Windows 10/11 Pro/Enterprise** with Hyper-V enabled
2. **QEMU for Windows** - Required for image conversion (RAW to VHDX)
3. **Administrator privileges**

## Installation

### 1. Install QEMU

**Option A: Using the install script (run as Administrator)**
```powershell
cd vmcreation/vm-creation
.\install_qemu.ps1
```

**Option B: Manual installation**
1. Download QEMU from https://www.qemu.org/download/#windows
2. Run the installer
3. Ensure `C:\Program Files\qemu\qemu-img.exe` is in your PATH

### 2. Enable Hyper-V

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

## Usage

1. Run as Administrator:
```cmd
run_vm_creator.bat
```

2. The script will:
   - Create VM named `ubuntu1`, `ubuntu2`, etc.
   - Download Ubuntu 24.04 cloud image
   - Convert to VHDX using qemu-img
   - Configure cloud-init with SSH
   - Set up Docker pre-configuration

## Files

- `create_ubuntu_vm_clean.ps1` - Main VM creation script
- `install_qemu.ps1` - QEMU installation helper
- `run_vm_creator.bat` - Batch launcher
- `user-data-simple` - Cloud-init configuration
- `build-selector.sh`, `docker-setup.sh`, `post-ssh-setup.sh` - Build scripts

## Troubleshooting

**"The system cannot find the file specified" for qemu-img.exe**
- QEMU is not installed or not in the expected path
- Run `install_qemu.ps1` as Administrator

**"Failed to add device 'Virtual Hard Disk'"**
- The VHDX file was not created successfully
- Check that qemu-img conversion completed without errors
- Verify `C:\VMs\<vmname>\os.vhdx` exists
