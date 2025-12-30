# ROCKNIX OS Build Environment

Custom build environment for ROCKNIX using devenv/nix for reproducible builds.

## Supported Devices

- Powkiddy RGB30 (RK3566)
- Anbernic RG353P/V (RK3566)
- Anbernic RG503 (RK3566)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (for Docker builds)
- [Nix](https://nixos.org/download.html) (for native FHS builds)
- [devenv](https://devenv.sh/getting-started/) (for native FHS builds)
- [direnv](https://direnv.net/) (optional but recommended)

## Setup

1. Clone this repository:
```bash
git clone --recursive https://github.com/Gao-OS/rocknix-os.git
cd rocknix-os
```

2. Initialize submodules (if not cloned with --recursive):
```bash
make init
```

## Building

### Method 1: Docker Build (Recommended)

The easiest way to build - uses the official ROCKNIX Docker image with all dependencies pre-installed.

```bash
# Build for RGB30 (default)
make build

# Build for specific device
make build DEVICE=RGB30
make build DEVICE=RG353P
make build DEVICE=RG353V
make build DEVICE=RG503

# Enter Docker build shell for manual commands
make docker-shell
```

### Method 2: Native FHS Build (via devenv)

Uses Nix's `buildFHSEnv` to create an FHS-compliant environment locally. This is useful for development and debugging.

```bash
# Enter devenv shell
devenv shell
# or with direnv:
direnv allow

# Enter FHS environment
rocknix-fhs

# Build inside FHS
cd source && make RK3566
```

**Helper scripts** (available after `devenv shell`):
| Command | Description |
|---------|-------------|
| `rocknix-fhs` | Enter FHS build environment |
| `rocknix-shell` | Enter FHS shell in source directory |
| `rocknix-build-rk3566` | Build RK3566 in FHS environment |
| `rocknix-clean` | Clean build in FHS environment |

## Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Build complete ROCKNIX image (Docker) |
| `make docker-shell` | Enter Docker build shell |
| `make menuconfig` | Configure build options |
| `make clean` | Clean build artifacts |
| `make distclean` | Full clean including downloads |
| `make help` | Show available commands |

## Build Output

Images will be generated in `source/target/` after a successful build:
- `ROCKNIX-<DEVICE>.aarch64-<DATE>-Generic.img.gz` - Generic image (works on all RK3566 devices)
- `ROCKNIX-<DEVICE>.aarch64-<DATE>-Specific.img.gz` - Device-specific image

## FHS Environment

The `devenv.nix` uses Nix's `buildFHSEnv` to create an FHS (Filesystem Hierarchy Standard) compliant sandbox. This is necessary because:

- Buildroot expects standard Linux paths (`/usr/bin`, `/usr/lib`, `/usr/include`)
- Nix's non-standard paths would break the build system
- The FHS environment provides isolation without requiring Docker

**Included tools:**
- Build: gcc, glibc, binutils, make, cmake, meson, ninja
- Scripting: python3, perl
- Image: squashfsTools, e2fsprogs, mtools, ubootTools
- Kernel: bison, flex, dtc, libelf, linuxHeaders
- Compression: lz4, zstd, lzo, cpio
- Caching: ccache (configured for faster rebuilds)

## Customization

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for detailed instructions on:
- Changing logos and branding
- System and device configuration
- EmulationStation menu customization
- Adding systemd services
- Adding scripts
- Creating new software packages
- Integrating emulators

## Resources

- [ROCKNIX GitHub](https://github.com/ROCKNIX/distribution)
- [ROCKNIX Wiki](https://github.com/ROCKNIX/distribution/wiki)
