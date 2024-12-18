docker build -t foxbuilder:latest .

export SDK_LOCAL_PATH=$(pwd)/luckfox-pico
git clone https://github.com/LuckfoxTECH/luckfox-pico.git --depth=1
docker run -it --name luckfox-builder -v $(pwd):/mnt/host foxbuilder:latest

export SDK_PATH=/mnt/host/luckfox-pico
cd $SDK_PATH/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/
source env_install_toolchain.sh
cd $SDK_PATH

# set build configuration
./build.sh lunch

# configure packages to install in buildroot
./build.sh buildrootconfig

# Use config from repo
cp ../.config sysdrv/source/buildroot/buildroot-2023.02.6/.config

./build.sh uboot
./build.sh kernel
./build.sh rootfs

# Package up the pieces
./build.sh firmware


# on LINUX x86 dev machine
scp -r spore@spore-server:/home/spore/repos/seedsigner-luckfox-pico/buildroot/luckfox-pico/output/image .

sudo /Users/spore/Documents/repos/seedsigner-luckfox-pico/buildroot/luckfox-pico/project/rkflash.sh update