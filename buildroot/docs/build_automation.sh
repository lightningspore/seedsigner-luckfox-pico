#!/bin/bash

# Build automation script for SeedSigner Luckfox Pico
# This script orchestrates the entire build process automatically

set -e

# Source the environment setup
source /etc/profile.d/sdk_init.sh

# Function to print colored output
print_step() {
    echo ""
    echo "🔧 =================================================="
    echo "🔧 $1"
    echo "🔧 =================================================="
    echo ""
}

print_success() {
    echo ""
    echo "✅ $1"
    echo ""
}

print_error() {
    echo ""
    echo "❌ $1"
    echo ""
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [auto|interactive|shell]"
    echo ""
    echo "  auto        - Run the full automated build (default)"
    echo "  interactive - Drop into interactive shell after validation"
    echo "  shell       - Drop directly into shell (skip validation)"
    echo "  validate    - Only run environment validation"
    echo ""
}

# Handle command line arguments
MODE="${1:-auto}"

case "$MODE" in
    "auto")
        echo "🚀 Starting automated SeedSigner build process..."
        ;;
    "interactive")
        echo "🔧 Starting interactive mode..."
        ;;
    "shell")
        echo "🐚 Dropping into shell..."
        exec /bin/bash
        ;;
    "validate")
        echo "🔍 Running environment validation only..."
        /app/validate_environment.sh
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

# Always validate environment first (unless in shell mode)
print_step "Validating Build Environment"
/app/validate_environment.sh

if [ "$MODE" = "interactive" ]; then
    print_success "Environment validation complete. Dropping into interactive shell."
    echo "💡 To run the automated build, execute: /mnt/cfg/buildroot/add_package_buildroot.sh"
    echo "💡 Or run individual build steps as documented in the build instructions."
    exec /bin/bash
fi

# Continue with automated build
print_step "Changing to SDK Directory"
cd "${LUCKFOX_SDK_DIR}"

print_step "Starting Automated Build Process"
print_success "Environment validated successfully. Beginning build..."

# Run the main build script
print_step "Executing SeedSigner Package Setup and Build"
echo "📍 Current working directory: $(pwd)"
echo "📍 Running: /mnt/cfg/buildroot/add_package_buildroot.sh"

# Execute the build script with proper error handling
if /mnt/cfg/buildroot/add_package_buildroot.sh; then
    print_success "Build completed successfully!"
    
    # Show final output information
    echo "📦 Build artifacts should be available at:"
    echo "   ${LUCKFOX_SDK_DIR}/output/image/"
    echo ""
    echo "🔍 Listing final build outputs:"
    if [ -d "${LUCKFOX_SDK_DIR}/output/image/" ]; then
        ls -la "${LUCKFOX_SDK_DIR}/output/image/"
    else
        echo "⚠️  Output directory not found at expected location"
    fi
    
    # Check for the final image
    FINAL_IMAGES=$(find "${LUCKFOX_SDK_DIR}/output/image/" -name "seedsigner-luckfox-pico-*.img" 2>/dev/null || true)
    if [ -n "$FINAL_IMAGES" ]; then
        echo ""
        echo "🎉 Final SeedSigner image(s) created:"
        echo "$FINAL_IMAGES"
    fi
    
else
    print_error "Build failed! Check the output above for error details."
    echo "💡 To debug interactively, run the container with:"
    echo "   docker run -it [your-volume-mounts] foxbuilder:latest interactive"
    exit 1
fi

print_success "Automated build process completed!"
echo "🐚 Keeping container alive for artifact extraction..."
echo "💡 Use 'docker cp' to extract build artifacts from the container"
echo "💡 Press Ctrl+C to stop the container"

# Keep container alive for artifact extraction
sleep infinity
