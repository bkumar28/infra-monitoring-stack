# Infrastructure Monitoring Stack

A lightweight, Docker-based infrastructure monitoring solution using **Prometheus**, **Grafana**, and **Node Exporter**. This stack provides real-time visibility into system metrics including CPU, memory, disk usage, and network statistics—ideal for developers, DevOps engineers, and small to medium-scale environments.


---

## Table of Contents

- [Stack Components](#stack-components)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Accessing the Stack](#accessing-the-stack)
- [Grafana Dashboard Setup](#grafana-dashboard-setup)
- [Useful Commands](#useful-commands)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Stack Components

| Component | Purpose | Port |
|-----------|---------|------|
| **Prometheus** | Metrics collection and time-series database | 9090 |
| **Node Exporter** | Exposes host-level system metrics | 9100 |
| **Grafana** | Visualization and dashboarding platform | 3000 |

---

## Features

- **Zero-configuration deployment** with Docker Compose
- **Pre-configured Prometheus** scrape targets
- **Real-time monitoring** of system resources
- **Persistent data storage** for metrics and dashboards
- **Customizable alerting** (Prometheus AlertManager ready)
- **Production-ready** with minimal resource footprint

---

## Prerequisites

Ensure you have the following installed on your system:

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)

Verify your installation:

```bash
docker --version
docker compose version
```

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/infra-monitoring-stack.git
cd infra-monitoring-stack
```

### 2. Start the Stack

```bash
docker compose up -d
```

### 3. Verify Running Containers

```bash
docker ps
```

**Expected output:**

```
CONTAINER ID   IMAGE                    STATUS         PORTS
<id>           prom/prometheus          Up             0.0.0.0:9090->9090/tcp
<id>           grafana/grafana          Up             0.0.0.0:3000->3000/tcp
<id>           prom/node-exporter       Up             0.0.0.0:9100->9100/tcp
```

---

## Accessing the Stack

Once the containers are running, access the following services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Prometheus** | http://localhost:9090 | None |
| **Node Exporter** | http://localhost:9100/metrics | None |
| **Grafana** | http://localhost:3000 | `admin` / `admin` |

> **Security Note**: Change the default Grafana password immediately after first login.

---

## Grafana Dashboard Setup

### Step 1: Add Prometheus Data Source

1. Open Grafana at http://localhost:3000
2. Navigate to **Connections** → **Data sources** → **Add data source**
3. Select **Prometheus**
4. Configure the following:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus:9090`
5. Click **Save & Test** (you should see a green success message)

### Step 2: Import Node Exporter Dashboard

1. Go to **Dashboards** → **Import**
2. Enter Dashboard ID: **1860** (Node Exporter Full)
3. Click **Load**
4. Select your **Prometheus** data source from the dropdown
5. Click **Import**

You'll now see comprehensive system metrics including:
- CPU usage and load average
- Memory and swap utilization
- Disk I/O and space usage
- Network traffic
- System uptime

### Recommended Additional Dashboards

- **Docker Monitoring**: Dashboard ID `893`
- **System Overview**: Dashboard ID `11074`

---

## Useful Commands

### Container Management

```bash
# Stop all containers
docker compose down

# Stop and remove volumes (⚠️ deletes all data)
docker compose down -v

# Restart the stack
docker compose restart

# Restart a specific service
docker compose restart prometheus
```

### Logs and Debugging

```bash
# View logs for all services
docker compose logs -f

# View logs for a specific service
docker logs prometheus
docker logs grafana
docker logs node-exporter

# Follow logs in real-time
docker logs -f prometheus
```

### Resource Monitoring

```bash
# Check container resource usage
docker stats

# Inspect container details
docker inspect prometheus
```

---

## Troubleshooting

### Prometheus Not Scraping Metrics

Check if targets are up:
1. Go to http://localhost:9090/targets
2. Ensure all targets show **State: UP**

If `node-exporter` is down, verify the container is running:
```bash
docker ps | grep node-exporter
```

### Grafana Connection Issues

Verify Prometheus is reachable from Grafana:
```bash
docker exec grafana curl http://prometheus:9090/-/healthy
```

### Port Conflicts

If ports 3000, 9090, or 9100 are already in use, modify the `docker-compose.yml` file to use different ports:
```yaml
ports:
  - "3001:3000"  # Change host port
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Prometheus](https://prometheus.io/) - The monitoring system
- [Grafana](https://grafana.com/) - The visualization platform
- [Node Exporter](https://github.com/prometheus/node_exporter) - Hardware and OS metrics exporter

---
