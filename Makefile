.PHONY: up down logs restart ps test-load test-error test-latency test-log-error clean help

# ── Core lifecycle ─────────────────────────────────────────────────────────────
up:
	docker compose up -d --build

down:
	docker compose down -v

logs:
	docker compose logs -f app

restart:
	docker compose restart

ps:
	docker compose ps

# ── Fault injection ────────────────────────────────────────────────────────────
test-load:
	bash scripts/load_test.sh

test-error:
	bash scripts/spike_errors.sh

test-latency:
	bash scripts/spike_latency.sh

test-log-error:
	bash scripts/spike_log_errors.sh

# ── Housekeeping ───────────────────────────────────────────────────────────────
clean:
	docker compose down -v --remove-orphans
	docker image prune -f

# ── Help ───────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  make up              Start all services (build if needed)"
	@echo "  make down            Stop and remove containers + volumes"
	@echo "  make logs            Tail FastAPI app logs"
	@echo "  make restart         Restart all services"
	@echo "  make ps              Show service status"
	@echo ""
	@echo "  make test-load       Baseline traffic (GET /)"
	@echo "  make test-error      Spike error rate (GET /error)"
	@echo "  make test-latency    Spike latency    (GET /slow)"
	@echo "  make test-log-error  Emit error logs  (GET /log-error)"
	@echo ""
	@echo "  make clean           Remove containers, volumes and dangling images"
	@echo ""
