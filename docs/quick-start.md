# Quick Start Guide (5 Minutes)

Get your Ubuntu VM up and running in under 5 minutes!

## 🚀 Step 1: Create Your VM (2 minutes)

**Run the interactive menu:**
```batch
vmmanager.bat
```

**Choose option 1: "Create New VM"**

The script will:
- Download Ubuntu 24.04 (cached for reuse)
- Create a Hyper-V VM with 4GB RAM, 2 CPUs
- Configure SSH access
- Detect the VM's IP address

**When complete, note the IP address and password shown.**

## 🔐 Step 2: Connect via SSH (1 minute)

```bash
ssh root@<VM_IP_ADDRESS>
# Password: UbuntuVM2024! (or your custom password)
```

**Change the password immediately:**
```bash
passwd root
# Enter new strong password
```

## 💾 Step 3: Set Up Backups (2 minutes)

**From the menu (vmmanager.bat), choose option 2: "Backup Operations"**

**Recommended: Option 1 - Restic Backup**
- Set environment variables (or enter when prompted):
  ```powershell
  $env:BACKUP_SERVER_USER = "your_username"
  $env:BACKUP_SERVER_PASSWORD = "your_password"
  ```
- Run the backup - it will stop/start the VM automatically

## 🐳 Step 4: Choose Your Docker Setup (Optional)

**Inside the VM, run the build selector:**
```bash
sudo ./build-selector.sh
```

Choose:
- **Personal**: Basic development tools
- **Business**: Production-ready stack
- **Custom**: Your own configuration

## ✅ You're Done!

Your VM is ready with:
- ✅ SSH access configured
- ✅ Docker installed and running
- ✅ Automated backups set up
- ✅ Web services accessible via displayed URLs

## 🔍 Troubleshooting

**VM won't start?**
- Run as Administrator
- Verify Hyper-V is enabled
- Check disk space (>50GB free)

**Can't SSH?**
- Wait 10-15 minutes for cloud-init
- Check VM console in Hyper-V Manager
- Run diagnostics: `vmmanager.bat` → Option 4

**Backup fails?**
- Set BACKUP_SERVER_USER and BACKUP_SERVER_PASSWORD
- Ensure SSH access to backup server
- Check firewall settings

## 📚 Next Steps

- Read the full [README.md](../README.md) for advanced features
- Explore [backup options](../backup/) for your needs
- Check [diagnostics](../diagnostics/) for troubleshooting tools
- Review [Docker configurations](../docker/) for custom setups

**Need help?** Run `vmmanager.bat` for the interactive menu with guided options!