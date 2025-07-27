#!/bin/bash
# SeedSigner Build Script - Self-Contained and Portable
# No home directory pollution, no docker-compose, just simple Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="seedsigner-builder"
CONTAINER_NAME="seedsigner-build-$(date +%s)"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_header() { echo -e "${BLUE}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
print_error() { echo -e "${RED}[ERROR] $1${NC}"; }

show_usage() {
    cat << 'USAGE'
SeedSigner Self-Contained Build System

Usage: ./build.sh [command] [options]

Commands:
  build       - Run full automated build (default)
  interactive - Start container in interactive mode  
  shell       - Start container with direct shell access
  clean       - Clean build artifacts and containers
  extract     - Extract build artifacts from last build
  status      - Show build system status

Options:
  --help, -h     - Show this help
  --force        - Force rebuild of Docker image
  --jobs, -j N   - Set number of parallel build jobs
  --output DIR   - Set output directory (default: ./build-output)

Key Features:
  ✅ All repos cloned INSIDE container (no $HOME pollution)
  ✅ No docker-compose needed (simple docker run)
  ✅ Persistent Docker volume for repos (faster subsequent builds)
  ✅ Completely portable and self-contained
  ✅ Automatic parallel build optimization

Examples:
  ./build.sh build             # Standard build
  ./build.sh build --jobs 8    # Use 8 parallel jobs
  ./build.sh interactive       # Debug build issues
  ./build.sh extract           # Extract build artifacts
  ./build.sh status            # Check volume and image status

Repository Persistence:
  - First build: Clones repos to Docker volume 'seedsigner-repos'
  - Subsequent builds: Reuses existing repos (much faster!)
  - Clean with volume removal: Forces complete re-clone

Performance:
  First build:  30-90 min (clones ~500MB+ of repos)
  Later builds: 15-45 min (reuses persistent repos)

No more $HOME pollution! 🎉 Fast subsequent builds! ⚡
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
    
    # ARM64 detection
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
        print_warning "ARM64 detected - using x86_64 emulation (may be slow)"
        PLATFORM_ARGS="--platform linux/amd64"
    else
        PLATFORM_ARGS=""
    fi
    
    print_success "Docker available"
}

build_docker_image() {
    local force_rebuild="$1"
    print_header "Building Docker Image"
    
    cd "$SCRIPT_DIR"
    
    local build_args="$PLATFORM_ARGS -t $IMAGE_NAME ."
    
    if [[ "$force_rebuild" == "true" ]]; then
        build_args="--no-cache $build_args"
        print_warning "Force rebuilding Docker image..."
    fi
    
    docker build $build_args
    print_success "Docker image built: $IMAGE_NAME"
}

run_build() {
    local mode="$1"
    local build_jobs="$2"
    local output_dir="${3:-./build-output}"
    
    print_header "Running Build ($mode)"
    
    # Ensure output directory exists
    mkdir -p "$output_dir"
    local abs_output_dir=$(realpath "$output_dir")
    
    # Create or use existing Docker volume for repositories
    local volume_name="seedsigner-repos"
    if ! docker volume ls | grep -q "$volume_name"; then
        print_success "Creating Docker volume for persistent repositories: $volume_name"
        docker volume create "$volume_name"
    else
        print_success "Using existing repository volume: $volume_name"
    fi
    
    # Set up build environment variables
    local env_args=""
    if [[ -n "$build_jobs" ]]; then
        env_args="-e BUILD_JOBS=$build_jobs"
        print_success "Using $build_jobs parallel build jobs"
    fi
    
    # Docker run arguments with persistent volume
    local docker_args="$PLATFORM_ARGS 
                       --name $CONTAINER_NAME 
                       --rm
                       -v $volume_name:/build/repos
                       -v $abs_output_dir:/build/output
                       $env_args"
    
    case "$mode" in
        "build")
            print_success "Starting automated build..."
            if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
                print_warning "ARM64 build will take 60-120 minutes due to emulation"
            else
                print_warning "Build will take 30-90 minutes"
            fi
            print_success "Repository volume: $volume_name (persists between builds)"
            docker run $docker_args "$IMAGE_NAME" auto
            ;;
        "interactive")
            print_success "Starting interactive mode..."
            print_success "Repository volume: $volume_name (persists between sessions)"
            docker run -it $docker_args "$IMAGE_NAME" interactive
            ;;
        "shell")
            print_success "Starting direct shell..."
            print_success "Repository volume: $volume_name (persists between sessions)"
            docker run -it $docker_args "$IMAGE_NAME" shell
            ;;
        *)
            print_error "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

