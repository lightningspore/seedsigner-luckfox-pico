#!/bin/bash
# SeedSigner Consolidated Build Script
# Combines functionality from all build scripts: build.sh, build_automation.sh, 
# docker-automation.sh, validate_environment.sh, sdk_init.sh, add_package_buildroot.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_header() { echo -e "${BLUE}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

show_usage() {
    cat << 'USAGE'
SeedSigner Consolidated Build System

Usage: ./build.sh [command] [options]

Commands:
  setup       - Clone required repositories to $HOME
  build       - Run automated build (default)
  interactive - Start container in interactive mode  
  shell       - Start container with direct shell access
  clean       - Clean build artifacts and containers
  status      - Check status of required repositories
  extract     - Extract build artifacts from container
  github      - Show GitHub Actions setup instructions
  config      - Create/update buildroot configuration

Options:
  --help, -h  - Show this help
  --force     - Force rebuild of Docker image
  --local     - Force local build (skip GitHub Actions recommendation)
  --jobs, -j N - Set number of parallel build jobs (default: auto-detect)

Examples:
  ./build.sh setup                     # First-time setup
  ./build.sh build                     # Standard build
  ./build.sh build --local             # Force local build on ARM64
  ./build.sh build --jobs 8            # Use 8 parallel jobs
  ./build.sh interactive               # Debug build issues

Required Repositories (auto-cloned by 'setup'):
  $HOME/luckfox-pico           - Main SDK
  $HOME/seedsigner             - SeedSigner code (luckfox-dev branch)  
  $HOME/seedsigner-os          - OS packages
  $HOME/seedsigner-luckfox-pico - This repository

Parallel Build Support:
  The build system automatically uses all available CPU cores for compilation.
  You can override this with --jobs N or by setting BUILD_JOBS environment variable.
  
  Examples:
    BUILD_JOBS=4 ./build.sh build       # Use 4 cores
    ./build.sh build --jobs 2           # Use 2 cores  
    ./build.sh build                    # Use all available cores ($(nproc))
USAGE
}

check_docker() {
    print_header "Checking Docker"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not installed"
        exit 1
    fi
    
    if ! docker version &> /dev/null; then
        print_error "Docker not running"
        exit 1
    fi
    
    # Check for docker-compose
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    else
        print_error "Docker Compose not available"
        exit 1
    fi
    
    # ARM64 detection and warning
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
        print_warning "ARM64 detected - using x86_64 emulation"
        USE_EMULATION=true
    else
        USE_EMULATION=false
    fi
    
    print_success "Docker available ($DOCKER_COMPOSE)"
}

check_repositories() {
    print_header "Checking Repositories"
    
    local repos=(
        "$HOME/luckfox-pico"
        "$HOME/seedsigner"
        "$HOME/seedsigner-os"
        "$HOME/seedsigner-luckfox-pico"
    )
    
    local missing=()
    for repo in "${repos[@]}"; do
        if [[ -d "$repo" && "$(ls -A "$repo" 2>/dev/null)" ]]; then
            print_success "$(basename "$repo") exists"
        else
            print_warning "$(basename "$repo") missing: $repo"
            missing+=("$repo")
        fi
    done
    
    if [[ ${#missing[@]} -ne 0 ]]; then
        print_error "Missing repositories. Run: $0 setup"
        return 1
    fi
    return 0
}

setup_repositories() {
    print_header "Setting Up Repositories"
    cd "$HOME"
    
    # Clone repos if missing
    [[ ! -d "luckfox-pico" ]] && {
        print_header "Cloning luckfox-pico"
        git clone https://github.com/lightningspore/luckfox-pico.git --depth=1
    }
    
    [[ ! -d "seedsigner-os" ]] && {
        print_header "Cloning seedsigner-os" 
        git clone https://github.com/seedsigner/seedsigner-os.git --depth=1
    }
    
    [[ ! -d "seedsigner" ]] && {
        print_header "Cloning seedsigner (luckfox-dev branch)"
        git clone https://github.com/lightningspore/seedsigner.git --depth=1 -b luckfox-dev
    }
    
    print_success "Repository setup complete"
}

build_docker_image() {
    local force_rebuild="$1"
    print_header "Building Docker Image"
    
    cd "$SCRIPT_DIR"
    
    local build_args="--platform=linux/amd64 -t foxbuilder:latest ."
    [[ "$force_rebuild" == "true" ]] && build_args="--no-cache $build_args"
    
    if [[ "$USE_EMULATION" == "true" ]]; then
        print_warning "ARM64 build - this may take 30+ minutes"
        if ! docker buildx build $build_args; then
            print_error "Docker build failed on ARM64"
            echo "Consider using GitHub Actions instead: $0 github"
            exit 1
        fi
    else
        docker buildx build $build_args
    fi
    
    print_success "Docker image built"
}

run_build() {
    local mode="$1"
    print_header "Starting Build ($mode)"
    
    cd "$SCRIPT_DIR"
    mkdir -p build-output
    
    case "$mode" in
        "auto")
            $DOCKER_COMPOSE up --build seedsigner-builder
            ;;
        "interactive")  
            $DOCKER_COMPOSE run --rm seedsigner-dev
            ;;
        "shell")
            $DOCKER_COMPOSE run --rm seedsigner-builder shell
            ;;
        *)
            print_error "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

