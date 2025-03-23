# seedsigner-luckfox-pico
Port of the SeedSigner code to the LuckFox Pico Pro/Max embedded ARM(ricv?) linux board

## Demo Videos

### First Look: Seedsigner running on Luckfox Pico linux devboard
[![SeedSigner on LuckFox Pico Pro Max](https://img.youtube.com/vi/WHkOSn-lPG4/0.jpg)](https://www.youtube.com/watch?v=WHkOSn-lPG4)


## Hardware Photos

![LuckFox Pico Pro Max - Seedsigner](img/luckfox-devboard-front.webp)

![Case From Behind](img/luckfox-devboard-back.webp)



## Materials Needed
- $20 [Luckfox Pico Pro Max](https://www.amazon.com/dp/B0D6QVC178)
- $16 - [Luckfox Camera SC3336](https://www.amazon.com/dp/B0CJM7S6F6)
- $1 - [40 Pin Header](https://www.amazon.com/dp/B01461DQ6S)
- $16 - [Seedsigner LCD Button Board](https://www.amazon.com/dp/B07FDX5PJY)
- $0.25 - [2 x Row Header Male](https://www.amazon.com/dp/B07R5QDL8D)
- $5 - TODO: Link to PCB sales
- $2 - TODO: Link to 3D Printed Case sales

Being lazy and ordering almost everything from Amazon:

<b>Total Cost: ~$60</b>


## OS Image Build With Buildroot
The OS image can be built using the buildroot scripts in the [buildroot](buildroot/) directory. See [OS-build-instructions.md](OS-build-instructions.md) for detailed build instructions.

![Buildroot Prompt](img/seedsigner-buildroot-setup.webp)

Key files:
- `sdk_init.sh` - Sets up the build environment inside of the builder container
- `image_builder.py` - Creates the final disk image from partition images
- `uboot_parser.py` - Helper script for parsing U-Boot partition info

Follow the instructions in `buildroot/add_package_buildroot.txt` to add the required SeedSigner packages to the buildroot configuration.

## Dev machine setup

```
# mac
brew install homebrew/cask/android-platform-tools

# linux
sudo apt install android-tools-adb
```

## Initial Hardware Setup
<b>THESE INSTRUCTIONS NEED TO BE UPDATED</b>
(Most of this is done in the Buildroot OS Build section)

But seeing how it is done here can help as you go above development using the device.

This configures the GPIO on the device
```
adb push config/luckfox.cfg /etc/luckfox.cfg

# reboot the device
```

## Hardware Test Suite

```
# push over the test file
adb push test_suite /
```

# Get to a device shell using adb
```
adb shell
```

### Run Test Suite
```
cd /test_suite
python test.py
```

## Copy over modified SeedSigner code
```
git clone https://github.com/lightningspore/seedsigner.git
cd seedsigner
git checkout 0.8.0-luckfox
adb push src /seedsigner
```

## Run seedsigner
```
cd /seedsigner
python main.py
```



## MICROSD CARD: Package individually made OS images to a flashable version
```
# cd to directory containing all of the individual images
./blkenvflash final-image.img
```

## ONBOARD! SPI Flash: version directly on device
```
# cd to directory containing all of the individual images
sudo rkflash.sh update
/Users/lightningspore/Documents/repos/seedsigner-luckfox-pico/buildroot/luckfox-pico/rkflash.sh update
```

## Flash SD Card
```
sudo dd bs=4M status=progress if=/Users/lightningspore/Downloads/pro_buildroot_sd/update.img of=/dev/disk5
```
