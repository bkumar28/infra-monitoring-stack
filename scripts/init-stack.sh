#!/usr/bin/env bash
# =============================================================================
# Script: init-stack.sh
#
# Description:
#   Comprehensive setup script for the Infrastructure Monitoring Stack
#   using Docker, Prometheus, Grafana, Node Exporter, Alertmanager, and Python dev tools.
#
# Features:
#   - Docker & Docker Compose installation (optional)
#   - Generate .env file with configurable ports and endpoints
#   - Create Docker secrets for Grafana, Alertmanager, and Slack webhook
#   - Generate Prometheus configuration from template
#   - Generate Alertmanager configuration from template
#   - Generate Prometheus alert rules from template
#   - All generated configs stored in `generated_configs/`
#
# Usage:
#   ./init-stack.sh [OPTIONS]
#
# Options:
#   --install-docker         Install Docker if missing
#   --step=<step1,step2,...> Run only specific steps
#   --skip=<step1,step2,...> Skip specific steps
#   --help                   Show usage
#
# Example:
#   ./init-stack.sh --install-docker
#   ./init-stack.sh --step=env,secrets
# =============================================================================

set -e

# ------------------------------
# Colors for log output
# ------------------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

# ------------------------------
# Directories and Files
# ------------------------------
ENV_FILE=".env"
SECRETS_DIR="./secrets"
TEMPLATES_DIR="./templates"
GENERATED_DIR="./generated_configs"

PROMETHEUS_TEMPLATE="$TEMPLATES_DIR/prometheus.yml.template"
PROMETHEUS_CONFIG="$GENERATED_DIR/prometheus.yml"

ALERT_TEMPLATE="$TEMPLATES_DIR/alertmanager.yml.template"
ALERT_CONFIG="$GENERATED_DIR/alertmanager.yml"

ALERT_RULES_TEMPLATE="$TEMPLATES_DIR/alert_rules.yml.template"
ALERT_RULES_CONFIG="$GENERATED_DIR/alert_rules.yml"

# ------------------------------
# Step control flags
# ------------------------------
RUN_DOCKER_INSTALL=false
RUN_DOCKER_COMPOSE_INSTALL=false
RUN_ENV_GENERATION=true
RUN_SECRETS_GENERATION=true
RUN_PROMETHEUS_CONFIG=true
RUN_ALERTMANAGER_CONFIG=true
RUN_ALERT_RULES_CONFIG=true

INSTALL_DOCKER=false
STEP_FLAG_PROVIDED=false

# =============================================================================
# Logging functions
# =============================================================================
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# =============================================================================
# Usage
# =============================================================================
show_usage() {
cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
  --install-docker          Install Docker if not present
  
  Step Control (if none specified, all steps run):
  --step=docker,compose,env,secrets,prometheus,alertmanager,alert_rules,all
  --skip=docker,compose,env,secrets,prometheus,alertmanager,alert_rules

  --help                    Show this help message
EOF
}

# =============================================================================
# Parse --step and --skip arguments
# =============================================================================
parse_steps() {
  local steps="$1"
  IFS=',' read -ra STEP_ARRAY <<< "$steps"

  for step in "${STEP_ARRAY[@]}"; do
    case "$step" in
      docker) RUN_DOCKER_INSTALL=true ;;
      compose) RUN_DOCKER_COMPOSE_INSTALL=true ;;
      env) RUN_ENV_GENERATION=true ;;
      secrets) RUN_SECRETS_GENERATION=true ;;
      prometheus) RUN_PROMETHEUS_CONFIG=true ;;
      alertmanager) RUN_ALERTMANAGER_CONFIG=true ;;
      alert_rules) RUN_ALERT_RULES_CONFIG=true ;;
      all)
        RUN_DOCKER_INSTALL=true
        RUN_DOCKER_COMPOSE_INSTALL=true
        RUN_ENV_GENERATION=true
        RUN_SECRETS_GENERATION=true
        RUN_PROMETHEUS_CONFIG=true
        RUN_ALERTMANAGER_CONFIG=true
        RUN_ALERT_RULES_CONFIG=true
        ;;
      *) log_error "Unknown step: $step"; show_usage; exit 1 ;;
    esac
  done
}

