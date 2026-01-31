#!/bin/bash
# Build Selector Script
# Allows user to choose between Personal and Business Docker builds

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please run docker-setup.sh first."
        exit 1
    fi

    if ! systemctl is-active --quiet docker; then
        warn "Docker service is not running. Starting it..."
        sudo systemctl start docker
    fi

    info "Docker is ready: $(docker --version)"
}

# Display build options
show_menu() {
    # Check if Gum is available for beautiful menus
    if command -v gum &> /dev/null; then
        echo
        gum style --border rounded --padding "1 2" --border-foreground 6 "Ubuntu VM Docker Build Selector"
        echo

        CHOICE=$(gum choose \
            "Personal Build - Homarr + Media Stack" \
            "Business Build - Homarr + Business Apps" \
            "Custom Build - Empty Docker setup" \
            "Exit")

        case "$CHOICE" in
            "Personal Build - Homarr + Media Stack") choice=1 ;;
            "Business Build - Homarr + Business Apps") choice=2 ;;
            "Custom Build - Empty Docker setup") choice=3 ;;
            "Exit") choice=4 ;;
            *) choice="" ;;
        esac

        # If Gum selection worked, return early
        if [[ -n "$choice" ]]; then
            return
        fi
    fi

    # Fallback to traditional menu
    echo
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Ubuntu VM Docker Build Selector${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
    echo -e "${YELLOW}Choose your build type:${NC}"
    echo
    echo -e "${GREEN}1) Personal Build${NC}"
    echo "   - Homarr (Dashboard)"
    echo "   - Dockplay (Media Server)"
    echo "   - Filebrowser (File Manager)"
    echo "   - Portainer CE (Docker Management)"
    echo
    echo -e "${BLUE}2) Business Build${NC}"
    echo "   - Homarr (Dashboard)"
    echo "   - NocoDB (Database Management)"
    echo "   - Nginx (Web Server)"
    echo "   - Prometheus (Monitoring)"
    echo
    echo -e "${PURPLE}3) Custom Build${NC}"
    echo "   - Start with minimal setup"
    echo "   - Add your own containers"
    echo
    echo -e "${RED}4) Exit${NC}"
    echo
}

# Personal Build Setup
setup_personal() {
    log "Setting up Personal Build..."

    # Create docker-compose directory
    mkdir -p ~/docker/personal
    cd ~/docker/personal

    # Create docker-compose.yml for Personal Build
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr
    ports:
      - "7575:7575"
    volumes:
      - ./homarr/configs:/app/data/configs
      - ./homarr/icons:/app/public/icons
      - ./homarr/data:/data
    restart: unless-stopped
    networks:
      - personal-network

  dockplay:
    image: dockplay/dockplay:latest
    container_name: dockplay
    ports:
      - "8080:8080"
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./dockplay/config:/config
      - ./dockplay/media:/media
    restart: unless-stopped
    networks:
      - personal-network

  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    ports:
      - "8081:80"
    volumes:
      - ./filebrowser/root:/srv
      - ./filebrowser/config:/config
    environment:
      - FB_BASEURL=/filebrowser
    restart: unless-stopped
    networks:
      - personal-network

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer/data:/data
    restart: unless-stopped
    networks:
      - personal-network

networks:
  personal-network:
    driver: bridge
EOF

    # Create data directories
    mkdir -p homarr/{configs,icons,data}
    mkdir -p dockplay/{config,media}
    mkdir -p filebrowser/{root,config}
    mkdir -p portainer/data

    # Start the services
    log "Starting Personal Build containers..."
    docker-compose up -d

    success "Personal Build setup complete!"
    echo
    echo -e "${GREEN}Access your services:${NC}"
    echo -e "  Homarr Dashboard:    http://$(hostname -I | awk '{print $1}'):7575"
    echo -e "  Dockplay Media:      http://$(hostname -I | awk '{print $1}'):8080"
    echo -e "  Filebrowser:         http://$(hostname -I | awk '{print $1}'):8081"
    echo -e "  Portainer:           http://$(hostname -I | awk '{print $1}'):9000"
    echo
    echo -e "${YELLOW}To add more containers, edit ~/docker/personal/docker-compose.yml${NC}"
}

