#!/bin/bash

# Base Paths - now using environment variables defined in Docker
# These are set in the Dockerfile and sdk_init.sh
SEEDSIGNER_OS_DIR="/mnt/ssos"
SEEDSIGNER_CODE_DIR="/mnt/ss"
SEEDSIGNER_LUCKFOX_DIR="/mnt/cfg/"
LUCKFOX_SDK_DIR="/mnt/host"

# Define common paths - now using environment variables
BUILDROOT_DIR="${LUCKFOX_SDK_DIR}/sysdrv/source/buildroot/buildroot-2023.02.6"
PACKAGE_DIR="${BUILDROOT_DIR}/package"
CONFIG_IN="${PACKAGE_DIR}/Config.in"
PYZBAR_PATCH="${PACKAGE_DIR}/python-pyzbar/0001-PATH-fixed-by-hand.patch"
ROOTFS_DIR="${LUCKFOX_SDK_DIR}/output/out/rootfs_uclibc_rv1106"

# Check if environment variables are set
if [ -z "$SEEDSIGNER_OS_DIR" ] || [ -z "$SEEDSIGNER_CODE_DIR" ] || [ -z "$LUCKFOX_SDK_DIR" ] || [ -z "$BUILDROOT_DIR" ]; then
    echo "Error: Required environment variables are not set. Please ensure you're running in the Docker container."
    echo "Required variables: SEEDSIGNER_OS_DIR, SEEDSIGNER_CODE_DIR, LUCKFOX_SDK_DIR, BUILDROOT_DIR"
    exit 1
fi

./build.sh clean

echo -e "\n\n\n" | timeout 5s ./build.sh buildrootconfig

# TODO: Put this checks before we enter the container 
# Check if buildroot directory exists
if [ ! -d "${BUILDROOT_DIR}" ]; then
    echo "Error: ${BUILDROOT_DIR} does not exist. Please run './build.sh buildrootconfig' first"
    exit 1
fi

Check if Config.in exists
if [ ! -f "${CONFIG_IN}" ]; then
    echo "Error: ${CONFIG_IN} does not exist. Please run './build.sh buildrootconfig' first"
    exit 1
fi

# Check if SeedSigner code directory exists
if [ ! -d "${SEEDSIGNER_CODE_DIR}" ]; then
    echo "Error: ${SEEDSIGNER_CODE_DIR} does not exist. Please clone the seedsigner repo."
    echo "git clone https://github.com/lightningspore/seedsigner.git"
    exit 1
fi

# Check if SeedSigner OS directory exists
if [ ! -d "${SEEDSIGNER_OS_DIR}" ]; then
    echo "Error: ${SEEDSIGNER_OS_DIR} does not exist. Please clone the seedsigner-os repo."
    echo "git clone https://github.com/SeedSigner/seedsigner-os.git"
    exit 1
fi


# Copy external packages
echo "Copying external packages..."
# TODO: PACKAGE_DIR doesnt exist until `./build.sh buildrootconfig`
cp -rv $SEEDSIGNER_OS_DIR/opt/external-packages/* "${PACKAGE_DIR}/"

# Update Python path in pyzbar patch
echo "Updating Python path in pyzbar patch..."
sed -i 's|path = ".*/site-packages/zbar.so"|path = "/usr/lib/python3.11/site-packages/zbar.so"|' "${PYZBAR_PATCH}"

# Add SeedSigner packages to Config.in
echo "Adding SeedSigner packages to Config.in..."
cat << 'EOF' | tee -a "${CONFIG_IN}"
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

# Default selections for SeedSigner packages
config BR2_PACKAGE_PYTHON_URTYPES
	default y

config BR2_PACKAGE_PYTHON_PYZBAR
	default y

config BR2_PACKAGE_PYTHON_MOCK
	default y

config BR2_PACKAGE_PYTHON_EMBIT
	default y

config BR2_PACKAGE_PYTHON_PILLOW
	default y

config BR2_PACKAGE_LIBCAMERA
	default y

config BR2_PACKAGE_LIBCAMERA_APPS
	default y

config BR2_PACKAGE_ZBAR
	default y

config BR2_PACKAGE_JPEG_TURBO
	default y

config BR2_PACKAGE_JPEG
	default y

config BR2_PACKAGE_PYTHON_QRCODE
	default y

config BR2_PACKAGE_PYTHON_PYQRCODE
	default y
EOF

# NOW RUN ./build.sh buildrootconfig
# OR 
# FIGURE OUT HOW TO COPY THE BUILDROOT CONFIG

# select all these packages required for seedsigner from the menu above
#cp -v /mnt/cfg/buildroot/config-latest /mnt/host/sysdrv/source/buildroot/buildroot-2023.02.6/.config

echo "Running ./build.sh buildrootconfig a 2nd time, ensure all packages are selected!" 
./build.sh buildrootconfig


# builds the first 3 parts:
echo "*** Building U-Boot..."
./build.sh uboot
echo "*** Building Kernel..."
./build.sh kernel
echo "*** Building Rootfs..."
./build.sh rootfs


# Copy SeedSigner code and config
echo "Copying SeedSigner code and configuration..."
cp -rv "${SEEDSIGNER_CODE_DIR}/src/" "${ROOTFS_DIR}/seedsigner"
cp -v /mnt/cfg/buildroot/files/luckfox.cfg "${ROOTFS_DIR}/etc/luckfox.cfg"

# TODO: Document nv12_converter. Very important!
# Re-obtain the C code. It was removed from the repo.
cp -v /mnt/cfg/buildroot/files/nv12_converter "${ROOTFS_DIR}"
cp -v /mnt/cfg/buildroot/files/start-seedsigner.sh "${ROOTFS_DIR}"
cp -v /mnt/cfg/buildroot/files/S99seedsigner "${ROOTFS_DIR}/etc/init.d/"

echo "Done! SeedSigner packages have been added to buildroot configuration."

echo "*** Building Media..."
./build.sh media
echo "*** Building App..."
./build.sh app
echo "*** Building Firmware..."
./build.sh firmware

echo "Building Final Image..."
cd /mnt/host/output/image
TS=$(date +%Y%m%d_%H%M%S)
/mnt/cfg/buildroot/blkenvflash seedsigner-luckfox-pico-${TS}.img

echo "Done! Final image is at /mnt/host/output/image/seedsigner-luckfox-pico-${TS}.img"