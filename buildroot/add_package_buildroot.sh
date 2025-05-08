#!/bin/bash

# Define common paths
BUILDROOT_DIR="/mnt/host/sysdrv/source/buildroot/buildroot-2023.02.6"
PACKAGE_DIR="${BUILDROOT_DIR}/package"
CONFIG_IN="${PACKAGE_DIR}/Config.in"
PYZBAR_PATCH="${PACKAGE_DIR}/python-pyzbar/0001-PATH-fixed-by-hand.patch"
ROOTFS_DIR="/mnt/host/output/out/rootfs_uclibc_rv1106"
SEEDSIGNER_OS_DIR="/mnt/ssos"
SEEDSIGNER_CODE_DIR="/mnt/ss"


# Check if buildroot directory exists
if [ ! -d "${BUILDROOT_DIR}" ]; then
    echo "Error: ${BUILDROOT_DIR} does not exist. Please run './build.sh buildrootconfig' first"
    exit 1
fi

# Check if Config.in exists
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
cp -rv /mnt/ssos/opt/external-packages/* "${PACKAGE_DIR}/"

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
EOF

# NOW RUN ./build.sh buildrootconfig
# select all these packages required for seedsigner from the menu above

# Copy SeedSigner code and config
echo "Copying SeedSigner code and configuration..."
cp -r "${SEEDSIGNER_CODE_DIR}/src/" "${ROOTFS_DIR}/seedsigner"
cp /mnt/cfg/config/luckfox.cfg "${ROOTFS_DIR}/etc/luckfox.cfg"
cp /mnt/cfg/nv12_converter "${ROOTFS_DIR}"
cp /mnt/cfg/start-seedsigner.sh "${ROOTFS_DIR}"

echo "Done! SeedSigner packages have been added to buildroot configuration."

./build.sh media
./build.sh app

./build.sh firmware

cd /mnt/host/output/image

/mnt/cfg/buildroot/blkenvflash seedsigner-luckfox-pico.img

