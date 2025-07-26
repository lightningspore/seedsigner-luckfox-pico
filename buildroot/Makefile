# SeedSigner Luckfox Pico Build System
# Convenience Makefile for common build operations

.PHONY: help setup build github interactive shell clean status extract

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "SeedSigner Luckfox Pico Build System"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make setup github   # Setup repos and show GitHub Actions guide"
	@echo "  make build-local    # Force local build"
	@echo "  make interactive    # Debug build issues"
	@echo "  make clean build    # Clean rebuild"

setup: ## Clone required repositories to $HOME
	./build.sh setup

github: ## Show GitHub Actions setup instructions
	./build.sh github

build: ## Run build (GitHub Actions recommended on ARM64)
	./build.sh build

build-local: ## Force local build (bypass GitHub Actions recommendation)
	./build.sh build --local

interactive: ## Start container in interactive mode for debugging
	./build.sh interactive

shell: ## Drop directly into container shell
	./build.sh shell

status: ## Check status of required repositories
	./build.sh status

clean: ## Clean build environment and artifacts
	./build.sh clean

extract: ## Extract build artifacts from container
	./build.sh extract

force-rebuild: ## Force rebuild of Docker image and run build
	./build.sh build --force --local

# Composite targets
quick-start: setup github ## Complete setup and show GitHub Actions guide

local-build: clean build-local ## Clean and rebuild locally

# Development targets
dev-setup: setup ## Setup for development (alias for setup)

dev-build: interactive ## Development build (interactive mode)

# Docker targets
docker-build: ## Build Docker image only
	docker buildx build --platform=linux/amd64 -t foxbuilder:latest .

docker-clean: ## Remove Docker containers and images
	docker-compose down --remove-orphans || true
	docker rm -f seedsigner-luckfox-builder seedsigner-luckfox-dev 2>/dev/null || true
	docker rmi foxbuilder:latest 2>/dev/null || true

# Info targets
info: ## Show build system information
	@echo "SeedSigner Luckfox Pico Build System"
	@echo "====================================="
	@echo "Project root: $(shell pwd)/.."
	@echo "Build script: ./build.sh"
	@echo "Docker Compose: docker-compose.yml"
	@echo "GitHub Actions: ../.github/workflows/build.yml"
	@echo ""
	@echo "Required repositories (in \$$HOME):"
	@echo "  - luckfox-pico"
	@echo "  - seedsigner" 
	@echo "  - seedsigner-os"
	@echo "  - seedsigner-luckfox-pico"
	@echo ""
	@echo "Current architecture: $(shell uname -m)"
	@echo "Recommendation: $(shell if [ "$(shell uname -m)" = "arm64" ]; then echo "Use GitHub Actions"; else echo "Local build OK"; fi)"
