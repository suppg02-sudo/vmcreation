# Operational Notes - VM Creation Automation

## Known Pitfalls & Limitations

### 🚨 **Critical Gotchas**

#### 1. **Hyper-V Virtual Switch Requirement**
- **Issue**: Script will fail if "New Virtual Switch" doesn't exist
- **Solution**: Create manually in Hyper-V Manager before running script
- **Command**: `New-VMSwitch -Name "New Virtual Switch" -SwitchType Internal`

#### 2. **QEMU Tools Installation Path**
- **Issue**: Script hardcoded to `C:\Program Files\qemu\qemu-img.exe`
- **Solution**: Ensure QEMU is installed in default location
- **Alternative**: Update script path if QEMU installed elsewhere

#### 3. **Administrator Privileges Required**
- **Issue**: Script fails without admin rights
- **Solution**: Always run as Administrator
- **Check**: Run `whoami /groups | findstr "S-1-5-32-544"` to verify admin status

#### 4. **Generation 1 VM Limitation**
- **Issue**: Ubuntu cloud images work best with Generation 1 VMs
- **Reason**: Cloud images expect BIOS, not UEFI
- **Impact**: Limited to 4 virtual processors on Generation 1 VMs

### ⏱️ **Timing Issues**

#### 1. **Cloud-Init Completion Time**
- **Expected**: 5-10 minutes after VM boot
- **Maximum**: Up to 15 minutes in script
- **Symptoms**: SSH connection refused during this time
- **Resolution**: Wait patiently, script will retry

#### 2. **IP Detection Delays**
- **Issue**: ARP table may not show VM immediately
- **Cause**: DHCP lease time and network discovery
- **Mitigation**: Script uses multiple detection methods

#### 3. **First Boot Variability**
- **Factor**: Network conditions affect boot time
- **Range**: 45 seconds to 3 minutes for initial boot
- **Impact**: IP detection may be delayed accordingly

### 💾 **Storage Considerations**

#### 1. **Disk Space Requirements**
- **Minimum**: 50GB free space (for 50GB VM disk)
- **Recommended**: 100GB+ for safety
- **Issue**: Script will fail if insufficient space
- **Check**: `Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}`

#### 2. **VHDX Compression Issues**
- **Issue**: Compressed VHDX files cause performance problems
- **Solution**: Script runs `compact /u` on directories
- **Warning**: This process can take several minutes

#### 3. **Temporary File Cleanup**
- **Location**: `C:\VMs\images\` for cached cloud images
- **Retention**: Old images kept for 30 days by default
- **Cleanup**: Manual deletion required for disk space recovery

### 🌐 **Network Configuration**

#### 1. **MAC Address Format Mismatch**
- **Issue**: Hyper-V shows colon format, ARP shows dash format
- **Example**: Hyper-V: `00:15:5D:01:5F:24`, ARP: `00-15-5d-01-5f-23`
- **Script Fix**: Handles both formats automatically

#### 2. **Virtual Switch Performance**
- **Issue**: Default virtual switch may have performance limitations
- **Solution**: Consider creating dedicated switch for production
- **Command**: `New-VMSwitch -Name "Production Switch" -SwitchType Internal -NetAdapterName "Ethernet"`

#### 3. **IP Address Conflicts**
- **Risk**: Multiple VMs may get same IP if not properly isolated
- **Prevention**: Each VM gets unique MAC address
- **Resolution**: Restart VM to get new DHCP lease

### 🔐 **Security Considerations**

#### 1. **Default Password Exposure**
- **Risk**: Password "Passw0rd" in user-data file
- **Mitigation**: Change immediately after first login
- **Script Limitation**: Cannot use encrypted passwords with cloud-init

#### 2. **SSH Key Generation**
- **Issue**: First connection generates SSH keys (slow)
- **Impact**: Initial SSH connection may be delayed
- **Workaround**: Pre-generate keys in cloud-init (advanced)

#### 3. **Root Login Security**
- **Risk**: Root login enabled by default
- **Recommendation**: Disable after initial setup
- **Command**: `sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config`

### 🐛 **Common Error Patterns**

#### 1. **"VHDX conversion failed"**
- **Cause**: QEMU tools not installed or wrong path
- **Fix**: Install QEMU in default location or update script
- **Check**: `C:\Program Files\qemu\qemu-img.exe --version`

#### 2. **"VM failed to start"**
- **Cause**: Insufficient memory or processor resources
- **Fix**: Close other applications, reduce VM memory if needed
- **Check**: `Get-VMHost | Select-Object MaximumDynamicMemoryRange`

#### 3. **"SSH connection timeout"**
- **Cause**: Cloud-init still running or network issues
- **Fix**: Wait longer or check VM console for errors
- **Manual**: `ssh -v root@<IP>` for verbose output

#### 4. **"IP address not detected"**
- **Cause**: VM not getting DHCP lease or network misconfiguration
- **Fix**: Check VM network adapter in Hyper-V Manager
- **Manual**: Connect to VM console and run `ip addr show`

### 📊 **Performance Optimizations**

#### 1. **VM Memory Allocation**
- **Default**: 4GB (suitable for most workloads)
- **Increase**: Edit script's `MemoryStartupBytes` parameter
- **Maximum**: Limited by host RAM

#### 2. **Processor Count**
- **Default**: 2 virtual processors
- **Increase**: Edit script's `Set-VMProcessor` line
- **Limitation**: Generation 1 VMs max at 4 processors

#### 3. **Disk Performance**
- **OS Disk**: Fixed 50GB (good performance)
- **Data Disk**: Dynamic 1TB (flexible but slower)
- **Optimization**: Consider fixed-size data disk for production

### 🔧 **Maintenance Tasks**

#### 1. **Regular Image Updates**
- **Frequency**: Monthly recommended
- **Process**: Delete old images, script will download new ones
- **Command**: `Remove-Item "C:\VMs\images\ubuntu-*-cloud.img"`

#### 2. **Log File Management**
- **Location**: `create_ubuntu_vm_improved_log.txt`
- **Retention**: Logs accumulate, manual cleanup needed
- **Archive**: Consider moving old logs to backup location

#### 3. **VM Template Creation**
- **Advanced**: Convert successful VM to template
- **Benefits**: Faster deployment, consistent configuration
- **Process**: Sysprep VM, then use as base image

### 🎯 **Best Practices**

#### 1. **Testing Strategy**
- Always test with simple script first
- Use improved script for production
- Keep logs for debugging

#### 2. **Resource Planning**
- Plan for 50GB+ disk space per VM
- Consider memory requirements
- Monitor host resource usage

#### 3. **Network Isolation**
- Use separate virtual switches for different environments
- Consider VLANs for production networks
- Monitor network traffic patterns

#### 4. **Backup Strategy**
- Regular VM snapshots before major changes
- Export VMs for disaster recovery
- Test restore procedures regularly

### 📞 **Support Escalation**

#### Before Escalating:
1. Check this operational notes document
2. Review runbook-vm-creation.md
3. Examine recent log files
4. Try manual VM creation via Hyper-V Manager

#### Information to Provide:
- VM name and creation time
- Error messages from logs
- Host system specifications
- Network configuration details

#### Common Solutions:
- **80% of issues**: Wait longer for cloud-init completion
- **15% of issues**: Restart VM or check network
- **5% of issues**: Resource constraints or misconfiguration