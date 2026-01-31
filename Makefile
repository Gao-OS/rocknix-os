# ROCKNIX Build Wrapper
# Custom build system for ROCKNIX OS

PROJECT_DIR := $(shell pwd)
SOURCE_DIR := $(PROJECT_DIR)/source
SCRIPTS_DIR := $(PROJECT_DIR)/scripts
OVERLAY_DIR := $(PROJECT_DIR)/overlay
OUT_DIR := $(PROJECT_DIR)/out
DOCKER_IMAGE := ghcr.io/rocknix/rocknix-build:latest

# Get user/group IDs for Docker
UID := $(shell id -u)
GID := $(shell id -g)

# Default device
DEVICE ?= RGB30

# Number of parallel jobs
JOBS ?= $(shell nproc)

# Determine ROCKNIX device identifier
ROCKNIX_DEVICE := RK3566

# Device to ROCKNIX mapping (all RK3566-based)
SUPPORTED_DEVICES := RGB30 RG353P RG353V RG353PS RG353VS RG503 RG-ARC-D RG-ARC-S RGB10MAX3 RGB20PRO RGB20SX RK2023 X35S X55

.PHONY: all build clean menuconfig distclean help init docker-build docker-shell fhs-build clean-out apply-overlay

all: build

help:
	@echo "ROCKNIX Build System"
	@echo ""
	@echo "Usage: make [target] [DEVICE=<device>] [JOBS=<n>]"
	@echo ""
	@echo "Targets:"
	@echo "  init         - Initialize submodules"
	@echo "  build        - Build ROCKNIX image using Docker (recommended)"
	@echo "  fhs-build    - Build using native FHS environment (requires devenv)"
	@echo "  docker-shell - Open shell in Docker build environment"
	@echo "  menuconfig   - Configure build options"
	@echo "  clean        - Clean build artifacts"
	@echo "  clean-out    - Clean output directory"
	@echo "  distclean    - Full clean including downloads and output"
	@echo ""
	@echo "Supported Devices (all RK3566-based):"
	@echo "  RGB30        - Powkiddy RGB30 (default)"
	@echo "  RG353P/V     - Anbernic RG353P, RG353V, RG353PS, RG353VS"
	@echo "  RG503        - Anbernic RG503"
	@echo "  RG-ARC       - Anbernic RG-ARC-D, RG-ARC-S"
	@echo "  X55/X35S     - Powkiddy X55, X35S"
	@echo "  RGB10MAX3    - Powkiddy RGB10 MAX 3"
	@echo "  RGB20PRO/SX  - Powkiddy RGB20 Pro, RGB20SX"
	@echo "  RK2023       - Powkiddy RK2023"
	@echo ""
	@echo "Output Images:"
	@echo "  *-Generic.img.gz  - Auto-detects device at boot (USE THIS FOR MOST DEVICES)"
	@echo "  *-Specific.img.gz - Hardcoded for Powkiddy X55/X35S only"
	@echo ""
	@echo "IMPORTANT: For RGB30, RG353, RG503, RG-ARC, use the Generic image!"
	@echo "           The Specific image is ONLY for Powkiddy X55 and X35S."
	@echo ""
	@echo "Output: $(OUT_DIR)/<device>/"
	@echo ""
	@echo "Examples:"
	@echo "  make build DEVICE=RGB30"
	@echo "  make build DEVICE=X55 JOBS=8"

init:
	git submodule update --init --recursive

# Docker build (recommended)
build: init apply-overlay docker-build copy-output
	@echo ""
	@echo "Build complete! Output: $(OUT_DIR)/$(DEVICE)/"

