# Fix OpenCode Server Spawn Error
# This script diagnoses and fixes the "Failed to spawn OpenCode Server" error

Write-Host "=== OpenCode Server Diagnostics & Fix ===" -ForegroundColor Cyan
Write-Host ""

# Check if OpenCode is installed
Write-Host "1. Checking OpenCode installation..." -ForegroundColor Green
$opencodePath = "$env:USERPROFILE\.opencode"
if (Test-Path $opencodePath) {
    Write-Host "   OpenCode directory found: $opencodePath" -ForegroundColor Green
}
else {
    Write-Host "   OpenCode directory NOT found!" -ForegroundColor Red
    Write-Host "   This is likely the cause of the spawn error." -ForegroundColor Yellow
}

Write-Host ""

# Check if opencode binary exists
Write-Host "2. Checking OpenCode binary..." -ForegroundColor Green
$opencodeBin = "$opencodePath\bin\opencode"
if (Test-Path $opencodeBin) {
    Write-Host "   OpenCode binary found: $opencodeBin" -ForegroundColor Green
}
else {
    Write-Host "   OpenCode binary NOT found!" -ForegroundColor Red
}

Write-Host ""

# Check port availability
Write-Host "3. Checking port 54720 availability..." -ForegroundColor Green
try {
    $portCheck = Test-NetConnection -ComputerName 127.0.0.1 -Port 54720 -WarningAction SilentlyContinue
    if ($portCheck.TcpTestSucceeded) {
        Write-Host "   WARNING: Port 54720 is already in use!" -ForegroundColor Yellow
        Write-Host "   Kill existing processes or change the port." -ForegroundColor Yellow
    }
    else {
        Write-Host "   Port 54720 is available" -ForegroundColor Green
    }
}
catch {
    Write-Host "   Could not check port status: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Check OpenCode config
Write-Host "4. Checking OpenCode configuration..." -ForegroundColor Green
$configPath = "$env:USERPROFILE\.config\opencode\opencode.json"
if (Test-Path $configPath) {
    Write-Host "   Config file found: $configPath" -ForegroundColor Green
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-Host "   Config is valid JSON" -ForegroundColor Green
        
        # Check for problematic plugins
        if ($config.plugin) {
            Write-Host "   Installed plugins:" -ForegroundColor White
            foreach ($plugin in $config.plugin) {
                Write-Host "     - $plugin" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "   ERROR: Config JSON is invalid!" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "   Config file NOT found!" -ForegroundColor Red
}

Write-Host ""

# Solutions
Write-Host "=== SOLUTIONS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Solution 1: Clear OpenCode cache and restart" -ForegroundColor Yellow
Write-Host "  1. Kill any running opencode processes"
Write-Host "  2. Delete: $opencodePath\.cache" -ForegroundColor White
Write-Host "  3. Delete: $env:USERPROFILE\.config\opencode\opencode-cache.json" -ForegroundColor White
Write-Host "  4. Restart OpenCode" -ForegroundColor White
Write-Host ""

Write-Host "Solution 2: Reinstall OpenCode" -ForegroundColor Yellow
Write-Host "  1. Remove: $opencodePath" -ForegroundColor White
Write-Host "  2. Download fresh OpenCode from: https://opencode.ai/download" -ForegroundColor White
Write-Host "  3. Install and configure" -ForegroundColor White
Write-Host ""

Write-Host "Solution 3: Check browser console" -ForegroundColor Yellow
Write-Host "  1. When OpenCode server starts (port 54720)" -ForegroundColor White
Write-Host "  2. Open browser DevTools (F12)" -ForegroundColor White
Write-Host "  3. Check Console tab for JavaScript errors" -ForegroundColor White
Write-Host "  4. The error 'castError at index-*.js' indicates frontend resource issue" -ForegroundColor White
Write-Host ""

Write-Host "Solution 4: Disable problematic plugins" -ForegroundColor Yellow
Write-Host "  1. Edit: $configPath" -ForegroundColor White
Write-Host "  2. Temporarily remove plugins that may cause conflicts" -ForegroundColor White
Write-Host "  3. Start with minimal config:" -ForegroundColor White
Write-Host '      { ''plugin'': [''oh-my-opencode''] }' -ForegroundColor White
Write-Host ""

Write-Host "=== END DIAGNOSTICS ===" -ForegroundColor Cyan
