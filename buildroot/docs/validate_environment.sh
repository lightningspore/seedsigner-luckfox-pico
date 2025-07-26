#!/bin/bash

# Script to validate that all required directories and files are present
# before starting the build process

set -e

echo "🔍 Validating build environment..."

# Required directories that should be mounted
REQUIRED_DIRS=(
    "/mnt/host"          # LUCKFOX_SDK_DIR
    "/mnt/ss"            # SEEDSIGNER_CODE_DIR  
    "/mnt/cfg"           # SEEDSIGNER_LUCKFOX_DIR
    "/mnt/ssos"          # SEEDSIGNER_OS_DIR
)

# Check if all required directories exist and are not empty
missing_dirs=()
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        missing_dirs+=("$dir")
        echo "❌ Missing directory: $dir"
    elif [ -z "$(ls -A $dir)" ]; then
        echo "⚠️  Warning: Directory $dir exists but appears to be empty"
    else
        echo "✅ Directory $dir exists and contains files"
    fi
done

# Check specific required files/directories within mounted volumes
REQUIRED_FILES=(
    "/mnt/host/build.sh"
    "/mnt/ss/src"
    "/mnt/cfg/buildroot/add_package_buildroot.sh"
    "/mnt/ssos/opt/external-packages"
)

missing_files=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        missing_files+=("$file")
        echo "❌ Missing required file/directory: $file"
    else
        echo "✅ Required file/directory exists: $file"
    fi
done

# Report validation results
if [ ${#missing_dirs[@]} -ne 0 ] || [ ${#missing_files[@]} -ne 0 ]; then
    echo ""
    echo "❌ Environment validation failed!"
    echo ""
    echo "Missing directories: ${missing_dirs[*]}"
    echo "Missing files: ${missing_files[*]}"
    echo ""
    echo "Please ensure all required repositories are cloned and properly mounted:"
    echo "1. Clone required repositories in your HOME directory:"
    echo "   git clone https://github.com/lightningspore/luckfox-pico.git"
    echo "   git clone https://github.com/seedsigner/seedsigner-os.git"
    echo "   git clone https://github.com/lightningspore/seedsigner.git -b luckfox-dev"
    echo ""
    echo "2. Run Docker with proper volume mounts as specified in the documentation"
    exit 1
fi

echo ""
echo "✅ Environment validation successful! All required directories and files are present."
echo "📦 Ready to proceed with build process..."
echo ""
