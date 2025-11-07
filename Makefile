SHELL := /bin/bash

TOOLS_DIR := hack/tools
TOOLS_BIN_DIR := $(TOOLS_DIR)/bin
HELM_DOCS_VERSION ?= v1.11.0
HELM_DOCS := $(TOOLS_BIN_DIR)/helm-docs

CHARTS_DIR := charts
ALL_CHARTS := $(shell find $(CHARTS_DIR) -maxdepth 1 -mindepth 1 -type d -exec test -f "{}/Chart.yaml" \; -print)

ifeq ($(CHART),)
TARGET_CHARTS := $(ALL_CHARTS)
else
ifeq ($(findstring $(CHARTS_DIR)/,$(CHART)),)
TARGET_CHARTS := $(CHARTS_DIR)/$(CHART)
else
TARGET_CHARTS := $(CHART)
endif
endif

DIST_DIR := dist

.PHONY: deps lint docs package clean tag tag-push tag-delete tag-repush release chart-tag chart-tag-push chart-tag-delete chart-tag-repush chart-release all

deps: $(HELM_DOCS) ## Install development dependencies (helm-docs)

$(HELM_DOCS):
	@if ! command -v go >/dev/null 2>&1; then \
		echo "Go is required to install helm-docs. Please install Go (https://go.dev/dl/)."; \
		exit 1; \
	fi
	@if ! command -v helm >/dev/null 2>&1; then \
		echo "Helm not found. Please install Helm manually (https://helm.sh/docs/intro/install/)."; \
		exit 1; \
	fi
	@echo "Installing helm-docs $(HELM_DOCS_VERSION) into $(TOOLS_BIN_DIR)..."
	@mkdir -p $(TOOLS_BIN_DIR)
	@GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/norwoodj/helm-docs/cmd/helm-docs@$(HELM_DOCS_VERSION)

lint:
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; else \
	for chart in $(TARGET_CHARTS); do \
		if [ ! -d "$$chart" ]; then echo "Unknown chart $$chart"; exit 1; fi; \
		echo "Linting $$chart"; \
		helm lint $$chart --strict || exit 1; \
	 done; fi

docs: $(HELM_DOCS)
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; exit 1; fi
	@if [ -z "$(CHART)" ]; then \
		PATH="$(abspath $(TOOLS_BIN_DIR)):$$PATH" $(HELM_DOCS) --chart-search-root $(CHARTS_DIR)/; \
	else \
		for chart in $(TARGET_CHARTS); do \
			if [ ! -d "$$chart" ]; then echo "Unknown chart $$chart"; exit 1; fi; \
			PATH="$(abspath $(TOOLS_BIN_DIR)):$$PATH" $(HELM_DOCS) --chart-search-root "$$chart"; \
		done; \
	fi
	@hack/update-charts-table.sh

package: clean docs lint
	@mkdir -p $(DIST_DIR)
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; else \
	for chart in $(TARGET_CHARTS); do \
		if [ ! -d "$$chart" ]; then echo "Unknown chart $$chart"; exit 1; fi; \
		echo "Packaging $$chart"; \
		helm package $$chart --destination $(DIST_DIR) || exit 1; \
	 done; fi

clean:
	@rm -rf $(DIST_DIR)

# Global repo tags (vX.Y.Z)
tag:
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., VERSION=v0.1.0)" >&2; exit 1; fi
	@case "$(VERSION)" in v*) ;; *) echo "ERROR: VERSION must be v-prefixed (e.g., v0.1.0)" >&2; exit 1;; esac
	@if git status --porcelain | grep -q '.'; then echo "ERROR: Working tree is not clean." >&2; exit 1; fi
	@if git rev-parse -q --verify "refs/tags/$(VERSION)" >/dev/null; then \
	  echo "ERROR: Tag $(VERSION) already exists." >&2; exit 1; \
	fi
	@git tag -a $(VERSION) -m "Release $(VERSION)"
	@echo "Created tag $(VERSION)"

