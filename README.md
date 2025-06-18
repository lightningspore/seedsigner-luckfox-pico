# seedsigner-luckfox-pico
Port of the SeedSigner code to the LuckFox Pico Pro/Max embedded ARM(ricv?) linux board

## Demo Videos

### First Look: Seedsigner running on Luckfox Pico linux devboard
[![SeedSigner on LuckFox Pico Pro Max](https://img.youtube.com/vi/WHkOSn-lPG4/0.jpg)](https://www.youtube.com/watch?v=WHkOSn-lPG4)

## Support the Developer
If you find this project helpful and would like to support its development, you can buy me a coffee! Your support helps keep this project going and funds future improvements. Help decentralize Bitcoin hardware!

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/lightningspore)

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
The OS image is built using Buildroot in a Docker container. The complete build process is documented in [OS-build-instructions.md](buildroot/OS-build-instructions.md).

![Buildroot Prompt](img/seedsigner-buildroot-setup.webp)

For detailed build instructions, package requirements, and troubleshooting, see [OS-build-instructions.md](buildroot/OS-build-instructions.md).

## Dev machine setup

### Install ADB
I find developing for the Luckfox Pico device to be fairly convenient since it works with `adb`. You can push files back and forth to your dev machine, and you can access the device as a shell easily.
```
# mac
brew install homebrew/cask/android-platform-tools

# linux
sudo apt install android-tools-adb
```

### ADB Connection and Device Management

1. Connect to the device:
```
# List connected devices
adb devices

# Connect to device shell
adb shell

# Check device info
adb shell uname -a
adb shell cat /proc/version
```

2. File Operations:
```
# Push files to device
adb push local_file.txt /remote/path/

# Pull files from device
adb pull /remote/path/file.txt .

# List files on device

adb shell ls /path/to/directory
```



## Initial Hardware Setup
<b>THESE INSTRUCTIONS NEED TO BE UPDATED</b>
(Most of this is done in the Buildroot OS Build section)

But seeing how it is done here can help as you go about development using the device.

This configures the GPIO on the device
```
adb push config/luckfox.cfg /etc/luckfox.cfg

# reboot the device
adb reboot
```

## Hardware Test Suite
The test suite verifies all hardware components of the device:

```
# push over the test files
adb push test_suite /
```

# Run Test Suite
```
adb shell python3 /test_suite/test.py
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
*This is also one of the downsides of this device*. The version specified here has onboard flash. There are other versions of the Luckfox Pico which don't have onboard flash, which I am excited to explore in the future. I might try desoldering it from the device, and post a video of the difficulty to do that. If there is no valid OS on the onboard SPI flash it will boot from the MicroSD card.

```
cd /os/build/output/dir/
sudo rkflash.sh update
```

(TODO: Add image showing the console output of the spi flashing process.)

### Flash MicroSD Card
```
sudo dd bs=4M status=progress if=/path/to/update.img of=/dev/diskX
```
Replace `/dev/diskX` with your actual SD card device path.


## Luckfox Pico OS Modifications
We have forked the [Luckfox Pico SDK](https://github.com/lightningspore/luckfox-pico) in order to enable various hardware features like pull-up resistors, adjust video RAM, and other things.

### Camera Memory
The Luckfox devotes some of its memory for camera related algorithms, but we don't use this feature. Particularly on the Luckfox Pico Mini device, which only has 64MB of RAM, it is beneficial for us to reclaim a bit of this memory.

Memory usage WITHOUT modification:
```bash
[root@luckfox ]# free -h
              total        used        free      shared  buff/cache   available
Mem:          33.0M       24.3M        1.4M      476.0K        7.3M        5.4M
Swap:             0           0           0
```

Memory usage WITH modification:
```bash
[root@luckfox ]# free -h
              total        used        free      shared  buff/cache   available
Mem:          53.0M       23.6M        1.9M      472.0K       27.5M       25.3M
Swap:             0           0           0
```

### Pull-up Resistors
Our current dev board has external pull-up resistors, since we didn't know how to enable these at the time, and it is always smart to plan ahead when designing PCBs. NOTE: Even with this commit with this change, the internal pull-ups don't seem to work.

### SPI Buffer Size
While it is possible to send SPI data in chunks, you are able to increase the SPI buffer size to slightly increase throughput, which is useful for larger displays.

### PWM Output
In order to control the LCD screen backlight and support true dimming of the display (instead of just changing the background color of the QR code, for example), we had to enable a PWM on a specific output pin.