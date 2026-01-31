#Requires -RunAsAdministrator

# VM Log Checker for Ubuntu43
# Check system, startup, and setup logs

param(
    [string]$VMName = "ubuntu43",
    [string]$VMIP = ""
)

Write-Host "=== VM LOG DIAGNOSTICS: $VMName ===" -ForegroundColor Cyan
Write-Host "Checking VM status and providing log access commands..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Check VM status
Write-Host "1. Checking VM status..." -ForegroundColor Green
$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if (-not $vm) {
    Write-Host "   VM '$VMName' not found" -ForegroundColor Red
    Write-Host "   Available VMs:" -ForegroundColor Yellow
    Get-VM | Select-Object Name, State | Format-Table -AutoSize
    exit 1
}
Write-Host "   VM State: $($vm.State)" -ForegroundColor White
Write-Host "   VM Status: $($vm.Status)" -ForegroundColor White

if ($vm.State -ne "Running") {
    Write-Host "   VM is not running. Cannot check logs." -ForegroundColor Red
    Write-Host "   Start the VM first: Start-VM -Name $VMName" -ForegroundColor Yellow
    exit 1
}

# Step 2: Get VM IP if not provided
if (-not $VMIP) {
    Write-Host "2. Detecting VM IP address..." -ForegroundColor Green
    $mac = (Get-VM -Name $VMName | Get-VMNetworkAdapter).MacAddress
    $macFormatted = $mac -replace '(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})', '$1:$2:$3:$4:$5:$6'
    $macDashed = $mac -replace '(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})', '$1-$2-$3-$4-$5-$6'

    $arp = arp -a | Select-String -Pattern $macFormatted
    if (-not $arp) {
        $arp = arp -a | Select-String -Pattern $macDashed
    }

    if ($arp) {
        $arpParts = $arp -split '\s+'
        if ($arpParts.Count -ge 2 -and $arpParts[1] -match '^\d+\.\d+\.\d+\.\d+$') {
            $VMIP = $arpParts[1]
            Write-Host "   IP detected: $VMIP" -ForegroundColor Green
        }
    }

    # If ARP fails, try subnet scan
    if (-not $VMIP) {
        Write-Host "   ARP failed, scanning subnet..." -ForegroundColor Yellow
        $localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "vEthernet (New Virtual Switch)").IPAddress
        if ($localIP) {
            $subnet = $localIP.Substring(0, $localIP.LastIndexOf('.')) + "."

            for ($i = 100; $i -le 200; $i++) {
                $testIP = "$subnet$i"
                if (Test-Connection -ComputerName $testIP -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    $connectResult = $tcpClient.BeginConnect($testIP, 22, $null, $null)
                    $waitResult = $connectResult.AsyncWaitHandle.WaitOne(2000, $false)
                    if ($waitResult) {
                        $tcpClient.EndConnect($connectResult)
                        $VMIP = $testIP
                        Write-Host "   IP found via scan: $VMIP" -ForegroundColor Green
                        $tcpClient.Close()
                        break
                    }
                    $tcpClient.Close()
                }
            }
        }
    }
}

if (-not $VMIP) {
    Write-Host "   Could not detect VM IP address" -ForegroundColor Red
    Write-Host "   Manual IP detection commands:" -ForegroundColor Yellow
    Write-Host "   - arp -a | findstr $macFormatted" -ForegroundColor White
    Write-Host "   - Or check Hyper-V Manager for VM network settings" -ForegroundColor White
    exit 1
}

Write-Host "3. VM IP Address: $VMIP" -ForegroundColor Green
Write-Host ""

