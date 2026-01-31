# UrBackup Web Interface Fix Script
# This script must be run as ADMINISTRATOR
# It will create firewall rules and restart the UrBackup service

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UrBackup Web Interface Fix Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✓ Running with administrator privileges" -ForegroundColor Green
Write-Host ""

# Step 1: Create Firewall Rules
Write-Host "[Step 1] Creating Windows Firewall rules..." -ForegroundColor Yellow

try {
    # Remove existing rules if they exist
    Remove-NetFirewallRule -DisplayName "UrBackup Web Interface*" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "UrBackup Server*" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "UrBackup Internet*" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "UrBackup Discovery*" -ErrorAction SilentlyContinue
    
    # Create new rules
    New-NetFirewallRule -DisplayName "UrBackup Web Interface (HTTP)" `
        -Direction Inbound `
        -LocalPort 55414 `
        -Protocol TCP `
        -Action Allow `
        -Profile Any `
        -ErrorAction Stop | Out-Null
    Write-Host "  ✓ Created rule for Web Interface (port 55414)" -ForegroundColor Green
    
    New-NetFirewallRule -DisplayName "UrBackup Server Port" `
        -Direction Inbound `
        -LocalPort 55413 `
        -Protocol TCP `
        -Action Allow `
        -Profile Any `
        -ErrorAction Stop | Out-Null
    Write-Host "  ✓ Created rule for Server (port 55413)" -ForegroundColor Green
    
    New-NetFirewallRule -DisplayName "UrBackup Internet Service" `
        -Direction Inbound `
        -LocalPort 55415 `
        -Protocol TCP `
        -Action Allow `
        -Profile Any `
        -ErrorAction Stop | Out-Null
    Write-Host "  ✓ Created rule for Internet Service (port 55415)" -ForegroundColor Green
    
    New-NetFirewallRule -DisplayName "UrBackup Discovery (UDP)" `
        -Direction Inbound `
        -LocalPort 35623 `
        -Protocol UDP `
        -Action Allow `
        -Profile Any `
        -ErrorAction Stop | Out-Null
    Write-Host "  ✓ Created rule for Discovery (port 35623 UDP)" -ForegroundColor Green
    
}
catch {
    Write-Host "  ✗ Failed to create some firewall rules: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Step 2: Restart UrBackup Service
Write-Host "[Step 2] Restarting UrBackup service..." -ForegroundColor Yellow

try {
    Restart-Service -Name "UrBackupWinServer" -Force -ErrorAction Stop
    Write-Host "  ✓ Service restarted successfully" -ForegroundColor Green
    
    # Wait for service to fully start
    Write-Host "  Waiting for service to initialize..." -ForegroundColor Gray
    Start-Sleep -Seconds 8
    
}
catch {
    Write-Host "  ✗ Failed to restart service: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Step 3: Verify Service Status
Write-Host "[Step 3] Checking service status..." -ForegroundColor Yellow

$service = Get-Service -Name "UrBackupWinServer"
if ($service.Status -eq "Running") {
    Write-Host "  ✓ UrBackup service is running" -ForegroundColor Green
}
else {
    Write-Host "  ✗ UrBackup service is NOT running (Status: $($service.Status))" -ForegroundColor Red
}

Write-Host ""

# Step 4: Test Port Binding
Write-Host "[Step 4] Testing port binding..." -ForegroundColor Yellow

$portListening = Get-NetTCPConnection -LocalPort 55414 -State Listen -ErrorAction SilentlyContinue

if ($portListening) {
    Write-Host "  ✓ Port 55414 is LISTENING!" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  SUCCESS!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The UrBackup web interface should now be accessible at:" -ForegroundColor White
    Write-Host "  http://localhost:55414" -ForegroundColor Cyan
    Write-Host "  or" -ForegroundColor White
    Write-Host "  http://YOUR_IP_ADDRESS:55414" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Default credentials:" -ForegroundColor White
    Write-Host "  Username: admin" -ForegroundColor Gray
    Write-Host "  Password: (blank)" -ForegroundColor Gray
    Write-Host ""
    
    # Try to open in browser
    $openBrowser = Read-Host "Would you like to open the web interface in your browser now? (Y/N)"
    if ($openBrowser -eq "Y" -or $openBrowser -eq "y") {
        Start-Process "http://localhost:55414"
    }
    
}
else {
    Write-Host "  ✗ Port 55414 is NOT listening" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ISSUE NOT RESOLVED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check the log file for errors:" -ForegroundColor White
    Write-Host "   Get-Content 'C:\Program Files\UrBackupServer\urbackup.log' -Tail 20" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Temporarily disable antivirus software and rerun this script" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Check if corporate security policies are blocking port binding" -ForegroundColor White
    Write-Host ""
    
    # Show recent log entries
    Write-Host "Recent log entries:" -ForegroundColor Yellow
    try {
        Get-Content "C:\Program Files\UrBackupServer\urbackup.log" -Tail 10 | ForEach-Object {
            if ($_ -match "ERROR") {
                Write-Host "  $_" -ForegroundColor Red
            }
            elseif ($_ -match "WARNING") {
                Write-Host "  $_" -ForegroundColor Yellow
            }
            else {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "  Could not read log file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
