# seedsigner-luckfox-pico
Port of the SeedSigner code to the LuckFox Pico Pro/Max embedded ARM(ricv?) linux board


## Dev machine setup
```
brew install homebrew/cask/android-platform-tools
```

## Initial Hardware Setup


This configures the GPIO on the device
```
adb push config/luckfox.cfg /etc/luckfox.cfg

# reboot the device
```

## Hardware Test Suite

```
# push over the test file
adb push test_suite /

# Get to a device shell using adb
```
adb shell
```

### Run Test Suite
```
cd /test_suite
python test.py
```

## More Setup
```
# Make sure pip is available
python -m ensurepip --default-pip
```



## Package individually made OS images to a flashable version
```
cd 
./blkenvflash/buildroot final-image.img
```

## Flash SD Card
```
sudo dd bs=4M status=progress if=/Users/lightningspore/Downloads/pro_buildroot_sd/update.img of=/dev/disk5
```

# KNOWN ISSUES:
```
1. ImportError: The _imagingft C module is not installed
Related to Pillow Library and Image Font Library
Possible solution: Re-install Pillow onces dependencies are installed:
apt install libtiff5-dev libjpeg8-dev libopenjp2-7-dev libfreetype6-dev


```