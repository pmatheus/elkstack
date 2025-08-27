#!/usr/bin/env bash
set -euo pipefail

# Optional bootstrap helper for this ELK+Fleet compose stack.
# - Can start the stack (unless --no-up)
# - Prints live health status for Elasticsearch, Kibana, Fleet Server
# - Exits 0 when all are healthy or non-zero on timeout
#
# Does NOT touch any memory settings.

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--no-up] [--timeout SECONDS] [--interval SECONDS]

Options:
  --no-up            Do not run 'docker compose up -d' (just monitor)
  --timeout SEC      Overall timeout for readiness (default: 1800)
  --interval SEC     Poll interval in seconds (default: 5)
  -h, --help         Show this help

This script prints status for:
  - Elasticsearch HTTPS endpoint
  - Kibana status API (requires elastic superuser)
  - Fleet Server status API

It uses the ports and credentials from your .env. TLS is self-signed; we curl with -k.
EOF
}

NO_UP=0
TIMEOUT=1800
INTERVAL=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-up) NO_UP=1; shift;;
    --timeout) TIMEOUT=${2:-}; shift 2;;
    --interval) INTERVAL=${2:-}; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required but not found in PATH." >&2
  exit 1
fi

# Load .env if present to get ports and passwords
if [[ -f .env ]]; then
  # shellcheck disable=SC2046
  export $(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | xargs -I {} echo {})
fi

: "${ES_PORT:=9200}"
: "${KIBANA_PORT:=5601}"
: "${FLEET_PORT:=8220}"
: "${ELASTIC_PASSWORD:=changeme}"

echo "bootstrap: ES ${ES_PORT}, Kibana ${KIBANA_PORT}, Fleet ${FLEET_PORT}"

if [[ "$NO_UP" -ne 1 ]]; then
  echo "Starting stack with: docker compose up -d"
  docker compose up -d
else
  echo "--no-up set; not starting containers (monitoring only)"
fi

start_ts=$(date +%s)

wait_for() {
  local name="$1"; shift
  local cmd=("$@")
  while true; do
    if "${cmd[@]}" >/dev/null 2>&1; then
      echo "[READY] ${name}"
      return 0
    else
      local now=$(date +%s)
      local elapsed=$(( now - start_ts ))
      if (( elapsed >= TIMEOUT )); then
        echo "[TIMEOUT] ${name} did not become ready in ${TIMEOUT}s" >&2
        return 1
      fi
      echo "[WAIT ] ${name} ... retrying in ${INTERVAL}s"
      sleep "${INTERVAL}"
    fi
  done
}

echo "Checking Elasticsearch readiness..."
wait_for "Elasticsearch HTTPS up" \
  bash -lc "curl -s -k https://localhost:${ES_PORT} | grep -q 'missing authentication credentials'"

echo "Checking Kibana status (requires elastic credentials)..."
wait_for "Kibana overall status available" \
  bash -lc "curl -s -k -u elastic:${ELASTIC_PASSWORD} https://localhost:${KIBANA_PORT}/api/status | grep -q '"overall":{"level":"available"'"

echo "Checking Fleet setup (Kibana Fleet initialization)..."
wait_for "Fleet initialized in Kibana" \
  bash -lc "curl -s -k -u elastic:${ELASTIC_PASSWORD} https://localhost:${KIBANA_PORT}/api/fleet/setup | grep -q '"isInitialized":true'"

echo "Checking Fleet Server health..."
wait_for "Fleet Server HEALTHY" \
  bash -lc "curl -s -k https://localhost:${FLEET_PORT}/api/status | grep -q 'HEALTHY'"

echo "All components are healthy. You can now open Kibana at: https://localhost:${KIBANA_PORT}"
echo "Tip: tail logs with 'docker compose logs -f es01 kibana fleet-server'"

