# Open Agents Control Plugin Installation Script
# Version: 1.0
# Last Updated: 2026-01-31

param(
    [switch]$Force = $false,
    [switch]$Verbose = $false
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

function Test-OpenCodeInstalled {
    $opencodePath = "C:\Program Files\Open Code\opencode.exe"
    if (-not (Test-Path $opencodePath)) {
        # Also check in Program Files (x86)
        $opencodePath = "C:\Program Files (x86)\Open Code\opencode.exe"
    }
    return Test-Path $opencodePath
}

function Get-OpenCodePath {
    $paths = @(
        "C:\Program Files\Open Code\opencode.exe",
        "C:\Program Files (x86)\Open Code\opencode.exe",
        "$env:LOCALAPPDATA\Programs\Open Code\opencode.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

function Test-ExtensionInstalled {
    param([string]$ExtensionId)
    
    $extensionsPath = "$env:USERPROFILE\.opencode\extensions"
    if (-not (Test-Path $extensionsPath)) {
        return $false
    }
    
    # Check if extension directory exists
    $extensionDir = Get-ChildItem -Path $extensionsPath -Directory | 
    Where-Object { $_.Name -like "*$ExtensionId*" }
    
    return $extensionDir -ne $null
}

function Install-OpenAgentsPlugin {
    Write-ColorOutput "==========================================" "Cyan"
    Write-ColorOutput "   Open Agents Control Plugin Installer" "Cyan"
    Write-ColorOutput "==========================================" "Cyan"
    Write-Host ""

    # Check if Open Code is installed
    Write-ColorOutput "Step 1: Checking Open Code installation..." "Cyan"
    $opencodePath = Get-OpenCodePath
    
    if (-not $opencodePath) {
        Write-ColorOutput "  ✗ Open Code is not installed!" "Red"
        Write-Host ""
        Write-Host "Please install Open Code first:"
        Write-Host "  1. Download from: https://opencode.dev/download"
        Write-Host "  2. Or run: .\install-opencode.ps1"
        Write-Host ""
        exit 1
    }
    
    Write-ColorOutput "  ✓ Open Code found at: $opencodePath" "Green"
    $opencodeVersion = & $opencodePath --version 2>$null
    Write-Host "  Version: $opencodeVersion"
    Write-Host ""

    # Check if Open Code is in PATH
    Write-ColorOutput "Step 2: Checking Open Code in PATH..." "Cyan"
    try {
        $versionCheck = & opencode --version 2>$null
        if ($versionCheck) {
            Write-ColorOutput "  ✓ Open Code command is available" "Green"
            $opencodeCmd = "opencode"
        }
        else {
            Write-ColorOutput "  ⚠ Open Code not in PATH, using full path" "Yellow"
            $opencodeCmd = $opencodePath
        }
    }
    catch {
        Write-ColorOutput "  ⚠ Open Code not in PATH, using full path" "Yellow"
        $opencodeCmd = $opencodePath
    }
    Write-Host ""

    # Check if extension is already installed
    Write-ColorOutput "Step 3: Checking for existing installation..." "Cyan"
    $extensionId = "openagents.open-agents-control"
    
    if (Test-ExtensionInstalled -ExtensionId $extensionId) {
        Write-ColorOutput "  ⚠ Open Agents Control plugin is already installed" "Yellow"
        
        if (-not $Force) {
            $reinstall = Read-Host "Do you want to reinstall/update? (y/N)"
            if ($reinstall -ne "y" -and $reinstall -ne "Y") {
                Write-Host "Installation cancelled."
                exit 0
            }
        }
        
        Write-ColorOutput "  Proceeding with reinstallation..." "Yellow"
        
        # Uninstall existing extension
        Write-Host "  Uninstalling existing extension..."
        try {
            & $opencodeCmd --uninstall-extension $extensionId 2>$null | Out-Null
            Write-ColorOutput "  ✓ Existing extension removed" "Green"
        }
        catch {
            Write-ColorOutput "  ⚠ Could not remove existing extension (may not be critical)" "Yellow"
        }
    }
    else {
        Write-ColorOutput "  ✓ No existing installation found" "Green"
    }
    Write-Host ""

    # Install the extension
    Write-ColorOutput "Step 4: Installing Open Agents Control plugin..." "Cyan"
    Write-Host "  Extension ID: $extensionId"
    Write-Host "  This may take a few moments..."
    Write-Host ""

    try {
        $output = & $opencodeCmd --install-extension $extensionId 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✓ Extension installed successfully!" "Green"
            if ($Verbose) {
                Write-Host "  Output: $output"
            }
        }
        else {
            Write-ColorOutput "  ✗ Installation failed" "Red"
            Write-ColorOutput "  Exit code: $LASTEXITCODE" "Red"
            Write-Host "  Output: $output"
            exit 1
        }
    }
    catch {
        Write-ColorOutput "  ✗ Installation failed" "Red"
        Write-ColorOutput "  Error: $($_.Exception.Message)" "Red"
        exit 1
    }

    Write-Host ""

    # Verify installation
    Write-ColorOutput "Step 5: Verifying installation..." "Cyan"
    
    Start-Sleep -Seconds 2  # Give Open Code time to register the extension
    
    if (Test-ExtensionInstalled -ExtensionId $extensionId) {
        Write-ColorOutput "  ✓ Extension verified!" "Green"
        
        # Get extension details
        $extensionsPath = "$env:USERPROFILE\.opencode\extensions"
        $extensionDir = Get-ChildItem -Path $extensionsPath -Directory | 
        Where-Object { $_.Name -like "*$ExtensionId*" }
        
        if ($extensionDir) {
            Write-Host "  Location: $($extensionDir.FullName)"
        }
    }
    else {
        Write-ColorOutput "  ⚠ Could not verify installation, but it may still be working" "Yellow"
        Write-Host "  Try opening Open Code and checking the Extensions view"
    }

    Write-Host ""

    # Configure default settings
    Write-ColorOutput "Step 6: Configuring default settings..." "Cyan"
    
    $settingsPath = "$env:APPDATA\Open Code\User\settings.json"
    $settingsDir = Split-Path -Parent $settingsPath
    
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }
    
    $defaultSettings = @{
        "openagents.server.enabled" = $true
        "openagents.server.port"    = 3000
        "openagents.server.host"    = "localhost"
        "openagents.logging.level"  = "info"
    }
    
    try {
        if (Test-Path $settingsPath) {
            $existingSettings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            Write-Host "  Updating existing settings..."
            
            foreach ($key in $defaultSettings.Keys) {
                if (-not $existingSettings.PSObject.Properties.Name.Contains($key)) {
                    $existingSettings | Add-Member -NotePropertyName $key -NotePropertyValue $defaultSettings[$key]
                }
            }
            
            $existingSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        }
        else {
            Write-Host "  Creating new settings file..."
            $defaultSettings | ConvertTo-Json | Set-Content $settingsPath
        }
        
        Write-ColorOutput "  ✓ Settings configured" "Green"
    }
    catch {
        Write-ColorOutput "  ⚠ Could not configure settings automatically" "Yellow"
        Write-Host "  You may need to configure settings manually in Open Code"
    }

    Write-Host ""

    # Print summary
    Write-ColorOutput "==========================================" "Cyan"
    Write-ColorOutput "   Installation Complete!" "Green"
    Write-ColorOutput "==========================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "Next Steps:" "Cyan"
    Write-Host "  1. Launch Open Code"
    Write-Host "  2. Press Ctrl+Shift+X to open Extensions view"
    Write-Host "  3. Verify 'Open Agents Control' appears in the list"
    Write-Host "  4. Press Ctrl+Shift+P and type 'Open Agents' to see available commands"
    Write-Host ""
    Write-ColorOutput "Configuration:" "Cyan"
    Write-Host "  Settings file: $settingsPath"
    Write-Host "  Extension ID: $extensionId"
    Write-Host ""
    Write-ColorOutput "Troubleshooting:" "Cyan"
    Write-Host "  If the plugin doesn't appear:"
    Write-Host "  - Restart Open Code (Ctrl+Shift+P > 'Developer: Reload Window')"
    Write-Host "  - Check the Output panel for errors (Ctrl+Shift+U)"
    Write-Host "  - Run this script again with -Force flag"
    Write-Host ""
}

# Main execution
Install-OpenAgentsPlugin
