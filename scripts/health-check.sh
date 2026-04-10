#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
fi

PROM_PORT="${PROMETHEUS_PORT:-9090}"
GRAFANA_PORT="${GRAFANA_PORT:-3000}"
RABBIT_PORT="${RABBITMQ_MANAGEMENT_PORT:-15672}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
KAFKA_EXT_PORT="${KAFKA_EXTERNAL_PORT:-29092}"

failures=0
MAX_RETRIES="${MAX_RETRIES:-20}"
SLEEP_SECONDS="${SLEEP_SECONDS:-3}"

wait_http() {
  local name="$1"
  local url="$2"
  local attempt=1
  while (( attempt <= MAX_RETRIES )); do
    if curl -fsS "$url" >/dev/null; then
      echo -e "${GREEN}OK${NC}  $name ($url)"
      return 0
    fi
    sleep "$SLEEP_SECONDS"
    attempt=$((attempt + 1))
  done
  echo -e "${RED}FAIL${NC} $name ($url)"
  failures=$((failures + 1))
}

wait_port() {
  local name="$1"
  local host="$2"
  local port="$3"
  local attempt=1
  while (( attempt <= MAX_RETRIES )); do
    if (echo >"/dev/tcp/$host/$port") >/dev/null 2>&1; then
      echo -e "${GREEN}OK${NC}  $name ($host:$port)"
      return 0
    fi
    sleep "$SLEEP_SECONDS"
    attempt=$((attempt + 1))
  done
  echo -e "${RED}FAIL${NC} $name ($host:$port)"
  failures=$((failures + 1))
}

echo -e "${YELLOW}Platform health checks...${NC}"
wait_http "Prometheus" "http://localhost:${PROM_PORT}/-/healthy"
wait_http "Grafana" "http://localhost:${GRAFANA_PORT}/api/health"
wait_http "RabbitMQ management" "http://localhost:${RABBIT_PORT}/api/overview"
wait_port "PostgreSQL" "localhost" "${POSTGRES_PORT}"
wait_port "Kafka external listener" "localhost" "${KAFKA_EXT_PORT}"

if [[ "$failures" -eq 0 ]]; then
  echo -e "${GREEN}All checks passed.${NC}"
  exit 0
fi

echo -e "${RED}$failures checks failed.${NC}"
exit 1
