#!/bin/bash

# Markdown Extractor - Automated Deployment Script for Hostinger VPS
# This script automates the deployment of your Docker-based Markdown Extractor API

set -e  # Exit on any error

# Configuration
PROJECT_NAME="markdown-extractor"
VPS_USER="root"
VPS_HOST="31.97.115.105"
LOCAL_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_PROJECT_DIR="/root/$PROJECT_NAME"

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

# Pre-deployment checks
pre_flight_checks() {
    log "🔍 Running pre-flight checks..."

    # Check if required files exist
    local required_files=("Dockerfile" "docker-compose.yml" "requirements.txt" "api/main.py" "models/")
    for file in "${required_files[@]}"; do
        if [[ ! -e "$LOCAL_PROJECT_DIR/$file" ]]; then
            error "Required file/directory not found: $file"
        fi
    done

    # Check if SSH key exists or password is available
    if [[ ! -f ~/.ssh/id_rsa ]] && [[ -z "$SSH_PASSWORD" ]]; then
        warning "No SSH key found. You'll need to enter password for each SSH connection."
    fi

    # Check Docker installation locally (optional)
    if command -v docker &> /dev/null; then
        log "Docker is available locally"
    else
        warning "Docker not found locally - this is OK for deployment"
    fi

    success "Pre-flight checks completed"
}

# Test SSH connection
test_ssh_connection() {
    log "🔗 Testing SSH connection to $VPS_HOST..."

    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $VPS_USER@$VPS_HOST "echo 'SSH connection successful'"; then
        success "SSH connection established"
    else
        error "Cannot connect to VPS. Please check your SSH credentials and network connection."
    fi
}

# Install Docker on VPS
install_docker_vps() {
    log "🐳 Installing Docker and Docker Compose on VPS..."

    ssh $VPS_USER@$VPS_HOST << 'EOF'
        # Update package list
        sudo apt update

        # Install Docker
        sudo apt install -y docker.io docker-compose

        # Enable and start Docker service
        sudo systemctl enable docker
        sudo systemctl start docker

        # Add user to docker group
        sudo usermod -aG docker $USER

        # Verify installation
        docker --version
        docker-compose --version

        echo "Docker installation completed successfully"
EOF

    success "Docker installed on VPS"
}

# Configure firewall
configure_firewall() {
    log "🔥 Configuring firewall..."

    ssh $VPS_USER@$VPS_HOST << 'EOF'
        # Check current firewall status
        sudo ufw status

        # Allow port 5000 for the API
        sudo ufw allow 5000/tcp

        # Allow SSH (should already be allowed)
        sudo ufw allow 22/tcp

        # Enable firewall if not already enabled
        sudo ufw --force enable

        # Verify rules
        sudo ufw status numbered

        echo "Firewall configured successfully"
EOF

    success "Firewall configured"
}

# Create project directory on VPS
create_project_directory() {
    log "📁 Creating project directory on VPS..."

    ssh $VPS_USER@$VPS_HOST "mkdir -p $REMOTE_PROJECT_DIR"

    success "Project directory created"
}

# Upload project files to VPS
upload_files() {
    log "📤 Uploading project files to VPS..."

    # Use rsync for efficient file transfer
    rsync -avz --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
          -e "ssh -o StrictHostKeyChecking=no" \
          "$LOCAL_PROJECT_DIR/" \
          "$VPS_USER@$VPS_HOST:$REMOTE_PROJECT_DIR/"

    success "Project files uploaded"
}

# Build and start containers
deploy_containers() {
    log "🚀 Building and starting containers..."

    ssh $VPS_USER@$VPS_HOST << EOF
        cd $REMOTE_PROJECT_DIR

        # Build the Docker image
        docker-compose build

        # Start the service in detached mode
        docker-compose up -d

        # Wait a moment for startup
        sleep 5

        # Verify container is running
        docker-compose ps

        echo "Container deployment completed"
EOF

    success "Containers built and started"
}

# Verify deployment
verify_deployment() {
    log "✅ Verifying deployment..."

    # Test health endpoint
    if ssh $VPS_USER@$VPS_HOST "curl -f http://localhost:5000/health" > /dev/null 2>&1; then
        success "Health check passed"

        # Get health response
        HEALTH_RESPONSE=$(ssh $VPS_USER@$VPS_HOST "curl -s http://localhost:5000/health")
        log "Health response: $HEALTH_RESPONSE"
    else
        error "Health check failed. Please check container logs."
    fi

    # Test external access
    if curl -f "http://$VPS_HOST:5000/health" > /dev/null 2>&1; then
        success "External access working"
        log "API accessible at: http://$VPS_HOST:5000"
    else
        warning "External access test failed. Check firewall and port forwarding."
    fi
}

# Main deployment function
main() {
    echo -e "${GREEN}"
    echo "🚀 Markdown Extractor - Automated VPS Deployment"
    echo "==============================================="
    echo -e "${NC}"

    log "Starting deployment to Hostinger VPS ($VPS_HOST)..."

    # Run deployment steps
    pre_flight_checks
    test_ssh_connection
    install_docker_vps
    configure_firewall
    create_project_directory
    upload_files
    deploy_containers
    verify_deployment

    # Final success message
    echo -e "${GREEN}"
    echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "====================================="
    echo -e "${NC}"
    echo "🌐 Your API is now accessible at: http://$VPS_HOST:5000"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Test document conversion: curl -X POST http://$VPS_HOST:5000/convert -F 'file=@yourfile.pdf'"
    echo "   2. Check logs: ssh $VPS_USER@$VPS_HOST 'docker-compose logs -f'"
    echo "   3. Monitor resources: ssh $VPS_USER@$VPS_HOST 'docker stats'"
    echo ""
    echo "🔧 Useful commands:"
    echo "   - Restart: ssh $VPS_USER@$VPS_HOST 'cd $REMOTE_PROJECT_DIR && docker-compose restart'"
    echo "   - Stop: ssh $VPS_USER@$VPS_HOST 'cd $REMOTE_PROJECT_DIR && docker-compose down'"
    echo "   - Update: Upload new files and run 'docker-compose up -d --build'"
}

# Handle script arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Automated deployment script for Markdown Extractor to Hostinger VPS"
        echo ""
        echo "Options:"
        echo "   help, -h, --help    Show this help message"
        echo "   (no args)          Run full deployment"
        echo ""
        echo "Environment Variables:"
        echo "   VPS_HOST           VPS hostname/IP (default: 31.97.115.105)"
        echo "   VPS_USER           SSH username (default: root)"
        echo "   SSH_PASSWORD       SSH password (if no key available)"
        echo ""
        echo "Examples:"
        echo "   $0                                    # Full deployment"
        echo "   VPS_HOST=123.456.789.0 $0            # Deploy to different VPS"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1. Use 'help' for usage information."
        ;;
esac
