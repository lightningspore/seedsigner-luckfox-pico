#!/bin/bash

# global package list
vi sysdrv/source/buildroot/buildroot-2023.02.6/package/Config.in

# make a modified package
cp -r sysdrv/source/buildroot/buildroot-2023.02.6/package/python-boto3 \
    sysdrv/source/buildroot/buildroot-2023.02.6/package/python-boto69



# clone seedsigner-os REPO

git clone https://github.com/SeedSigner/seedsigner-os.git
cd seedsigner-os/opt

# this is better
sudo cp -rv external-packages/* \
    ~/seedsigner-luckfox-pico/buildroot/luckfox-pico/sysdrv/source/buildroot/buildroot-2023.02.6/package/


sudo nano ~/seedsigner-luckfox-pico/buildroot/luckfox-pico/sysdrv/source/buildroot/buildroot-2023.02.6/package/python-pyzbar/0001-PATH-fixed-by-hand.patch
# update the python path to 3.11
# +        path = "/usr/lib/python3.11/site-packages/zbar.so


# Add in the new packages
sudo nano ~/seedsigner-luckfox-pico/buildroot/luckfox-pico/sysdrv/source/buildroot/buildroot-2023.02.6/package/Config.in

```text
menu "SeedSigner"
        source "package/python-urtypes/Config.in"
        source "package/python-pyzbar/Config.in"
        source "package/python-mock/Config.in"
        source "package/python-embit/Config.in"
        source "package/python-pillow/Config.in"
        source "package/libcamera/Config.in"
        source "package/libcamera-apps/Config.in"
        source "package/zbar/Config.in"
        source "package/jpeg-turbo/Config.in.options"
        source "package/jpeg/Config.in"
        source "package/python-qrcode/Config.in"
        source "package/python-pyqrcode/Config.in"
endmenu
```


[build.sh:info] If you need to add custom files, \
    please upload them to <Luckfox Sdk>/output/out/rootfs_uclibc_rv1106

# copy over forked seedsigner code
sudo cp -r src/ \
../seedsigner-luckfox-pico/buildroot/luckfox-pico/output/out/rootfs_uclibc_rv1106/seedsigner

# copy over GPIO configuration file
sudo cp config/luckfox.cfg /etc/luckfox.cfg