#!/usr/bin/env bash
# 大量打 /error，製造高 5xx 錯誤率，觸發 HighErrorRate alert
set -euo pipefail

URL="${1:-http://localhost:8000/error}"
REQUESTS="${2:-300}"

echo "==> Spiking error rate"
echo "    URL      : $URL"
echo "    Requests : $REQUESTS"
echo ""

for i in $(seq 1 "$REQUESTS"); do
  curl -sf "$URL" >/dev/null 2>&1 || true &
  # 每 20 個請求暫停一下，避免 OS 開太多 fd
  if (( i % 20 == 0 )); then
    wait
    echo "    Sent $i / $REQUESTS requests..."
  fi
done

wait
echo "==> Done — check Prometheus/Grafana for HighErrorRate alert"