# Apply overlay files to source directory
apply-overlay:
	@if [ -d "$(OVERLAY_DIR)" ]; then \
		echo "Applying overlay files..."; \
		cp -rv $(OVERLAY_DIR)/* $(SOURCE_DIR)/; \
		if ! grep -q "mount-games-external.service" $(SOURCE_DIR)/projects/ROCKNIX/packages/rocknix/package.mk; then \
			echo "Patching package.mk to enable mount-games-external.service..."; \
			sed -i '/enable_service rocknix-autostart.service/a\  ### Mount external games storage before ES-DE starts\n  enable_service mount-games-external.service' \
				$(SOURCE_DIR)/projects/ROCKNIX/packages/rocknix/package.mk; \
		fi; \
		if ! grep -q "Mount Games External" $(SOURCE_DIR)/projects/ROCKNIX/packages/misc/modules/sources/gamelist.xml; then \
			echo "Patching gamelist.xml to add Mount Games External entry..."; \
			sed -i '/<\/gameList>/i\    <game>\n        <path>./Mount Games External.sh</path>\n        <name>Mount Games External</name>\n        <desc>Mount external games storage (/storage/games-external) to /storage/roms using bind mount. Use this if games from external storage are not visible.</desc>\n        <developer>Gao-OS</developer>\n        <publisher>Gao-OS</publisher>\n        <rating>5.0</rating>\n        <releasedate>2024</releasedate>\n        <genre>tool</genre>\n        <players>1</players>\n    </game>' \
				$(SOURCE_DIR)/projects/ROCKNIX/packages/misc/modules/sources/gamelist.xml; \
		fi; \
	fi

docker-build:
	@echo "Building ROCKNIX for $(DEVICE) ($(ROCKNIX_DEVICE)) using Docker..."
	docker run --rm --user $(UID):$(GID) \
		-v "$(PROJECT_DIR)":"$(PROJECT_DIR)" \
		-w "$(SOURCE_DIR)" \
		-e THREADCOUNT=$(JOBS) \
		$(DOCKER_IMAGE) \
		/bin/bash -c "make $(ROCKNIX_DEVICE)"

# Copy output to out directory
copy-output:
	@echo "Copying output to $(OUT_DIR)/$(DEVICE)/..."
	@mkdir -p "$(OUT_DIR)/$(DEVICE)"
	@if [ -d "$(SOURCE_DIR)/target" ]; then \
		for file in $(SOURCE_DIR)/target/ROCKNIX-$(ROCKNIX_DEVICE)*.img.gz \
		            $(SOURCE_DIR)/target/ROCKNIX-$(ROCKNIX_DEVICE)*.tar \
		            $(SOURCE_DIR)/target/ROCKNIX-$(ROCKNIX_DEVICE)*.sha256; do \
			if [ -f "$$file" ]; then \
				cp -v "$$file" "$(OUT_DIR)/$(DEVICE)/"; \
			fi; \
		done; \
		cd "$(OUT_DIR)/$(DEVICE)" && \
		for img in ROCKNIX-$(ROCKNIX_DEVICE)*-Generic.img.gz; do \
			if [ -f "$$img" ]; then ln -sf "$$img" "latest-Generic.img.gz"; fi; \
		done && \
		for img in ROCKNIX-$(ROCKNIX_DEVICE)*-Specific.img.gz; do \
			if [ -f "$$img" ]; then ln -sf "$$img" "latest-Specific.img.gz"; fi; \
		done; \
		echo ""; \
		echo "Output files:"; \
		ls -lh "$(OUT_DIR)/$(DEVICE)/"*.img.gz 2>/dev/null || true; \
		echo ""; \
		echo "=== WHICH IMAGE TO USE ==="; \
		echo "For $(DEVICE): Use latest-Generic.img.gz (auto-detects device)"; \
		echo "Note: latest-Specific.img.gz is ONLY for Powkiddy X55/X35S"; \
	else \
		echo "Error: Build output not found"; \
		exit 1; \
	fi

# FHS build (native, requires devenv shell)
fhs-build: init apply-overlay
	@echo "Building ROCKNIX for $(DEVICE) ($(ROCKNIX_DEVICE)) using FHS environment..."
	DEVICE=$(DEVICE) JOBS=$(JOBS) $(SCRIPTS_DIR)/build.sh

# Docker shell for manual operations
docker-shell:
	docker run --rm -it --user $(UID):$(GID) \
		-v "$(PROJECT_DIR)":"$(PROJECT_DIR)" \
		-w "$(SOURCE_DIR)" \
		$(DOCKER_IMAGE) \
		/bin/bash

# Menuconfig
menuconfig:
	docker run --rm -it --user $(UID):$(GID) \
		-v "$(PROJECT_DIR)":"$(PROJECT_DIR)" \
		-w "$(SOURCE_DIR)" \
		$(DOCKER_IMAGE) \
		/bin/bash -c "PROJECT=ROCKNIX DEVICE=$(ROCKNIX_DEVICE) make kconfig-menuconfig-$(ROCKNIX_DEVICE)"

# Clean targets
clean:
	cd $(SOURCE_DIR) && make clean || true

clean-out:
	rm -rf $(OUT_DIR)

distclean: clean-out
	cd $(SOURCE_DIR) && make distclean || true
