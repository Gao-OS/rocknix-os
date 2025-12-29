# ROCKNIX OS Build Environment

Custom build environment for ROCKNIX using devenv/nix for reproducible builds.

## Supported Devices

- Powkiddy RGB30 (RK3566)
- Anbernic RG353P/V (RK3566)
- Anbernic RG503 (RK3566)

## Prerequisites

- [Nix](https://nixos.org/download.html)
- [devenv](https://devenv.sh/getting-started/)
- [direnv](https://direnv.net/) (optional but recommended)

## Setup

1. Clone this repository:
```bash
git clone --recursive <repo-url>
cd rocknix-os
```

2. Initialize the devenv environment:
```bash
devenv shell
```

Or with direnv:
```bash
direnv allow
```

3. Initialize submodules (if not cloned with --recursive):
```bash
make init
```

## Building

Build for RGB30 (default):
```bash
make build
```

Build for a specific device:
```bash
make build DEVICE=RG353P
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make build` | Build complete ROCKNIX image |
| `make image` | Build only the image (skip init) |
| `make menuconfig` | Configure build options |
| `make clean` | Clean build artifacts |
| `make distclean` | Full clean including downloads |
| `make help` | Show available commands |

## Build Output

Images will be generated in `rocknix/target/` after a successful build:
- `ROCKNIX-<DEVICE>.aarch64-<DATE>-Generic.img.gz` - Generic image
- `ROCKNIX-<DEVICE>.aarch64-<DATE>-Specific.img.gz` - Device-specific image

## Customization

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for detailed instructions on:
- Changing logos and branding
- System and device configuration
- EmulationStation menu customization
- Adding systemd services
- Adding scripts
- Creating new software packages
- Integrating emulators

Edit `devenv.nix` to add additional build dependencies.

## Resources

- [ROCKNIX GitHub](https://github.com/ROCKNIX/distribution)
- [ROCKNIX Wiki](https://github.com/ROCKNIX/distribution/wiki)
