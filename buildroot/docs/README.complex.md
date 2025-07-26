# SeedSigner Luckfox Pico - Automated Build System

This directory contains an improved Docker-based build system for creating SeedSigner OS images for the Luckfox Pico device.

## 🚀 Quick Start

### 1. Setup (First Time Only)
```bash
cd buildroot/
./build.sh setup
```
This will automatically clone all required repositories to your `$HOME` directory.

### 2. Build the OS Image
```bash
./build.sh build
```
This runs the complete automated build process.

### 3. Extract Build Artifacts
After the build completes, extract the final image:
```bash
./build.sh extract
```
The built OS image will be available in `buildroot/build-output/`.

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `./build.sh setup` | Clone required repositories |
| `./build.sh build` | Run automated build |
| `./build.sh interactive` | Start container in interactive mode |
| `./build.sh shell` | Drop directly into container shell |
| `./build.sh status` | Check repository status |
| `./build.sh clean` | Clean containers and artifacts |
| `./build.sh extract` | Extract build artifacts |

## 🔧 Build Modes

### Automated Mode (Default)
Runs the complete build process without user interaction:
```bash
./build.sh build
```

### Interactive Mode
Validates environment then drops into shell for manual build steps:
```bash
./build.sh interactive
```
In interactive mode, you can run individual commands:
```bash
# Inside container
/mnt/cfg/buildroot/add_package_buildroot.sh  # Full build
# Or individual steps:
./build.sh uboot
./build.sh kernel
./build.sh rootfs
```

### Shell Mode
Direct shell access (skips validation):
```bash
./build.sh shell
```

## 📁 Directory Structure

After setup, your `$HOME` directory should contain:
```
~/
├── luckfox-pico/           # Luckfox SDK
├── seedsigner/             # SeedSigner code (luckfox-dev branch)
├── seedsigner-os/          # SeedSigner OS packages
└── seedsigner-luckfox-pico/ # This repository
```

## 🐳 Docker Details

### Build Environment
- **Base Image**: Ubuntu 22.04
- **Architecture**: Must run on x86_64 (cross-compiles for ARM)
- **Mount Points**:
  - `/mnt/host` → `~/luckfox-pico` (SDK)
  - `/mnt/ss` → `~/seedsigner` (SeedSigner code)
  - `/mnt/cfg` → `~/seedsigner-luckfox-pico` (This repo)
  - `/mnt/ssos` → `~/seedsigner-os` (OS packages)
  - `/mnt/output` → `./build-output` (Build artifacts)

### Using Docker Compose
You can also use Docker Compose directly:
```bash
# Automated build
docker-compose up seedsigner-builder

# Interactive mode
docker-compose run seedsigner-dev

# With custom environment
BUILD_OUTPUT_DIR=./my-builds docker-compose up seedsigner-builder
```

## 🛠 Build Process Details

The automated build performs these steps:

1. **Environment Validation**: Checks all required directories and files
2. **Package Setup**: Adds SeedSigner packages to buildroot configuration
3. **Component Build**: Builds U-Boot, kernel, rootfs, media components
4. **SeedSigner Integration**: Copies SeedSigner code and configuration
5. **Firmware Packaging**: Creates final flashable image

## 📤 Output Files

After a successful build, you'll find these files in the build output:

- `seedsigner-luckfox-pico-TIMESTAMP.img` - Final flashable OS image
- `boot.img`, `rootfs.img`, etc. - Individual component images
- `update.img` - Alternative update image

## 🔍 Troubleshooting

### Common Issues

**"Missing directories" error**:
```bash
./build.sh setup  # Clone missing repositories
```

**Docker permission errors**:
```bash
sudo usermod -aG docker $USER  # Add user to docker group
newgrp docker  # Refresh group membership
```

**Build fails with package errors**:
```bash
./build.sh clean     # Clean environment
./build.sh build --force  # Force rebuild
```

**Container keeps running**:
The container stays alive after build completion for artifact extraction. Stop it with:
```bash
docker stop seedsigner-luckfox-builder
```

### Advanced Debugging

**Interactive debugging**:
```bash
./build.sh interactive
# Inside container:
cd /mnt/host
./build.sh buildrootconfig  # Manual package selection
```

**Check build logs**:
```bash
docker logs seedsigner-luckfox-builder
```

**Manual container management**:
```bash
# List containers
docker ps -a

# Connect to running container
docker exec -it seedsigner-luckfox-builder bash

# Copy files from container
docker cp seedsigner-luckfox-builder:/mnt/host/output/image/ ./build-output/
```

## 🔄 Development Workflow

### Making Changes
1. Modify source code in respective repositories
2. Run `./build.sh build` to rebuild
3. Test the generated image

### Updating Configurations
- Buildroot config: Modify `configs/luckfox_pico_defconfig`
- SeedSigner config: Update files in `files/` directory
- Build scripts: Edit `add_package_buildroot.sh` or `build_automation.sh`

### Contributing
When contributing improvements:
1. Test with `./build.sh build`
2. Verify with `./build.sh interactive` for debugging
3. Update documentation as needed

## 📖 Related Documentation

- [Original Build Instructions](../docs/OS-build-instructions.md)
- [Luckfox Pico Official Guide](https://wiki.luckfox.com/Luckfox-Pico/Linux-MacOS-Burn-Image/)
- [SeedSigner Project](https://github.com/seedsigner/seedsigner)