# Step 3: Test SSH connectivity
Write-Host "4. Testing SSH connectivity..." -ForegroundColor Green
$sshTest = ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$VMIP "echo 'SSH OK'" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   SSH connection successful" -ForegroundColor Green
}
else {
    Write-Host "   SSH connection failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "   This may be normal if cloud-init is still running" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Provide log checking commands
Write-Host "=== LOG CHECKING COMMANDS ===" -ForegroundColor Cyan
Write-Host "Run these commands in the VM console (Hyper-V Manager) or via SSH:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Cloud-Init Status:" -ForegroundColor Green
Write-Host "   sudo cloud-init status" -ForegroundColor White
Write-Host "   sudo cloud-init status --long" -ForegroundColor White
Write-Host ""

Write-Host "2. Cloud-Init Output Log:" -ForegroundColor Green
Write-Host "   sudo cat /var/log/cloud-init-output.log" -ForegroundColor White
Write-Host "   sudo tail -50 /var/log/cloud-init-output.log" -ForegroundColor White
Write-Host ""

Write-Host "3. SSH Setup Log (if exists):" -ForegroundColor Green
Write-Host "   sudo cat /var/log/ssh-setup.log" -ForegroundColor White
Write-Host ""

Write-Host "4. System Logs:" -ForegroundColor Green
Write-Host "   sudo journalctl --since '1 hour ago' | head -50" -ForegroundColor White
Write-Host "   sudo cat /var/log/syslog | tail -50" -ForegroundColor White
Write-Host ""

Write-Host "5. SSH Service Status:" -ForegroundColor Green
Write-Host "   sudo systemctl status ssh" -ForegroundColor White
Write-Host "   sudo systemctl is-active ssh" -ForegroundColor White
Write-Host "   sudo netstat -tlnp | grep :22" -ForegroundColor White
Write-Host ""

Write-Host "6. SSH Configuration:" -ForegroundColor Green
Write-Host "   sudo cat /etc/ssh/sshd_config | grep -E '(PermitRootLogin|PasswordAuthentication|Port)'" -ForegroundColor White
Write-Host "   sudo sshd -t" -ForegroundColor White
Write-Host ""

Write-Host "7. Firewall Status:" -ForegroundColor Green
Write-Host "   sudo ufw status" -ForegroundColor White
Write-Host ""

Write-Host "8. Root User Status:" -ForegroundColor Green
Write-Host "   sudo cat /etc/passwd | grep root" -ForegroundColor White
Write-Host "   sudo cat /etc/shadow | grep root" -ForegroundColor White
Write-Host ""

# Step 5: Quick diagnostic commands
Write-Host "=== QUICK DIAGNOSTIC SCRIPT ===" -ForegroundColor Cyan
Write-Host "Copy and run this in VM console:" -ForegroundColor Yellow
Write-Host ""
Write-Host "echo '=== QUICK VM DIAGNOSTICS ===' && echo 'Date: '`$(date) && echo 'Hostname: '`$(hostname) && echo 'Uptime: '`$(uptime) && echo '' && echo '=== Cloud-Init Status ===' && sudo cloud-init status 2>/dev/null || echo 'cloud-init command not found' && echo '' && echo '=== SSH Service ===' && sudo systemctl is-active ssh 2>/dev/null || echo 'ssh service check failed' && sudo netstat -tlnp 2>/dev/null | grep :22 || echo 'port 22 not listening' && echo '' && echo '=== SSH Config ===' && sudo grep -E '(PermitRootLogin|PasswordAuthentication)' /etc/ssh/sshd_config 2>/dev/null || echo 'ssh config check failed' && echo '' && echo '=== Firewall ===' && sudo ufw status 2>/dev/null | head -10 || echo 'ufw check failed'" -ForegroundColor White
Write-Host ""

Write-Host "=== TROUBLESHOOTING STEPS ===" -ForegroundColor Cyan
Write-Host "If SSH is not working:" -ForegroundColor Yellow
Write-Host "1. Wait 5-10 more minutes for cloud-init to complete" -ForegroundColor White
Write-Host "2. Check the logs above for errors" -ForegroundColor White
Write-Host "3. Run: sudo systemctl restart ssh" -ForegroundColor White
Write-Host "4. Run: sudo passwd root (set password to: Passw0rd)" -ForegroundColor White
Write-Host "5. Run: sudo ufw allow ssh" -ForegroundColor White
Write-Host "   sudo ufw --force enable" -ForegroundColor White
Write-Host ""

Write-Host "=== END DIAGNOSTICS ===" -ForegroundColor Cyan