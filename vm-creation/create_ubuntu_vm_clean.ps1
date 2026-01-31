# Ubuntu VM Creator for Hyper-V
# Version: 1.0
# Last Updated: 2025-12-27
# Description: Automated Ubuntu 24.04 VM creation with cloud-init SSH configuration
#
# Features:
#   - Automatic VM numbering (ubuntu1, ubuntu2, etc.)
#   - Cloud-init powered SSH setup
#   - Docker pre-configured
#   - Auto IP detection
#
# Requirements: Windows 10/11 Pro/Enterprise, Hyper-V, QEMU tools, Administrator privileges
# Configuration: Adjust paths and settings in this script or use ../config.json
#
# Usage: Run as Administrator via run_vm_creator.bat or:
#        powershell -ExecutionPolicy Bypass -File create_ubuntu_vm_clean.ps1 [-RootPassword "YourPassword"]

#Requires -RunAsAdministrator

param([string]$RootPassword = "UbuntuVM2024!")

$LogPath = "$PSScriptRoot\create_ubuntu_vm_clean_log.txt"
Start-Transcript -Path $LogPath -Append

# Determine next VM name
$existingVMs = Get-VM | Where-Object { $_.Name -like "ubuntu*" }
$numbers = @()
foreach ($vm in $existingVMs) {
    if ($vm.Name -match '^ubuntu(\d+)$') {
        $numbers += [int]$matches[1]
    }
}
$nextNum = if ($numbers.Count -gt 0) { ($numbers | Measure-Object -Maximum).Maximum + 1 } else { 1 }
$VMName = "ubuntu$nextNum"
Write-Host "Creating VM: $VMName"

# Paths
$VMPath = "C:\VMs\$VMName"
$ImageUrl = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
$ImageCache = "C:\VMs\images\ubuntu-24.04-cloud.img"
$OsVHDXPath = "$VMPath\os.vhdx"
$CidVHDXPath = "$VMPath\cidata.vhdx"
$DataVHDXPath = "$VMPath\data.vhdx"
$SwitchName = "New Virtual Switch"

# Check for QEMU installation
$QemuImgPath = "C:\Program Files\qemu\qemu-img.exe"
if (!(Test-Path $QemuImgPath)) {
    # Try common alternative locations
    $QemuImgPath = "C:\Program Files (x86)\qemu\qemu-img.exe"
    if (!(Test-Path $QemuImgPath)) {
        # Try PATH
        $QemuInPath = Get-Command qemu-img.exe -ErrorAction SilentlyContinue
        if ($QemuInPath) {
            $QemuImgPath = $QemuInPath.Source
        } else {
            Write-Error "QEMU is not installed. Please install QEMU from https://www.qemu.org/download/#windows"
            exit 1
        }
    }
}

# Create directories
if (!(Test-Path $VMPath)) { New-Item -ItemType Directory -Path $VMPath }
if (!(Test-Path "C:\VMs\images")) { New-Item -ItemType Directory -Path "C:\VMs\images" }

# Download image if needed
$downloadImage = $false
if (!(Test-Path $ImageCache)) {
    $downloadImage = $true
}
elseif ((Get-Item $ImageCache).LastWriteTime -lt (Get-Date).AddDays(-30)) {
    $downloadImage = $true
}

if ($downloadImage) {
    Write-Host "Downloading Ubuntu cloud image..."
    Invoke-WebRequest -Uri $ImageUrl -OutFile $ImageCache -ErrorAction Stop
}

# Convert to VHDX using QEMU
Write-Host "Converting image to VHDX..."
if (Test-Path $OsVHDXPath) { Remove-Item $OsVHDXPath -Force }
Start-Process -FilePath $QemuImgPath -ArgumentList "convert", "-O", "vhdx", "-o", "subformat=dynamic", $ImageCache, $OsVHDXPath -Wait -NoNewWindow

# Ensure VHDX is uncompressed and not sparse
Write-Host "Optimizing VHDX file..."
& compact.exe /u $OsVHDXPath | Out-Null
& fsutil.exe sparse setflag $OsVHDXPath 0 | Out-Null

Resize-VHD -Path $OsVHDXPath -SizeBytes 50GB

# Create user-data and meta-data - using simple version for reliable SSH
$userData = Get-Content "$PSScriptRoot\user-data-simple" -Raw
$userData = $userData -replace "Passw0rd", $RootPassword
$metaData = "instance-id: $VMName`nlocal-hostname: $VMName"

