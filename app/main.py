import logging
import random
import time
import uuid

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

from logging_conf import setup_logging
from metrics import REQUEST_COUNT, REQUEST_LATENCY, EXCEPTION_COUNT

setup_logging()
logger = logging.getLogger("app")

app = FastAPI(title="Demo FastAPI Observability App", version="1.0.0")


@app.middleware("http")
async def observe_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())
    method = request.method
    path = request.url.path
    start = time.perf_counter()
    status_code = 500

    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    except Exception as exc:
        EXCEPTION_COUNT.labels(
            method=method,
            path=path,
            exception_type=type(exc).__name__,
        ).inc()
        logger.exception(
            "unhandled exception",
            extra={"request_id": request_id, "method": method, "path": path},
        )
        raise
    finally:
        duration = time.perf_counter() - start
        REQUEST_COUNT.labels(
            method=method, path=path, status_code=str(status_code)
        ).inc()
        REQUEST_LATENCY.labels(method=method, path=path).observe(duration)

        logger.info(
            "request completed",
            extra={
                "request_id": request_id,
                "service": "demo-fastapi",
                "method": method,
                "path": path,
                "status_code": status_code,
                "latency_ms": round(duration * 1000, 2),
            },
        )


@app.get("/")
async def root():
    return {"message": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/slow")
async def slow():
    delay = random.uniform(2, 5)
    time.sleep(delay)
    return {"message": "slow response", "delay_seconds": round(delay, 2)}


@app.get("/error")
async def error():
    if random.random() < random.uniform(0.3, 0.6):
        return JSONResponse(status_code=500, content={"message": "simulated error"})
    return {"message": "ok"}


@app.get("/log-error")
async def log_error():
    logger.error(
        "simulated application error",
        extra={"service": "demo-fastapi", "event": "manual_error_log"},
    )
    return {"message": "error log emitted"}


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
