# ROCKNIX OS Build Skill

This skill documents how to build, customize, and troubleshoot ROCKNIX OS for handheld gaming devices.

## Repository Structure

```
rocknix-os/
├── source/                 # ROCKNIX upstream submodule (READ-ONLY)
├── overlay/                # Custom modifications (copied to source before build)
│   └── projects/ROCKNIX/packages/rocknix/
│       ├── sources/scripts/    # Custom scripts → /usr/bin/
│       └── system.d/           # Systemd services
├── scripts/                # Build helper scripts
│   ├── build.sh
│   ├── clean.sh
│   └── mount-image.sh
├── out/                    # Build output images
├── Makefile                # Build wrapper
├── devenv.nix              # Nix FHS environment
└── docs/
    └── CUSTOMIZATION.md
```

## Build Commands

```bash
# Docker build (recommended)
make build DEVICE=RGB30

# With specific job count (use JOBS=1 to avoid meson lock race conditions)
make build DEVICE=RGB30 JOBS=1

# Enter Docker shell for debugging
make docker-shell

# Apply overlay without building
make apply-overlay

# Clean builds
make clean          # Clean build artifacts
make clean-out      # Clean output directory
make distclean      # Full clean including downloads
```

## Supported Devices

All RK3566-based devices:
- **RGB30** - Powkiddy RGB30 (default)
- **RG353P/V** - Anbernic RG353P, RG353V, RG353PS, RG353VS
- **RG503** - Anbernic RG503
- **RG-ARC** - Anbernic RG-ARC-D, RG-ARC-S
- **X55/X35S** - Powkiddy X55, X35S
- **RGB10MAX3** - Powkiddy RGB10 MAX 3
- **RK2023** - Powkiddy RK2023

## Image Types

| Image | Device Tree | Use For |
|-------|-------------|---------|
| **Generic** | Auto-detected via `fdtdir` | RGB30, RG353, RG503, RG-ARC, RGB10MAX3, RK2023 |
| **Specific** | Hardcoded `rk3566-powkiddy-x55.dtb` | Powkiddy X55 and X35S **ONLY** |

**IMPORTANT:** Always use Generic image for RGB30! The Specific image causes display glitches due to wrong device tree.

## Overlay System

The `overlay/` directory keeps `source/` read-only while allowing customizations.

### Adding a Systemd Service

1. Create service file:
```bash
overlay/projects/ROCKNIX/packages/rocknix/system.d/my-service.service
```

2. Create script (if needed):
```bash
overlay/projects/ROCKNIX/packages/rocknix/sources/scripts/my-script
chmod +x overlay/projects/ROCKNIX/packages/rocknix/sources/scripts/my-script
```

3. Add to Makefile `apply-overlay` target:
```makefile
sed -i '/enable_service rocknix-autostart.service/a\  enable_service my-service.service' \
    $(SOURCE_DIR)/projects/ROCKNIX/packages/rocknix/package.mk
```

### Service Example

```ini
# overlay/projects/ROCKNIX/packages/rocknix/system.d/mount-games-external.service
[Unit]
Description=Mount external games storage to roms
After=rocknix-automount.service
Before=emustation.service essway.service

[Service]
Type=oneshot
ExecStart=/usr/bin/mount-games-external
RemainAfterExit=yes

[Install]
WantedBy=rocknix.target
```

## Key Source Paths

| Path | Description |
|------|-------------|
| `source/projects/ROCKNIX/config.xml` | Device tree mappings (Generic vs Specific) |
| `source/projects/ROCKNIX/packages/rocknix/package.mk` | Main package build script |
| `source/projects/ROCKNIX/packages/rocknix/system.d/` | Systemd services |
| `source/projects/ROCKNIX/packages/rocknix/sources/scripts/` | Scripts installed to /usr/bin |
| `source/projects/ROCKNIX/packages/rocknix/autostart/` | Autostart scripts (less reliable than systemd) |
| `source/projects/ROCKNIX/packages/ui/emulationstation/` | ES-DE frontend |

## Boot Sequence

```
systemd-tmpfiles-setup.service
    ↓
rocknix-automount.service      # Mounts storage
    ↓
mount-games-external.service   # Custom mounts (if added)
    ↓
rocknix-autostart.service      # Runs autostart scripts
    ↓
emustation.service             # Starts EmulationStation-DE
```

## Inspecting Built Images

```bash
# Mount image for inspection
./scripts/mount-image.sh out/RGB30/latest-Generic.img.gz

# Inspect contents
ls /tmp/rocknix-inspect/boot/device_trees/       # Device trees
ls /tmp/rocknix-inspect/system/usr/bin/          # Binaries
ls /tmp/rocknix-inspect/system/usr/lib/libretro/ # Emulator cores
ls /tmp/rocknix-inspect/system/usr/lib/systemd/system/ # Services

# Check boot config
cat /tmp/rocknix-inspect/boot/extlinux/extlinux.conf

# Unmount
./scripts/mount-image.sh --unmount
```

## Troubleshooting

### Display Glitches on RGB30

**Symptom:** Flickering, pixel shifting, vertical lines during boot

**Cause:** Using Specific image instead of Generic

**Solution:** Use `latest-Generic.img.gz` - it auto-detects the correct device tree

### Meson Lock Race Condition

**Symptom:** Build fails with meson lock errors

**Solution:** Reduce parallel jobs:
```bash
make build JOBS=1
```

### Build Takes Too Long

Full build with JOBS=1 takes ~10 hours. With higher parallelism (~8 jobs), it can complete in ~2-3 hours, but may hit race conditions.

### Service Not Starting

1. Verify service is enabled in package.mk
2. Check service file syntax
3. SSH into device and check:
```bash
systemctl status my-service
journalctl -u my-service
```

## Device Access

- **Username:** `root`
- **Password:** `rocknix`
- **SSH:** Enabled by default

```bash
ssh root@<device-ip>
```

## Build Output

```
out/RGB30/
├── ROCKNIX-RK3566.aarch64-YYYYMMDD-Generic.img.gz      # Main image
├── ROCKNIX-RK3566.aarch64-YYYYMMDD-Generic.img.gz.sha256
├── ROCKNIX-RK3566.aarch64-YYYYMMDD-Specific.img.gz     # X55/X35S only
├── ROCKNIX-RK3566.aarch64-YYYYMMDD-Specific.img.gz.sha256
├── ROCKNIX-RK3566.aarch64-YYYYMMDD.tar                 # Update archive
├── ROCKNIX-RK3566.aarch64-YYYYMMDD.tar.sha256
├── latest-Generic.img.gz → ...                         # Symlink
└── latest-Specific.img.gz → ...                        # Symlink
```

## Flashing

```bash
# Linux/macOS
gunzip -c out/RGB30/latest-Generic.img.gz | sudo dd of=/dev/sdX bs=4M status=progress

# Or use balenaEtcher with the .img.gz file directly
```

## Runtime Customization (Without Rebuild)

SSH into device and create custom systemd service:

```bash
cat > /storage/.config/system.d/my-service.service <<'EOF'
[Unit]
Description=My custom service
After=rocknix-automount.service
Before=emustation.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo hello"
RemainAfterExit=yes

[Install]
WantedBy=rocknix.target
EOF

systemctl daemon-reload
systemctl enable my-service.service
reboot
```

## Resources

- [ROCKNIX GitHub](https://github.com/ROCKNIX/distribution)
- [ROCKNIX Wiki](https://github.com/ROCKNIX/distribution/wiki)
