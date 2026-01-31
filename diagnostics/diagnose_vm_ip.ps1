# VM IP Diagnosis Script
# Find out why VM IP detection is failing

param(
    [string]$VMName = "ubuntu40"
)

Write-Host "=== VM IP DIAGNOSIS ===" -ForegroundColor Cyan
Write-Host "VM Name: $VMName" -ForegroundColor Yellow
Write-Host "Known IP: 192.168.1.139" -ForegroundColor Yellow
Write-Host ""

try {
    # Step 1: Get VM details
    Write-Host "1. Getting VM details..." -ForegroundColor Green
    $vm = Get-VM -Name $VMName -ErrorAction Stop
    Write-Host "   VM State: $($vm.State)" -ForegroundColor White
    Write-Host "   VM Status: $($vm.Status)" -ForegroundColor White
    
    # Step 2: Get VM MAC address
    Write-Host "2. Getting VM MAC address..." -ForegroundColor Green
    $vmNic = Get-VMNetworkAdapter -VMName $VMName
    $mac = $vmNic.MacAddress
    Write-Host "   MAC Address: $mac" -ForegroundColor White
    
    # Step 3: Format MAC for different standards
    $macFormatted = $mac -replace '(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})', '$1:$2:$3:$4:$5:$6'
    $macDashed = $mac -replace '(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})', '$1-$2-$3-$4-$5-$6'
    Write-Host "   MAC (colon format): $macFormatted" -ForegroundColor White
    Write-Host "   MAC (dash format): $macDashed" -ForegroundColor White
    
    # Step 4: Check ARP table
    Write-Host "3. Checking ARP table..." -ForegroundColor Green
    Write-Host "   Looking for MAC: $macFormatted" -ForegroundColor White
    $arp = arp -a | Select-String -Pattern $macFormatted
    if (-not $arp) {
        Write-Host "   Looking for MAC: $macDashed" -ForegroundColor White
        $arp = arp -a | Select-String -Pattern $macDashed
    }
    
    if ($arp) {
        Write-Host "   ✓ Found in ARP table:" -ForegroundColor Green
        Write-Host "   $arp" -ForegroundColor White
    }
    else {
        Write-Host "   ✗ NOT found in ARP table" -ForegroundColor Red
    }
    
    # Step 5: Show full ARP table for debugging
    Write-Host "4. Full ARP table (first 10 entries):" -ForegroundColor Green
    arp -a | Select-String "192.168.1" | Select-Object -First 10 | ForEach-Object {
        Write-Host "   $($_.Line)" -ForegroundColor Gray
    }
    
    # Step 6: Check if known IP is in ARP table
    Write-Host "5. Checking if known IP (192.168.1.139) is in ARP:" -ForegroundColor Green
    $knownIP = "192.168.1.139"
    $knownArp = arp -a | Select-String $knownIP
    if ($knownArp) {
        Write-Host "   ✓ Known IP found in ARP:" -ForegroundColor Green
        Write-Host "   $knownArp" -ForegroundColor White
        Write-Host "   Associated MAC: $(($knownArp -split '\s+')[1])" -ForegroundColor White
    }
    else {
        Write-Host "   ✗ Known IP NOT found in ARP" -ForegroundColor Red
    }
    
    # Step 7: Test direct connection to known IP
    Write-Host "6. Testing connection to known IP..." -ForegroundColor Green
    if (Test-Connection -ComputerName $knownIP -Count 1 -Quiet) {
        Write-Host "   ✓ IP $knownIP responds to ping" -ForegroundColor Green
    }
    else {
        Write-Host "   ✗ IP $knownIP does NOT respond to ping" -ForegroundColor Red
    }
    
    # Step 8: Check SSH port
    Write-Host "7. Testing SSH port on known IP..." -ForegroundColor Green
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectResult = $tcpClient.BeginConnect($knownIP, 22, $null, $null)
        $waitResult = $connectResult.AsyncWaitHandle.WaitOne(2000, $false)
        if ($waitResult) {
            $tcpClient.EndConnect($connectResult)
            Write-Host "   ✓ SSH port 22 is open on $knownIP" -ForegroundColor Green
            $tcpClient.Close()
        }
        else {
            Write-Host "   ✗ SSH port 22 is NOT open on $knownIP" -ForegroundColor Red
        }
        $tcpClient.Close()
    }
    catch {
        Write-Host "   ✗ Cannot connect to SSH port: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Step 9: Alternative IP detection methods
    Write-Host "8. Alternative IP detection methods..." -ForegroundColor Green
    
    # Method A: KVP Exchange
    try {
        $kvp = Get-VMIntegrationService -VMName $VMName | Where-Object { $_.Name -eq "KVP Exchange" }
        if ($kvp -and $kvp.PrimaryOperationalStatus -eq "Ok") {
            $vmKvp = Get-VM -Name $VMName | Select-Object -ExpandProperty VMNetworkAdapters | Select-Object IPAddresses
            if ($vmKvp.IPAddresses) {
                Write-Host "   KVP IP addresses: $($vmKvp.IPAddresses -join ', ')" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "   KVP method failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Method B: Network scan of subnet
    Write-Host "9. Scanning local subnet for active hosts..." -ForegroundColor Green
    $subnet = "192.168.1."
    $activeIPs = @()
    for ($i = 1; $i -le 254; $i++) {
        $testIP = "$subnet$i"
        if (Test-Connection -ComputerName $testIP -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $activeIPs += $testIP
        }
    }
    Write-Host "   Active IPs found: $($activeIPs -join ', ')" -ForegroundColor White
    
    # Step 10: Recommendations
    Write-Host "=== RECOMMENDATIONS ===" -ForegroundColor Cyan
    if (-not $arp) {
        Write-Host "• ARP table doesn't show VM MAC - VM may not have sent ARP request yet" -ForegroundColor Yellow
        Write-Host "• Wait a few more minutes and run this script again" -ForegroundColor Yellow
    }
    
    if ($knownArp) {
        Write-Host "• Known IP (192.168.1.139) is in ARP table - IP detection should work" -ForegroundColor Green
        Write-Host "• Script should find this IP automatically" -ForegroundColor Green
    }
    
    Write-Host "• Try manual SSH connection: ssh root@192.168.1.139" -ForegroundColor Yellow
    Write-Host "• If SSH works, the script's IP detection logic needs fixing" -ForegroundColor Yellow
    
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== END DIAGNOSIS ===" -ForegroundColor Cyan