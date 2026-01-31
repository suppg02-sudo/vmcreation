# QEMU Installation Script for Windows
# This script downloads and installs QEMU for Windows

$QemuUrl = "https://download.qemu.org/qemu-w64-setup-20241130.exe"
$InstallerPath = "$env:TEMP\qemu-installer.exe"
$InstallDir = "C:\Program Files\qemu"

Write-Host "Downloading QEMU installer..."
Invoke-WebRequest -Uri $QemuUrl -OutFile $InstallerPath -ErrorAction Stop

Write-Host "Installing QEMU..."
Write-Host "NOTE: You may need to manually run the installer with administrator privileges."
Write-Host "The installer will be saved to: $InstallerPath"

# Attempt to run installer silently (may require admin)
try {
    Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/D=$InstallDir" -Wait -NoNewWindow -ErrorAction Stop
    Write-Host "QEMU installed successfully to $InstallDir"
} catch {
    Write-Warning "Silent installation failed. Please run the installer manually."
    Write-Host "To complete installation, run:"
    Write-Host "  $InstallerPath"
    Write-Host "  Then add '$InstallDir' to your PATH environment variable."
}

# Verify installation
$QemuImgPath = "$InstallDir\qemu-img.exe"
if (Test-Path $QemuImgPath) {
    Write-Host "QEMU installed successfully!"
    & $QemuImgPath --version
} else {
    Write-Host "Please complete the QEMU installation manually."
}
