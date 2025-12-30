#!/bin/bash
# ROCKNIX Custom Build Script
# Builds ROCKNIX and outputs to ./out/{device}/

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$PROJECT_DIR/source"

# Default values
DEVICE="${DEVICE:-RGB30}"
ROCKNIX_DEVICE=""
CLEAN_BUILD="${CLEAN_BUILD:-0}"
JOBS="${JOBS:-$(nproc)}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Map device names to ROCKNIX device identifiers
map_device() {
    case "$DEVICE" in
        RGB30|RG353P|RG353V|RG353PS|RG353VS|RG503|RG-ARC-D|RG-ARC-S|RGB10MAX3|RGB20PRO|RGB20SX|RK2023|X35S|X55)
            ROCKNIX_DEVICE="RK3566"
            ;;
        *)
            log_error "Unknown device: $DEVICE"
            echo "Supported devices: RGB30, RG353P, RG353V, RG503, X55, etc."
            exit 1
            ;;
    esac
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --device DEVICE    Target device (default: RGB30)"
    echo "  -c, --clean            Clean build before building"
    echo "  -j, --jobs N           Number of parallel jobs (default: $(nproc))"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Supported devices:"
    echo "  RGB30      - Powkiddy RGB30"
    echo "  RG353P     - Anbernic RG353P"
    echo "  RG353V     - Anbernic RG353V"
    echo "  RG503      - Anbernic RG503"
    echo "  X55        - Powkiddy X55"
    echo ""
    echo "Environment variables:"
    echo "  DEVICE       - Target device"
    echo "  CLEAN_BUILD  - Set to 1 for clean build"
    echo "  JOBS         - Number of parallel jobs"
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--device)
                DEVICE="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN_BUILD=1
                shift
                ;;
            -j|--jobs)
                JOBS="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."
    cd "$SOURCE_DIR"
    make clean || true
}

# Run the build
run_build() {
    log_info "Building ROCKNIX for $DEVICE ($ROCKNIX_DEVICE)..."
    log_info "Using $JOBS parallel jobs"

    cd "$SOURCE_DIR"

    # Set build environment
    export PROJECT=ROCKNIX
    export DEVICE="$ROCKNIX_DEVICE"
    export ARCH=aarch64
    export THREADCOUNT="$JOBS"

    # Run the build
    make "$ROCKNIX_DEVICE"
}

# Copy output to out directory
copy_output() {
    local OUT_DIR="$PROJECT_DIR/out/$DEVICE"
    local SOURCE_TARGET="$SOURCE_DIR/target"
    local DATE=$(date +%Y%m%d)

    log_info "Copying build output to $OUT_DIR..."

    # Create output directory
    mkdir -p "$OUT_DIR"

    # Find and copy the built images
    if [ -d "$SOURCE_TARGET" ]; then
        # Copy all image files
        for file in "$SOURCE_TARGET"/ROCKNIX-${ROCKNIX_DEVICE}*.img.gz \
                    "$SOURCE_TARGET"/ROCKNIX-${ROCKNIX_DEVICE}*.tar \
                    "$SOURCE_TARGET"/ROCKNIX-${ROCKNIX_DEVICE}*.sha256; do
            if [ -f "$file" ]; then
                cp -v "$file" "$OUT_DIR/"
            fi
        done

        # Create a latest symlink
        cd "$OUT_DIR"
        for img in ROCKNIX-${ROCKNIX_DEVICE}*-Generic.img.gz; do
            if [ -f "$img" ]; then
                ln -sf "$img" "latest-Generic.img.gz"
            fi
        done
        for img in ROCKNIX-${ROCKNIX_DEVICE}*-Specific.img.gz; do
            if [ -f "$img" ]; then
                ln -sf "$img" "latest-Specific.img.gz"
            fi
        done

        log_success "Output copied to $OUT_DIR"
        echo ""
        echo "Built images:"
        ls -lh "$OUT_DIR"/*.img.gz 2>/dev/null || true
    else
        log_error "Build output not found at $SOURCE_TARGET"
        exit 1
    fi
}

# Main
main() {
    parse_args "$@"
    map_device

    echo "=============================================="
    echo "  ROCKNIX Custom Build"
    echo "=============================================="
    echo "  Device:     $DEVICE"
    echo "  Target:     $ROCKNIX_DEVICE"
    echo "  Jobs:       $JOBS"
    echo "  Clean:      $CLEAN_BUILD"
    echo "  Output:     $PROJECT_DIR/out/$DEVICE/"
    echo "=============================================="
    echo ""

    # Clean if requested
    if [ "$CLEAN_BUILD" = "1" ]; then
        clean_build
    fi

    # Run build
    run_build

    # Copy output
    copy_output

    log_success "Build complete!"
}

main "$@"
