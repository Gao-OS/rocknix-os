#!/usr/bin/env bash
#
# ROCKNIX Image Mount Script
#
# This script mounts a ROCKNIX image file to inspect its contents.
# It handles decompression, partition mounting, and squashfs mounting.
#
# Usage:
#   ./scripts/mount-image.sh <image.img.gz>           # Mount image
#   ./scripts/mount-image.sh --unmount                # Unmount and cleanup
#   ./scripts/mount-image.sh --help                   # Show help
#
# Examples:
#   ./scripts/mount-image.sh out/RGB30/latest-Specific.img.gz
#   ./scripts/mount-image.sh out/RGB30/ROCKNIX-RK3566.aarch64-20251230-Specific.img.gz
#

set -e

# Configuration
MOUNT_BASE="/tmp/rocknix-inspect"
MOUNT_BOOT="$MOUNT_BASE/boot"
MOUNT_SYSTEM="$MOUNT_BASE/system"
EXTRACTED_IMG="$MOUNT_BASE/rocknix.img"

# Boot partition offset (sector 32768 * 512 bytes)
BOOT_OFFSET=16777216

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "ROCKNIX Image Mount Script"
    echo ""
    echo "Usage:"
    echo "  $0 <image.img.gz>    Mount a ROCKNIX image for inspection"
    echo "  $0 --unmount         Unmount and cleanup"
    echo "  $0 --status          Show current mount status"
    echo "  $0 --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 out/RGB30/latest-Specific.img.gz"
    echo "  $0 out/RGB30/ROCKNIX-RK3566.aarch64-20251230-Specific.img.gz"
    echo ""
    echo "After mounting, inspect the image at:"
    echo "  Boot partition: $MOUNT_BOOT"
    echo "  System root:    $MOUNT_SYSTEM"
}

print_status() {
    echo "=== Mount Status ==="
    if mountpoint -q "$MOUNT_SYSTEM" 2>/dev/null; then
        echo -e "${GREEN}System mounted:${NC} $MOUNT_SYSTEM"
    else
        echo -e "${YELLOW}System not mounted${NC}"
    fi

    if mountpoint -q "$MOUNT_BOOT" 2>/dev/null; then
        echo -e "${GREEN}Boot mounted:${NC} $MOUNT_BOOT"
    else
        echo -e "${YELLOW}Boot not mounted${NC}"
    fi

    if [ -f "$EXTRACTED_IMG" ]; then
        echo -e "${GREEN}Extracted image:${NC} $EXTRACTED_IMG ($(du -h "$EXTRACTED_IMG" | cut -f1))"
    else
        echo -e "${YELLOW}No extracted image${NC}"
    fi
}

do_unmount() {
    echo "Unmounting ROCKNIX image..."

    # Unmount system (squashfs) first
    if mountpoint -q "$MOUNT_SYSTEM" 2>/dev/null; then
        echo "  Unmounting system..."
        sudo umount "$MOUNT_SYSTEM"
    fi

    # Unmount boot partition
    if mountpoint -q "$MOUNT_BOOT" 2>/dev/null; then
        echo "  Unmounting boot..."
        sudo umount "$MOUNT_BOOT"
    fi

    # Remove extracted image
    if [ -f "$EXTRACTED_IMG" ]; then
        echo "  Removing extracted image..."
        rm -f "$EXTRACTED_IMG"
    fi

    # Remove mount directories
    [ -d "$MOUNT_SYSTEM" ] && rmdir "$MOUNT_SYSTEM" 2>/dev/null || true
    [ -d "$MOUNT_BOOT" ] && rmdir "$MOUNT_BOOT" 2>/dev/null || true
    [ -d "$MOUNT_BASE" ] && rmdir "$MOUNT_BASE" 2>/dev/null || true

    echo -e "${GREEN}Cleanup complete${NC}"
}

do_mount() {
    local IMAGE_FILE="$1"

    # Resolve symlinks
    if [ -L "$IMAGE_FILE" ]; then
        IMAGE_FILE="$(dirname "$IMAGE_FILE")/$(readlink "$IMAGE_FILE")"
    fi

    # Check if file exists
    if [ ! -f "$IMAGE_FILE" ]; then
        echo -e "${RED}Error: Image file not found: $IMAGE_FILE${NC}"
        exit 1
    fi

    # Check if already mounted
    if mountpoint -q "$MOUNT_BOOT" 2>/dev/null || mountpoint -q "$MOUNT_SYSTEM" 2>/dev/null; then
        echo -e "${YELLOW}Warning: Image already mounted. Unmounting first...${NC}"
        do_unmount
    fi

    echo "Mounting ROCKNIX image: $IMAGE_FILE"
    echo ""

    # Create mount directories
    mkdir -p "$MOUNT_BOOT" "$MOUNT_SYSTEM"

    # Step 1: Decompress if needed
    if [[ "$IMAGE_FILE" == *.gz ]]; then
        echo "Step 1/3: Decompressing image..."
        gunzip -k -c "$IMAGE_FILE" > "$EXTRACTED_IMG"
        echo "  Extracted: $(du -h "$EXTRACTED_IMG" | cut -f1)"
    elif [[ "$IMAGE_FILE" == *.img ]]; then
        echo "Step 1/3: Copying image..."
        cp "$IMAGE_FILE" "$EXTRACTED_IMG"
    else
        echo -e "${RED}Error: Unsupported file format. Use .img or .img.gz${NC}"
        exit 1
    fi

    # Step 2: Mount boot partition
    echo "Step 2/3: Mounting boot partition..."
    sudo mount -o loop,offset=$BOOT_OFFSET,ro "$EXTRACTED_IMG" "$MOUNT_BOOT"
    echo "  Mounted at: $MOUNT_BOOT"

    # Step 3: Mount squashfs system
    if [ -f "$MOUNT_BOOT/SYSTEM" ]; then
        echo "Step 3/3: Mounting system squashfs..."
        sudo mount -o loop,ro "$MOUNT_BOOT/SYSTEM" "$MOUNT_SYSTEM"
        echo "  Mounted at: $MOUNT_SYSTEM"
    else
        echo -e "${YELLOW}Warning: SYSTEM file not found in boot partition${NC}"
    fi

    echo ""
    echo -e "${GREEN}=== Mount Complete ===${NC}"
    echo ""
    echo "Inspect the image at:"
    echo "  Boot partition: $MOUNT_BOOT"
    echo "  System root:    $MOUNT_SYSTEM"
    echo ""
    echo "Useful commands:"
    echo "  ls $MOUNT_BOOT/                           # Boot files"
    echo "  ls $MOUNT_BOOT/device_trees/              # Supported devices"
    echo "  ls $MOUNT_SYSTEM/usr/lib/libretro/        # Emulator cores"
    echo "  ls $MOUNT_SYSTEM/usr/bin/                 # Binaries"
    echo ""
    echo "To unmount: $0 --unmount"
}

# Main
case "${1:-}" in
    --help|-h)
        print_usage
        ;;
    --unmount|-u)
        do_unmount
        ;;
    --status|-s)
        print_status
        ;;
    "")
        print_usage
        exit 1
        ;;
    *)
        do_mount "$1"
        ;;
esac
