# platform-infra

Infrastructure repository for local and CI environments.

## Scope
- Docker Compose for local platform
- Shared environment defaults
- Monitoring stack
- Operational runbooks

## Stack in this repo
- Kafka (KRaft, single-node for local development)
- RabbitMQ (management UI)
- PostgreSQL
- Prometheus
- Grafana

## Repository structure
- `docker-compose.yml` - local infrastructure services
- `.env.example` - environment defaults
- `prometheus/prometheus.yml` - scrape config
- `grafana/provisioning/` - datasource and dashboard provisioning
- `grafana/dashboards/platform-overview.json` - baseline dashboard
- `scripts/up.sh` - start platform + run health checks
- `scripts/down.sh` - stop platform
- `scripts/reset.sh` - stop and delete volumes
- `scripts/health-check.sh` - readiness checks

## Quick start

```bash
cp .env.example .env
./scripts/up.sh
```

Services:
- Kafka bootstrap: `localhost:${KAFKA_EXTERNAL_PORT:-29092}`
- RabbitMQ AMQP: `localhost:${RABBITMQ_AMQP_PORT:-5672}`
- RabbitMQ UI: `http://localhost:${RABBITMQ_MANAGEMENT_PORT:-15672}`
- PostgreSQL: `localhost:${POSTGRES_PORT:-5432}`
- Prometheus: `http://localhost:${PROMETHEUS_PORT:-9090}`
- Grafana: `http://localhost:${GRAFANA_PORT:-3000}`

Default Grafana credentials:
- user: `admin`
- password: `admin`

## Health-check scenario

```bash
./scripts/health-check.sh
```

Checks:
- Prometheus health endpoint
- Grafana health endpoint
- RabbitMQ management endpoint
- PostgreSQL port availability
- Kafka external listener port availability

## Stop and reset

```bash
./scripts/down.sh
./scripts/reset.sh
```

## CI smoke startup idea

For CI runner with Docker available:

```bash
docker compose --env-file .env.example up -d
./scripts/health-check.sh
docker compose --env-file .env.example down -v
```

## Notes
- This is intentionally a local-friendly setup for showcase work, not production hardening.
- Kafka runs in single-node mode for developer convenience.
