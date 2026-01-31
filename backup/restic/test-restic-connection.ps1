# Test Restic SFTP Connection

Write-Host "=== Testing Restic SFTP Connection ===" -ForegroundColor Green

$Restic_Path = "C:\Restic\restic.exe"
$Password_File = "C:\Restic\password.txt"
$Remote_Server = "srvdocker02"
$Remote_User = "usdaw"

# Check files exist
Write-Host "1. Checking files..." -ForegroundColor Yellow
if (!(Test-Path $Restic_Path)) {
    Write-Host "   ERROR: Restic not found at $Restic_Path" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Restic found" -ForegroundColor Green

if (!(Test-Path $Password_File)) {
    Write-Host "   ERROR: Password file not found at $Password_File" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Password file found" -ForegroundColor Green

# Test basic Restic
Write-Host "2. Testing Restic..." -ForegroundColor Yellow
try {
    $version = & $Restic_Path version 2>&1
    Write-Host "   ✓ Restic working: $version" -ForegroundColor Green
}
catch {
    Write-Host "   ✗ Restic error: $_" -ForegroundColor Red
    exit 1
}

# Test password file
Write-Host "3. Testing password file..." -ForegroundColor Yellow
$env:RESTIC_PASSWORD_FILE = $Password_File
Write-Host "   Set RESTIC_PASSWORD_FILE=$Password_File" -ForegroundColor Cyan

# Test SSH connection
Write-Host "4. Testing SSH connection..." -ForegroundColor Yellow
try {
    $sshTest = ssh $Remote_User@$Remote_Server "echo 'SSH test successful'" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ SSH connection working" -ForegroundColor Green
    }
    else {
        Write-Host "   ✗ SSH connection failed" -ForegroundColor Red
        Write-Host "   Make sure SSH key is set up: ssh-copy-id usdaw@srvdocker02" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "   ✗ SSH test error: $_" -ForegroundColor Red
    exit 1
}

# Test SFTP directory creation
Write-Host "5. Testing SFTP directory access..." -ForegroundColor Yellow
try {
    $dirTest = ssh $Remote_User@$Remote_Server "mkdir -p /media/backup/test && ls -la /media/backup" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ SFTP directory access working" -ForegroundColor Green
        Write-Host "   Directory listing:" -ForegroundColor Cyan
        Write-Host $dirTest -ForegroundColor Gray
    }
    else {
        Write-Host "   ✗ SFTP directory access failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "   ✗ SFTP test error: $_" -ForegroundColor Red
    exit 1
}

# Test Restic SFTP connection
Write-Host "6. Testing Restic SFTP connection..." -ForegroundColor Yellow

$sftpUrls = @(
    "sftp://$Remote_User@$Remote_Server/media/backup/test-repo",
    "sftp:$Remote_User@$Remote_Server/media/backup/test-repo",
    "$Remote_User@$Remote_Server/media/backup/test-repo"
)

foreach ($url in $sftpUrls) {
    Write-Host "   Testing: $url" -ForegroundColor Cyan
    try {
        # Try to initialize a test repository
        $initResult = & $Restic_Path init --repo $url 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✓ SUCCESS with: $url" -ForegroundColor Green
            Write-Host "   Use this URL format for your backups!" -ForegroundColor Green

            # Clean up test repo
            & $Restic_Path forget --repo $url --keep-daily 0 2>$null
            break
        }
        else {
            Write-Host "   ✗ Failed: $($initResult -join ' ')" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "   ✗ Error: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "If all tests passed, Restic is ready for backup!" -ForegroundColor Green
Write-Host "If SFTP tests failed, check SSH key setup." -ForegroundColor Yellow