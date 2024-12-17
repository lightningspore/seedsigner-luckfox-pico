docker build -t foxbuilder:latest .

export SDK_LOCAL_PATH=$(pwd)/luckfox-pico
git clone https://github.com/LuckfoxTECH/luckfox-pico.git
docker run -it --name luckfox-builder -v $(pwd):/mnt/host foxbuilder:latest

export SDK_PATH=/mnt/host   
cd $SDK_PATH/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/
source env_install_toolchain.sh
cd $SDK_PATH

./build.sh lunch

./build.sh kernel
./build.sh firmware