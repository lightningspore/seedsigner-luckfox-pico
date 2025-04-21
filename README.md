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
The OS image can be built using the buildroot scripts in the [buildroot](buildroot/) directory. See [OS-build-instructions.md](buildroot/OS-build-instructions.md) for detailed build instructions.

![Buildroot Prompt](img/seedsigner-buildroot-setup.webp)

The build process requires Docker and follows these main steps:
1. Setup Docker build environment
2. Clone Luckfox SDK
3. Configure buildroot packages (RKISP, LIBCAMERA, ZBAR, LIBJPEG)
4. Build U-Boot, kernel, rootfs, and media components
5. Package the final firmware image

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
The test suite verifies all hardware components of the device:

```
# push over the test file
adb push test_suite /
```

# Get to a device shell using adb
```
adb shell
```

# Run Test Suite
cd /test_suite
python test.py
```

The test suite includes:
- Button testing (all 8 buttons)
- Camera testing (capture and display)
- LCD display testing
- QR code testing

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

## Flashing the Device

### MICROSD CARD: Package individually made OS images to a flashable version
```
# cd to directory containing all of the individual images
./blkenvflash final-image.img
```

### ONBOARD! SPI Flash: version directly on device
```
# cd to directory containing all of the individual images
sudo rkflash.sh update
```

### Flash MicroSD Card
```
sudo dd bs=4M status=progress if=/path/to/update.img of=/dev/diskX
```
Replace `/dev/diskX` with your actual SD card device path.
