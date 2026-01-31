# MCP Server Diagnostics
Write-Host "=== MCP SERVER DIAGNOSTICS ===" -ForegroundColor Cyan

# Check MCP JSON
Write-Host "1. Checking MCP configuration..." -ForegroundColor Green
try {
    $mcp = Get-Content ".kilocode/mcp.json" | ConvertFrom-Json
    Write-Host "   MCP JSON is valid" -ForegroundColor Green
    Write-Host "   Configured servers:" -ForegroundColor White
    $mcp.mcpServers | Get-Member -MemberType NoteProperty | ForEach-Object {
        Write-Host "     - $($_.Name)" -ForegroundColor White
    }
}
catch {
    Write-Host "   MCP JSON error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Check Node.js/npm availability
Write-Host "2. Checking Node.js/npm availability..." -ForegroundColor Green
try {
    $nodeVersion = & node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Node.js available: $nodeVersion" -ForegroundColor Green
    }
    else {
        Write-Host "   Node.js not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "   Node.js check failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $npmVersion = & npm --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   npm available: v$npmVersion" -ForegroundColor Green
    }
    else {
        Write-Host "   npm not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "   npm check failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $npxVersion = & npx --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   npx available: v$npxVersion" -ForegroundColor Green
    }
    else {
        Write-Host "   npx not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "   npx check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Check context7 package
Write-Host "3. Checking context7-mcp package..." -ForegroundColor Green
try {
    $result = & npx @upstash/context7-mcp --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   context7-mcp package available" -ForegroundColor Green
        Write-Host "   Version info: $result" -ForegroundColor White
    }
    else {
        Write-Host "   context7-mcp package not working (exit code: $LASTEXITCODE)" -ForegroundColor Red
    }
}
catch {
    Write-Host "   context7-mcp check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Recommendations
Write-Host "=== RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host "If MCP servers are not working:" -ForegroundColor Yellow
Write-Host "1. Install Node.js from https://nodejs.org/" -ForegroundColor White
Write-Host "2. Verify npm and npx are in PATH" -ForegroundColor White
Write-Host "3. Run: npm install -g @upstash/context7-mcp" -ForegroundColor White
Write-Host "4. Restart VS Code after installation" -ForegroundColor White
Write-Host "5. Check VS Code MCP server logs for errors" -ForegroundColor White

Write-Host ""
Write-Host "=== END MCP DIAGNOSTICS ===" -ForegroundColor Cyan