# Business Build Setup
setup_business() {
    log "Setting up Business Build..."

    # Create docker-compose directory
    mkdir -p ~/docker/business
    cd ~/docker/business

    # Create docker-compose.yml for Business Build
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr-business
    ports:
      - "7575:7575"
    volumes:
      - ./homarr/configs:/app/data/configs
      - ./homarr/icons:/app/public/icons
      - ./homarr/data:/data
    restart: unless-stopped
    networks:
      - business-network

  nocodb:
    image: nocodb/nocodb:latest
    container_name: nocodb
    ports:
      - "8080:8080"
    environment:
      - NC_DB=sqlite3:///data/nocodb.db
    volumes:
      - ./nocodb/data:/usr/app/data
    restart: unless-stopped
    networks:
      - business-network

  nginx:
    image: nginx:alpine
    container_name: nginx-business
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/html:/usr/share/nginx/html
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
    restart: unless-stopped
    networks:
      - business-network

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - business-network

networks:
  business-network:
    driver: bridge
EOF

    # Create Prometheus config
    mkdir -p prometheus
    cat > prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

    # Create Nginx config
    mkdir -p nginx/{html,conf.d,ssl}
    cat > nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://homarr:7575;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /nocodb/ {
        proxy_pass http://nocodb:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /prometheus/ {
        proxy_pass http://prometheus:9090/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Create data directories
    mkdir -p homarr/{configs,icons,data}
    mkdir -p nocodb/data
    mkdir -p prometheus/data

    # Start the services
    log "Starting Business Build containers..."
    docker-compose up -d

    success "Business Build setup complete!"
    echo
    echo -e "${GREEN}Access your services:${NC}"
    echo -e "  Homarr Dashboard:    http://$(hostname -I | awk '{print $1}'):7575"
    echo -e "  NocoDB Database:     http://$(hostname -I | awk '{print $1}'):8080"
    echo -e "  Nginx Web Server:    http://$(hostname -I | awk '{print $1}')"
    echo -e "  Prometheus:          http://$(hostname -I | awk '{print $1}'):9090"
    echo
    echo -e "${YELLOW}To add more containers, edit ~/docker/business/docker-compose.yml${NC}"
}

# Custom Build Setup
setup_custom() {
    log "Setting up Custom Build..."

    # Create docker-compose directory
    mkdir -p ~/docker/custom
    cd ~/docker/custom

    # Create minimal docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Add your custom containers here
  # Example:
  # web:
  #   image: nginx:alpine
  #   ports:
  #     - "80:80"

networks:
  custom-network:
    driver: bridge
EOF

    success "Custom Build setup complete!"
    echo
    echo -e "${YELLOW}Edit ~/docker/custom/docker-compose.yml to add your containers${NC}"
    echo -e "${YELLOW}Then run: cd ~/docker/custom && docker-compose up -d${NC}"
}

# Main menu loop
main() {
    check_docker

    while true; do
        show_menu

        # If Gum was used and choice is already set, skip read
        if [[ -z "${choice:-}" ]]; then
            read -p "Enter your choice (1-4): " choice
        fi

        case $choice in
            1|"Personal Build - Homarr + Media Stack")
                setup_personal
                break
                ;;
            2|"Business Build - Homarr + Business Apps")
                setup_business
                break
                ;;
            3|"Custom Build - Empty Docker setup")
                setup_custom
                break
                ;;
            4|"Exit")
                info "Exiting build selector."
                exit 0
                ;;
            *)
                error "Invalid choice. Please select 1-4."
                unset choice  # Reset for next iteration
                sleep 2
                ;;
        esac
    done

    log "Build setup completed successfully!"
    info "Your Docker containers are now running."
    info "Use 'docker ps' to see running containers."
    info "Use 'docker-compose logs' to view container logs."
}

# Run main function
main "$@"