clean_environment() {
    print_header "Cleaning Environment"
    cd "$SCRIPT_DIR"
    
    $DOCKER_COMPOSE down --remove-orphans 2>/dev/null || true
    docker rm -f seedsigner-luckfox-builder seedsigner-luckfox-dev 2>/dev/null || true
    
    read -p "Remove build-output directory? (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && rm -rf build-output && print_success "Build output removed"
    
    print_success "Environment cleaned"
}

extract_artifacts() {
    print_header "Extracting Artifacts"
    
    local container="seedsigner-luckfox-builder"
    local output_dir="$SCRIPT_DIR/build-output"
    
    mkdir -p "$output_dir"
    
    if docker ps -a --format "{{.Names}}" | grep -q "$container"; then
        docker cp "$container:/mnt/host/output/image/." "$output_dir/"
        print_success "Artifacts extracted to: $output_dir"
        echo "Contents:"
        ls -la "$output_dir/"
    else
        print_error "Container $container not found"
        echo "Run a build first with: $0 build"
    fi
}

show_github_instructions() {
    print_header "🚀 GitHub Actions Build Setup"
    
    # Check if we're in a git repository
    if [[ -d .git ]]; then
        CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
        print_success "Git repository detected"
        echo "  Remote: $CURRENT_REMOTE"
        echo "  Branch: $CURRENT_BRANCH"
    else
        print_warning "Not in a git repository"
    fi
    
    cat << 'GITHUB_INFO'

📋 GitHub Actions builds provide:
  ✅ Native x86_64 performance (no emulation)
  ✅ Reliable, consistent builds
  ✅ Automatic artifact storage
  ✅ 45-90 minute build time

🛠️  Setup Steps:

1. Push this repository to GitHub:
   git push origin <branch>

2. GitHub Actions will automatically:
   📥 Clone required repositories
   🔨 Build the SeedSigner OS
   📦 Package build artifacts

3. Monitor and download:
   🌐 Go to: https://github.com/YOUR_USERNAME/seedsigner-luckfox-pico/actions
   👀 Watch the "Build SeedSigner OS" workflow
   📥 Download artifacts when complete

🎯 Manual Trigger:
   - Go to Actions tab → "Build SeedSigner OS" → "Run workflow"

💡 Pro Tips:
   - Builds trigger automatically on push to main/develop
   - Artifacts are kept for 30 days
   - Use 'Force rebuild' if you need to update dependencies

GITHUB_INFO
    
    if [[ -f "../.github/workflows/build.yml" ]] || [[ -f ".github/workflows/build.yml" ]]; then
        print_success "GitHub Actions workflow file found!"
    else
        print_warning "GitHub Actions workflow file not found"
    fi
    
    echo ""
    print_header "Still want to build locally?"
    echo "Run: ./build.sh build --local"
}

