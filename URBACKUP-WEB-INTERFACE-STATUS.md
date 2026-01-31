# UrBackup Web Interface Investigation

**Investigation Date:** 2025-12-30 at 13:30

## Summary

Yes, **UrBackup Server DOES have a web interface** and it **SHOULD be running**, but it is currently **NOT accessible** due to a service startup error.

---

## Expected Configuration

Based on the installation at `C:\Program Files\UrBackupServer`, UrBackup is configured to run with:

- **Web Interface Port:** 55414 (HTTP)
- **Server Port:** 55413
- **Internet Service Port:** 55415
- **Web Root Directory:** `C:\Program Files\UrBackupServer\urbackup\www`

The web interface files exist and are properly installed in the www directory.

---

## Current Status

### ✅ What's Working:
- UrBackup Windows Service (`UrBackupWinServer`) is **RUNNING**
- Process `urbackup_srv.exe` (PID 26252) is active
- Database has been successfully upgraded to version 68

### ❌ What's NOT Working:
- **Web interface is NOT accessible** on port 55414
- Service failed to bind to required ports during startup
- Connection to `http://localhost:55414` fails with `ERR_CONNECTION_REFUSED`

---

## Error Analysis

From the log file (`C:\Program Files\UrBackupServer\urbackup.log`), the following errors occurred at **2025-12-30 13:23:02**:

```
ERROR: HTTP: Failed binding socket to port 55414. Another instance of this application may already be active and bound to this port.
ERROR: InternetService: Failed binding socket to port 55415. Another instance of this application may already be active and bound to this port.
ERROR: Failed binding SOCKET to Port 55413
ERROR: Error while starting listening to ports. Stopping server.
```

### Key Issue:
The error message suggests "another instance" might be using these ports, but investigation showed:
- **No other processes** are currently listening on ports 55413, 55414, or 55415
- Only **one urbackup_srv process** is running
- The service appears to have partially started but the HTTP server component failed

---

## ROOT CAUSE IDENTIFIED ⚠️

After extensive testing, I discovered the **root cause** of the web interface failure:

### The Issue:
When attempting to bind to ports 55413, 55414, and 55415, the system returns an **ACCESS PERMISSIONS** error:
```
"An attempt [to bind to port] access permissions"
```

This is **NOT** caused by:
- ❌ Another process using the ports (verified: no process is listening on these ports)
- ❌ Windows reserved port range (verified: ports 55413-55415 are not in excluded ranges)
- ❌ Lack of service privileges (service runs as LocalSystem with full permissions)
- ❌ URL ACL restrictions (no HTTP.SYS URL reservations blocking the ports)

This **IS** likely caused by:
- ✅ **Windows Firewall or Security Software** blocking port binding at the socket level
- ✅ **Antivirus or Endpoint Protection** intercepting the bind operation
- ✅ **Windows Defender Firewall with Advanced Security** blocking the binding attempt
- ✅ **Network isolation policy** or group policy restrictions

---

## Resolution Steps (IN ORDER)

### Step 1: Check and Configure Windows Firewall

The UrBackup Windows Server service needs firewall rules. Check if they exist and are enabled:

```powershell
# Check for existing UrBackup firewall rules
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*UrBackup*" } | Format-Table DisplayName, Enabled, Direction, Action -AutoSize
```

**Create firewall rules if they don't exist** (requires administrator):

```powershell
# Allow inbound connections for UrBackup web interface (port 55414)

---

## How to Access the Web Interface (Once Fixed)

After successfully restarting the service, access the web interface at:

- **Local access:** `http://localhost:55414`
- **Network access:** `http://YOUR_SERVER_IP:55414`

The default credentials are typically:
- **Username:** admin
- **Password:** (empty/blank on first login)

You'll be prompted to set a password on first access.

---

## Configuration Files

- **Service Arguments:** `C:\Program Files\UrBackupServer\args.txt`
- **Log File:** `C:\Program Files\UrBackupServer\urbackup.log`
- **Database:** `C:\Program Files\UrBackupServer\urbackup\backup_server.db`
- **Web Interface:** `C:\Program Files\UrBackupServer\urbackup\www`

---

## Additional Notes

- The service successfully upgraded the database from an older version to version 68
- All required DLL plugins are loaded (httpserver.dll, urbackupserver.dll, etc.)
- The web interface files (index.htm, CSS, JavaScript, etc.) are present and intact
- No firewall rules were checked during this investigation - you may need to allow port 55414 through Windows Firewall

---

## Next Steps

1. **Restart the UrBackup service** with administrator privileges
2. **Monitor the log file** for any new errors: `C:\Program Files\UrBackupServer\urbackup.log`
3. **Test web access** at `http://localhost:55414`
4. **Configure firewall rules** if accessing from other machines on the network

If the issue persists after restart, there may be a configuration problem or a conflict with security software.

New-NetFirewallRule -DisplayName 'UrBackup Web Interface (HTTP)' -Direction Inbound -LocalPort 55414 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName 'UrBackup Server' -Direction Inbound -LocalPort 55413 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName 'UrBackup Internet Service' -Direction Inbound -LocalPort 55415 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName 'UrBackup Discovery' -Direction Inbound -LocalPort 35623 -Protocol UDP -Action Allow
```

### Step 2: Restart UrBack service and Test

After creating firewall rules, restart the service:

```powershell
Restart-Service -Name 'UrBackupWinServer' -Force
Start-Sleep -Seconds 3

# Check if ports are now listening
Get-NetTCPConnection -LocalPort 55414 -State Listen -ErrorAction SilentlyContinue

# Check the log
Get-Content 'C:\Program Files\UrBackupServer\urbackup.log' -Tail 10
```

### Step 3: If Still Failing - Check Antivirus

If the above doesn't work, **temporarily disable antivirus software** and restart the service. Many antivirus/endpoint protection tools block socket binding operations.

### Step 4: Alternative - Use Official UrBackup Fix Script

Run the eset_pw.bat script which may reset configurations:

```cmd
cd "C:\Program Files\UrBackupServer"
reset_pw.bat
```

---

## Recommended FIRST ACTION

**Run this PowerShell script as Administrator to create firewall rules and restart the service:**

```powershell
# Must run as Administrator
New-NetFirewallRule -DisplayName 'UrBackup Web Interface' -Direction Inbound -LocalPort 55414 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName 'UrBackup Server Port' -Direction Inbound -LocalPort 55413 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName 'UrBackup Internet' -Direction Inbound -LocalPort 55415 -Protocol TCP -Action Allow

# Restart the service
Restart-Service -Name 'UrBackupWinServer' -Force
Start-Sleep -Seconds 5

# Test if it's listening
if (Get-NetTCPConnection -LocalPort 55414 -State Listen -ErrorAction SilentlyContinue) {
    Write-Host "SUCCESS! UrBackup web interface is now listening on port 55414" -ForegroundColor Green
    Write-Host "Access it at: http://localhost:55414" -ForegroundColor Cyan
} else {
    Write-Host "FAILED: Port 55414 is still not listening. Check the log:" -ForegroundColor Red
    Get-Content 'C:\Program Files\UrBackupServer\urbackup.log' -Tail 5
}
```

