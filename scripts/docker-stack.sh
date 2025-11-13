#!/bin/bash
# -----------------------------------------------------------------------------
# Script: docker-stack.sh
#
# Description:
#   Comprehensive Docker management script for the Infrastructure Monitoring Stack
#   (Prometheus, Grafana, Node Exporter, Alertmanager).
#
#   This script handles:
#     - Building Docker containers
#     - Starting and stopping the stack
#     - Restarting containers
#     - Viewing logs and container status
#     - Cleaning containers and volumes
#     - Full setup including .env, secrets, and config generation
#
# Requirements:
#   - Docker must be installed and running
#   - Docker Compose must be installed
#   - Scripts for generating .env and configs must be present in ./scripts/
#
# Usage:
#   ./docker-stack.sh build         # Build Docker containers
#   ./docker-stack.sh up            # Start containers in detached mode
#   ./docker-stack.sh down          # Stop and remove containers
#   ./docker-stack.sh restart       # Restart containers
#   ./docker-stack.sh logs          # Follow container logs
#   ./docker-stack.sh status        # Show container status
#   ./docker-stack.sh clean         # Remove containers, volumes, and orphaned resources
#   ./docker-stack.sh full-setup    # Complete setup: generate .env, secrets, configs, start stack
#   ./docker-stack.sh help          # Show this help message
# -----------------------------------------------------------------------------

set -e

COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# -------------------------
# Colors for output
# -------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -------------------------
# Output helper functions
# -------------------------
print_status()  { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# -------------------------
# Check if Docker is running
# -------------------------
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# -------------------------
# Docker management functions
# -------------------------
build_containers() {
    print_status "Building Docker containers..."
    docker compose -f "$COMPOSE_FILE" build
    print_success "Containers built successfully."
}

start_containers() {
    print_status "Starting Docker containers..."
    docker compose -f "$COMPOSE_FILE" up -d
    sleep 5
    print_success "Containers started."
}

stop_containers() {
    print_status "Stopping Docker containers..."
    docker compose -f "$COMPOSE_FILE" down
    print_success "Containers stopped."
}

restart_containers() {
    print_status "Restarting Docker containers..."
    stop_containers
    start_containers
}

view_logs() {
    print_status "Displaying container logs..."
    docker compose -f "$COMPOSE_FILE" logs -f
}

check_status() {
    print_status "Container status:"
    docker compose -f "$COMPOSE_FILE" ps
}

clean_containers() {
    print_warning "This will remove containers, networks, and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
        docker system prune -f
        print_success "Cleanup completed."
    else
        print_status "Cleanup cancelled."
    fi
}

# -------------------------
# Full setup function
# -------------------------
full_setup() {
    print_status "Running full setup..."

    check_docker

    # Generate .env if missing
    if [ ! -f "$ENV_FILE" ]; then
        print_status "Generating .env file..."
        ./scripts/generate-env.sh
    fi

    # Generate Prometheus and Alertmanager configs from templates
    print_status "Generating Prometheus and Alertmanager configs..."
    ./scripts/generate-prometheus-config.sh
    ./scripts/generate-alertmanager-config.sh

    # Create secrets folder if missing
    mkdir -p secrets
    if [ ! -f secrets/grafana_admin_password.txt ]; then
        echo "admin" > secrets/grafana_admin_password.txt
        print_status "Created Grafana admin password secret (default: admin)"
    fi
    if [ ! -f secrets/alertmanager_password.txt ]; then
        echo "alertmanager" > secrets/alertmanager_password.txt
        print_status "Created Alertmanager password secret (default: alertmanager)"
    fi
    if [ ! -f secrets/slack_webhook ]; then
        echo "YOUR_SLACK_WEBHOOK_URL" > secrets/slack_webhook
        print_status "Created Slack webhook secret (edit with actual webhook URL)"
    fi

    # Start the stack
    start_containers

    print_success "Full setup completed! Access services at the ports defined in .env"
}

# -------------------------
# Show help
# -------------------------
show_help() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  build        Build Docker containers"
    echo "  up           Start containers in detached mode"
    echo "  down         Stop and remove containers"
    echo "  restart      Restart containers"
    echo "  logs         View container logs"
    echo "  status       Show container status"
    echo "  clean        Clean containers and volumes"
    echo "  full-setup   Complete setup: .env, secrets, configs, start stack"
    echo "  help         Show this help message"
}

# -------------------------
# Main execution
# -------------------------
main() {
    CMD="${1:-help}"

    case "$CMD" in
        build) check_docker; build_containers ;;
        up) check_docker; start_containers ;;
        down) check_docker; stop_containers ;;
        restart) check_docker; restart_containers ;;
        logs) check_docker; view_logs ;;
        status) check_docker; check_status ;;
        clean) check_docker; clean_containers ;;
        full-setup) full_setup ;;
        help|--help|-h) show_help ;;
        *) print_error "Unknown command: $CMD"; show_help ;;
    esac
}

# Run main function
main "$@"
