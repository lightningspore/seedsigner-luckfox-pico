#!/bin/bash
# Consolidated Docker Build Automation Script
# Combines: build_automation.sh + validate_environment.sh + add_package_buildroot.sh + sdk_init.sh

set -e

# Environment setup (from sdk_init.sh)
export LUCKFOX_SDK_DIR="/mnt/host"
export SEEDSIGNER_OS_DIR="/mnt/ssos"
export SEEDSIGNER_CODE_DIR="/mnt/ss"
export SEEDSIGNER_LUCKFOX_DIR="/mnt/cfg"
export BUILDROOT_DIR="${LUCKFOX_SDK_DIR}/sysdrv/source/buildroot/buildroot-2023.02.6"
export PACKAGE_DIR="${BUILDROOT_DIR}/package"
export CONFIG_IN="${PACKAGE_DIR}/Config.in"
export PYZBAR_PATCH="${PACKAGE_DIR}/python-pyzbar/0001-PATH-fixed-by-hand.patch"
export ROOTFS_DIR="${LUCKFOX_SDK_DIR}/output/out/rootfs_uclibc_rv1106"

# Parallel build configuration
export BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
export MAKEFLAGS="-j${BUILD_JOBS}"
export BR2_JLEVEL="${BUILD_JOBS}"

# Export parallel build variables for compatibility
export FORCE_UNSAFE_CONFIGURE=1

# Colors for output
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_step() { echo -e "\n${BLUE}🔧 $1${NC}\n"; }
print_success() { echo -e "\n${GREEN}✅ $1${NC}\n"; }
print_error() { echo -e "\n${RED}❌ $1${NC}\n"; }

show_usage() {
    echo "Usage: $0 [auto|interactive|shell|validate]"
    echo ""
    echo "  auto        - Run the full automated build (default)"
    echo "  interactive - Drop into interactive shell after validation"
    echo "  shell       - Drop directly into shell (skip validation)"
    echo "  validate    - Only run environment validation"
    echo ""
}

