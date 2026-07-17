# workshop.mk — Includable Makefile for AgnosticD workshop/demo/infra projects
# Include in your project Makefile:
#   include $(HOME)/.local/share/rhel-devops-skills/workshop.mk
#
# Requires: PROJECT_TYPE variable set in the including Makefile
# Supported PROJECT_TYPE values: hub-student, demo, agnosticd-infra, shared-cluster

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Shared library location
WORKSHOP_LIB ?= $(HOME)/.local/share/rhel-devops-skills

# Deploy script paths (override in project Makefile if non-standard)
DEPLOY_SCRIPT ?= scripts/deploy-workshop.sh
TEARDOWN_SCRIPT ?= scripts/teardown-workshop.sh
QUOTA_SCRIPT ?= scripts/check-quota.sh
BOOTSTRAP_SCRIPT ?= bootstrap.sh

# Flags passed through to scripts
INCREASE ?=
ENV ?=
RESUME ?=
PARALLEL ?=

# Build flag arguments
_FLAGS :=
ifdef RESUME
  _FLAGS += --resume
endif
ifdef PARALLEL
  _FLAGS += --parallel $(PARALLEL)
endif

# ─── Common Targets ──────────────────────────────────────────────────────────

.PHONY: help setup check check-quota deploy destroy dry-run status

help: ## Show available targets
	@echo ""
	@echo "  Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

setup: ## Install prerequisites and configure environment
	@$(BOOTSTRAP_SCRIPT)

check: ## Run validation checks only
	@$(BOOTSTRAP_SCRIPT) --check-only

check-quota: ## Check cloud provider quotas (read-only, safe for AI agents)
ifdef INCREASE
	@$(QUOTA_SCRIPT) --increase
else
	@$(QUOTA_SCRIPT)
endif

deploy: check-quota ## Deploy environment (runs quota check first)
	@$(DEPLOY_SCRIPT) $(_FLAGS)

destroy: ## Destroy environment (prompts for confirmation)
	@$(TEARDOWN_SCRIPT) $(_FLAGS)

dry-run: ## Preview deploy without making changes
	@$(DEPLOY_SCRIPT) --dry-run $(_FLAGS)

status: ## Show current environment status
	@$(QUOTA_SCRIPT) --status 2>/dev/null || true
	@echo ""
	@if [ -f .workshop-state ]; then \
		echo "  Environment State:"; \
		echo "  ─────────────────────────────────────"; \
		cat .workshop-state | while IFS='=' read -r key value; do \
			printf "    %-20s %s\n" "$$key:" "$$value"; \
		done; \
		echo ""; \
	else \
		echo "  No deployment state found. Run: make deploy"; \
	fi

# ─── Hub-Student Targets (only when PROJECT_TYPE=hub-student) ─────────────────

ifeq ($(PROJECT_TYPE),hub-student)

.PHONY: deploy-hub deploy-students destroy-hub destroy-students stop start

deploy-hub: check-quota ## Deploy hub cluster only
	@$(DEPLOY_SCRIPT) --hub-only $(_FLAGS)

deploy-students: ## Deploy student clusters only
	@$(DEPLOY_SCRIPT) --students-only $(_FLAGS)

destroy-hub: ## Destroy hub cluster only
	@$(TEARDOWN_SCRIPT) --hub-only

destroy-students: ## Destroy student clusters only (parallel)
	@$(TEARDOWN_SCRIPT) --students-only

stop: ## Stop all clusters (hub + students)
	@$(DEPLOY_SCRIPT) --action stop

start: ## Start all clusters (hub + students)
	@$(DEPLOY_SCRIPT) --action start

endif

# ─── Shared-Cluster Targets (only when PROJECT_TYPE=shared-cluster) ───────────

ifeq ($(PROJECT_TYPE),shared-cluster)

.PHONY: create-users delete-users

create-users: ## Create/update user namespaces on existing cluster
	@$(DEPLOY_SCRIPT) --users-only $(_FLAGS)

delete-users: ## Delete user namespaces (keeps cluster running)
	@$(TEARDOWN_SCRIPT) --users-only

endif

# ─── Infrastructure Targets (only when PROJECT_TYPE=agnosticd-infra) ──────────

ifeq ($(PROJECT_TYPE),agnosticd-infra)

.PHONY: stop start

deploy: check-quota ## Deploy environment (specify ENV=dev|test|prod)
ifdef ENV
	@$(DEPLOY_SCRIPT) --env $(ENV) $(_FLAGS)
else
	@$(DEPLOY_SCRIPT) $(_FLAGS)
endif

stop: ## Stop infrastructure (specify ENV=dev|test|prod)
ifdef ENV
	@$(DEPLOY_SCRIPT) --action stop --env $(ENV)
else
	@$(DEPLOY_SCRIPT) --action stop
endif

start: ## Start infrastructure (specify ENV=dev|test|prod)
ifdef ENV
	@$(DEPLOY_SCRIPT) --action start --env $(ENV)
else
	@$(DEPLOY_SCRIPT) --action start
endif

endif
