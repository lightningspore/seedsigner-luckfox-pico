#!/bin/bash

# SeedSigner Build Wrapper Script
# This script simplifies the Docker-based build process

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=================================="
    echo -e "$1"
    echo -e "==================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_usage() {
    echo "SeedSigner Buildroot Build Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup       - Check and setup required repositories"
    echo "  build       - Run automated build (default)"
    echo "  github      - Show GitHub Actions build instructions"
    echo "  interactive - Start container in interactive mode"
    echo "  shell       - Start container with direct shell access"
    echo "  clean       - Clean build artifacts and containers"
    echo "  status      - Check status of required repositories"
    echo ""
    echo "Options:"
    echo "  --help, -h  - Show this help message"
    echo "  --force     - Force rebuild of Docker image"
    echo "  --local     - Force local build (skip GitHub Actions recommendation)"
    echo ""
    echo "Examples:"
    echo "  $0 setup              # Check and clone required repos"
    echo "  $0 github             # Show GitHub Actions setup"
    echo "  $0 build              # Run build (GitHub Actions on ARM64)"
    echo "  $0 build --local      # Force local build"
    echo "  $0 build --force      # Rebuild Docker image and run build"
    echo "  $0 interactive        # Start in interactive mode for debugging"
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check Docker version for buildx support
    DOCKER_VERSION=$(docker version --format '{{.Client.Version}}' 2>/dev/null)
    if [ -z "$DOCKER_VERSION" ]; then
        print_error "Cannot get Docker version. Is Docker running?"
        exit 1
    fi
    
    # Check if we're on ARM64 (like Apple Silicon Macs)
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        print_warning "Detected ARM64 architecture. Will use x86_64 emulation for build."
        print_warning "Docker will handle platform emulation automatically."
        USE_EMULATION=true
    else
        print_success "Running on x86_64, no emulation needed"
        USE_EMULATION=false
    fi
    
    # Check if Docker Compose is available
    if ! command -v docker-compose &> /dev/null; then
        print_warning "docker-compose not found, trying 'docker compose'"
        if ! docker compose version &> /dev/null; then
            print_error "Neither docker-compose nor 'docker compose' is available"
            exit 1
        else
            DOCKER_COMPOSE="docker compose"
        fi
    else
        DOCKER_COMPOSE="docker-compose"
    fi
    
    print_success "Docker and Docker Compose are available"
}