tag-push:
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., VERSION=v0.1.0)" >&2; exit 1; fi
	@if ! git rev-parse -q --verify "refs/tags/$(VERSION)" >/dev/null; then \
	  echo "ERROR: Tag $(VERSION) not found. Create it first: make tag VERSION=$(VERSION)" >&2; exit 1; \
	fi
	@git push origin $(VERSION)

tag-delete:
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., VERSION=v0.1.0)" >&2; exit 1; fi
	@echo "Deleting local tag $(VERSION)"
	@-git tag -d $(VERSION)
	@echo "Deleting remote tag $(VERSION)"
	@-git push --delete origin $(VERSION) || git push origin :refs/tags/$(VERSION)

tag-repush: tag-delete tag
	@$(MAKE) tag-push

release: tag tag-push

# Per-chart tags (chart-name-1.2.3)
chart-tag:
	@if [ -z "$(CHART)" ]; then echo "ERROR: CHART is required (e.g., CHART=klustre-csi-plugin)" >&2; exit 1; fi
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., VERSION=0.1.0)" >&2; exit 1; fi
	@if [ ! -d "$(CHARTS_DIR)/$(CHART)" ]; then echo "ERROR: Chart '$(CHART)' not found under $(CHARTS_DIR)/" >&2; exit 1; fi
	@if git status --porcelain | grep -q '.'; then echo "ERROR: Working tree is not clean." >&2; exit 1; fi
	@TAG_NAME="$(CHART)-$(VERSION)"; \
	if git rev-parse -q --verify "refs/tags/$${TAG_NAME}" >/dev/null; then \
	  echo "ERROR: Tag $${TAG_NAME} already exists." >&2; \
	  exit 1; \
	fi; \
	git tag -a "$${TAG_NAME}" -m "Release $${TAG_NAME}"; \
	echo "Created tag $${TAG_NAME}"

chart-tag-push:
	@if [ -z "$(CHART)" ]; then echo "ERROR: CHART is required (e.g., CHART=klustre-csi-plugin)" >&2; exit 1; fi
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., VERSION=0.1.0)" >&2; exit 1; fi
	@TAG_NAME="$(CHART)-$(VERSION)"; \
	if ! git rev-parse -q --verify "refs/tags/$${TAG_NAME}" >/dev/null; then \
	  echo "ERROR: Tag $${TAG_NAME} not found. Create it first: make chart-tag CHART=$(CHART) VERSION=$(VERSION)" >&2; \
	  exit 1; \
	fi; \
	git push origin "$${TAG_NAME}"

chart-tag-delete:
	@if [ -z "$(CHART)" ]; then echo "ERROR: CHART is required (e.g., CHART=klustre-csi-plugin)" >&2; exit 1; fi
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., VERSION=0.1.0)" >&2; exit 1; fi
	@TAG_NAME="$(CHART)-$(VERSION)"; \
	echo "Deleting local tag $${TAG_NAME}"; \
	- git tag -d "$${TAG_NAME}"; \
	echo "Deleting remote tag $${TAG_NAME}"; \
	- git push --delete origin "$${TAG_NAME}" || git push origin :refs/tags/"$${TAG_NAME}"

chart-tag-repush: chart-tag-delete chart-tag
	@$(MAKE) chart-tag-push CHART=$(CHART) VERSION=$(VERSION)

chart-release:
	@if [ -z "$(CHART)" ]; then echo "ERROR: CHART is required (e.g., CHART=klustre-csi-plugin)" >&2; exit 1; fi
	@if [ -z "$(VERSION)" ]; then echo "ERROR: VERSION is required (e.g., VERSION=0.1.0)" >&2; exit 1; fi
	@$(MAKE) lint CHART=$(CHART)
	@$(MAKE) docs CHART=$(CHART)
	@$(MAKE) package CHART=$(CHART)
	@$(MAKE) chart-tag CHART=$(CHART) VERSION=$(VERSION)
	@$(MAKE) chart-tag-push CHART=$(CHART) VERSION=$(VERSION)

all: deps lint docs package