# Copy build scripts to a temporary location for cloud-init
$buildScripts = @(
    "$PSScriptRoot\build-selector.sh",
    "$PSScriptRoot\docker-setup.sh",
    "$PSScriptRoot\post-ssh-setup.sh"
)

# Create cidata VHDX
Write-Host "Creating cidata VHDX..."
if (Test-Path $CidVHDXPath) { Remove-Item $CidVHDXPath -Force }
New-VHD -Path $CidVHDXPath -SizeBytes 100MB -Fixed -ErrorAction Stop | Out-Null
$mounted = Mount-VHD -Path $CidVHDXPath -Passthru
$disk = $mounted | Get-Disk | Initialize-Disk -PartitionStyle MBR -PassThru
$partition = $disk | New-Partition -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter $partition.DriveLetter -FileSystem FAT32 -NewFileSystemLabel "cidata" -Confirm:$false | Out-Null
$drive = "$($partition.DriveLetter):"
$userData | Out-File "$drive\user-data" -Encoding ASCII
$metaData | Out-File "$drive\meta-data" -Encoding ASCII

# Copy build scripts to cloud-init drive
foreach ($script in $buildScripts) {
    if (Test-Path $script) {
        $scriptName = Split-Path $script -Leaf
        Copy-Item $script "$drive\$scriptName" -Force
    }
}

Dismount-VHD -Path $CidVHDXPath

# Create VM
Write-Host "Creating VM..."
New-VM -Name $VMName -MemoryStartupBytes 4GB -Generation 1 -VHDPath $OsVHDXPath -Path "C:\VMs" -SwitchName $SwitchName -ErrorAction Stop
Set-VMProcessor -VMName $VMName -Count 2
Add-VMHardDiskDrive -VMName $VMName -ControllerType IDE -Path $CidVHDXPath
Get-VM -Name $VMName | Get-VMNetworkAdapter | Set-VMNetworkAdapter -MacAddressSpoofing On

# Add data disk
Write-Host "Adding data disk..."
if (Test-Path $DataVHDXPath) { Remove-Item $DataVHDXPath -Force }
New-VHD -Path $DataVHDXPath -SizeBytes 1TB -Dynamic -ErrorAction Stop | Out-Null
Add-VMScsiController -VMName $VMName
Add-VMHardDiskDrive -VMName $VMName -ControllerType SCSI -Path $DataVHDXPath

# Start VM
Write-Host "Starting VM..."
Start-VM -Name $VMName

# Wait for VM to boot and initialize
Write-Host "VM started. Waiting for initial boot (30 seconds)..."
Start-Sleep -Seconds 30

# Enable enhanced session mode for better VM access
Write-Host "Configuring enhanced VM services..."
Set-VM -Name $VMName -EnhancedSessionTransportType HvSocket

# Quick IP detection
Write-Host "Detecting VM IP address..."
$mac = (Get-VM -Name $VMName | Get-VMNetworkAdapter).MacAddress
$macFormatted = $mac -replace '(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})', '$1:$2:$3:$4:$5:$6'
$macDashed = $mac -replace '(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})', '$1-$2-$3-$4-$5-$6'

# Try ARP table lookup
$arp = arp -a | Select-String -Pattern $macFormatted
if (-not $arp) {
    $arp = arp -a | Select-String -Pattern $macDashed
}

$ip = $null
if ($arp) {
    $arpParts = $arp -split '\s+'
    if ($arpParts.Count -ge 2 -and $arpParts[1] -match '^\d+\.\d+\.\d+\.\d+$') {
        $ip = $arpParts[1]
    }
}

# Display results
Write-Host "`n🎉 === VM CREATION COMPLETE ==="
Write-Host "VM Name: $VMName"
if ($ip) {
    Write-Host "IP Address: $ip"
    Write-Host "SSH Command: ssh root@$ip"
}
else {
    Write-Host "IP Address: Check Hyper-V Manager or use: arp -a | findstr $macFormatted"
    Write-Host "SSH Command: ssh root@<VM_IP>"
}
Write-Host "Username: root"
Write-Host "Password: $RootPassword"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. SSH to your VM: ssh root@$(if ($ip) { $ip } else { '<VM_IP>' })"
Write-Host "2. Docker is pre-installed and ready!"
Write-Host "3. Choose your Docker build (Personal/Business/Custom)"
Write-Host "4. Access your web services via the displayed URLs"
Write-Host ""
Write-Host "The VM is ready with SSH and Docker!"

Stop-Transcript