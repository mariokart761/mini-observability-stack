#!/usr/bin/env bash
# 多次打 /log-error，製造 error level log 供 Loki 查詢
set -euo pipefail

URL="${1:-http://localhost:8000/log-error}"
REQUESTS="${2:-50}"

echo "==> Emitting error logs"
echo "    URL      : $URL"
echo "    Requests : $REQUESTS"
echo ""

for i in $(seq 1 "$REQUESTS"); do
  curl -sf "$URL" >/dev/null 2>&1 || true &
  if (( i % 10 == 0 )); then
    wait
    echo "    Emitted $i / $REQUESTS log-error events..."
  fi
done

wait
echo "==> Done — search Loki: {service=\"demo-fastapi\"} |= \"simulated application error\""
