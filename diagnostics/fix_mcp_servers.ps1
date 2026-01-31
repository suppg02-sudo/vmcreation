# Fix MCP Servers - Install Node.js and required packages

Write-Host "=== MCP SERVER FIX ===" -ForegroundColor Cyan
Write-Host "Installing Node.js and MCP server dependencies..." -ForegroundColor Yellow
Write-Host ""

# Check if Node.js is already installed
Write-Host "1. Checking current Node.js installation..." -ForegroundColor Green
try {
    $nodeVersion = & node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Node.js already installed: $nodeVersion" -ForegroundColor Green
        $skipNodeInstall = $true
    }
}
catch {
    Write-Host "   Node.js not found - will install" -ForegroundColor Yellow
    $skipNodeInstall = $false
}

if (-not $skipNodeInstall) {
    Write-Host ""
    Write-Host "2. Downloading Node.js installer..." -ForegroundColor Green

    # Download Node.js LTS installer
    $nodeUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
    $installerPath = "$env:TEMP\nodejs-installer.msi"

    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -ErrorAction Stop
        Write-Host "   Download complete: $installerPath" -ForegroundColor Green
    }
    catch {
        Write-Host "   Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Please download Node.js manually from https://nodejs.org/" -ForegroundColor Yellow
        exit 1
    }

    Write-Host ""
    Write-Host "3. Installing Node.js..." -ForegroundColor Green
    Write-Host "   This will require administrator privileges..." -ForegroundColor Yellow

    try {
        # Run installer silently
        $installProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru
        if ($installProcess.ExitCode -eq 0) {
            Write-Host "   Node.js installation completed" -ForegroundColor Green
        }
        else {
            Write-Host "   Node.js installation failed (exit code: $($installProcess.ExitCode))" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "   Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    # Clean up installer
    Remove-Item $installerPath -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "4. Refreshing environment PATH..." -ForegroundColor Green
# Refresh PATH for current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host ""
Write-Host "5. Verifying Node.js installation..." -ForegroundColor Green
try {
    $nodeVersion = & node --version 2>$null
    $npmVersion = & npm --version 2>$null
    $npxVersion = & npx --version 2>$null

    Write-Host "   Node.js: $nodeVersion" -ForegroundColor Green
    Write-Host "   npm: v$npmVersion" -ForegroundColor Green
    Write-Host "   npx: v$npxVersion" -ForegroundColor Green
}
catch {
    Write-Host "   Verification failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   You may need to restart PowerShell or your computer" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "6. Installing context7-mcp package..." -ForegroundColor Green
try {
    Write-Host "   Installing @upstash/context7-mcp..." -ForegroundColor Yellow
    & npm install -g @upstash/context7-mcp 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   context7-mcp installed successfully" -ForegroundColor Green
    }
    else {
        Write-Host "   context7-mcp installation failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "   Installation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "7. Testing MCP server..." -ForegroundColor Green
try {
    $testResult = & npx @upstash/context7-mcp --help 2>$null | Select-Object -First 5
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   MCP server test successful" -ForegroundColor Green
    }
    else {
        Write-Host "   MCP server test failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "   Test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Restart VS Code completely" -ForegroundColor White
Write-Host "2. Check VS Code MCP server logs for any remaining issues" -ForegroundColor White
Write-Host "3. The context7 MCP server should now be available" -ForegroundColor White
Write-Host ""
Write-Host "If issues persist:" -ForegroundColor Yellow
Write-Host "- Check VS Code Developer Console (Help > Toggle Developer Tools)" -ForegroundColor White
Write-Host "- Look for MCP-related error messages" -ForegroundColor White
Write-Host "- Verify the .kilocode/mcp.json configuration" -ForegroundColor White

Write-Host ""
Write-Host "=== MCP SERVER FIX COMPLETE ===" -ForegroundColor Cyan