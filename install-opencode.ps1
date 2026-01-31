# Open Code Automated Installation Script
# Run as Administrator
# Version: 2.0
# Last Updated: 2026-01-31

param(
    [switch]$SkipVerification = $false,
    [switch]$Silent = $false,
    [switch]$NoLaunch = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdministratorPrivileges {
    # Check if we're already running as admin
    if (Test-Administrator) {
        return $true
    }

    # Relaunch the script with administrator privileges
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    
    # Pass through existing parameters
    if ($SkipVerification) { $psi.Arguments += " -SkipVerification" }
    if ($Silent) { $psi.Arguments += " -Silent" }
    if ($NoLaunch) { $psi.Arguments += " -NoLaunch" }
    if ($Force) { $psi.Arguments += " -Force" }
    
    $psi.Verb = "RunAs"
    $psi.UseShellExecute = $true

    try {
        $process = [System.Diagnostics.Process]::Start($psi)
        $process.WaitForExit()
        return $process.ExitCode -eq 0
    }
    catch {
        return $false
    }
}

function Refresh-EnvironmentVariables {
    # Refresh environment variables for the current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + 
    [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Broadcast environment change to other processes
    if (-not $Silent) {
        Write-ColorOutput "  ✓ Environment variables refreshed" "Green"
    }
}

function Create-DesktopShortcut {
    $WshShell = New-Object -ComObject WScript.Shell
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Open Code.lnk"
    $targetPath = "C:\Program Files\Open Code\opencode.exe"

    if (-not (Test-Path $targetPath)) {
        $targetPath = "C:\Program Files (x86)\Open Code\opencode.exe"
    }

    if (Test-Path $targetPath) {
        $shortcut = $WshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.WorkingDirectory = Split-Path $targetPath
        $shortcut.Description = "Open Code - Open Source Code Editor"
        $shortcut.Save()
        
        if (-not $Silent) {
            Write-ColorOutput "  ✓ Desktop shortcut created" "Green"
        }
        return $true
    }
    return $false
}

function Install-OpenCode {
    Write-ColorOutput "==========================================" "Cyan"
    Write-ColorOutput "   Open Code Installation Script v2.0" "Cyan"
    Write-ColorOutput "==========================================" "Cyan"
    Write-Host ""

    # Auto-elevate if not running as administrator
    if (-not (Test-Administrator)) {
        Write-ColorOutput "Requesting administrator privileges..." "Yellow"
        if (Request-AdministratorPrivileges) {
            exit 0
        }
        else {
            Write-ColorOutput "ERROR: Could not obtain administrator privileges!" "Red"
            Write-Host ""
            Write-Host "Please:"
            Write-Host "  1. Right-click on this script"
            Write-Host "  2. Select 'Run as Administrator'"
            Write-Host ""
            exit 1
        }
    }

    Write-ColorOutput "✓ Administrator privileges confirmed" "Green"
    Write-Host ""

    # Check if Open Code is already installed
    $opencodePath = "C:\Program Files\Open Code\opencode.exe"
    if (-not (Test-Path $opencodePath)) {
        $opencodePath = "C:\Program Files (x86)\Open Code\opencode.exe"
    }

    if (Test-Path $opencodePath -and -not $Force) {
        Write-ColorOutput "Open Code is already installed at: $opencodePath" "Yellow"
        
        if (-not $Silent) {
            $reinstall = Read-Host "Do you want to reinstall? (y/N)"
            if ($reinstall -ne "y" -and $reinstall -ne "Y") {
                Write-Host "Installation cancelled."
                exit 0
            }
        }
        else {
            Write-ColorOutput "Use -Force to reinstall in silent mode" "Yellow"
            exit 0
        }
        
        Write-ColorOutput "Proceeding with reinstallation..." "Yellow"
    }

    # Define download URL and paths
    Write-ColorOutput "Step 1: Downloading Open Code installer..." "Cyan"
    $downloadUrl = "https://opencode.dev/latest/win32-x64-user/OpenCodeSetup.exe"
    $installerPath = "$env:TEMP\OpenCodeSetup.exe"

    try {
        if (-not $Silent) {
            Write-Host "  Downloading from: $downloadUrl"
        }
        
        $progressPreference = 'SilentlyContinue'
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $installerPath)
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
            if (-not $Silent) {
                Write-Host "  File size: $([math]::Round($fileSize, 2)) MB"
            }
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
    if (-not $Silent) {
        Write-Host "  This may take a few minutes..."
        Write-Host ""
    }

    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/silent", "/mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" -Wait -PassThru
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
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-ColorOutput "  ✓ Temporary files removed" "Green"
    }
    catch {
        Write-ColorOutput "  ⚠ Warning: Could not remove temporary files" "Yellow"
    }

    Write-Host ""

    # Refresh environment variables
    Write-ColorOutput "Step 5: Refreshing environment variables..." "Cyan"
    Refresh-EnvironmentVariables

    Write-Host ""

    # Create desktop shortcut
    Write-ColorOutput "Step 6: Creating desktop shortcut..." "Cyan"
    Create-DesktopShortcut

    Write-Host ""

    # Verify installation
    Write-ColorOutput "Step 7: Verifying installation..." "Cyan"
    
    # Re-check for Open Code in both locations
    $opencodePath = "C:\Program Files\Open Code\opencode.exe"
    if (-not (Test-Path $opencodePath)) {
        $opencodePath = "C:\Program Files (x86)\Open Code\opencode.exe"
    }

    if (Test-Path $opencodePath) {
        Write-ColorOutput "  ✓ Open Code installed successfully!" "Green"
        Write-Host ""
        
        if (-not $Silent) {
            Write-ColorOutput "Installation Summary:" "Cyan"
            Write-Host "  Location: $opencodePath"
            $version = & $opencodePath --version 2>$null
            Write-Host "  Version:  $version"
            Write-Host ""
            Write-ColorOutput "Next Steps:" "Cyan"
            Write-Host "  1. Launch Open Code from the Start menu or desktop shortcut"
            Write-Host "  2. Install the Open Agents Control plugin:"
            Write-Host "     - Press Ctrl+Shift+X to open Extensions"
            Write-Host "     - Search for 'Open Agents Control'"
            Write-Host "     - Click Install"
            Write-Host ""
            Write-ColorOutput "Or run the plugin installation script:" "Cyan"
            Write-Host "  .\install-openagents-plugin.ps1"
            Write-Host ""
        }
    }
    else {
        Write-ColorOutput "  ✗ Installation verification failed" "Red"
        Write-ColorOutput "  Open Code not found at expected location" "Red"
        exit 1
    }

    Write-ColorOutput "==========================================" "Cyan"
    Write-ColorOutput "   Installation Complete!" "Green"
    Write-ColorOutput "==========================================" "Cyan"
    Write-Host ""

    # Auto-launch Open Code if requested
    if (-not $NoLaunch -and -not $Silent) {
        Write-ColorOutput "Would you like to launch Open Code now? (Y/n)" "Cyan"
        $launch = Read-Host
        if ($launch -ne "n" -and $launch -ne "N") {
            Write-Host "Launching Open Code..."
            Start-Process $opencodePath
            Write-ColorOutput "  ✓ Open Code launched" "Green"
        }
    }
    elseif (-not $NoLaunch -and $Silent) {
        # Auto-launch in silent mode
        Start-Process $opencodePath
    }
}

# Main execution
Install-OpenCode
