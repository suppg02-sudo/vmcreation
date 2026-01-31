# Docker Integration Guide

This guide explains how Docker is integrated into the Ubuntu VM automation and how to use the build selector system.

## 🏗️ How Docker Fits In

The VM creation process automatically installs Docker during cloud-init setup. The `build-selector.sh` script provides three pre-configured Docker Compose stacks to get you started quickly.

### Integration Points

1. **VM Creation**: Docker is installed via cloud-init in `vm-creation/user-data-final`
2. **Build Selector**: `docker/build-selector.sh` - Interactive menu for choosing Docker stacks
3. **Compose Files**: Pre-built configurations in `docker/docker-compose-*.yml`
4. **Setup Script**: `docker/docker-setup.sh` - Manual Docker installation if needed

## 🚀 Using the Build Selector

The build selector (`build-selector.sh`) is copied to the VM during creation and provides three options:

### 1. Personal Build
**Location**: `~/docker/personal/docker-compose.yml`

Includes:
- **Homarr** (Dashboard) - http://VM_IP:7575
- **Dockplay** (Media Server) - http://VM_IP:8080
- **Filebrowser** (File Manager) - http://VM_IP:8081
- **Portainer CE** (Docker Management) - http://VM_IP:9000

### 2. Business Build
**Location**: `~/docker/business/docker-compose.yml`

Includes:
- **Homarr** (Dashboard) - http://VM_IP:7575
- **NocoDB** (Database) - http://VM_IP:8080
- **Nginx** (Web Server) - http://VM_IP
- **Prometheus** (Monitoring) - http://VM_IP:9090

### 3. Custom Build
**Location**: `~/docker/custom/docker-compose.yml`

Starts with a minimal template for you to customize.

## 📁 File Structure

```
docker/
├── build-selector.sh          # Interactive build chooser (runs in VM)
├── docker-setup.sh            # Manual Docker installation
├── docker-compose-personal.yml # Personal stack template
├── docker-compose-business.yml # Business stack template
├── docker-compose-custom.yml   # Custom stack template
└── install_gum.sh             # Installs Gum for beautiful menus
```

## 🔧 Manual Docker Setup

If you need to install Docker manually:

```bash
# Run the setup script
sudo ./docker/docker-setup.sh

# Or install manually
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker
```

## 🎯 Workflow

1. **VM Creation**: Docker installed automatically
2. **SSH to VM**: `ssh root@VM_IP`
3. **Run Build Selector**: `sudo ./build-selector.sh`
4. **Choose Stack**: Personal, Business, or Custom
5. **Access Services**: Use displayed URLs

## 🔄 Managing Containers

```bash
# View running containers
docker ps

# View logs
cd ~/docker/personal  # or business/custom
docker-compose logs

# Stop all containers
docker-compose down

# Start containers
docker-compose up -d

# Update containers
docker-compose pull
docker-compose up -d
```

## 🛠️ Customization

### Adding Services

Edit the appropriate `docker-compose.yml`:

```bash
cd ~/docker/personal
nano docker-compose.yml
# Add your service, then:
docker-compose up -d
```

### Environment Variables

Add environment files:

```bash
cd ~/docker/personal
nano .env
# Add variables like:
# MYSQL_ROOT_PASSWORD=mypassword
```

### Volumes

Data persists in `./service-name/` directories within each Docker folder.

## 🔍 Troubleshooting

### Build Selector Won't Run
```bash
# Make executable
chmod +x build-selector.sh

# Install Gum for better menus
sudo ./install_gum.sh
```

### Containers Won't Start
```bash
# Check logs
docker-compose logs

# Check port conflicts
sudo netstat -tulpn | grep :PORT
```

### Permission Issues
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

## 📊 Monitoring

Use the included monitoring tools:

- **Portainer**: Web UI for Docker management
- **Prometheus**: Metrics collection (Business build)
- **Docker Stats**: `docker stats`

## 🔒 Security Considerations

- Change default passwords immediately
- Use Docker secrets for sensitive data
- Keep containers updated
- Use specific user permissions
- Consider firewall rules for exposed ports

## 📚 Related Documentation

- [Quick Start Guide](quick-start.md) - 5-minute setup
- [VM Creation Runbook](runbook-vm-creation.md) - Detailed VM setup
- [Operational Notes](operational-notes.md) - Troubleshooting
- [Main README](../README.md) - Complete overview