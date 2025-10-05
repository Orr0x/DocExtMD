#!/bin/bash

# VPS Management Script for Markdown Extractor
# Run this script on your Hostinger VPS for ongoing management

set -e  # Exit on any error

# Configuration
PROJECT_DIR="/opt/markdown-extractor"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

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

# Check if running as correct user
check_user() {
    if [[ $EUID -eq 0 ]]; then
        error "Don't run this script as root. Use your regular user account."
    fi

    # Check if user is in docker group
    if ! groups | grep -q docker; then
        warning "User not in docker group. You may need to use sudo for some commands."
    fi
}

# Navigate to project directory
cd_to_project() {
    if [[ ! -d "$PROJECT_DIR" ]]; then
        error "Project directory not found: $PROJECT_DIR"
    fi

    cd "$PROJECT_DIR"
    log "Working in: $(pwd)"
}

# Status check
status() {
    log "🔍 Checking service status..."

    if [[ -f "$COMPOSE_FILE" ]]; then
        docker-compose ps

        # Check if containers are running
        if docker-compose ps | grep -q "Up"; then
            success "Services are running"

            # Show resource usage
            echo ""
            log "📊 Resource usage:"
            docker stats --no-stream markdown-extractor 2>/dev/null || warning "Could not get stats (container might not be running)"

            # Show recent logs
            echo ""
            log "📜 Recent logs:"
            docker-compose logs --tail=5 markdown-extractor
        else
            warning "No services are currently running"
        fi
    else
        error "Docker Compose file not found: $COMPOSE_FILE"
    fi
}

# Start services
start() {
    log "🚀 Starting services..."

    cd_to_project

    if [[ -f "$COMPOSE_FILE" ]]; then
        docker-compose up -d
        success "Services started"

        # Wait a moment and check status
        sleep 3
        status
    else
        error "Docker Compose file not found"
    fi
}

# Stop services
stop() {
    log "⏹️  Stopping services..."

    cd_to_project

    if [[ -f "$COMPOSE_FILE" ]]; then
        docker-compose down
        success "Services stopped"
    else
        error "Docker Compose file not found"
    fi
}

# Restart services
restart() {
    log "🔄 Restarting services..."

    stop
    sleep 2
    start
}

# View logs
logs() {
    log "📜 Showing logs..."

    cd_to_project

    if [[ -f "$COMPOSE_FILE" ]]; then
        if [[ "${1:-}" == "--follow" ]] || [[ "${1:-}" == "-f" ]]; then
            docker-compose logs -f markdown-extractor
        else
            docker-compose logs --tail=50 markdown-extractor
        fi
    else
        error "Docker Compose file not found"
    fi
}

# Update deployment
update() {
    log "🔄 Updating deployment..."

    cd_to_project

    if [[ -f "$COMPOSE_FILE" ]]; then
        log "Pulling latest changes (if using git)..."
        git pull 2>/dev/null || warning "Git not initialized or no remote configured"

        log "Rebuilding and restarting..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d

        success "Deployment updated"

        # Verify
        sleep 5
        status
    else
        error "Docker Compose file not found"
    fi
}

# Backup logs
backup_logs() {
    log "💾 Backing up logs..."

    BACKUP_DIR="$PROJECT_DIR/backups"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    LOG_BACKUP="$BACKUP_DIR/logs_$TIMESTAMP.tar.gz"

    mkdir -p "$BACKUP_DIR"

    # Create backup of logs and important files
    tar -czf "$LOG_BACKUP" \
        -C "$PROJECT_DIR" \
        --exclude="node_modules" \
        --exclude="*.pyc" \
        --exclude="__pycache__" \
        extraction.log 2>/dev/null || true

    success "Logs backed up to: $LOG_BACKUP"
}

# Cleanup old backups
cleanup_backups() {
    log "🧹 Cleaning up old backups..."

    BACKUP_DIR="$PROJECT_DIR/backups"

    if [[ -d "$BACKUP_DIR" ]]; then
        # Keep only last 5 backups
        cd "$BACKUP_DIR"
        ls -t *.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

        REMAINING=$(ls *.tar.gz 2>/dev/null | wc -l)
        success "Cleanup completed. $REMAINING backup(s) remaining"
    else
        warning "No backup directory found"
    fi
}

# System health check
health_check() {
    log "🏥 System health check..."

    echo "=== Docker Status ==="
    systemctl is-active docker || error "Docker service not running"

    echo "=== Disk Usage ==="
    df -h | grep -E "(Filesystem|/dev/)" | head -5

    echo "=== Memory Usage ==="
    free -h

    echo "=== Container Status ==="
    docker-compose ps 2>/dev/null || warning "No docker-compose project found"

    echo "=== Network Connections ==="
    ss -tuln | grep :5000 || warning "No service listening on port 5000"

    success "Health check completed"
}

# Main menu
show_menu() {
    echo -e "${GREEN}"
    echo "🚀 Markdown Extractor - VPS Management"
    echo "====================================="
    echo -e "${NC}"
    echo "1. Status - Check service status and resources"
    echo "2. Start  - Start the services"
    echo "3. Stop   - Stop the services"
    echo "4. Restart - Restart the services"
    echo "5. Logs   - View service logs"
    echo "6. Update - Update and rebuild deployment"
    echo "7. Backup - Backup logs and data"
    echo "8. Health - System health check"
    echo "9. Help   - Show this help"
    echo "0. Exit"
    echo ""
    echo -n "Enter your choice [0-9]: "
}

# Main function
main() {
    check_user

    while true; do
        show_menu
        read -r choice

        case $choice in
            1) status ;;
            2) start ;;
            3) stop ;;
            4) restart ;;
            5)
                echo "View logs:"
                echo "1. Last 50 lines"
                echo "2. Follow logs (Ctrl+C to exit)"
                echo -n "Choice: "
                read -r log_choice
                case $log_choice in
                    1) logs ;;
                    2) logs --follow ;;
                    *) warning "Invalid choice" ;;
                esac
                ;;
            6) update ;;
            7)
                backup_logs
                cleanup_backups
                ;;
            8) health_check ;;
            9)
                echo "Help:"
                echo "  This script manages your Markdown Extractor deployment on the VPS."
                echo "  Use the numbered options above to perform various operations."
                echo ""
                echo "  Keyboard shortcuts:"
                echo "    Ctrl+C - Exit from logs or menus"
                echo "    Enter  - Continue to next step"
                ;;
            0)
                log "👋 Goodbye!"
                exit 0
                ;;
            *)
                warning "Invalid option. Please choose 0-9."
                ;;
        esac

        echo ""
        echo -n "Press Enter to continue..."
        read -r
        clear
    done
}

# Handle script arguments
case "${1:-}" in
    "status")
        check_user
        status
        ;;
    "start")
        check_user
        start
        ;;
    "stop")
        check_user
        stop
        ;;
    "restart")
        check_user
        restart
        ;;
    "logs")
        check_user
        cd_to_project
        logs
        ;;
    "update")
        check_user
        update
        ;;
    "backup")
        check_user
        backup_logs
        cleanup_backups
        ;;
    "health")
        check_user
        health_check
        ;;
    "help"|"-h"|"--help")
        echo "VPS Management Script for Markdown Extractor"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  status    Check service status"
        echo "  start     Start services"
        echo "  stop      Stop services"
        echo "  restart   Restart services"
        echo "  logs      View logs"
        echo "  update    Update deployment"
        echo "  backup    Backup logs"
        echo "  health    System health check"
        echo "  help      Show this help"
        echo ""
        echo "Interactive mode:"
        echo "  $0  (no arguments) - Launch interactive menu"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage information."
        ;;
esac
