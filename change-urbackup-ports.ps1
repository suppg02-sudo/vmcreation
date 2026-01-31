# Change UrBackup Ports Script
# This will change the default ports to higher port numbers

param(
    [int]$HttpPort = 8080,
    [int]$ServerPort = 55513,
    [int]$InternetPort = 55515
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UrBackup Port Change Script" -ForegroundColor Cyan
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

$argsFile = "C:\Program Files\UrBackupServer\args.txt"
$backupFile = "C:\Program Files\UrBackupServer\args.txt.backup"

Write-Host "New port configuration:" -ForegroundColor Yellow
Write-Host "  HTTP Web Interface: $HttpPort" -ForegroundColor White
Write-Host "  Server Port: $ServerPort" -ForegroundColor White
Write-Host "  Internet Service: $InternetPort" -ForegroundColor White
Write-Host ""

# Step 1: Stop the service
Write-Host "[Step 1] Stopping UrBackup service..." -ForegroundColor Yellow
try {
    Stop-Service -Name "UrBackupWinServer" -Force -ErrorAction Stop
    Write-Host "  ✓ Service stopped" -ForegroundColor Green
    Start-Sleep -Seconds 2
}
catch {
    Write-Host "  ✗ Failed to stop service: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""

# Step 2: Backup current args.txt
Write-Host "[Step 2] Backing up current configuration..." -ForegroundColor Yellow
try {
    Copy-Item -Path $argsFile -Destination $backupFile -Force
    Write-Host "  ✓ Backup created: $backupFile" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Failed to backup: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Step 3: Read and modify args.txt
Write-Host "[Step 3] Updating port configuration..." -ForegroundColor Yellow
try {
    $content = Get-Content -Path $argsFile -Raw
    
    # Replace the port values
    $content = $content -replace '--port\r?\n\d+', "--port`r`n$ServerPort"
    $content = $content -replace '--http_port\r?\n\d+', "--http_port`r`n$HttpPort"
    $content = $content -replace '--internet_port\r?\n\d+', "--internet_port`r`n$InternetPort"
    
    # Write back to file
    Set-Content -Path $argsFile -Value $content -NoNewline
    
    Write-Host "  ✓ Configuration updated" -ForegroundColor Green
    Write-Host "    - Server port changed to: $ServerPort" -ForegroundColor Gray
    Write-Host "    - HTTP port changed to: $HttpPort" -ForegroundColor Gray
    Write-Host "    - Internet port changed to: $InternetPort" -ForegroundColor Gray
    
}
catch {
    Write-Host "  ✗ Failed to update configuration: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""

# Step 4: Start the service
Write-Host "[Step 4] Starting UrBackup service..." -ForegroundColor Yellow
try {
    Start-Service -Name "UrBackupWinServer" -ErrorAction Stop
    Write-Host "  ✓ Service started" -ForegroundColor Green
    
    # Wait for service to initialize
    Write-Host "  Waiting for service to initialize..." -ForegroundColor Gray
    Start-Sleep -Seconds 8
    
}
catch {
    Write-Host "  ✗ Failed to start service: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""

# Step 5: Test port binding
Write-Host "[Step 5] Testing port binding..." -ForegroundColor Yellow

$httpListening = Get-NetTCPConnection -LocalPort $HttpPort -State Listen -ErrorAction SilentlyContinue
$serverListening = Get-NetTCPConnection -LocalPort $ServerPort -State Listen -ErrorAction SilentlyContinue
$internetListening = Get-NetTCPConnection -LocalPort $InternetPort -State Listen -ErrorAction SilentlyContinue

if ($httpListening) {
    Write-Host "  ✓ HTTP port $HttpPort is LISTENING!" -ForegroundColor Green
}
else {
    Write-Host "  ✗ HTTP port $HttpPort is NOT listening" -ForegroundColor Red
}

if ($serverListening) {
    Write-Host "  ✓ Server port $ServerPort is LISTENING!" -ForegroundColor Green
}
else {
    Write-Host "  ✗ Server port $ServerPort is NOT listening" -ForegroundColor Red
}

if ($internetListening) {
    Write-Host "  ✓ Internet port $InternetPort is LISTENING!" -ForegroundColor Green
}
else {
    Write-Host "  ✗ Internet port $InternetPort is NOT listening" -ForegroundColor Red
}

Write-Host ""

# Step 6: Check log for errors
Write-Host "[Step 6] Checking log for errors..." -ForegroundColor Yellow
$logFile = "C:\Program Files\UrBackupServer\urbackup.log"
$recentErrors = Get-Content $logFile -Tail 10 | Where-Object { $_ -match "ERROR" }

if ($recentErrors) {
    Write-Host "  Recent errors found:" -ForegroundColor Red
    $recentErrors | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ✓ No recent errors in log" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($httpListening) {
    Write-Host "  SUCCESS!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The UrBackup web interface is now accessible at:" -ForegroundColor White
    Write-Host "  http://localhost:$HttpPort" -ForegroundColor Cyan
    Write-Host ""
    
    # Offer to open browser
    $openBrowser = Read-Host "Would you like to open the web interface in your browser now? (Y/N)"
    if ($openBrowser -eq "Y" -or $openBrowser -eq "y") {
        Start-Process "http://localhost:$HttpPort"
    }
    
}
else {
    Write-Host "  PORTS STILL NOT BINDING" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "The port change did not resolve the issue." -ForegroundColor Yellow
    Write-Host "This suggests the problem is not port-specific." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To restore original ports, run:" -ForegroundColor White
    Write-Host "  Copy-Item '$backupFile' '$argsFile' -Force" -ForegroundColor Gray
    Write-Host "  Restart-Service UrBackupWinServer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor White
    Write-Host "  1. Antivirus software blocking ALL port binding attempts" -ForegroundColor Gray
    Write-Host "  2. Corrupted UrBackup installation" -ForegroundColor Gray
    Write-Host "  3. Missing DLL dependencies" -ForegroundColor Gray
    Write-Host "  4. Security policy blocking the application" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
