#!/bin/bash
# SeedSigner Self-Contained Build Script - No Home Directory Pollution!
# All repositories cloned inside container - completely portable

set -e

# Environment setup - everything happens inside /build
export BUILD_DIR="/build"
export REPOS_DIR="/build/repos"
export OUTPUT_DIR="/build/output"

# Repository URLs for cloning
export LUCKFOX_REPO_URL="https://github.com/lightningspore/luckfox-pico.git"
export SEEDSIGNER_REPO_URL="https://github.com/lightningspore/seedsigner.git"
export SEEDSIGNER_BRANCH="upstream-luckfox-staging-1"
export SEEDSIGNER_OS_REPO_URL="https://github.com/seedsigner/seedsigner-os.git"

# Internal paths (after cloning)
export LUCKFOX_SDK_DIR="$REPOS_DIR/luckfox-pico"
export SEEDSIGNER_CODE_DIR="$REPOS_DIR/seedsigner"
export SEEDSIGNER_OS_DIR="$REPOS_DIR/seedsigner-os"
export SEEDSIGNER_LUCKFOX_DIR="/build"

# Common paths (computed after SDK directory is determined)
export BUILDROOT_DIR="${LUCKFOX_SDK_DIR}/sysdrv/source/buildroot/buildroot-2023.02.6"
export PACKAGE_DIR="${BUILDROOT_DIR}/package"
export CONFIG_IN="${PACKAGE_DIR}/Config.in"
export PYZBAR_PATCH="${PACKAGE_DIR}/python-pyzbar/0001-PATH-fixed-by-hand.patch"
export ROOTFS_DIR="${LUCKFOX_SDK_DIR}/output/out/rootfs_uclibc_rv1106"

# Parallel build configuration
export BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
export MAKEFLAGS="-j${BUILD_JOBS}"
export BR2_JLEVEL="${BUILD_JOBS}"
export FORCE_UNSAFE_CONFIGURE=1

# Colors for output
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_step() { echo -e "\n${BLUE}[STEP] $1${NC}\n"; }
print_success() { echo -e "\n${GREEN}[SUCCESS] $1${NC}\n"; }
print_error() { echo -e "\n${RED}[ERROR] $1${NC}\n"; }
print_info() { echo -e "\n${YELLOW}[INFO] $1${NC}\n"; }

show_usage() {
    echo "SeedSigner Self-Contained Build System"
    echo "Usage: $0 [auto|interactive|shell|clone-only]"
    echo ""
    echo "  auto        - Run full automated build with repo cloning (default)"
    echo "  interactive - Clone repos + drop into interactive shell"
    echo "  shell       - Drop directly into shell (no setup)"
    echo "  clone-only  - Only clone repositories and exit"
    echo ""
    echo "Features:"
    echo "  - All repositories cloned inside container"
    echo "  - No host directory pollution"
    echo "  - Self-contained and portable"
    echo ""
}

clone_repositories() {
    print_step "Cloning Required Repositories"
    
    mkdir -p "$REPOS_DIR"
    cd "$REPOS_DIR"
    
    # Clone luckfox-pico SDK
    if [[ ! -d "luckfox-pico" ]]; then
        print_info "Cloning luckfox-pico SDK..."
        git clone "$LUCKFOX_REPO_URL" --depth=1 --single-branch luckfox-pico
        print_success "luckfox-pico cloned"
    else
        print_info "luckfox-pico already exists"
    fi
    
    # Clone SeedSigner OS packages
    if [[ ! -d "seedsigner-os" ]]; then
        print_info "Cloning seedsigner-os packages..."
        git clone "$SEEDSIGNER_OS_REPO_URL" --depth=1 --single-branch seedsigner-os
        print_success "seedsigner-os cloned"
    else
        print_info "seedsigner-os already exists"
    fi
    
    # Clone SeedSigner code (specific branch)
    if [[ ! -d "seedsigner" ]]; then
        print_info "Cloning seedsigner code (branch: $SEEDSIGNER_BRANCH)..."
        git clone "$SEEDSIGNER_REPO_URL" --depth=1 -b "$SEEDSIGNER_BRANCH" --single-branch seedsigner
        print_success "seedsigner cloned"
    else
        print_info "seedsigner already exists"
    fi
    
    # Show repository status
    print_info "Repository Status:"
    echo "  luckfox-pico: $(du -sh luckfox-pico 2>/dev/null | cut -f1 || echo 'missing')"
    echo "  seedsigner-os: $(du -sh seedsigner-os 2>/dev/null | cut -f1 || echo 'missing')"  
    echo "  seedsigner: $(du -sh seedsigner 2>/dev/null | cut -f1 || echo 'missing')"
    echo "  Total: $(du -sh . 2>/dev/null | cut -f1 || echo 'unknown')"
    
    print_success "All repositories cloned successfully"
}

