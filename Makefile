SHELL := /bin/bash

TOOLS_DIR := hack/tools
TOOLS_BIN_DIR := $(TOOLS_DIR)/bin
HELM_DOCS_VERSION ?= v1.11.0
HELM_DOCS := $(TOOLS_BIN_DIR)/helm-docs
HELM_UNITTEST_VERSION ?= v0.5.1
KUBECONFORM_VERSION ?= v0.6.7
KUBECONFORM := $(TOOLS_BIN_DIR)/kubeconform
KUBECONFORM_K8S_VERSION ?= 1.28.0
HELM_SCHEMA_VERSION ?= 0.18.1
HELM_SCHEMA := $(TOOLS_BIN_DIR)/helm-schema
HELM_SCHEMA_MODULE ?= github.com/dadav/helm-schema/cmd/helm-schema

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

.PHONY: deps lint docs test validate golden schema verify helm-unittest-plugin package clean tag tag-push tag-delete tag-repush release chart-tag chart-tag-push chart-tag-delete chart-tag-repush chart-release all

deps: $(HELM_DOCS) $(KUBECONFORM) $(HELM_SCHEMA) ## Install development dependencies

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

$(KUBECONFORM):
	@if ! command -v go >/dev/null 2>&1; then \
		echo "Go is required to install kubeconform. Please install Go (https://go.dev/dl/)."; \
		exit 1; \
	fi
	@echo "Installing kubeconform $(KUBECONFORM_VERSION) into $(TOOLS_BIN_DIR)..."
	@mkdir -p $(TOOLS_BIN_DIR)
	@GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/yannh/kubeconform/cmd/kubeconform@$(KUBECONFORM_VERSION)

$(HELM_SCHEMA):
	@if ! command -v go >/dev/null 2>&1; then \
		echo "Go is required to install helm-schema. Please install Go (https://go.dev/dl/)."; \
		exit 1; \
	fi
	@echo "Installing helm-schema $(HELM_SCHEMA_VERSION) into $(TOOLS_BIN_DIR)..."
	@mkdir -p $(TOOLS_BIN_DIR)
	@GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install $(HELM_SCHEMA_MODULE)@$(HELM_SCHEMA_VERSION)

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

package: clean verify
	@mkdir -p $(DIST_DIR)
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; else \
	for chart in $(TARGET_CHARTS); do \
		if [ ! -d "$$chart" ]; then echo "Unknown chart $$chart"; exit 1; fi; \
		echo "Packaging $$chart"; \
		helm package $$chart --destination $(DIST_DIR) || exit 1; \
	 done; fi

clean:
	@rm -rf $(DIST_DIR)

helm-unittest-plugin:
	@if ! helm plugin list 2>/dev/null | awk 'NR>1 {print $$1}' | grep -qx "unittest"; then \
		echo "Installing helm-unittest $(HELM_UNITTEST_VERSION)..."; \
		helm plugin install https://github.com/helm-unittest/helm-unittest --version $(HELM_UNITTEST_VERSION); \
	fi

test: helm-unittest-plugin
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; else \
	for chart in $(TARGET_CHARTS); do \
		if [ ! -d "$$chart" ]; then echo "Unknown chart $$chart"; exit 1; fi; \
		if [ -d "$$chart/tests" ]; then \
			echo "Running unit tests for $$chart"; \
			helm unittest "$$chart" || exit 1; \
		else \
			echo "Skipping $$chart (no tests directory)"; \
		fi; \
	 done; fi

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
	-git tag -d "$${TAG_NAME}"; \
	echo "Deleting remote tag $${TAG_NAME}"; \
	-git push --delete origin "$${TAG_NAME}" || git push origin :refs/tags/"$${TAG_NAME}"

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
validate: $(KUBECONFORM)
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; else \
	for chart in $(TARGET_CHARTS); do \
		if [ ! -d "$$chart" ]; then echo "Unknown chart $$chart"; exit 1; fi; \
		echo "Validating rendered manifests for $$chart"; \
		tmp="$$(mktemp)"; \
		if helm template klustre "$$chart" --include-crds > "$$tmp"; then \
			$(KUBECONFORM) -strict -ignore-missing-schemas -kubernetes-version $(KUBECONFORM_K8S_VERSION) "$$tmp" || { rm -f "$$tmp"; exit 1; }; \
		else \
			rm -f "$$tmp"; \
			exit 1; \
		fi; \
		rm -f "$$tmp"; \
	 done; fi

golden:
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; else \
	for chart in $(TARGET_CHARTS); do \
		scenario_dir="$$chart/tests/golden/scenarios"; \
		if [ ! -d "$$scenario_dir" ]; then \
			echo "Skipping $$chart (no golden scenarios)"; \
			continue; \
		fi; \
		out_dir="$$chart/tests/golden/rendered"; \
		mkdir -p "$$out_dir"; \
		for values in "$$scenario_dir"/*.yaml; do \
			[ -e "$$values" ] || continue; \
			scenario=$$(basename "$$values"); \
			scenario="$${scenario%.yaml}"; \
			out_file="$$out_dir/$${scenario}.yaml"; \
			echo "Rendering $$chart ($$scenario) -> $$out_file"; \
			if ! helm template klustre "$$chart" --include-crds -f "$$values" > "$$out_file"; then \
				echo "Failed to render $$chart scenario $$scenario"; \
				exit 1; \
			fi; \
			done; \
		 done; fi

schema: $(HELM_SCHEMA)
	@if [ -z "$(TARGET_CHARTS)" ]; then echo "No charts found under $(CHARTS_DIR)/"; else \
	for chart in $(TARGET_CHARTS); do \
		values_file="$$chart/values.yaml"; \
		if [ ! -f "$$values_file" ]; then \
			echo "Skipping $$chart (missing values.yaml)"; \
			continue; \
		fi; \
		output_file="$$chart/values.schema.json"; \
		echo "Generating schema for $$chart -> $$output_file"; \
		$(HELM_SCHEMA) "$$values_file" > "$$output_file"; \
		done; fi

verify: docs lint test validate schema golden
