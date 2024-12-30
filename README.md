# seedsigner-luckfox-pico
Port of the SeedSigner code to the LuckFox Pico Pro/Max embedded ARM(ricv?) linux board


## Dev machine setup
```
# mac
brew install homebrew/cask/android-platform-tools

# linux
sudo apt install android-tools-adb
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

## Download Python source packages (no wheels!)
```
pip download -r requirements.txt --no-binary ":all"
# TODO: For each python dep, untar, or unzip the downloaded file from pypi
adb push python_deps /

# ON LUCKFOX INSTALL OLD FASHIONED WAY
cd /python_deps/qrcode...
python setup.py install
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
