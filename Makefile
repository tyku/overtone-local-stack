COMPOSE := docker compose
PROFILE ?= mock
REBUILD ?= 0
BUILD_FLAGS ?=
UP_FLAGS ?= -d
BUILD_SERVICES ?=
UP_SERVICES ?=
SERVICE ?=

.PHONY: up up-gpu _up infra app frontend smoke-overtone build down logs ps config

up:
	@$(MAKE) _up PROFILE=mock OTHER_PROFILE=gpu

up-gpu:
	@$(MAKE) _up PROFILE=gpu OTHER_PROFILE=mock

_up:
	@$(COMPOSE) --profile $(OTHER_PROFILE) stop inference-$(OTHER_PROFILE) >/dev/null 2>&1 || true
	@$(COMPOSE) --profile $(OTHER_PROFILE) rm -f inference-$(OTHER_PROFILE) >/dev/null 2>&1 || true
	@if [ "$(REBUILD)" = "1" ] || [ "$(REBUILD)" = "true" ] || [ "$(REBUILD)" = "yes" ]; then \
		$(COMPOSE) --profile $(PROFILE) build $(BUILD_FLAGS) $(BUILD_SERVICES); \
	fi
	@$(COMPOSE) --profile $(PROFILE) up $(UP_FLAGS) $(UP_SERVICES)

infra:
	@$(COMPOSE) up $(UP_FLAGS) postgres redis minio minio-init

app:
	@$(COMPOSE) up $(UP_FLAGS) api worker frontend-assets nginx

frontend:
	@$(COMPOSE) build $(BUILD_FLAGS) frontend-assets
	@$(COMPOSE) rm -f frontend-assets >/dev/null 2>&1 || true
	@$(COMPOSE) up $(UP_FLAGS) frontend-assets nginx

smoke-overtone:
	@sh ./scripts/smoke-overtone.sh

build:
	@$(COMPOSE) --profile $(PROFILE) build $(BUILD_FLAGS) $(BUILD_SERVICES)

down:
	@$(COMPOSE) --profile mock --profile gpu down

logs:
	@$(COMPOSE) --profile mock --profile gpu logs -f $(SERVICE)

ps:
	@$(COMPOSE) --profile mock --profile gpu ps

config:
	@$(COMPOSE) --profile $(PROFILE) config --quiet
