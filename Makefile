ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help

# custom variables
repository ?= https://github.com/openedx/edx-analytics-dashboard.git
branch ?= master

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help

clean: ## Clean checkout insights code
	rm -rf insights
.PHONY: clean

clone: ## Clone code, to custom repo and branch `make repository=https://github.com/fccn/edx-analytics-dashboard.git branch=nau/lilac.master clone`
	git clone $(repository) --branch $(branch) --depth 1 insights
.PHONY: clone

build: ## Build docker image
	docker build . -t openedx-insights
.PHONY: build
