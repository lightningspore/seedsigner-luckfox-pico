# SeedSigner Build System

Docker-based build system for SeedSigner OS that uses containerized compilation without host filesystem pollution.

## Requirements

- Docker (any recent version)
- 4GB+ RAM recommended
- 3GB free disk space
- Linux, macOS, or Windows with WSL2

## Quick Start

```bash
./build.sh build
# Artifacts automatically available in ./build-output/
```

## Commands

| Command | Description |
|---------|-------------|
| `./build.sh build` | Full automated build (artifacts auto-exported) |
| `./build.sh build --jobs N` | Build with N parallel jobs |
| `./build.sh interactive` | Interactive debugging mode |
| `./build.sh shell` | Direct shell access |
| `./build.sh clean` | Clean containers and volumes |
| `./build.sh status` | Show system status |

## Build Process

1. Creates Docker container with cross-compilation toolchain
2. Clones required repositories inside container:
   - luckfox-pico SDK
   - seedsigner code (upstream-luckfox-staging-1 branch)
   - seedsigner-os packages
3. Compiles U-Boot bootloader
4. Builds Linux kernel with device drivers
5. Creates root filesystem with SeedSigner application
6. Packages components into flashable image
7. **Automatically exports artifacts** to host filesystem

## Output

Build artifacts are **automatically available** in `./build-output/`:
- `seedsigner-luckfox-pico-YYYYMMDD_HHMMSS.img` - Flashable OS image
- Additional build logs and intermediate files

**No extract step required** - artifacts appear immediately when build completes.

## Performance

- First build: 30-90 minutes (includes repository cloning)
- Subsequent builds: 15-45 minutes (reuses cached repositories)

Repository caching uses Docker volume `seedsigner-repos` which persists between builds.

## CI/CD Integration

Perfect for automated builds:
```bash
./build.sh build --output ./release-artifacts
# Artifacts automatically available for upload/deployment
```

## Configuration

Build parallelization is automatically configured based on available CPU cores.
Override with `--jobs N` option or `BUILD_JOBS` environment variable.

ARM64 hosts use x86_64 emulation which significantly increases build time.

## Troubleshooting

For build failures, use interactive mode to debug individual steps:

```bash
./build.sh interactive
cd /build/repos/luckfox-pico
./build.sh clean
./build.sh buildrootconfig
```

Check Docker resource allocation if builds fail due to memory constraints.
