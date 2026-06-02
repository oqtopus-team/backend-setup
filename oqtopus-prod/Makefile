SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

.PHONY: up-core stop-core restart-core logs-core rm-core build-core exec-core
.PHONY: up-mitigator stop-mitigator restart-mitigator logs-mitigator rm-mitigator build-mitigator exec-mitigator
.PHONY: up-estimator stop-estimator restart-estimator logs-estimator rm-estimator build-estimator exec-estimator
.PHONY: up-combiner stop-combiner restart-combiner logs-combiner rm-combiner build-combiner exec-combiner
.PHONY: build-sse_runtime up-sse_engine stop-sse_engine restart-sse_engine logs-sse_engine rm-sse_engine build-sse_engine exec-sse_engine
.PHONY: up-tranqu stop-tranqu restart-tranqu logs-tranqu rm-tranqu build-tranqu exec-tranqu
.PHONY: up-gateway stop-gateway restart-gateway logs-gateway rm-gateway build-gateway exec-gateway show-current-status change-status-to-active change-status-to-inactive change-status-to-maintenance generate-device-topology
.PHONY: ps up down images help

ENV_FILE := ./config/.env
include $(ENV_FILE)

# MONITORING_ENABLED=true → enable Docker Compose monitoring profile
ifeq ($(MONITORING_ENABLED),true)
export COMPOSE_PROFILES := monitoring
endif

COMPOSE := docker compose --env-file $(ENV_FILE)

# ------------------
# core
# ------------------
up-core: ## start core
	$(COMPOSE) up -d core

stop-core: ## stop core
	$(COMPOSE) stop core

restart-core: stop-core up-core ## restart core

logs-core: ## show core logs
	$(COMPOSE) logs core

rm-core: ## remove core
	$(COMPOSE) rm core

build-core: ## build core
	cd core && \
	git pull && \
	cd .. && \
	$(COMPOSE) build core

exec-core: ## execute core
	$(COMPOSE) exec core bash

# ------------------
# sse_engine
# ------------------
up-sse_engine: ## start sse_engine
	$(COMPOSE) up -d sse_engine

stop-sse_engine: ## stop sse_engine
	$(COMPOSE) stop sse_engine

restart-sse_engine: stop-sse_engine up-sse_engine ## restart sse_engine

logs-sse_engine: ## show sse_engine logs
	$(COMPOSE) logs sse_engine

rm-sse_engine: ## remove sse_engine
	$(COMPOSE) rm sse_engine

build-sse_engine: ## build sse_engine
	cd sse_engine && \
	git pull && \
	cd .. && \
	$(COMPOSE) build sse_engine

exec-sse_engine: ## execute sse_engine
	$(COMPOSE) exec sse_engine bash

# ------------------
# sse_runtime
# ------------------
build-sse_runtime: ## build sse_runtime
	cd sse_runtime/sse_runtime && \
	git pull && \
	docker build . -t $(SSE_CONTAINER_IMAGE) --build-arg UID=$(UID) --build-arg GID=$(GID)

# ------------------
# mitigator
# ------------------
up-mitigator: ## start mitigator
	$(COMPOSE) up -d mitigator

stop-mitigator: ## stop mitigator
	$(COMPOSE) stop mitigator

restart-mitigator: stop-mitigator up-mitigator ## restart mitigator

logs-mitigator: ## show mitigator logs
	$(COMPOSE) logs mitigator

rm-mitigator: ## remove mitigator
	$(COMPOSE) rm mitigator

build-mitigator: ## build mitigator
	cd mitigator && \
	git pull && \
	cd .. && \
	$(COMPOSE) build mitigator

exec-mitigator: ## execute mitigator
	$(COMPOSE) exec mitigator bash

# ------------------
# estimator
# ------------------
up-estimator: ## start estimator
	$(COMPOSE) up -d estimator

stop-estimator: ## stop estimator
	$(COMPOSE) stop estimator

restart-estimator: stop-estimator up-estimator ## restart estimator

logs-estimator: ## show estimator logs
	$(COMPOSE) logs estimator

rm-estimator: ## remove estimator
	$(COMPOSE) rm estimator

build-estimator: ## build estimator
	cd estimator && \
	git pull && \
	cd .. && \
	$(COMPOSE) build estimator

exec-estimator: ## execute estimator
	$(COMPOSE) exec estimator bash

# ------------------
# combiner
# ------------------
up-combiner: ## start combiner
	$(COMPOSE) up -d combiner

stop-combiner: ## stop combiner
	$(COMPOSE) stop combiner

restart-combiner: stop-combiner up-combiner ## restart combiner

logs-combiner: ## show combiner logs
	$(COMPOSE) logs combiner

rm-combiner: ## remove combiner
	$(COMPOSE) rm combiner

build-combiner: ## build combiner
	cd combiner && \
	git pull && \
	cd .. && \
	$(COMPOSE) build combiner

exec-combiner: ## execute combiner
	$(COMPOSE) exec combiner bash

# ------------------
# tranqu
# ------------------
up-tranqu: ## start tranqu
	$(COMPOSE) up -d tranqu

stop-tranqu: ## stop tranqu
	$(COMPOSE) stop tranqu

restart-tranqu: stop-tranqu up-tranqu ## restart tranqu

logs-tranqu: ## show tranqu logs
	$(COMPOSE) logs tranqu

rm-tranqu: ## remove tranqu
	$(COMPOSE) rm tranqu

build-tranqu: ## build tranqu
	cd tranqu-server && \
	git pull && \
	cd .. && \
	$(COMPOSE) build tranqu

exec-tranqu: ## execute tranqu
	$(COMPOSE) exec tranqu bash

# ------------------
# gateway
# ------------------
up-gateway: ## start gateway
	$(COMPOSE) up -d gateway

stop-gateway: ## stop gateway
	$(COMPOSE) stop gateway

restart-gateway: stop-gateway up-gateway ## restart gateway

logs-gateway: ## show gateway logs
	$(COMPOSE) logs gateway

rm-gateway: ## remove gateway
	$(COMPOSE) rm gateway

build-gateway: ## build gateway
	cd device-gateway && \
	git pull && \
	cd .. && \
	$(COMPOSE) build gateway

exec-gateway: ## execute gateway
	$(COMPOSE) exec gateway bash

show-current-status: ## show the current status of the device
	@cat device-gateway/config/device_status

change-status-to-active: ## change the status of the device to active
	@$(MAKE) -C device-gateway change-status-to-active

change-status-to-inactive: ## change the status of the device to inactive
	@$(MAKE) -C device-gateway change-status-to-inactive

change-status-to-maintenance: ## change the status of the device to maintenance
	@$(MAKE) -C device-gateway change-status-to-maintenance

generate-device-topology: ## generate the device topology
	@$(MAKE) -C device-gateway generate-device-topology

# ------------------
# other
# ------------------
ps: ## show the status of all containers
	$(COMPOSE) ps

up: ## start all containers
	$(COMPOSE) up -d

down: ## stop all containers
	$(COMPOSE) down

images: ## show docker images
	docker images

help: ## show help
	@echo "Usage: make <target>"
	@echo ""
	@grep -h -E '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS=":.*## "}; {printf "\033[36m%-28s\033[0m %s\n", $$1, $$2}'
