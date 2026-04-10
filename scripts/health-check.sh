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

check_http() {
  local name="$1"
  local url="$2"
  if curl -fsS "$url" >/dev/null; then
    echo -e "${GREEN}OK${NC}  $name ($url)"
  else
    echo -e "${RED}FAIL${NC} $name ($url)"
    failures=$((failures + 1))
  fi
}

check_port() {
  local name="$1"
  local host="$2"
  local port="$3"
  if (echo >"/dev/tcp/$host/$port") >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}  $name ($host:$port)"
  else
    echo -e "${RED}FAIL${NC} $name ($host:$port)"
    failures=$((failures + 1))
  fi
}

echo -e "${YELLOW}Platform health checks...${NC}"
check_http "Prometheus" "http://localhost:${PROM_PORT}/-/healthy"
check_http "Grafana" "http://localhost:${GRAFANA_PORT}/api/health"
check_http "RabbitMQ management" "http://localhost:${RABBIT_PORT}/api/overview"
check_port "PostgreSQL" "localhost" "${POSTGRES_PORT}"
check_port "Kafka external listener" "localhost" "${KAFKA_EXT_PORT}"

if [[ "$failures" -eq 0 ]]; then
  echo -e "${GREEN}All checks passed.${NC}"
  exit 0
fi

echo -e "${RED}$failures checks failed.${NC}"
exit 1
