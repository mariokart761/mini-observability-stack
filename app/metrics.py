from prometheus_client import Counter, Histogram, Gauge

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status_code"],
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "path"],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)

EXCEPTION_COUNT = Counter(
    "http_exceptions_total",
    "Total unhandled exceptions",
    ["method", "path", "exception_type"],
)

APP_INFO = Gauge(
    "app_info",
    "Application metadata",
    ["app_name", "version"],
)

APP_INFO.labels(app_name="demo-fastapi", version="1.0.0").set(1)
