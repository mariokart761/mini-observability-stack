#!/usr/bin/env bash
# 大量打 /slow，製造高延遲，觸發 HighLatencyP95 alert
set -euo pipefail

URL="${1:-http://localhost:8000/slow}"
CONCURRENCY="${2:-8}"

echo "==> Spiking latency"
echo "    URL         : $URL"
echo "    Concurrency : $CONCURRENCY (each waits 2-5s per request)"
echo ""

# 每個 worker 連續打 10 次 /slow (~20-50s 延遲累積)
worker() {
  for _ in $(seq 1 10); do
    curl -sf "$URL" >/dev/null 2>&1 || true
  done
}

for _ in $(seq 1 "$CONCURRENCY"); do
  worker &
done

wait
echo "==> Done — check Prometheus/Grafana for HighLatencyP95 alert"
