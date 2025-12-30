#!/bin/bash
# ROCKNIX Clean Script
# Cleans build artifacts

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$PROJECT_DIR/source"
OUT_DIR="$PROJECT_DIR/out"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Clean types
CLEAN_TYPE="${1:-build}"

case "$CLEAN_TYPE" in
    build)
        log_info "Cleaning build artifacts..."
        cd "$SOURCE_DIR"
        make clean || true
        log_success "Build artifacts cleaned"
        ;;
    out)
        log_info "Cleaning output directory..."
        rm -rf "$OUT_DIR"
        log_success "Output directory cleaned"
        ;;
    distclean)
        log_info "Running distclean (full clean including downloads)..."
        cd "$SOURCE_DIR"
        make distclean || true
        rm -rf "$OUT_DIR"
        log_success "Full clean completed"
        ;;
    all)
        log_info "Cleaning everything..."
        cd "$SOURCE_DIR"
        make distclean || true
        rm -rf "$OUT_DIR"
        log_success "All cleaned"
        ;;
    *)
        echo "Usage: $0 [build|out|distclean|all]"
        echo ""
        echo "  build     - Clean build artifacts (default)"
        echo "  out       - Clean output directory only"
        echo "  distclean - Full clean including downloads"
        echo "  all       - Clean everything"
        exit 1
        ;;
esac
