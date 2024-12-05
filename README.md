# seedsigner-luckfox-pico
Port of the SeedSigner code to the LuckFox Pico Pro/Max embedded ARM(ricv?) linux board


## Dev machine setup
```
brew install android-platform-tools
```

## Initial Hardware Setup

## Flash SD Card
```
sudo dd bs=4M status=progress if=/Users/lightningspore/Downloads/pro_buildroot_sd/update.img of=/dev/disk5
```

This configures the GPIO on the device
```
adb push config/luckfox.cfg /etc/luckfox.cfg

# rebo
```

## Package individually made OS images to a flashable version
```
cd 
./blkenvflash/buildroot final-image.img
```

## Hardware Test Suite

### Test Buttons

### Test LCD
```
# push over the test file
adb push test_suite /

# Get to a device shell using adb
```
adb shell
```

### Test Camera
 
#### TESTING


