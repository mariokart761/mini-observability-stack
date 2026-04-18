# mini-observability-stack

練手用，一套可本機快速啟動的小型 Observability 平台，以 FastAPI 示範應用為核心，整合 Prometheus、Grafana、Loki、Alloy 與 Alertmanager。

## 架構

```
Client / Load Script
        |
        v
   FastAPI App  ──── stdout JSON logs ────┐
        |                                  │
        │ /metrics                         └──> Grafana Alloy ──> Loki
        v
   Prometheus <──── Node Exporter
        ^
        │
     cAdvisor

Prometheus ── alert rules ──> Alertmanager

Grafana ── query ──> Prometheus / Loki
```

## 元件清單

| 元件 | 用途 | Port |
|------|------|------|
| FastAPI App | Demo web application | 8000 |
| Prometheus | Metrics 收集與 alert rules | 9090 |
| Alertmanager | Alert 分組、去重、路由 | 9093 |
| Grafana | Dashboard 與 log 查詢 | 3000 |
| Loki | Log aggregation | 3100 |
| Grafana Alloy | Log collector（取代 Promtail） | — |
| Node Exporter | 主機 metrics | 9100 |
| cAdvisor | 容器 metrics | 8080 |

## 快速開始

### 前提

- Docker Engine 20.10+
- Docker Compose v2
- `make`
- `curl`（測試腳本用）、`bash`

### 啟動

```bash
# 1. 複製設定
cp .env.example .env

# 2. 一鍵啟動
make up

# 3. 確認所有服務已啟動
make ps
```

### 服務入口

| 服務 | URL | 預設帳密 |
|------|-----|---------|
| FastAPI | http://localhost:8000 | — |
| Prometheus | http://localhost:9090 | — |
| Alertmanager | http://localhost:9093 | — |
| Grafana | http://localhost:3000 | admin / admin |
| Loki（API） | http://localhost:3100 | — |
| cAdvisor | http://localhost:8080 | — |

## FastAPI Endpoints

| Endpoint | 說明 |
|----------|------|
| `GET /` | 正常回應 200 |
| `GET /health` | 健康檢查 |
| `GET /slow` | 隨機 2–5 秒延遲 |
| `GET /error` | 30–60% 機率回 500 |
| `GET /log-error` | 主動寫 error log，回 200 |
| `GET /metrics` | Prometheus metrics |

## Dashboard 說明

Grafana 自動載入三份 dashboard（無須手動匯入）：

### A. Host Overview
- CPU / Memory / Disk 使用率（Gauge）
- Network RX/TX 時間序列
- CPU 使用率趨勢

資料來源：Node Exporter

### B. Container Overview
- 各 container CPU / Memory 時間序列
- Container restart 計數表格
- Top containers by memory 表格
- Container Network I/O

資料來源：cAdvisor

### C. FastAPI App Overview
- Requests per second（依 endpoint 分組）
- 5xx Error rate 時間序列
- P95 / P99 latency（依 endpoint 分組）
- Endpoint 請求量表格
- 最近 15 分鐘 error logs（Loki）

## 故障注入與測試

### 正常 baseline 流量

```bash
make test-load
# 或
bash scripts/load_test.sh http://localhost:8000/ 5 60
```

### 情境 A：高錯誤率（觸發 HighErrorRate alert）

```bash
make test-error
```

預期：
- Grafana「Error Rate」面板 5xx 明顯上升
- Prometheus Alerts → `HighErrorRate` 進入 firing
- Loki 查到大量 status_code=500 records

### 情境 B：高延遲（觸發 HighLatencyP95 alert）

```bash
make test-latency
```

預期：
- Grafana「P95 Latency」面板上升到 2s 以上
- Prometheus Alerts → `HighLatencyP95` 進入 firing

### 情境 C：手動錯誤事件（Loki 查詢練習）

```bash
make test-log-error
```

在 Grafana → Explore → Loki 查詢：

```logql
{service="demo-fastapi"} |= "simulated application error"
```

## 告警規格

| Alert | 條件 | 持續時間 | Severity |
|-------|------|---------|----------|
| HighErrorRate | 5xx ratio > 10% | 2m | warning |
| HighLatencyP95 | P95 latency > 2s | 5m | warning |
| HostCPUHigh | CPU > 80% | 5m | critical |
| ContainerMemoryHigh | Container memory > 85% limit | 5m | warning |

## 排查示範（Metrics → Logs）

1. **開啟 Grafana → C. FastAPI App Overview**
2. 觀察 Error Rate 面板是否上升
3. 找到問題 endpoint（例如 `/error`）
4. 切換到 **Grafana → Explore → Loki**
5. 查詢相關 logs：
   ```logql
   {service="demo-fastapi", level="ERROR"}
   ```
6. 可用 `request_id` 追蹤單次請求完整記錄：
   ```logql
   {service="demo-fastapi"} | json | request_id="<your-id>"
   ```
7. 確認 status_code、latency_ms、path 等欄位，定位根因

## 常用 PromQL 查詢

```promql
# 目前 RPS
sum(rate(http_requests_total[1m]))

# 5xx error rate
sum(rate(http_requests_total{status_code=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))

# P95 latency（依 endpoint）
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path))

# 主機 CPU
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)

# Container memory top 5
topk(5, container_memory_usage_bytes{name!=""})
```

## 停止服務

```bash
make down    # 停止並刪除 containers + volumes
make clean   # 同上，另外清理 dangling images
```

## 後續擴充方向

- **Traces**：整合 Grafana Tempo + OpenTelemetry
- **Kubernetes**：改寫成 Helm chart
- **真實告警通知**：在 `alertmanager/alertmanager.yml` 加入 Slack / PagerDuty webhook
- **高可用**：Prometheus federation、Loki 多副本
