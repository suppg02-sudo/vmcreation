# Open Code Automated Installation Script
# Run as Administrator
# Version: 1.0
# Last Updated: 2026-01-31

param(
    [switch]$SkipVerification = $false
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-OpenCode {
    Write-ColorOutput "==========================================" "Cyan"
    Write-ColorOutput "   Open Code Installation Script" "Cyan"
    Write-ColorOutput "==========================================" "Cyan"
    Write-Host ""

    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-ColorOutput "ERROR: This script must be run as Administrator!" "Red"
        Write-Host ""
        Write-Host "Please:"
        Write-Host "  1. Right-click on PowerShell"
        Write-Host "  2. Select 'Run as Administrator'"
        Write-Host "  3. Navigate to this script and run it again"
        Write-Host ""
        exit 1
    }

    Write-ColorOutput "✓ Administrator privileges confirmed" "Green"
    Write-Host ""

    # Check if Open Code is already installed
    $opencodePath = "C:\Program Files\Open Code\opencode.exe"
    if (Test-Path $opencodePath) {
        Write-ColorOutput "Open Code is already installed at: $opencodePath" "Yellow"
        $reinstall = Read-Host "Do you want to reinstall? (y/N)"
        if ($reinstall -ne "y" -and $reinstall -ne "Y") {
            Write-Host "Installation cancelled."
            exit 0
        }
        Write-ColorOutput "Proceeding with reinstallation..." "Yellow"
    }

    # Define download URL and paths
    Write-ColorOutput "Step 1: Downloading Open Code installer..." "Cyan"
    $downloadUrl = "https://opencode.dev/latest/win32-x64-user/OpenCodeSetup.exe"
    $installerPath = "$env:TEMP\OpenCodeSetup.exe"

    try {
        Write-Host "  Downloading from: $downloadUrl"
        $progressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        $progressPreference = 'Continue'
        Write-ColorOutput "  ✓ Download completed" "Green"
    }
    catch {
        Write-ColorOutput "  ✗ Failed to download installer" "Red"
        Write-ColorOutput "  Error: $($_.Exception.Message)" "Red"
        exit 1
    }

    Write-Host ""

    # Verify downloaded file
    if (-not $SkipVerification) {
        Write-ColorOutput "Step 2: Verifying downloaded installer..." "Cyan"
        if (Test-Path $installerPath) {
            $fileSize = (Get-Item $installerPath).Length / 1MB
            Write-Host "  File size: $([math]::Round($fileSize, 2)) MB"
            Write-ColorOutput "  ✓ Installer file verified" "Green"
        }
        else {
            Write-ColorOutput "  ✗ Installer file not found" "Red"
            exit 1
        }
    }

    Write-Host ""

    # Install Open Code
    Write-ColorOutput "Step 3: Installing Open Code..." "Cyan"
    Write-Host "  This may take a few minutes..."
    Write-Host ""

    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/silent", "/mergetasks=!runcode" -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput "  ✓ Installation completed successfully" "Green"
        }
        else {
            Write-ColorOutput "  ✗ Installation failed with exit code: $($process.ExitCode)" "Red"
            exit 1
        }
    }
    catch {
        Write-ColorOutput "  ✗ Installation failed" "Red"
        Write-ColorOutput "  Error: $($_.Exception.Message)" "Red"
        exit 1
    }

    Write-Host ""

    # Clean up
    Write-ColorOutput "Step 4: Cleaning up..." "Cyan"
    try {
        Remove-Item $installerPath -Force
        Write-ColorOutput "  ✓ Temporary files removed" "Green"
    }
    catch {
        Write-ColorOutput "  ⚠ Warning: Could not remove temporary files" "Yellow"
    }

    Write-Host ""

    # Verify installation
    Write-ColorOutput "Step 5: Verifying installation..." "Cyan"
    if (Test-Path $opencodePath) {
        Write-ColorOutput "  ✓ Open Code installed successfully!" "Green"
        Write-Host ""
        Write-ColorOutput "Installation Summary:" "Cyan"
        Write-Host "  Location: $opencodePath"
        Write-Host "  Version:  $(& $opencodePath --version 2>$null)"
        Write-Host ""
        Write-ColorOutput "Next Steps:" "Cyan"
        Write-Host "  1. Launch Open Code from the Start menu"
        Write-Host "  2. Install the Open Agents Control plugin:"
        Write-Host "     - Press Ctrl+Shift+X to open Extensions"
        Write-Host "     - Search for 'Open Agents Control'"
        Write-Host "     - Click Install"
        Write-Host ""
        Write-ColorOutput "Or run the plugin installation script:" "Cyan"
        Write-Host "  .\install-openagents-plugin.ps1"
        Write-Host ""
    }
    else {
        Write-ColorOutput "  ✗ Installation verification failed" "Red"
        Write-ColorOutput "  Open Code not found at expected location" "Red"
        exit 1
    }

    Write-ColorOutput "==========================================" "Cyan"
    Write-ColorOutput "   Installation Complete!" "Green"
    Write-ColorOutput "==========================================" "Cyan"
}

# Main execution
Install-OpenCode
