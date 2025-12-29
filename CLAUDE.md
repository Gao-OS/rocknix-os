# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a build environment wrapper for ROCKNIX OS (a Linux distribution for handheld gaming devices). It uses devenv/nix for reproducible builds and wraps the upstream ROCKNIX distribution as a git submodule.

## Build Commands

```bash
# Enter dev environment (provides all build dependencies)
devenv shell
# or with direnv:
direnv allow

# Initialize submodules
make init

# Build for RGB30 (default device)
make build

# Build for specific device
make build DEVICE=RGB30
make build DEVICE=RG353P
make build DEVICE=RG353V
make build DEVICE=RG503

# Configure build options
make menuconfig

# Clean build artifacts
make clean
make distclean  # full clean including downloads
```

## Architecture

```
rocknix-os/
├── devenv.nix      # Nix environment with build dependencies
├── Makefile        # Build wrapper translating device names to ROCKNIX params
└── rocknix/        # ROCKNIX distribution submodule (upstream source)
    ├── projects/   # Device/SoC-specific configurations
    ├── packages/   # Package build recipes
    └── scripts/    # Build system scripts
```

**Build flow:** The top-level Makefile maps friendly device names (RGB30, RG353P) to ROCKNIX build parameters (PROJECT=Rockchip, DEVICE=RK3566) and invokes the upstream build system.

**Output:** Built images are generated in `rocknix/release/`.

## Device Mapping

| Device | ROCKNIX_PROJECT | ROCKNIX_DEVICE |
|--------|-----------------|----------------|
| RGB30  | Rockchip        | RK3566         |
| RG353P | Rockchip        | RK3566         |
| RG353V | Rockchip        | RK3566         |
| RG503  | Rockchip        | RK3566         |

## Adding Dependencies

Edit `devenv.nix` to add build-time dependencies. The file uses standard Nix package set.
