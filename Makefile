.PHONY: up down logs restart ps test-load test-error test-latency test-log-error clean help

# ── OS detection ───────────────────────────────────────────────────────────────
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
else
    UNAME_S := $(shell uname -s 2>/dev/null)
    ifeq ($(UNAME_S),Linux)
        DETECTED_OS := Linux
    else ifeq ($(UNAME_S),Darwin)
        DETECTED_OS := Mac
    else
        DETECTED_OS := Unknown
    endif
endif

# ── Compose file selection ────────────────────────────────────────────────────
ifeq ($(DETECTED_OS),Linux)
    COMPOSE_FILES := -f docker-compose.yml
else
    COMPOSE_FILES := -f docker-compose.yml -f docker-compose.windows.yml
endif

DC := docker compose $(COMPOSE_FILES)

# ── Core lifecycle ─────────────────────────────────────────────────────────────
up:
	$(DC) up -d --build

down:
	$(DC) down -v

logs:
	$(DC) logs -f app

restart:
	$(DC) restart

ps:
	$(DC) ps

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
	$(DC) down -v --remove-orphans
	docker image prune -f

# ── Help ───────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "Detected OS: $(DETECTED_OS)"
	@echo "Compose files: $(COMPOSE_FILES)"
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