skip_steps() {
  local steps="$1"
  IFS=',' read -ra STEP_ARRAY <<< "$steps"

  for step in "${STEP_ARRAY[@]}"; do
    case "$step" in
      docker) RUN_DOCKER_INSTALL=false ;;
      compose) RUN_DOCKER_COMPOSE_INSTALL=false ;;
      env) RUN_ENV_GENERATION=false ;;
      secrets) RUN_SECRETS_GENERATION=false ;;
      prometheus) RUN_PROMETHEUS_CONFIG=false ;;
      alertmanager) RUN_ALERTMANAGER_CONFIG=false ;;
      alert_rules) RUN_ALERT_RULES_CONFIG=false ;;
      *) log_error "Unknown step to skip: $step"; show_usage; exit 1 ;;
    esac
  done
}

# =============================================================================
# Argument parsing
# =============================================================================
for arg in "$@"; do
  case $arg in
    --install-docker) INSTALL_DOCKER=true; shift ;;
    --step=*)
      if [[ "$STEP_FLAG_PROVIDED" = false ]]; then
        RUN_DOCKER_INSTALL=false
        RUN_DOCKER_COMPOSE_INSTALL=false
        RUN_ENV_GENERATION=false
        RUN_SECRETS_GENERATION=false
        RUN_PROMETHEUS_CONFIG=false
        RUN_ALERTMANAGER_CONFIG=false
        RUN_ALERT_RULES_CONFIG=false
        STEP_FLAG_PROVIDED=true
      fi
      parse_steps "${arg#*=}"
      shift
      ;;
    --skip=*)
      skip_steps "${arg#*=}"
      shift
      ;;
    --help) show_usage; exit 0 ;;
    *) log_error "Unknown option: $arg"; show_usage; exit 1 ;;
  esac
done

# =============================================================================
# OS Validation
# =============================================================================
if [[ "$(uname -s)" != "Linux" ]]; then
  log_error "This script supports only Linux."
  exit 1
fi

if ! grep -qi ubuntu /etc/os-release; then
  log_warn "Non-Ubuntu OS detected. Docker installation may require manual steps."
fi

# =============================================================================
# Docker Installation
# =============================================================================
install_docker() {
  log_step "Checking Docker installation..."
  if ! command -v docker &>/dev/null; then
    if [[ "$INSTALL_DOCKER" = true ]]; then
      log_info "Installing Docker..."
      sudo apt update -y
      sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      sudo apt update -y
      sudo apt install -y docker-ce docker-ce-cli containerd.io
      sudo systemctl enable docker
      sudo systemctl start docker
      log_info "Docker installed successfully."
    else
      log_warn "Docker not found. Use --install-docker to install."
    fi
  else
    log_info "Docker is already installed."
  fi
}

# =============================================================================
# Docker Compose Installation
# =============================================================================
install_docker_compose() {
  log_step "Checking Docker Compose..."
  if ! docker compose version &>/dev/null; then
    if [[ "$INSTALL_DOCKER" = true ]]; then
      log_info "Installing Docker Compose..."
      sudo curl -L "https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      log_info "Docker Compose installed successfully."
    else
      log_warn "Docker Compose not found. Use --install-docker to install."
    fi
  else
    log_info "Docker Compose is already installed."
  fi
}

# =============================================================================
# Generate .env file
# =============================================================================
generate_env() {
  log_step "Generating .env file..."
  if [[ -f "$ENV_FILE" ]]; then
      log_warn "$ENV_FILE already exists. Overwriting..."
  fi
  cat > "$ENV_FILE" <<EOF
# Ports
PROMETHEUS_PORT=9090
NODE_EXPORTER_PORT=9100
GRAFANA_PORT=3000
ALERTMANAGER_PORT=9093

# Endpoints
PROMETHEUS_ENDPOINT=prometheus
NODE_EXPORTER_ENDPOINT=node-exporter
GRAFANA_ENDPOINT=grafana
ALERTMANAGER_ENDPOINT=alertmanager

# Slack
SLACK_CHANNEL=#alerts
EOF
  log_info ".env file created/updated."
}