backup_config() {
    print_header "Backing Up Config"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local config_file="$HOME/luckfox-pico/sysdrv/source/buildroot/buildroot-2023.02.6/.config"
    local backup_file="$SCRIPT_DIR/configs/config_$timestamp.config"
    
    if [[ -f "$config_file" ]]; then
        mkdir -p "$SCRIPT_DIR/configs"
        cp "$config_file" "$backup_file"
        print_success "Config backed up to: $backup_file"
    else
        print_warning "Config file not found at: $config_file"
    fi
}

show_status() {
    print_header "Build System Status"
    
    echo "📍 Current directory: $(pwd)"
    echo "🏠 Script directory: $SCRIPT_DIR"
    echo "📦 Architecture: $(uname -m)"
    
    if check_repositories; then
        print_success "All repositories present"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null && docker version &> /dev/null; then
        print_success "Docker available"
        if docker images | grep -q foxbuilder; then
            print_success "foxbuilder image exists"
        else
            print_warning "foxbuilder image not built yet"
        fi
    else
        print_warning "Docker not available"
    fi
    
    # Check for build output
    if [[ -d "$SCRIPT_DIR/build-output" ]] && [[ "$(ls -A "$SCRIPT_DIR/build-output" 2>/dev/null)" ]]; then
        print_success "Build output directory exists with contents"
        echo "  Contents: $(ls "$SCRIPT_DIR/build-output" | head -3 | tr '\n' ' ')..."
    else
        print_warning "No build output found"
    fi
}

# Main script logic
main() {
    local command="${1:-build}"
    local force_rebuild=false
    local force_local=false
    local build_jobs=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --force)
                force_rebuild=true
                shift
                ;;
            --local)
                force_local=true
                shift
                ;;
            --jobs|-j)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    build_jobs="$2"
                    export BUILD_JOBS="$build_jobs"
                    shift 2
                else
                    print_error "Invalid or missing argument for --jobs"
                    exit 1
                fi
                ;;
            *)
                if [[ -z "${command_set:-}" ]]; then
                    command="$1"
                    command_set=true
                fi
                shift
                ;;
        esac
    done
    
    # Show build configuration if jobs specified
    if [[ -n "$build_jobs" ]]; then
        echo "🔧 Build Configuration: Using $build_jobs parallel jobs"
    fi
    
    # Always check requirements for most commands
    if [[ "$command" != "github" && "$command" != "status" ]]; then
        check_docker
    fi
    
    case "$command" in
        "setup")
            setup_repositories
            ;;
        "status")
            show_status
            ;;
        "github")
            show_github_instructions
            ;;
        "config")
            backup_config
            ;;
        "build")
            # Check if we should recommend GitHub Actions
            if [[ "$USE_EMULATION" == "true" && "$force_local" == "false" ]]; then
                print_header "🌟 GitHub Actions Recommended for ARM64"
                cat << 'ARM64_WARNING'

You're on an ARM64 system (Apple Silicon Mac). For the best experience:

1. 🚀 Use GitHub Actions (recommended):
   ./build.sh github    # Show setup instructions

2. 🔧 Force local build (slower, may fail):
   ./build.sh build --local

3. 📖 See other options in documentation

ARM64_WARNING
                
                read -p "Continue with local build anyway? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo ""
                    print_success "Run './build.sh github' for GitHub Actions setup"
                    exit 0
                fi
            fi
            
            if check_repositories; then
                build_docker_image "$force_rebuild"
                run_build "auto"
            else
                print_error "Setup required repositories first with: $0 setup"
                exit 1
            fi
            ;;
        "interactive")
            if check_repositories; then
                build_docker_image "$force_rebuild"
                run_build "interactive"
            else
                print_error "Setup required repositories first with: $0 setup"
                exit 1
            fi
            ;;
        "shell")
            if check_repositories; then
                build_docker_image "$force_rebuild"
                run_build "shell"
            else
                print_error "Setup required repositories first with: $0 setup"
                exit 1
            fi
            ;;
        "clean")
            clean_environment
            ;;
        "extract")
            extract_artifacts
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
