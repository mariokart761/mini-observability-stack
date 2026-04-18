#!/usr/bin/env bash
# 持續對 / 發送請求作為 baseline traffic
set -euo pipefail

URL="${1:-http://localhost:8000/}"
CONCURRENCY="${2:-5}"
DURATION="${3:-60}"  # seconds

echo "==> Starting baseline load test"
echo "    URL         : $URL"
echo "    Concurrency : $CONCURRENCY"
echo "    Duration    : ${DURATION}s"
echo ""

end_time=$(( $(date +%s) + DURATION ))

worker() {
  while [ "$(date +%s)" -lt "$end_time" ]; do
    curl -sf "$URL" >/dev/null 2>&1 || true
  done
}

for _ in $(seq 1 "$CONCURRENCY"); do
  worker &
done

wait
echo "==> Done"
