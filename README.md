# Infrastructure Monitoring Stack

A lightweight, Docker-based infrastructure monitoring solution using **Prometheus**, **Grafana**, **Node Exporter**, and **Alertmanager**. This stack provides real-time visibility into system metrics including CPU, memory, disk usage, and network statistics—ideal for developers, DevOps engineers, and small to medium-scale environments.

---

## Table of Contents

- [Stack Components](#stack-components)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Accessing the Stack](#accessing-the-stack)
- [Grafana Dashboard Setup](#grafana-dashboard-setup)
- [Alertmanager & Slack Notifications](#alertmanager--slack-notifications)
- [Management Commands](#management-commands)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Stack Components

| Component | Purpose | Default Port |
|-----------|---------|--------------|
| **Prometheus** | Metrics collection and time-series database | 9090 |
| **Node Exporter** | Exposes host-level system metrics | 9100 |
| **Grafana** | Visualization and dashboarding platform | 3000 |
| **Alertmanager** | Alerting and notifications | 9093 |

All ports are configurable via the `.env` file.

---


## Prerequisites

- **Operating System**: Linux (Ubuntu recommended)
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Slack Workspace** (Optional): For alert notifications

### Automated Installation

The project includes an automated installation option:

```bash
chmod +x scripts/init-stack.sh
./scripts/init-stack.sh --install-docker
```

This will install both Docker and Docker Compose if not present.

### Slack Webhook Setup (Optional)

If you want to receive alerts via Slack:

1. Follow the comprehensive setup guide in **[docs/slack.md](docs/slack.md)**
2. Keep your webhook URL ready for configuration during setup

### Manual Installation (Ubuntu)

<details>
<summary>Click to expand manual installation steps</summary>

#### Docker Installation
```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
```

#### Docker Compose Installation
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### Verification
```bash
docker --version
docker compose version
```

</details>

---

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/infra-monitoring-stack.git
cd infra-monitoring-stack
```

### 2. Initialize the Stack
```bash
chmod +x scripts/init-stack.sh scripts/docker-stack.sh
./scripts/init-stack.sh
```

This script will:
- Generate `.env` file with default ports and endpoints
- Create Docker secrets in `secrets/` directory
- Generate configuration files in `generated_configs/` from templates

**Optional - Configure Slack Notifications:**

If you set up a Slack webhook (see [Prerequisites](#prerequisites)), update it now:

```bash
# Update webhook URL
echo "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" > secrets/slack_webhook.txt

# Set your alert channel in .env
sed -i 's/SLACK_CHANNEL=.*/SLACK_CHANNEL=#your-channel/' .env
```

### 3. Start the Stack
```bash
./scripts/docker-stack.sh up
```

### 4. Verify Running Containers
```bash
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE                       STATUS    PORTS
<id>           prom/prometheus:latest      Up        0.0.0.0:9090->9090/tcp
<id>           grafana/grafana:latest      Up        0.0.0.0:3000->3000/tcp
<id>           prom/node-exporter:latest   Up        0.0.0.0:9100->9100/tcp
<id>           prom/alertmanager:latest    Up        0.0.0.0:9093->9093/tcp
```

---


## Configuration

### Environment Variables (.env)

The `.env` file is automatically generated but can be customized:

```bash
# Service Ports
PROMETHEUS_PORT=9090
NODE_EXPORTER_PORT=9100
GRAFANA_PORT=3000
ALERTMANAGER_PORT=9093

# Service Endpoints (for Docker internal networking)
PROMETHEUS_ENDPOINT=prometheus
NODE_EXPORTER_ENDPOINT=node-exporter
GRAFANA_ENDPOINT=grafana
ALERTMANAGER_ENDPOINT=alertmanager

# Slack Configuration
SLACK_CHANNEL=#alerts
```

### Secrets Management

Secrets are stored in the `secrets/` directory:

- **grafana_admin_password.txt**: Grafana admin password (default: `admin123`)
- **alertmanager_password.txt**: Alertmanager password (default: `alert123`)
- **slack_webhook.txt**: Slack webhook URL (update with your actual webhook)

**⚠️ Security Warning**: Change default passwords before deploying to production!

### Regenerating Configurations

If you modify templates or environment variables:

```bash
./scripts/init-stack.sh --step=prometheus,alertmanager,alert_rules
./scripts/docker-stack.sh restart
```

---

## Accessing the Stack

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Prometheus** | http://localhost:9090 | None |
| **Node Exporter** | http://localhost:9100/metrics | None |
| **Grafana** | http://localhost:3000 | `admin` / `admin123` |
| **Alertmanager** | http://localhost:9093 | None |

> Replace `localhost` with your server IP if accessing remotely.

---

## Grafana Dashboard Setup

### Step 1: Add Prometheus Data Source

1. Navigate to **Connections** → **Data sources** → **Add data source**
2. Select **Prometheus**
3. Configure:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus:9090`
4. Click **Save & Test**

### Step 2: Import Node Exporter Dashboard

1. Go to **Dashboards** → **Import**
2. Enter Dashboard ID: **1860** (Node Exporter Full)
3. Select your **Prometheus** data source
4. Click **Import**

### Available Metrics

- CPU usage, load average, and core statistics
- Memory and swap utilization
- Disk I/O, space usage, and filesystem stats
- Network traffic and interface statistics
- System uptime and processes

### Recommended Additional Dashboards

- **Docker Monitoring**: Dashboard ID `893`
- **Prometheus Stats**: Dashboard ID `3662`
- **System Overview**: Dashboard ID `11074`

---

## Alertmanager & Slack Notifications

### Setup Slack Notifications

#### 1. Create Slack Channel and Webhook

Follow the comprehensive setup guide in **[docs/slack.md](docs/slack.md)** to create your Slack app and webhook URL.

#### 2. Configure Webhook in Your Stack

Once you have your Webhook URL:

```bash
# Update the webhook secret file
echo "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" > secrets/slack_webhook.txt
```

#### 3. Set Alert Channel

Edit `.env` to specify your Slack channel:

```bash
SLACK_CHANNEL=#alerts
```

#### 4. Apply Configuration

Regenerate Alertmanager config and restart:

```bash
./scripts/init-stack.sh --step=alertmanager
./scripts/docker-stack.sh restart
```

### Alert Rules

Alert rules are defined in `templates/alert_rules.yml.template` and include:

- **InstanceDown**: Service unavailability alerts
- **HighCPUUsage**: CPU threshold alerts
- **HighMemoryUsage**: Memory threshold alerts
- **DiskSpaceLow**: Disk space warnings

Customize alert rules by editing the template and regenerating configs.

---

## Management Commands

### Stack Management

```bash
./scripts/docker-stack.sh up          # Start the stack
./scripts/docker-stack.sh down        # Stop the stack
./scripts/docker-stack.sh restart     # Restart the stack
./scripts/docker-stack.sh status      # Show container status
./scripts/docker-stack.sh logs        # Follow container logs
./scripts/docker-stack.sh clean       # Remove containers and volumes
```

### Configuration Management

```bash
# Regenerate all configurations
./scripts/init-stack.sh

# Regenerate specific configurations
./scripts/init-stack.sh --step=prometheus
./scripts/init-stack.sh --step=alertmanager,alert_rules

# Skip specific steps
./scripts/init-stack.sh --skip=secrets
```

### Docker Commands

```bash
# View logs for specific service
docker logs -f prometheus
docker logs -f grafana

# Monitor resource usage
docker stats

# Access container shell
docker exec -it prometheus sh
```

---

## Troubleshooting

### Prometheus Not Scraping Metrics

1. Check targets: http://localhost:9090/targets
2. Verify all targets show **State: UP**
3. Check Node Exporter:
   ```bash
   curl http://localhost:9100/metrics
   ```

### Grafana Connection Issues

1. Test Prometheus connectivity:
   ```bash
   docker exec grafana curl http://prometheus:9090/-/healthy
   ```

2. Verify data source configuration in Grafana UI

### Port Conflicts

If ports are already in use:

1. Stop conflicting services, or
2. Modify ports in `.env`:
   ```bash
   PROMETHEUS_PORT=9091
   GRAFANA_PORT=3001
   ```
3. Restart stack:
   ```bash
   ./scripts/docker-stack.sh restart
   ```

### Permission Errors

If you encounter permission issues:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Configuration Not Applied

After modifying templates or `.env`:

```bash
./scripts/init-stack.sh --step=prometheus,alertmanager,alert_rules
./scripts/docker-stack.sh restart
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Prometheus](https://prometheus.io/) - Monitoring and alerting toolkit
- [Grafana](https://grafana.com/) - Analytics and visualization platform
- [Node Exporter](https://github.com/prometheus/node_exporter) - Hardware and OS metrics exporter
- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) - Alert handling and routing

---

## Support

For issues, questions, or feature requests, please [open an issue](https://github.com/<your-username>/infra-monitoring-stack/issues) on GitHub.