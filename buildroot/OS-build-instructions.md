# **Comprehensive Guide to Building & Flashing Luckfox Pico Pro Max OS**

## **Step 1: Set Up the Linux VM (for Mac Users)**
If you're using a Mac (ARM-based), you **must** use a Linux VM to compile the image.

1. **Log in to your Linux VM from Mac (Terminal)**
   ```sh
   ssh -i ~/Downloads/IR.pem ubuntu@************
   ```
2. **If the key isn't working, adjust permissions:**
   ```sh
   chmod 700 ~/Downloads/IR.pem
   ```

---

## **Step 2: Clone the Necessary Repositories**
Run the following commands inside your **Ubuntu VM**:

```sh
git clone https://github.com/LuckfoxTECH/luckfox-pico.git --depth=1
git clone https://github.com/spore/seedsigner-luckfox-pico.git
git clone https://github.com/seedsigner/seedsigner.git
```

- `luckfox-pico`: **Luckfox SDK** repo for building firmware.
- `seedsigner-luckfox-pico`: Used specifically for **building OS images**.
- `seedsigner`: The actual **Python application**.

---

## **Step 3: Build the Docker Image**
Move into the **buildroot** directory:

```sh
cd ~/seedsigner-luckfox-pico/buildroot
```

Check the **Dockerfile** (optional):

```sh
cat Dockerfile
```

Build the Docker image:

```sh
docker build -t foxbuilder:latest .
```

---

## **Step 4: Run the Docker Container**
Move into the **Luckfox SDK directory**:

```sh
cd ~/seedsigner-luckfox-pico/buildroot/luckfox-pico
```

Start the Docker container:

```sh
docker run -it --name luckfox-builder -v $(pwd):/mnt/host foxbuilder:latest
```

If a container with the same name already exists, remove it first:

```sh
docker rm -f luckfox-builder
docker run -it --name luckfox-builder -v $(pwd):/mnt/host foxbuilder:latest
```

---

## **Step 5: Set Up the SDK Path (Inside Docker)**
Run these commands **inside the Docker container**:

```sh
export SDK_PATH=/mnt/host
cd $SDK_PATH/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/
source env_install_toolchain.sh
cd $SDK_PATH
```

---

## **Step 6: Configure the Build**
Set the build configuration:

```sh
./build.sh lunch
```

1. **Select the device type**: `pico pro max`
2. **Select storage type**: `SD Card`
3. **Confirm selection**

Configure the OS packages:

```sh
./build.sh buildrootconfig
```

Enable the following packages:

- `RKISP`
- `LIBCAMERA`
- `ZBAR`
- `LIBJPEG`

Sanity check the selected packages:

```sh
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep "LIBCAMERA"
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep "ZBAR"
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep "LIBJPEG"
```

Final check (list all enabled packages):

```sh
cat sysdrv/source/buildroot/buildroot-2023.02.6/.config | grep -v "^#"
```

---

## **Step 7: Start the Build Process**
Now, compile each part of the OS image:

```sh
./build.sh uboot
./build.sh kernel
./build.sh rootfs
./build.sh media  # Needed for camera support
```

---

## **Step 8: Verify the Built Firmware**
After the build completes, check that the `.img` files exist:

```sh
ls -l /mnt/host/output/image/
```

Expected output:

```
boot.img  download.bin  env.img  idblock.img  oem.img  rootfs.img  sd_update.txt  tftp_update.txt  uboot.img  update.img  userdata.img
```

---

## **Step 9: Package the Firmware**
Run:

```sh
./build.sh firmware
```

Double-check all necessary `.img` files exist:

```sh
ls -l /mnt/host/output/image/
```

---

## **Step 10: Transfer Firmware from Ubuntu VM to Mac**
Run the following **on your Mac** to copy the built firmware from Ubuntu:

```sh
scp -i ~/Downloads/IR.pem -r ubuntu@*********:/home/ubuntu/seedsigner-luckfox-pico/buildroot/luckfox-pico/output/image ~/Downloads/
```

Verify the files on your Mac:

```sh
ls -l ~/Downloads/image/
```

---

## **Step 11: Flash the Firmware onto Luckfox Board (From Mac)**
### **1️⃣ Install Rockchip Flashing Tool**
Run the following on **Mac**:

```sh
brew install libusb
git clone https://github.com/rockchip-linux/rkdeveloptool.git
cd rkdeveloptool
make
```

### **2️⃣ Connect Luckfox Board to Mac**
1. **Power off the Luckfox Pico Pro Max.**
2. **Hold the recovery button** (or short the recovery pins).
3. **Plug in the USB-C cable to your Mac.**
4. **Release the recovery button after 3 seconds.**

Verify if the board is detected:

```sh
lsusb
```

### **3️⃣ Flash the Firmware**
#### **Erase the existing firmware**

```sh
./rkdeveloptool ef
```

#### **Write the bootloader**

```sh
./rkdeveloptool db ~/Downloads/image/idblock.img
./rkdeveloptool ul ~/Downloads/image/uboot.img
```

#### **Flash the complete firmware**

```sh
./rkdeveloptool wl 0x40 ~/Downloads/image/update.img
```

#### **Reboot the board**

```sh
./rkdeveloptool rd
```

🎉 **Your Luckfox Pico Pro Max should now boot with the new firmware!**

---

## **✅ Final Checks**
If the board isn't booting, verify:
1. Did all `.img` files exist in `/mnt/host/output/image/` before flashing?
2. Did `rkdeveloptool` show any errors?
3. Was the board detected via `lsusb`?

Let me know if you run into any issues! 🚀🔥

