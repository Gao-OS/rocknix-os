# ROCKNIX Customization Guide

This guide explains how to customize ROCKNIX for your own distribution or device.

## Directory Structure Overview

```
source/
├── distributions/ROCKNIX/     # Branding, logos, system options
├── projects/ROCKNIX/          # Device configs, packages, services
│   ├── devices/               # Per-device configurations
│   └── packages/              # ROCKNIX-specific packages
├── packages/                  # Core packages (emulators, libs, tools)
├── config/                    # Build system configuration
└── scripts/                   # Build scripts
```

---

## 1. Logos and Branding

### Boot Splash Screen

**Location:** `distributions/ROCKNIX/logos/`

Create resolution-specific splash images:
```
distributions/ROCKNIX/logos/
├── rocknix-logo.png          # Main logo
└── splash/
    ├── splash-720.png        # 720p displays
    ├── splash-1080.png       # 1080p displays
    └── boot-logo.bmp.gz      # Bootloader logo (compressed BMP)
```

The splash screen package is at:
`projects/ROCKNIX/packages/tools/rocknix-splash/`

### System Branding

**File:** `distributions/ROCKNIX/options`

```bash
# Distribution identity
DISTRONAME="ROCKNIX"
OSNAME="rocknix"
DESCRIPTION="An Open Source firmware."

# URLs
HOME_URL="https://rocknix.org"
WIKI_URL="https://rocknix.org"
BUG_REPORT_URL="https://rocknix.org"

# Boot labels
DISTRO_BOOTLABEL="ROCKNIX"
DISTRO_DISKLABEL="STORAGE"
```

---

## 2. System Configuration

### Distribution Options

**File:** `distributions/ROCKNIX/options`

Key settings:
```bash
# System
ROOT_PASSWORD="rocknix"           # Default root password
SYSTEM_SIZE=2048                  # System partition size (MB)

# Features
BLUETOOTH_SUPPORT="yes"
PIPEWIRE_SUPPORT="yes"
ROCKNIX_JOYPAD="yes"
JOYSTICK_SUPPORT="yes"

# Display
WINDOWMANAGER="none"              # or "sway", "weston"
```

### Device-Specific Config

**Location:** `projects/ROCKNIX/devices/<DEVICE>/options`

Example for RK3566:
```bash
# Kernel
LINUX="rk3566"
KERNEL_TARGET="Image"

# Graphics
VULKAN_SUPPORT="no"
OPENGL_SUPPORT="yes"
OPENGLES_SUPPORT="yes"

# Device features
DEVICE_HAS_FAN="yes"
```

---

## 3. System Menu (EmulationStation)

### Configuration Files

**Location:** `projects/ROCKNIX/packages/ui/emulationstation/`

```
emulationstation/
├── config/
│   └── common/
│       ├── es_settings.cfg      # Default settings
│       ├── es_features.cfg      # Feature definitions
│       └── es_input.cfg         # Input mappings
├── sources/
│   ├── es_settings              # Settings init script
│   └── start_es.sh              # Startup script
└── system.d/
    └── emustation.service       # Systemd service
```

### Customizing ES Settings

Edit `config/common/es_settings.cfg`:
```xml
<?xml version="1.0"?>
<string name="ThemeSet" value="art-book-next" />
<string name="ScreenSaverBehavior" value="dim" />
<bool name="ShowHelpPrompts" value="true" />
```

### Adding Themes

Themes are packages in `projects/ROCKNIX/packages/ui/`:
```
ui/
├── es-theme-art-book-next/
├── es-theme-carbon/
└── es-theme-minimal/
```

---

## 4. Systemd Services

### Adding a New Service

1. Create service file in your package's `system.d/` directory:

**Example:** `packages/mypackage/system.d/myservice.service`
```ini
[Unit]
Description=My Custom Service
After=network.target

[Service]
Type=simple
Environment=HOME=/storage
ExecStart=/usr/bin/mycommand
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

2. The build system automatically installs `system.d/*.service` to `/usr/lib/systemd/system/`

### Key System Services

| Service | Purpose | Location |
|---------|---------|----------|
| `emustation.service` | EmulationStation frontend | `ui/emulationstation/system.d/` |
| `sway.service` | Wayland compositor | `wayland/compositor/sway/system.d/` |
| `seatd.service` | Seat management | `wayland/lib/seatd/system.d/` |

### Enabling Services

In your `package.mk`:
```bash
post_makeinstall_target() {
  enable_service myservice.service
}
```

---

## 5. Scripts

### Autostart Scripts

**Location:** `packages/<category>/<package>/autostart/`

Scripts run at boot in numeric order:
```
autostart/
├── 001-controller           # First: controller setup
├── 003-gpudriver            # GPU initialization
├── 098-deviceutils          # Device utilities
└── 111-sway-init            # Last: UI startup
```

**Example autostart script:**
```bash
#!/bin/bash
# autostart/050-myscript

# Source system functions
. /etc/profile

# Your initialization code
echo "Initializing my feature..."
/usr/bin/my-init-command
```

### System Utility Scripts

**Location:** `projects/ROCKNIX/packages/sysutils/system-utils/sources/scripts/`

Common scripts:
- `fancontrol` - Fan speed management
- `ledcontrol` - LED control
- `battery_led_status` - Battery indicator
- `turbomode` - Performance profiles
- `volume` - Audio control

### ROCKNIX Core Scripts

**Location:** `projects/ROCKNIX/packages/rocknix/sources/scripts/`

- `rocknix-config` - Configuration management
- `rocknix-bluetooth-agent` - Bluetooth pairing
- `rocknix-scraper` - Game metadata scraper

---

## 6. Adding Software Packages

### Package Structure

```
packages/<category>/<package-name>/
├── package.mk                # Build recipe (required)
├── config/                   # Configuration files
├── sources/                  # Additional source files
├── patches/                  # Source patches
├── system.d/                 # Systemd services
├── udev.d/                   # Udev rules
├── profile.d/                # Shell profile scripts
├── autostart/                # Boot scripts
└── scripts/                  # Runtime scripts
```

### Package Template (package.mk)

```bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024 Your Name

PKG_NAME="mypackage"
PKG_VERSION="1.0.0"
PKG_SHA256="abc123..."
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/example/mypackage"
PKG_URL="https://github.com/example/mypackage/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Description of my package"

# Build system: cmake, meson, autotools, make, manual
PKG_TOOLCHAIN="cmake"

# CMake options
PKG_CMAKE_OPTS_TARGET="-DBUILD_SHARED_LIBS=ON"

# Custom build steps (optional)
pre_configure_target() {
  # Run before configure
  export CFLAGS="${CFLAGS} -DSOME_FLAG"
}

makeinstall_target() {
  # Custom install
  mkdir -p ${INSTALL}/usr/bin
  cp myprogram ${INSTALL}/usr/bin/
}

post_makeinstall_target() {
  # After install
  mkdir -p ${INSTALL}/usr/config/mypackage
  cp ${PKG_DIR}/config/* ${INSTALL}/usr/config/mypackage/
}
```

### Package Categories

| Category | Purpose |
|----------|---------|
| `emulators/` | Emulator cores (libretro, standalone) |
| `tools/` | Utilities and tools |
| `sysutils/` | System utilities |
| `multimedia/` | Media players, codecs |
| `network/` | Network tools |
| `graphics/` | GPU drivers, graphics libs |
| `wayland/` | Wayland compositors, libs |
| `ui/` | User interface (ES, themes) |

### Adding Package to Build

1. **For all builds:** Add to virtual package

   Edit `packages/virtual/emulators/package.mk`:
   ```bash
   PKG_DEPENDS_TARGET+=" myemulator"
   ```

2. **For specific devices:** Add to device package

   Edit `projects/ROCKNIX/devices/RK3566/packages/mypackage/package.mk`

### Build Commands

```bash
# Build single package
make package PACKAGE=mypackage

# Clean and rebuild
make package-clean PACKAGE=mypackage
make package PACKAGE=mypackage

# Full image with new package
make build DEVICE=RGB30
```

---

## 7. Adding Emulators

### Libretro Core

**Location:** `packages/emulators/libretro/<core-name>/`

```bash
# package.mk for libretro core
PKG_NAME="mycore-lr"
PKG_VERSION="abc123"
PKG_SHA256="..."
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://github.com/libretro/mycore"
PKG_URL="https://github.com/libretro/mycore/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="My libretro core"

PKG_LIBNAME="mycore_libretro.so"
PKG_LIBPATH="${PKG_LIBNAME}"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_LIBPATH} ${INSTALL}/usr/lib/libretro/
}
```

### Standalone Emulator

**Location:** `packages/emulators/standalone/<emulator-name>/`

Include wrapper script and ES configuration for integration.

---

## 8. Device Tree and Kernel

### Adding Kernel Patches

**Location:** `projects/ROCKNIX/devices/<DEVICE>/patches/linux/<version>/`

```
devices/RK3566/patches/linux/
├── 6.12-LTS/
│   ├── 001-fix-something.patch
│   └── 002-add-feature.patch
└── mainline/
    └── 001-mainline-fix.patch
```

### Device Tree Configuration

**File:** `projects/ROCKNIX/config.xml`

```xml
<RK3566 dtb_prefix="rockchip">
  <Generic mkimage_options="dtb,extlinux,uboot" fdt="device_trees" fdt_type="fdtdir">
    <file>rk3566-powkiddy-rgb30</file>
    <file>rk3566-anbernic-rg353p</file>
  </Generic>
</RK3566>
```

---

## 9. Quick Reference

### File Locations

| What | Where |
|------|-------|
| Logo/Splash | `distributions/ROCKNIX/logos/` |
| System options | `distributions/ROCKNIX/options` |
| Device config | `projects/ROCKNIX/devices/<DEVICE>/options` |
| ES config | `projects/ROCKNIX/packages/ui/emulationstation/config/` |
| System scripts | `projects/ROCKNIX/packages/rocknix/sources/scripts/` |
| Emulators | `packages/emulators/` |
| New packages | `packages/<category>/<name>/` |

### Build Commands

```bash
# Enter Docker build environment
make docker-shell

# Build for RGB30
make build DEVICE=RGB30

# Build single package
make package PACKAGE=<name>

# Clean package
make package-clean PACKAGE=<name>

# Full clean
make distclean
```

### Runtime Paths (on device)

| Path | Purpose |
|------|---------|
| `/storage/.config/` | User configuration |
| `/storage/roms/` | Game ROMs |
| `/usr/lib/libretro/` | Libretro cores |
| `/usr/bin/` | Executables |
| `/usr/config/` | Default configs |