# =============================================================================
# Generate Docker secrets
# =============================================================================
generate_secrets() {
  log_step "Generating secrets..."
  mkdir -p "$SECRETS_DIR"

  [[ -f "$SECRETS_DIR/grafana_admin_password.txt" ]] && log_warn "Grafana secret exists. Overwriting..."
  echo "admin123" > "$SECRETS_DIR/grafana_admin_password.txt"
  log_info "Grafana secret created/updated."

  [[ -f "$SECRETS_DIR/alertmanager_password.txt" ]] && log_warn "Alertmanager secret exists. Overwriting..."
  echo "alert123" > "$SECRETS_DIR/alertmanager_password.txt"
  log_info "Alertmanager secret created/updated."

  [[ -f "$SECRETS_DIR/slack_webhook.txt" ]] && log_warn "Slack webhook secret exists. Overwriting..."
  echo "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX" > "$SECRETS_DIR/slack_webhook.txt"
  log_warn "Slack webhook secret created/updated. Update with real URL."
}

# =============================================================================
# Generate Prometheus config
# =============================================================================
generate_prometheus_config() {
  log_step "Generating Prometheus config..."
  [[ ! -f "$PROMETHEUS_TEMPLATE" ]] && { log_error "Template not found: $PROMETHEUS_TEMPLATE"; exit 1; }
  [[ ! -f "$ENV_FILE" ]] && { log_error ".env missing!"; exit 1; }

  mkdir -p "$GENERATED_DIR"
  set -a; source "$ENV_FILE"; set +a
  envsubst < "$PROMETHEUS_TEMPLATE" > "$PROMETHEUS_CONFIG"
  log_info "Prometheus config generated at $PROMETHEUS_CONFIG"
}

# =============================================================================
# Generate Alertmanager config
# =============================================================================
generate_alertmanager_config() {
  log_step "Generating Alertmanager config..."
  [[ ! -f "$ALERT_TEMPLATE" ]] && { log_error "Template not found: $ALERT_TEMPLATE"; exit 1; }
  [[ ! -f "$ENV_FILE" ]] && { log_error ".env missing!"; exit 1; }

  mkdir -p "$GENERATED_DIR"
  set -a; source "$ENV_FILE"; set +a
  envsubst < "$ALERT_TEMPLATE" > "$ALERT_CONFIG"
  log_info "Alertmanager config generated at $ALERT_CONFIG"
}

# =============================================================================
# Generate Prometheus alert rules
# =============================================================================
generate_alert_rules() {
  log_step "Generating Prometheus alert rules..."
  [[ ! -f "$ALERT_RULES_TEMPLATE" ]] && { log_error "Template not found: $ALERT_RULES_TEMPLATE"; exit 1; }
  [[ ! -f "$ENV_FILE" ]] && { log_error ".env missing!"; exit 1; }

  mkdir -p "$GENERATED_DIR"
  set -a; source "$ENV_FILE"; set +a
  envsubst < "$ALERT_RULES_TEMPLATE" > "$ALERT_RULES_CONFIG"
  log_info "Prometheus alert rules generated at $ALERT_RULES_CONFIG"
}

# =============================================================================
# Main execution
# =============================================================================
log_info "Starting Infrastructure Monitoring setup..."

[[ "$RUN_DOCKER_INSTALL" = true ]] && install_docker
[[ "$RUN_DOCKER_COMPOSE_INSTALL" = true ]] && install_docker_compose
[[ "$RUN_ENV_GENERATION" = true ]] && generate_env
[[ "$RUN_SECRETS_GENERATION" = true ]] && generate_secrets
[[ "$RUN_PROMETHEUS_CONFIG" = true ]] && generate_prometheus_config
[[ "$RUN_ALERTMANAGER_CONFIG" = true ]] && generate_alertmanager_config
[[ "$RUN_ALERT_RULES_CONFIG" = true ]] && generate_alert_rules

log_info "Setup complete! All configs generated in $GENERATED_DIR"
