#!/usr/bin/env bash
# 持續打 /error，一段時間內維持高 5xx 比例，觸發 HighErrorRate alert
set -euo pipefail

URL="${1:-http://localhost:8000/error}"
DURATION_SECONDS="${2:-120}"   # 預設持續 2 分鐘
CONCURRENCY="${3:-20}"         # 每秒平行請求數
SLEEP_SECONDS="${4:-1}"        # 每輪間隔秒數

echo "==> Sustaining high error rate"
echo "    URL         : $URL"
echo "    Duration    : ${DURATION_SECONDS}s"
echo "    Concurrency : $CONCURRENCY"
echo "    Interval    : ${SLEEP_SECONDS}s"
echo ""

end_time=$((SECONDS + DURATION_SECONDS))
round=0
sent=0

while (( SECONDS < end_time )); do
  round=$((round + 1))

  for _ in $(seq 1 "$CONCURRENCY"); do
    curl -sf "$URL" >/dev/null 2>&1 || true &
  done

  wait
  sent=$((sent + CONCURRENCY))

  remaining=$((end_time - SECONDS))
  if (( remaining < 0 )); then
    remaining=0
  fi

  echo "    Round $round sent=$sent remaining=${remaining}s"
  sleep "$SLEEP_SECONDS"
done

echo ""
echo "==> Done"
echo "    Total requests sent: $sent"
echo "    Now check Prometheus alerts / Alertmanager"