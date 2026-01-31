# setup-restic-windows.ps1 - Download and setup Restic for Windows
# This script downloads the latest Restic binary for Windows

param(
    [string]$InstallPath = "$env:USERPROFILE\restic",
    [switch]$Force = $false
)

# Helper functions
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Restic Setup for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script is not running as Administrator. Some features may not work properly."
    Write-Host "It is recommended to run this script as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Create installation directory
if (-not (Test-Path $InstallPath)) {
    Write-Log "Creating installation directory: $InstallPath"
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}
else {
    Write-Log "Installation directory exists: $InstallPath"
}

# Check if Restic is already installed
$resticExe = Join-Path $InstallPath "restic.exe"
if (Test-Path $resticExe) {
    Write-Log "Restic is already installed at: $resticExe"
    $currentVersion = & $resticExe version
    Write-Log "Current version: $currentVersion"
    
    if (-not $Force) {
        Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
        Write-Host ""
        return
    }
}

# Download latest Restic
Write-Log "Downloading latest Restic for Windows..."
$resticUrl = "https://github.com/restic/restic/releases/download/v0.16.5/restic_0.16.5_windows_amd64.zip"
$downloadPath = "$env:TEMP\restic.zip"

try {
    Write-Log "Downloading from: $resticUrl"
    Invoke-WebRequest -Uri $resticUrl -OutFile $downloadPath -UseBasicParsing
    Write-Log "Download completed successfully"
}
catch {
    Write-Error "Failed to download Restic: $_"
    exit 1
}

# Extract Restic
Write-Log "Extracting Restic..."
try {
    Expand-Archive -Path $downloadPath -DestinationPath $InstallPath -Force
    Write-Log "Extraction completed successfully"
}
catch {
    Write-Error "Failed to extract Restic: $_"
    exit 1
}

# Rename extracted file to restic.exe
$extractedExe = Get-ChildItem -Path $InstallPath -Filter "*.exe" | Select-Object -First 1
if ($extractedExe -and $extractedExe.Name -ne "restic.exe") {
    Write-Log "Renaming $($extractedExe.Name) to restic.exe..."
    Rename-Item -Path $extractedExe.FullName -NewName "restic.exe" -Force
}

# Clean up
Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue

# Verify installation
if (Test-Path $resticExe) {
    Write-Log "Verifying installation..."
    $version = & $resticExe version
    Write-Success "Restic installed successfully!"
    Write-Host "Version: $version" -ForegroundColor Green
    Write-Host "Location: $resticExe" -ForegroundColor Green
    Write-Host ""
    
    # Add to PATH if not already there
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$InstallPath*") {
        Write-Log "Adding Restic to user PATH..."
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallPath", "User")
        Write-Success "Restic has been added to your PATH."
        Write-Host "Please restart your terminal or log off and back on for changes to take effect." -ForegroundColor Yellow
    }
    else {
        Write-Log "Restic is already in PATH"
    }
    
    Write-Host ""
    Write-Success "Setup complete!"
    Write-Host "You can now use Restic by running: restic" -ForegroundColor Cyan
}
else {
    Write-Error "Installation verification failed. Restic.exe not found at: $resticExe"
    exit 1
}