clean_environment() {
    print_header "Cleaning Environment"
    
    # Stop and remove any running containers
    if docker ps -a --format "{{.Names}}" | grep -q "seedsigner-build"; then
        print_warning "Stopping existing build containers..."
        docker ps -a --format "{{.Names}}" | grep "seedsigner-build" | xargs docker rm -f
    fi
    
    # Remove Docker volume if requested
    local volume_name="seedsigner-repos"
    if docker volume ls | grep -q "$volume_name"; then
        read -p "Remove persistent repository volume '$volume_name'? This will force re-cloning repos (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker volume rm "$volume_name" 2>/dev/null || print_warning "Volume cleanup failed"
            print_success "Repository volume removed - repos will be re-cloned on next build"
        else
            print_success "Repository volume preserved - faster subsequent builds"
        fi
    fi
    
    # Remove image if requested
    read -p "Remove Docker image '$IMAGE_NAME'? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rmi "$IMAGE_NAME" 2>/dev/null || print_warning "Image not found"
        print_success "Docker image removed"
    fi
    
    # Clean build output
    read -p "Remove build-output directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf build-output
        print_success "Build output removed"
    fi
    
    print_success "Environment cleaned"
}

extract_artifacts() {
    print_header "Extracting Build Artifacts"
    
    local output_dir="${1:-./build-output}"
    mkdir -p "$output_dir"
    
    # Look for running or stopped containers with our name pattern
    local container=$(docker ps -a --format "{{.Names}}" | grep "seedsigner-build" | head -1)
    
    if [[ -n "$container" ]]; then
        print_success "Found container: $container"
        docker cp "$container:/build/output/." "$output_dir/"
        print_success "Artifacts extracted to: $output_dir"
        echo ""
        echo "Build artifacts:"
        ls -la "$output_dir/"
    else
        print_error "No build container found"
        echo "Available containers:"
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    fi
}

show_status() {
    print_header "Build System Status"
    
    echo "Script directory: $SCRIPT_DIR"
    echo "Architecture: $(uname -m)"
    echo "Platform args: ${PLATFORM_ARGS:-none}"
    
    # Check Docker image
    if docker images | grep -q "$IMAGE_NAME"; then
        print_success "Docker image '$IMAGE_NAME' exists"
        docker images | grep "$IMAGE_NAME"
    else
        print_warning "Docker image '$IMAGE_NAME' not built yet"
    fi
    
    # Check Docker volume for repositories
    local volume_name="seedsigner-repos"
    if docker volume ls | grep -q "$volume_name"; then
        print_success "Repository volume '$volume_name' exists (persistent repos)"
        # Try to get volume info
        local volume_info=$(docker volume inspect "$volume_name" 2>/dev/null | grep '"Mountpoint"' | cut -d'"' -f4)
        echo "  Volume path: ${volume_info:-unknown}"
    else
        print_warning "Repository volume '$volume_name' not created yet"
        echo "  First build will clone repos and create volume"
    fi
    
    # Check for running containers
    local running=$(docker ps --format "{{.Names}}" | grep "seedsigner-build" | head -1)
    if [[ -n "$running" ]]; then
        print_success "Build container running: $running"
    fi
    
    # Check for build output
    if [[ -d "build-output" ]] && [[ "$(ls -A build-output 2>/dev/null)" ]]; then
        print_success "Build output exists:"
        ls -la build-output/ | head -5
    else
        print_warning "No build output found"
    fi
}

# Main script logic
main() {
    local command="${1:-build}"
    local force_rebuild=false
    local build_jobs=""
    local output_dir=""
    
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
            --jobs|-j)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    build_jobs="$2"
                    shift 2
                else
                    print_error "Invalid or missing argument for --jobs"
                    exit 1
                fi
                ;;
            --output)
                if [[ -n "$2" ]]; then
                    output_dir="$2"
                    shift 2
                else
                    print_error "Missing argument for --output"
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
    
    # Set default output directory if not specified
    output_dir="${output_dir:-./build-output}"
    
    # Always check Docker for most commands
    if [[ "$command" != "status" ]]; then
        check_docker
    fi
    
    case "$command" in
        "status")
            show_status
            ;;
        "build")
            build_docker_image "$force_rebuild"
            run_build "build" "$build_jobs" "$output_dir"
            ;;
        "interactive")
            build_docker_image "$force_rebuild"
            run_build "interactive" "$build_jobs" "$output_dir"
            ;;
        "shell")
            build_docker_image "$force_rebuild"
            run_build "shell" "$build_jobs" "$output_dir"
            ;;
        "clean")
            clean_environment
            ;;
        "extract")
            extract_artifacts "$output_dir"
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
