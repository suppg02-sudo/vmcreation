# Changelog

All notable changes to the VMCreation project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2025-12-27

### Added
- **Interactive Management Menu**: Created `vmmanager.ps1` and `vmmanager.bat` ⭐ NEW
  - Unified menu for VM creation, backup, restore, and diagnostics
  - Submenu for 3 backup options (Restic, Borg-Windows, Borg-VM)
  - Submenu for restore operations
  - VM lifecycle management (create, list, start/stop, delete)
- **Unified Configuration**: Created `config.json` for centralized settings management
- **Directory Structure**: Organized project into logical subdirectories
  - `vm-creation/` - VM automation scripts
  - `backup/restic/` - Restic backup solution
  - `backup/borg-windows/` - BorgBackup for Windows host ⭐ NEW
  - `backup/borg/` - BorgBackup in-VM solution
  - `diagnostics/` - Diagnostic and troubleshooting tools
  - `docker/` - Docker configurations
  - `archive/` - Deprecated script versions
- **Version Tracking**: This CHANGELOG to track script versions
- **Archive System**: Date-stamped archival of deprecated scripts
- **Triple Backup Options**: Users can now choose between Restic, Borg-Windows, or Borg-in-VM

### Changed
- **Major Reorganization**: Restructured entire project for better maintainability
- **Security Improvement**: Removed hardcoded credentials from active scripts
- **Script Naming**: Renamed scripts for clarity (e.g., `backup-final-fixed.ps1` → `backup-final.ps1`)

### Fixed
- **vmmanager.ps1**: Fixed file encoding/corruption issues causing PowerShell parsing errors
  - Recreated file with clean UTF-8 encoding using write_to_file tool
  - Script now parses correctly and executes without syntax errors
  - Requires Administrator privileges (expected for Hyper-V operations)
  - Verified syntax is correct and script loads properly
  - All functions and control structures properly closed

### Removed
- Archived 35+ deprecated script versions to `archive/2025-12-27/`
- Removed hardcoded passwords from current working scripts

### Security
- Credentials now referenced via environment variables in `config.json`
- SSH key authentication documented and recommended
- Archived scripts with hardcoded credentials isolated

---

## Current Script Versions

### VM Creation
- **create_ubuntu_vm_clean.ps1** - v1.0 (2025-12-27)
  - Automated Ubuntu 24.04 VM creation with cloud-init
  - SSH auto-configuration
  - Multi-tier IP detection

### Backup - Restic
- **backup-final.ps1** - v1.0 (2025-12-27)
  - Image-level VHD backup to remote SSH server
  - Incremental backup with deduplication
  - Automatic VM stop/start

### Backup - Borg Windows
- **backup-borg-windows.ps1** - v1.0 (2025-12-27)
  - Image-level VHD backup using BorgBackup from Windows host
  - Alternative to Restic with better deduplication
  - Faster incremental backups
  - Automatic VM stop/start

### Backup - Borg (In-VM)
- **backup-borg.sh** - v1.0
  - Full system backup from within VM
  - Deduplication and compression
  - Retention policy management

### Diagnostics
- **check_vm_logs.ps1** - v1.0
  - VM status monitoring
  - Cloud-init verification
  - SSH service checks

- **diagnose_vm_ip.ps1** - v1.0
  - IP detection diagnostics
  - Network connectivity testing

---

## Archived Scripts (2025-12-27)

The following scripts were archived as deprecated versions:

**Backup Scripts**: backup-debug-final.ps1, backup-with-known-ip.ps1, backup-working-final.ps1, backup-fixed-path.ps1, correct-backup-target.ps1, correct-vm-backup.ps1, comprehensive-backup-solution.ps1, fixed-backup-script.ps1, working-backup-script.ps1, fast-vm-backup.ps1, hyperv-vm-backup.ps1, simple-hyperv-backup.ps1, vm-safe-restic-backup.ps1, speed-optimized-backup.ps1, simple-rsync-backup.ps1

**Restic Scripts**: restic-vhd-backup.ps1, restic-vhd-backup-final.ps1, restic-vhd-backup-fixed.ps1, restic-vhd-backup-debug.ps1, windows-restic-vhd-backup.ps1, windows-restic-vhd-backup-fixed.ps1, restic-with-password.ps1, restic-working-backup.ps1, restic-final-working.ps1, ubuntu-vm-backup-restic.ps1

**Setup Scripts**: setup-backup-automation.ps1, setup-restic-backup.ps1, complete-restic-setup.ps1, manual-restic-install.ps1, manual-restic-install-fixed.ps1, debug-restic-install.ps1, download-restic.ps1

**Other**: monitor-backup-progress.ps1, simple-test.ps1, test_syntax.ps1, validate_syntax.ps1

All archived scripts remain available in `archive/2025-12-27/` for reference.
