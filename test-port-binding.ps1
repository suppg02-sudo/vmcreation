# Test if we can bind to ports 55414, 55415, and 55413
# This will help diagnose the UrBackup binding issue

$ports = @(55414, 55415, 55413)
$results = @()

foreach ($port in $ports) {
    try {
        Write-Host "Testing port $port..." -ForegroundColor Cyan
        
        # Try to create a TCP listener on the port
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
        $listener.Start()
        
        Write-Host "✓ Successfully bound to port $port" -ForegroundColor Green
        
        # Close the listener
        $listener.Stop()
        $listener = $null
        
        $results += [PSCustomObject]@{
            Port    = $port
            Status  = "Success"
            Message = "Port is available and can be bound"
        }
    }
    catch {
        Write-Host "✗ Failed to bind to port $port" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        
        $results += [PSCustomObject]@{
            Port    = $port
            Status  = "Failed"
            Message = $_.Exception.Message
        }
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host "`n=== Port Binding Test Results ===" -ForegroundColor White
$results | Format-Table -AutoSize

Write-Host "`n=== Checking for processes using these ports ===" -ForegroundColor White
foreach ($port in $ports) {
    $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connections) {
        Write-Host "Port $port is in use by:" -ForegroundColor Yellow
        $connections | Format-Table State, OwningProcess, LocalAddress, LocalPort -AutoSize
    }
    else {
        Write-Host "Port $port is not in use" -ForegroundColor Green
    }
}
