# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a build environment wrapper for ROCKNIX OS (a Linux distribution for handheld gaming devices). It uses devenv/nix for the dev shell and Docker for builds, wrapping the upstream ROCKNIX distribution as a git submodule.

## Build Commands

```bash
# Initialize submodules
make init

# Build for RGB30 (default device)
make build

# Build for specific device
make build DEVICE=RGB30
make build DEVICE=RG353P
make build DEVICE=RG353V
make build DEVICE=RG503

# Enter Docker build shell
make docker-shell

# Other
make menuconfig        # Configure build options
make clean             # Clean build artifacts
make distclean         # Full clean including downloads
```

## Architecture

```
rocknix-os/
├── devenv.nix      # Nix dev shell (docker, git, make)
├── Makefile        # Build wrapper with custom output directory
├── overlay/        # Custom overlay files applied to source before build
├── scripts/        # Custom build scripts
│   ├── build.sh    # Main build script
│   └── clean.sh    # Clean script
├── out/            # Build output (per-device subdirectories)
│   └── RGB30/      # Output for RGB30 device
└── source/         # ROCKNIX distribution submodule (upstream source)
    ├── projects/   # Device/SoC-specific configurations
    ├── packages/   # Package build recipes
    └── scripts/    # Upstream build scripts
```

**Build flow:** The top-level Makefile maps friendly device names (RGB30, RG353P) to ROCKNIX build parameters (PROJECT=Rockchip, DEVICE=RK3566), applies overlay files, then invokes the upstream build system inside Docker.

**Output:** Built images are generated in `out/<DEVICE>/` (e.g., `out/RGB30/`).

## Device Mapping

| Device | ROCKNIX_PROJECT | ROCKNIX_DEVICE |
|--------|-----------------|----------------|
| RGB30  | Rockchip        | RK3566         |
| RG353P | Rockchip        | RK3566         |
| RG353V | Rockchip        | RK3566         |
| RG503  | Rockchip        | RK3566         |
