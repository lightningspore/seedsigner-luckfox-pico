# Export base paths
export LUCKFOX_SDK_DIR="/mnt/host"
export SEEDSIGNER_OS_DIR="/mnt/ssos"
export SEEDSIGNER_CODE_DIR="/mnt/ss"
export SEEDSIGNER_LUCKFOX_DIR="/mnt/cfg"

# Export derived paths using base paths
export BUILDROOT_DIR="${LUCKFOX_SDK_DIR}/sysdrv/source/buildroot/buildroot-2023.02.6"
export PACKAGE_DIR="${BUILDROOT_DIR}/package"
export CONFIG_IN="${PACKAGE_DIR}/Config.in"
export PYZBAR_PATCH="${PACKAGE_DIR}/python-pyzbar/0001-PATH-fixed-by-hand.patch"
export ROOTFS_DIR="${LUCKFOX_SDK_DIR}/output/out/rootfs_uclibc_rv1106"

cd $LUCKFOX_SDK_DIR/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/
source env_install_toolchain.sh
cd $LUCKFOX_SDK_DIR