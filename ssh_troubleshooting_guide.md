# SSH Troubleshooting Guide for Ubuntu Cloud-Init VMs

## Current Status
- VM: ubuntu40
- IP: 192.168.1.39
- Network: ✅ Responding to ping
- SSH: ❌ Connection refused

## Step 1: Check SSH Service Status

```bash
# Connect to VM console (via Hyper-V Manager) and run:
sudo systemctl status ssh
sudo systemctl status sshd

# Check if SSH is installed
which ssh
which sshd
```

## Step 2: Check Cloud-Init Status

```bash
# Check cloud-init completion
sudo cloud-init status

# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log
sudo cat /var/log/cloud-init.log

# Check if cloud-init is still running
ps aux | grep cloud-init
```

## Step 3: Enable SSH Debug Logging

```bash
# Edit SSH daemon configuration
sudo nano /etc/ssh/sshd_config

# Add or modify these lines:
LogLevel DEBUG3
PermitRootLogin yes
PasswordAuthentication yes

# Restart SSH service
sudo systemctl restart ssh
```

## Step 4: Check SSH Daemon Logs

```bash
# View SSH daemon logs in real-time
sudo journalctl -u ssh -f
sudo journalctl -u sshd -f

# Check system logs
sudo tail -f /var/log/syslog | grep ssh
sudo tail -f /var/log/auth.log
```

## Step 5: Manual SSH Service Start

```bash
# If SSH isn't running, start it manually
sudo systemctl start ssh
sudo systemctl enable ssh

# Verify SSH is listening
sudo netstat -tlnp | grep :22
sudo ss -tlnp | grep :22
```

## Step 6: Test SSH Connection with Verbose Output

```bash
# From your Windows machine, run:
ssh -v root@192.168.1.39
ssh -vvv root@192.168.1.39
ssh -o StrictHostKeyChecking=no root@192.168.1.39
```

## Step 7: Verify SSH Configuration

```bash
# Check SSH configuration
sudo sshd -t
sudo sshd -T

# Check if root login is permitted
grep PermitRootLogin /etc/ssh/sshd_config
```

## Step 8: Check Firewall

```bash
# Check UFW firewall status
sudo ufw status

# Allow SSH if blocked
sudo ufw allow ssh
sudo ufw enable
```

## Step 9: Check Network Connectivity Details

```bash
# From VM console, verify network interface
ip addr show
ip route show

# Test local SSH
ssh localhost
ssh root@localhost
```

## Common Solutions

### If Cloud-Init is Still Running:
```bash
# Wait for completion
sudo cloud-init status --long
sudo cloud-init init
```

### If SSH Service Failed to Start:
```bash
# Reconfigure SSH
sudo dpkg-reconfigure openssh-server
sudo systemctl restart ssh
```

### If Root Login is Disabled:
```bash
# Edit SSH config
sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### If Password Authentication is Disabled:
```bash
# Edit SSH config
sudo sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

## Quick Fix Commands

If you want to quickly fix SSH access, run these in the VM console:

```bash
# Enable SSH and root login
sudo systemctl enable ssh
sudo systemctl start ssh
sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Set root password
sudo passwd root

# Allow SSH through firewall
sudo ufw allow ssh
```

## Testing SSH Access

Once SSH is working, test from your Windows machine:

```bash
# Basic connection test
ssh root@192.168.1.39
# Password: (your chosen root password)

# Test with specific options
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@192.168.1.39 "echo 'SSH working!'"

# File transfer test
echo "test" | ssh root@192.168.1.39 "cat > /tmp/test.txt"