check_repositories() {
    print_header "Checking Required Repositories"
    
    local missing_repos=()
    
    # Required repositories 
    local repos=(
        "$HOME/luckfox-pico:https://github.com/lightningspore/luckfox-pico.git"
        "$HOME/seedsigner:https://github.com/lightningspore/seedsigner.git:-b luckfox-dev"
        "$HOME/seedsigner-luckfox-pico:current repo"
        "$HOME/seedsigner-os:https://github.com/seedsigner/seedsigner-os.git"
    )
    
    for repo_info in "${repos[@]}"; do
        local repo_path="${repo_info%%:*}"
        local repo_details="${repo_info#*:}"
        local repo_name="$(basename "$repo_path")"
        
        if [ -d "$repo_path" ] && [ "$(ls -A "$repo_path")" ]; then
            print_success "$repo_name exists at $repo_path"
        else
            print_warning "$repo_name missing or empty at $repo_path"
            if [ "$repo_details" != "current repo" ]; then
                missing_repos+=("$repo_info")
            fi
        fi
    done
    
    if [ ${#missing_repos[@]} -ne 0 ]; then
        echo ""
        print_error "Some required repositories are missing!"
        echo "Run '$0 setup' to clone them automatically"
        return 1
    fi
    
    return 0
}

setup_repositories() {
    print_header "Setting Up Required Repositories"
    
    cd "$HOME"
    
    # Clone repositories if they don't exist
    if [ ! -d "luckfox-pico" ]; then
        print_header "Cloning luckfox-pico..."
        git clone https://github.com/lightningspore/luckfox-pico.git --depth=1 --single-branch
    else
        print_success "luckfox-pico already exists"
    fi
    
    if [ ! -d "seedsigner-os" ]; then
        print_header "Cloning seedsigner-os..."
        git clone https://github.com/seedsigner/seedsigner-os.git --depth=1 --single-branch
    else
        print_success "seedsigner-os already exists"
    fi
    
    if [ ! -d "seedsigner" ]; then
        print_header "Cloning seedsigner (luckfox-dev branch)..."
        git clone https://github.com/lightningspore/seedsigner.git --depth=1 -b luckfox-dev --single-branch
    else
        print_success "seedsigner already exists"
    fi
    
    print_success "Repository setup complete!"
}

build_image() {
    local force_rebuild="$1"
    
    print_header "Building Docker Image"
    
    cd "$SCRIPT_DIR"
    
    # Try different build approaches based on platform
    local build_success=false
    
    if [ "$USE_EMULATION" = "true" ]; then
        print_warning "Building for x86_64 on ARM64 - this may take a while..."
        
        # Try buildx first
        print_header "Attempting build with buildx..."
        if [ "$force_rebuild" = "true" ]; then
            if docker buildx build --no-cache --platform=linux/amd64 -t foxbuilder:latest . 2>/dev/null; then
                build_success=true
            fi
        else
            if docker buildx build --platform=linux/amd64 -t foxbuilder:latest . 2>/dev/null; then
                build_success=true
            fi
        fi
        
        # If buildx fails, try regular docker build
        if [ "$build_success" = "false" ]; then
            print_warning "buildx failed, trying regular docker build..."
            if [ "$force_rebuild" = "true" ]; then
                if docker build --no-cache --platform=linux/amd64 -t foxbuilder:latest . 2>/dev/null; then
                    build_success=true
                fi
            else
                if docker build --platform=linux/amd64 -t foxbuilder:latest . 2>/dev/null; then
                    build_success=true
                fi
            fi
        fi
        
        # If both fail, provide helpful error message
        if [ "$build_success" = "false" ]; then
            print_error "Docker build failed on ARM64 with emulation!"
            echo ""
            echo "This is a common issue on Apple Silicon Macs. Here are your options:"
            echo ""
            echo "1. 🌟 Use GitHub Actions (Recommended):"
            echo "   - Push your code to GitHub"
            echo "   - GitHub Actions will build automatically on x86_64"
            echo "   - Download artifacts from the Actions tab"
            echo ""
            echo "2. 🔧 Try Colima instead of Docker Desktop:"
            echo "   brew install colima"
            echo "   colima start --arch x86_64 --memory 8 --cpu 4"
            echo ""
            echo "3. 📖 See ARM64_COMPATIBILITY.md for more solutions"
            echo ""
            echo "4. ☁️  Use a cloud x86_64 machine for building"
            exit 1
        fi
    else
        # Native x86_64 build
        if [ "$force_rebuild" = "true" ]; then
            docker buildx build --no-cache --platform=linux/amd64 -t foxbuilder:latest .
        else
            docker buildx build --platform=linux/amd64 -t foxbuilder:latest .
        fi
        build_success=true
    fi
    
    if [ "$build_success" = "true" ]; then
        print_success "Docker image built successfully"
    fi
}

run_build() {
    local mode="$1"
    
    print_header "Starting SeedSigner Build"
    
    cd "$SCRIPT_DIR"
    
    # Create build output directory
    mkdir -p "${SCRIPT_DIR}/build-output"
    
    case "$mode" in
        "auto")
            print_header "Running Automated Build"
            $DOCKER_COMPOSE up --build seedsigner-builder
            ;;
        "interactive")
            print_header "Starting Interactive Mode"
            $DOCKER_COMPOSE run --rm seedsigner-dev
            ;;
        "shell")
            print_header "Starting Shell Mode"
            $DOCKER_COMPOSE run --rm seedsigner-builder shell
            ;;
        *)
            print_error "Unknown build mode: $mode"
            exit 1
            ;;
    esac
}

clean_build() {
    print_header "Cleaning Build Environment"
    
    cd "$SCRIPT_DIR"
    
    # Stop and remove containers
    $DOCKER_COMPOSE down --remove-orphans 2>/dev/null || true
    
    # Remove any lingering containers
    docker rm -f seedsigner-luckfox-builder seedsigner-luckfox-dev 2>/dev/null || true
    
    # Optionally remove build output
    read -p "Remove build output directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "${SCRIPT_DIR}/build-output"
        print_success "Build output removed"
    fi
    
    print_success "Clean complete"
}

extract_artifacts() {
    print_header "Extracting Build Artifacts"
    
    local container_name="seedsigner-luckfox-builder"
    local output_dir="${SCRIPT_DIR}/build-output"
    
    mkdir -p "$output_dir"
    
    # Check if container exists and is running
    if docker ps -a --format "table {{.Names}}" | grep -q "$container_name"; then
        print_header "Extracting artifacts from container..."
        
        # Extract the entire output/image directory
        docker cp "${container_name}:/mnt/host/output/image/." "$output_dir/"
        
        print_success "Artifacts extracted to: $output_dir"
        echo "Contents:"
        ls -la "$output_dir/"
    else
        print_error "Container $container_name not found"
        echo "Run a build first with: $0 build"
    fi
}

