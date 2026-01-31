# GitHub Repository Setup Script for Ubuntu VM Creator
# This script initializes a Git repository and prepares it for GitHub

Write-Host "=== GitHub Repository Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitInstalled) {
    Write-Host "ERROR: Git is not installed. Please install Git from https://git-scm.com/download/win" -ForegroundColor Red
    Write-Host ""
    Write-Host "After installing Git, run this script again." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Git is installed: $($gitInstalled.Source)" -ForegroundColor Green
Write-Host ""

# Get repository name
$repoName = Read-Host "Enter repository name (default: ubuntu-vm-creator)"
if ([string]::IsNullOrWhiteSpace($repoName)) {
    $repoName = "ubuntu-vm-creator"
}

# Initialize git repository
Write-Host "Initializing Git repository..." -ForegroundColor Yellow
git init
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to initialize Git repository" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "Git repository initialized" -ForegroundColor Green
Write-Host ""

# Create .gitignore
Write-Host "Creating .gitignore file..." -ForegroundColor Yellow
$gitignoreContent = @"
# VM files
*.vhdx
*.vhd
*.img
C:\VMs\

# Logs
*.log
*_log.txt

# Temporary files
*.tmp
*.temp
*~

# OS specific
.DS_Store
Thumbs.db
desktop.ini

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Backup files
*.bak
*.bak2
backup-files/

# Archives
archive/
"@
$gitignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8
Write-Host ".gitignore created" -ForegroundColor Green
Write-Host ""

# Create README.md
Write-Host "Creating README.md..." -ForegroundColor Yellow
$readmeContent = @"
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
   ```bash
   ssh root@<VM_IP>
   ```

2. Docker is pre-installed and ready to use

3. Choose your Docker build (Personal/Business/Custom)

4. Access your web services via the displayed URLs

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
"@
$readmeContent | Out-File -FilePath "README.md" -Encoding UTF8
Write-Host "README.md created" -ForegroundColor Green
Write-Host ""

# Add all files to git
Write-Host "Adding files to Git..." -ForegroundColor Yellow
git add .
Write-Host "Files added" -ForegroundColor Green
Write-Host ""

# Create initial commit
Write-Host "Creating initial commit..." -ForegroundColor Yellow
$commitMessage = "Initial commit: Ubuntu VM Creator for Hyper-V"
git commit -m $commitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: No files were committed (might be empty or already committed)" -ForegroundColor Yellow
} else {
    Write-Host "Initial commit created" -ForegroundColor Green
}
Write-Host ""

# Instructions for GitHub
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Create a new repository on GitHub: https://github.com/new" -ForegroundColor White
Write-Host "   - Repository name: $repoName" -ForegroundColor White
Write-Host "   - Make it Public or Private as needed" -ForegroundColor White
Write-Host "   - Do NOT initialize with README, .gitignore, or license" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. After creating the repository, run these commands:" -ForegroundColor White
Write-Host ""
Write-Host "   git remote add origin https://github.com/<YOUR_USERNAME>/$repoName.git" -ForegroundColor Cyan
Write-Host "   git branch -M main" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. On another PC with Hyper-V:" -ForegroundColor White
Write-Host "   git clone https://github.com/<YOUR_USERNAME>/$repoName.git" -ForegroundColor Cyan
Write-Host "   cd $repoName" -ForegroundColor Cyan
Write-Host "   run_vmcreator.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
pause