validate_environment() {
    print_step "Validating Build Environment"
    
    local required_dirs=(
        "$LUCKFOX_SDK_DIR"
        "$SEEDSIGNER_CODE_DIR"  
        "$SEEDSIGNER_OS_DIR"
    )
    
    local required_items=(
        "$LUCKFOX_SDK_DIR/build.sh"
        "$SEEDSIGNER_CODE_DIR/src"
        "$SEEDSIGNER_OS_DIR/opt/external-packages"
    )
    
    local missing_dirs=()
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
            echo "[ERROR] Missing: $dir"
        else
            echo "[OK] Found: $dir"
        fi
    done
    
    local missing_items=()
    for item in "${required_items[@]}"; do
        if [[ ! -e "$item" ]]; then
            missing_items+=("$item")
            echo "[ERROR] Missing: $item"
        else
            echo "[OK] Found: $item"
        fi
    done
    
    if [[ ${#missing_dirs[@]} -ne 0 || ${#missing_items[@]} -ne 0 ]]; then
        print_error "Environment validation failed"
        echo "Missing directories: ${missing_dirs[*]}"
        echo "Missing items: ${missing_items[*]}"
        echo "Try running with 'clone-only' mode first to setup repositories"
        exit 1
    fi
    
    print_success "Environment validation complete"
}

setup_sdk_environment() {
    print_step "Setting Up SDK Environment"
    
    cd "$LUCKFOX_SDK_DIR"
    
    # Initialize SDK if needed (creates .BoardConfig.mk)
    if [[ ! -f ".BoardConfig.mk" ]]; then
        print_info "Initializing SDK (first time setup)..."
        # Run the SDK init which creates the board config
        echo -e "\n\n\n" | timeout 10s ./build.sh lunch 2>/dev/null || {
            print_info "SDK lunch completed (timeout expected)"
        }
    fi
    
    # Source the toolchain environment
    local toolchain_dir="$LUCKFOX_SDK_DIR/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf"
    if [[ -f "$toolchain_dir/env_install_toolchain.sh" ]]; then
        print_info "Sourcing toolchain environment..."
        cd "$toolchain_dir"
        set +e  # Temporarily disable exit on error
        source env_install_toolchain.sh 2>/dev/null
        local source_result=$?
        set -e  # Re-enable exit on error
        
        cd "$LUCKFOX_SDK_DIR"
        print_success "Toolchain environment configured"
    else
        print_error "Toolchain environment script not found at: $toolchain_dir/env_install_toolchain.sh"
        exit 1
    fi
}

run_automated_build() {
    print_step "Starting Automated SeedSigner Build"
    
    # Show build configuration
    print_info "Build Configuration:"
    echo "   CPU Cores Available: $(nproc)"
    echo "   Build Jobs: $BUILD_JOBS"
    echo "   MAKEFLAGS: $MAKEFLAGS"
    echo "   Build Directory: $BUILD_DIR"
    echo "   Output Directory: $OUTPUT_DIR"
    
    # Setup repositories and environment
    clone_repositories
    validate_environment
    setup_sdk_environment
    
    # Clean any previous builds
    print_step "Cleaning Previous Build"
    cd "$LUCKFOX_SDK_DIR"
    ./build.sh clean
    
    # Initial buildroot configuration
    print_step "Initial Buildroot Configuration"
    echo -e "\n\n\n" | timeout 5s ./build.sh buildrootconfig || {
        print_error "buildrootconfig failed, continuing..."
    }
    
    # Verify buildroot directory exists
    if [[ ! -d "$BUILDROOT_DIR" ]]; then
        print_error "Buildroot directory not found: $BUILDROOT_DIR"
        exit 1
    fi
    
    # Install SeedSigner packages
    print_step "Installing SeedSigner Packages"
    cp -rv "$SEEDSIGNER_OS_DIR/opt/external-packages/"* "$PACKAGE_DIR/"
    
    # Update Python path in pyzbar patch
    print_step "Updating pyzbar Configuration"
    if [[ -f "$PYZBAR_PATCH" ]]; then
        sed -i 's|path = ".*/site-packages/zbar.so"|path = "/usr/lib/python3.11/site-packages/zbar.so"|' "$PYZBAR_PATCH"
    fi
    
    # Add SeedSigner packages to Config.in
    print_step "Adding SeedSigner Menu to Buildroot"
    cat << 'CONFIGMENU' >> "$CONFIG_IN"
menu "SeedSigner"
        source "package/python-urtypes/Config.in"
        source "package/python-pyzbar/Config.in"
        source "package/python-mock/Config.in"
        source "package/python-embit/Config.in"
        source "package/python-pillow/Config.in"
        source "package/libcamera/Config.in"
        source "package/libcamera-apps/Config.in"
        source "package/zbar/Config.in"
        source "package/jpeg-turbo/Config.in.options"
        source "package/jpeg/Config.in"
        source "package/python-qrcode/Config.in"
        source "package/python-pyqrcode/Config.in"
endmenu
CONFIGMENU
    
    # Select a minimal set of packages to run seedsigner using a defconfig
    print_step "Applying SeedSigner Configuration"
    if [[ -f "/build/configs/luckfox_pico_defconfig" ]]; then
        cp -v "/build/configs/luckfox_pico_defconfig" \
              "$LUCKFOX_SDK_DIR/sysdrv/source/buildroot/buildroot-2023.02.6/configs/luckfox_pico_defconfig"
        cp -v "/build/configs/luckfox_pico_defconfig" \
              "$LUCKFOX_SDK_DIR/sysdrv/source/buildroot/buildroot-2023.02.6/.config"
    else
        print_error "SeedSigner configuration file not found"
        exit 1
    fi
    
    # Build components in order
    print_step "Building U-Boot"
    ./build.sh uboot
    
    print_step "Building Kernel"
    ./build.sh kernel
    
    print_step "Building Rootfs"
    ./build.sh rootfs
    
    print_step "Building Media Support"
    ./build.sh media
    
    print_step "Building Applications"
    ./build.sh app
    
    # Install SeedSigner code and configuration files
    print_step "Installing SeedSigner Code"
    cp -rv "$SEEDSIGNER_CODE_DIR/src/" "$ROOTFS_DIR/seedsigner"
    
    # Copy configuration files if they exist
    [[ -f "/build/files/luckfox.cfg" ]] && cp -v "/build/files/luckfox.cfg" "$ROOTFS_DIR/etc/luckfox.cfg"
    [[ -f "/build/files/nv12_converter" ]] && cp -v "/build/files/nv12_converter" "$ROOTFS_DIR/"
    [[ -f "/build/files/start-seedsigner.sh" ]] && cp -v "/build/files/start-seedsigner.sh" "$ROOTFS_DIR/"
    [[ -f "/build/files/S99seedsigner" ]] && cp -v "/build/files/S99seedsigner" "$ROOTFS_DIR/etc/init.d/"
    
    # Package firmware
    print_step "Packaging Firmware"
    ./build.sh firmware
    
    # Create final image
    print_step "Creating Final Image"
    cd "$LUCKFOX_SDK_DIR/output/image"
    
    # Generate timestamped image name
    TS=$(date +%Y%m%d_%H%M%S)
    IMAGE="seedsigner-luckfox-pico-${TS}.img"
    
    # Create the final image
    if [[ -f "/build/blkenvflash" ]]; then
        "/build/blkenvflash" "$IMAGE"
    else
        print_error "blkenvflash tool not found"
        exit 1
    fi
    
    # Copy output to standardized location
    mkdir -p "$OUTPUT_DIR"
    cp -v "$IMAGE" "$OUTPUT_DIR/"
    cp -v * "$OUTPUT_DIR/" 2>/dev/null || true  # Copy other build artifacts
    
    print_success "Build Complete!"
    echo "Final image: $OUTPUT_DIR/$IMAGE"
    echo ""
    echo "Build artifacts:"
    ls -la "$OUTPUT_DIR/"
}

start_interactive_mode() {
    print_step "Starting Interactive Mode"
    
    clone_repositories
    validate_environment
    setup_sdk_environment
    
    print_success "Environment ready!"
    echo ""
    echo "Available commands:"
    echo "  - cd $LUCKFOX_SDK_DIR && ./build.sh [command]"
    echo "  - /build/docker-automation.sh auto  # Run full build"
    echo "  - exit  # Exit interactive mode"
    echo ""
    echo "Build artifacts will be available in: $OUTPUT_DIR"
    
    # Switch to SDK directory for convenience
    cd "$LUCKFOX_SDK_DIR"
    exec /bin/bash
}

# Main entry point
main() {
    local mode="${1:-auto}"
    
    case "$mode" in
        "auto")
            print_info "Starting automated build mode..."
            run_automated_build
            ;;
        "interactive")
            print_info "Starting interactive mode..."
            start_interactive_mode
            ;;
        "shell")
            print_info "Starting direct shell..."
            exec /bin/bash
            ;;
        "clone-only")
            print_info "Cloning repositories only..."
            clone_repositories
            print_success "Repositories cloned. Container exiting."
            ;;
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown mode: $mode"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