show_github_instructions() {
    print_header "🚀 GitHub Actions Build Setup"
    
    # Check if we're in a git repository
    if [ -d .git ]; then
        CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
        print_success "Git repository detected"
        echo "  Remote: $CURRENT_REMOTE"
        echo "  Branch: $CURRENT_BRANCH"
    else
        print_warning "Not in a git repository"
    fi
    
    echo ""
    echo "📋 GitHub Actions builds provide:"
    echo "  ✅ Native x86_64 performance (no emulation)"
    echo "  ✅ Reliable, consistent builds"
    echo "  ✅ Automatic artifact storage"
    echo "  ✅ 45-90 minute build time"
    echo ""
    
    echo "🛠️  Setup Steps:"
    echo ""
    echo "1. Push this repository to GitHub:"
    if [ -d .git ]; then
        if [ "$CURRENT_REMOTE" != "none" ]; then
            echo "   git push origin $CURRENT_BRANCH"
        else
            echo "   git remote add origin https://github.com/YOUR_USERNAME/seedsigner-luckfox-pico.git"
            echo "   git push -u origin $CURRENT_BRANCH"
        fi
    else
        echo "   git init"
        echo "   git add ."
        echo "   git commit -m \"Add improved build system\""
        echo "   git remote add origin https://github.com/YOUR_USERNAME/seedsigner-luckfox-pico.git"
        echo "   git push -u origin main"
    fi
    echo ""
    
    echo "2. GitHub Actions will automatically:"
    echo "   📥 Clone required repositories"
    echo "   🔨 Build the SeedSigner OS"
    echo "   📦 Package build artifacts"
    echo ""
    
    echo "3. Monitor and download:"
    echo "   🌐 Go to: https://github.com/YOUR_USERNAME/seedsigner-luckfox-pico/actions"
    echo "   👀 Watch the \"Build SeedSigner OS\" workflow"
    echo "   📥 Download artifacts when complete"
    echo ""
    
    echo "🎯 Manual Trigger:"
    echo "   - Go to Actions tab → \"Build SeedSigner OS\" → \"Run workflow\""
    echo "   - Optionally enable \"Force rebuild Docker image\""
    echo ""
    
    echo "📁 The workflow file is already included at:"
    echo "   .github/workflows/build.yml"
    echo ""
    
    if [ -f "../.github/workflows/build.yml" ] || [ -f ".github/workflows/build.yml" ]; then
        print_success "GitHub Actions workflow file found!"
    else
        print_warning "GitHub Actions workflow file not found"
        echo "Make sure .github/workflows/build.yml exists"
    fi
    
    echo ""
    echo "💡 Pro Tips:"
    echo "   - Builds trigger automatically on push to main/develop"
    echo "   - Artifacts are kept for 30 days"
    echo "   - Check the Actions tab for build status"
    echo "   - Use 'Force rebuild' if you need to update dependencies"
    echo ""
    
    print_header "Still want to build locally?"
    echo "Run: ./build.sh build --local"
}

# Main script logic
main() {
    local command="${1:-build}"
    local force_rebuild=false
    local force_local=false
    
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
            *)
                if [ -z "${command_set:-}" ]; then
                    command="$1"
                    command_set=true
                fi
                shift
                ;;
        esac
    done
    
    # Always check requirements for most commands
    if [ "$command" != "github" ]; then
        check_requirements
    fi
    
    case "$command" in
        "setup")
            setup_repositories
            ;;
        "status")
            check_repositories
            ;;
        "github")
            show_github_instructions
            ;;
        "build")
            # Check if we should recommend GitHub Actions
            if [ "$USE_EMULATION" = "true" ] && [ "$force_local" = "false" ]; then
                print_header "🌟 GitHub Actions Recommended for ARM64"
                echo ""
                echo "You're on an ARM64 system (Apple Silicon Mac). For the best experience:"
                echo ""
                echo "1. 🚀 Use GitHub Actions (recommended):"
                echo "   ./build.sh github    # Show setup instructions"
                echo ""
                echo "2. 🔧 Force local build (slower, may fail):"
                echo "   ./build.sh build --local"
                echo ""
                echo "3. 📖 See other options:"
                echo "   cat ARM64_COMPATIBILITY.md"
                echo ""
                
                read -p "Continue with local build anyway? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo ""
                    print_success "Run './build.sh github' for GitHub Actions setup"
                    exit 0
                fi
            fi
            
            if check_repositories; then
                build_image "$force_rebuild"
                run_build "auto"
            else
                print_error "Setup required repositories first with: $0 setup"
                exit 1
            fi
            ;;
        "interactive")
            if check_repositories; then
                build_image "$force_rebuild"
                run_build "interactive"
            else
                print_error "Setup required repositories first with: $0 setup"
                exit 1
            fi
            ;;
        "shell")
            if check_repositories; then
                build_image "$force_rebuild"
                run_build "shell"
            else
                print_error "Setup required repositories first with: $0 setup"
                exit 1
            fi
            ;;
        "clean")
            clean_build
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
