docker build -t foxbuilder:latest .

export SDK_LOCAL_PATH=$(pwd)/luckfox-pico
git clone https://github.com/LuckfoxTECH/luckfox-pico.git --depth=1

# YOU MUST ENTER THE CONTAINER IN THE luckfox-pico sdk folder
docker run -it --name luckfox-builder -v $(pwd):/mnt/host foxbuilder:latest


export SDK_PATH=/mnt/host
cd $SDK_PATH/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/
source env_install_toolchain.sh
cd $SDK_PATH

# set build configuration
./build.sh lunch

# configure packages to install in buildroot
./build.sh buildrootconfig
# rksip
# libcamera
# zbar
# jpeg



# Use config from repo
cp ../.config sysdrv/source/buildroot/buildroot-2023.02.6/.config

./build.sh uboot
./build.sh kernel
./build.sh rootfs
# needed for camera libs
./build.sh media

# Package up the pieces
./build.sh firmware


# on LINUX x86 dev machine
scp -r spore@spore-server:/home/spore/repos/seedsigner-luckfox-pico/buildroot/luckfox-pico/output/image .

sudo /Users/spore/Documents/repos/seedsigner-luckfox-pico/buildroot/luckfox-pico/project/rkflash.sh update



pip download --no-binary ":all:" pyzbar@git+https://github.com/seedsigner/pyzbar.git@c3c237821c6a20b17953efe59b90df0b514a1c03