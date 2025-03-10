# OS Build Instructions

## Setup the Docker build environment
Run these commands from `buildroot` directory.

Build the builder image:
```
docker build -t foxbuilder:latest .
```

Clone the Luckfox SDK repo:
```
export SDK_LOCAL_PATH=$(pwd)/luckfox-pico
git clone https://github.com/LuckfoxTECH/luckfox-pico.git --depth=1
```


## Run OS Build

Run these commands from `buildroot/luckfox-pico` directory. This is the directory/repo we cloned above.

```
# YOU MUST ENTER THE CONTAINER IN THE luckfox-pico sdk folder
docker run -it --name luckfox-builder -v $(pwd):/mnt/host foxbuilder:latest
```

These below commands are run INSIDE of the docker image.

This command sets up some PATHs and changes to the proper working directory.
```
export SDK_PATH=/mnt/host
cd $SDK_PATH/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/
source env_install_toolchain.sh
cd $SDK_PATH
```

This commands sets the build targets:
Select, Pico Pro Max, buildroot, and SPI.
```
# set build configuration
./build.sh lunch
```

This command allows us to choose what packages to install into our OS image.
```
# configure packages to install in buildroot
./build.sh buildrootconfig
## SELECT THESE BELOW PACKAGES
# RKISP
# LIBCAMERA
# ZBAR
# LIBJPEG
```
After selecting the above packages, SAVE the configuration.
The configuration is saved at: `sysdrv/source/buildroot/buildroot-2023.02.6/.config`

You can sanity check your configuration to ensure the selected packages have been enabled like so:
```
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep "LIBCAMERA"
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep "ZBAR"
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep "LIBJPEG"
...
```

A final sanity check, this shows all enabled packages... This might be useful as we try and remove any unnecessary packages from the build:
```
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep -v "^#"
```

This command will use one of the saved configurations for the build:
```
# Use config from repo
cp ../configs/config_20241218184332.config sysdrv/source/buildroot/buildroot-2023.02.6/.config

# Sanity check the configuration was loaded properly
# Selected packages like ZBAR should be listed as enabled here
./build.sh buildrootconfig
```

Start the image build process:
```
./build.sh uboot
./build.sh kernel
./build.sh rootfs
# needed for camera libs
./build.sh media

# Package up the pieces
./build.sh firmware
```


# on LINUX x86 dev machine
scp -r spore@spore-server:/home/spore/repos/seedsigner-luckfox-pico/buildroot/luckfox-pico/output/image .

sudo /Users/spore/Documents/repos/seedsigner-luckfox-pico/buildroot/luckfox-pico/project/rkflash.sh update



pip download --no-binary ":all:" pyzbar@git+https://github.com/seedsigner/pyzbar.git@c3c237821c6a20b17953efe59b90df0b514a1c03