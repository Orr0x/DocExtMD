#!/bin/bash

# VPS Setup Script for Markdown Extractor
# Run this script directly on your Hostinger VPS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use: sudo $0"
    fi
}

# Install Docker and Docker Compose
install_docker() {
    log "🐳 Installing Docker and Docker Compose..."

    # Update package list
    apt update

    # Install required packages
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up stable repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    # Add current user to docker group
    usermod -aG docker $SUDO_USER

    log "Docker installation completed"
}

# Configure firewall
configure_firewall() {
    log "🔥 Configuring firewall..."

    # Install UFW if not present
    apt install -y ufw

    # Enable UFW
    ufw --force enable

    # Allow SSH
    ufw allow 22/tcp

    # Allow API port
    ufw allow 5000/tcp

    # Show status
    ufw status numbered

    log "Firewall configured"
}

# Create project directory
setup_project() {
    log "📁 Setting up project directory..."

    PROJECT_DIR="/opt/markdown-extractor"

    # Create directory
    mkdir -p "$PROJECT_DIR"

    # Set proper permissions
    chown $SUDO_USER:$SUDO_USER "$PROJECT_DIR"

    log "Project directory created: $PROJECT_DIR"
}

# Main installation function
main() {
    echo -e "${GREEN}"
    echo "🚀 Markdown Extractor - VPS Setup Script"
    echo "======================================"
    echo -e "${NC}"

    log "Starting VPS setup..."

    check_root
    install_docker
    configure_firewall
    setup_project

    echo -e "${GREEN}"
    echo "✅ VPS SETUP COMPLETED SUCCESSFULLY!"
    echo "==================================="
    echo -e "${NC}"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Exit root: exit"
    echo "   2. Upload project files: scp -r /path/to/markdown-extractor root@31.97.115.105:/opt/"
    echo "   3. Navigate to project: cd /opt/markdown-extractor"
    echo "   4. Build and start: docker-compose up -d"
    echo "   5. Test API: curl http://localhost:5000/health"
    echo ""
    echo "🔧 Useful commands:"
    echo "   - Check status: docker-compose ps"
    echo "   - View logs: docker-compose logs -f"
    echo "   - Restart: docker-compose restart"
    echo "   - Stop: docker-compose down"
    echo ""
    echo "🌐 Your API will be accessible at: http://31.97.115.105:5000"
}

# Handle script arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "VPS Setup Script for Markdown Extractor"
        echo ""
        echo "Usage: sudo $0"
        echo ""
        echo "This script will:"
        echo "  1. Install Docker and Docker Compose"
        echo "  2. Configure firewall (ports 22 and 5000)"
        echo "  3. Create project directory"
        echo ""
        echo "After running this script:"
        echo "  1. Upload your project files"
        echo "  2. Run: docker-compose up -d"
        echo "  3. Test: curl http://localhost:5000/health"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1. Use 'help' for usage information."
        ;;
esac