validate_environment() {
    print_step "Validating Build Environment"
    
    local required_dirs=(
        "/mnt/host"          # LUCKFOX_SDK_DIR
        "/mnt/ss"            # SEEDSIGNER_CODE_DIR  
        "/mnt/cfg"           # SEEDSIGNER_LUCKFOX_DIR
        "/mnt/ssos"          # SEEDSIGNER_OS_DIR
    )
    
    local missing_dirs=()
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
            echo "❌ Missing: $dir"
        elif [[ -z "$(ls -A "$dir" 2>/dev/null | grep -v -E '\.(DS_Store|git|github|gitignore)$')" ]]; then
            echo "⚠️ Empty: $dir"
        else
            echo "✅ Found: $dir"
        fi
    done
    
    # Check specific required files/directories
    local required_files=(
        "/mnt/host/build.sh"
        "/mnt/ss/src"
        "/mnt/cfg/buildroot/add_package_buildroot.sh"
        "/mnt/ssos/opt/external-packages"
    )
    
    local missing_files=()
    for file in "${required_files[@]}"; do
        if [[ ! -e "$file" ]]; then
            missing_files+=("$file")
            echo "❌ Missing file/directory: $file"
        else
            echo "✅ Required file/directory exists: $file"
        fi
    done
    
    if [[ ${#missing_dirs[@]} -ne 0 || ${#missing_files[@]} -ne 0 ]]; then
        print_error "Environment validation failed"
        echo "Missing directories: ${missing_dirs[*]}"
        echo "Missing files: ${missing_files[*]}"
        echo ""
        echo "Please ensure all required repositories are cloned and properly mounted"
        exit 1
    fi
    
    print_success "Environment validation complete"
}

setup_sdk_environment() {
    print_step "Setting Up SDK Environment"
    
    # Save current directory and script path
    local original_dir=$(pwd)
    local script_path="/app/docker-automation.sh"
    
    # Change to toolchain directory and source environment
    cd "${LUCKFOX_SDK_DIR}/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/"
    
    # Source the toolchain environment carefully
    if [[ -f "env_install_toolchain.sh" ]]; then
        echo "📦 Sourcing toolchain environment..."
        set +e  # Temporarily disable exit on error
        source env_install_toolchain.sh 
        local source_result=$?
        set -e  # Re-enable exit on error
        
        if [[ $source_result -ne 0 ]]; then
            echo "⚠️ Toolchain environment sourcing had issues, continuing..."
        fi
    else
        print_error "Toolchain environment script not found!"
        exit 1
    fi
    
    # Return to SDK directory
    cd "${LUCKFOX_SDK_DIR}"
    print_success "SDK environment configured"
}

run_automated_build() {
    print_step "Starting Automated SeedSigner Build"
    
    # Show parallel build configuration
    echo "🚀 Parallel Build Configuration:"
    echo "   CPU Cores Available: $(nproc)"
    echo "   Build Jobs: ${BUILD_JOBS}"
    echo "   MAKEFLAGS: ${MAKEFLAGS}"
    echo ""
    
    # Environment setup
    validate_environment
    setup_sdk_environment
    
    # Clean previous build
    print_step "Cleaning Previous Build"
    ./build.sh clean
    
    # Initial buildroot config
    print_step "Initial Buildroot Configuration"
    echo -e "\n\n\n" | timeout 5s ./build.sh buildrootconfig || {
        print_error "buildrootconfig failed, continuing anyway"
    }
    
    # Check if buildroot directory exists after config
    if [[ ! -d "$BUILDROOT_DIR" ]]; then
        print_error "$BUILDROOT_DIR missing after buildrootconfig"
        exit 1
    fi
    
    # Copy external packages
    print_step "Installing SeedSigner Packages"
    cp -rv "${SEEDSIGNER_OS_DIR}/opt/external-packages/"* "${PACKAGE_DIR}/"
    
    # Update Python path in pyzbar patch
    print_step "Updating pyzbar Configuration"
    sed -i 's|path = ".*/site-packages/zbar.so"|path = "/usr/lib/python3.11/site-packages/zbar.so"|' "${PYZBAR_PATCH}"
    
    # Add SeedSigner packages to Config.in
    print_step "Adding SeedSigner Menu to Buildroot"
    cat << 'CONFIGMENU' >> "${CONFIG_IN}"
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
    
    # Apply configuration
    print_step "Applying SeedSigner Configuration"
    cp -v "${SEEDSIGNER_LUCKFOX_DIR}/buildroot/configs/luckfox_pico_defconfig" \
          "${LUCKFOX_SDK_DIR}/sysdrv/source/buildroot/buildroot-2023.02.6/configs/luckfox_pico_defconfig"
    cp -v "${SEEDSIGNER_LUCKFOX_DIR}/buildroot/configs/luckfox_pico_defconfig" \
          "${LUCKFOX_SDK_DIR}/sysdrv/source/buildroot/buildroot-2023.02.6/.config"
    
    # Build components
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
    
    # Install SeedSigner code and configuration
    print_step "Installing SeedSigner Code"
    cp -rv "${SEEDSIGNER_CODE_DIR}/src/" "${ROOTFS_DIR}/seedsigner"
    cp -v "${SEEDSIGNER_LUCKFOX_DIR}/buildroot/files/luckfox.cfg" "${ROOTFS_DIR}/etc/luckfox.cfg"
    cp -v "${SEEDSIGNER_LUCKFOX_DIR}/buildroot/files/nv12_converter" "${ROOTFS_DIR}/"
    cp -v "${SEEDSIGNER_LUCKFOX_DIR}/buildroot/files/start-seedsigner.sh" "${ROOTFS_DIR}/"
    cp -v "${SEEDSIGNER_LUCKFOX_DIR}/buildroot/files/S99seedsigner" "${ROOTFS_DIR}/etc/init.d/"
    
    # Package firmware
    print_step "Packaging Firmware"
    ./build.sh firmware
    
    # Create final image
    print_step "Creating Final Image"
    cd "${LUCKFOX_SDK_DIR}/output/image"
    TS=$(date +%Y%m%d_%H%M%S)
    IMAGE="seedsigner-luckfox-pico-${TS}.img"
    "${SEEDSIGNER_LUCKFOX_DIR}/buildroot/blkenvflash" "$IMAGE"
    
    print_success "Build Complete! Final image: ${LUCKFOX_SDK_DIR}/output/image/$IMAGE"
    
    # List final outputs
    echo "📦 Build outputs:"
    ls -la "${LUCKFOX_SDK_DIR}/output/image/"
}

# Handle command line arguments
MODE="${1:-auto}"

case "$MODE" in
    "auto")
        echo "🚀 Starting automated SeedSigner build process..."
        run_automated_build
        ;;
    "interactive")
        echo "🔧 Starting interactive mode..."
        validate_environment
        setup_sdk_environment
        print_success "Environment validated. Dropping into interactive shell."
        echo "💡 To run the automated build, execute: /app/docker-automation.sh auto"
        exec /bin/bash
        ;;
    "shell")
        echo "🐚 Dropping into shell..."
        exec /bin/bash
        ;;
    "validate")
        echo "🔍 Running environment validation only..."
        validate_environment
        exit 0
        ;;
    "help"|"-h"|"--help")
        show_usage
        exit 0
        ;;
    *)
        echo "Unknown mode: $MODE"
        show_usage
        exit 1
        ;;
esac

# If we get here from auto mode, keep container alive
if [[ "$MODE" == "auto" ]]; then
    print_success "Automated build process completed!"
    echo "🐚 Keeping container alive for artifact extraction..."
    echo "💡 Use 'docker cp' to extract build artifacts from the container"
    echo "💡 Press Ctrl+C to stop the container"
    
    # Keep container alive for artifact extraction
    sleep infinity
fi
