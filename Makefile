# ROCKNIX Build Wrapper
# Supported devices: RGB30 (RK3566)

ROCKNIX_DIR := rocknix
BUILD_DIR := build

# Default device
DEVICE ?= RGB30
PROJECT ?= Rockchip

# Determine ROCKNIX device identifier
ifeq ($(DEVICE),RGB30)
    ROCKNIX_DEVICE := RK3566
    ROCKNIX_PROJECT := Rockchip
endif

ifeq ($(DEVICE),RG353P)
    ROCKNIX_DEVICE := RK3566
    ROCKNIX_PROJECT := Rockchip
endif

ifeq ($(DEVICE),RG353V)
    ROCKNIX_DEVICE := RK3566
    ROCKNIX_PROJECT := Rockchip
endif

ifeq ($(DEVICE),RG503)
    ROCKNIX_DEVICE := RK3566
    ROCKNIX_PROJECT := Rockchip
endif

.PHONY: all build clean menuconfig distclean image help init

all: build

help:
	@echo "ROCKNIX Build System"
	@echo ""
	@echo "Usage: make [target] [DEVICE=<device>]"
	@echo ""
	@echo "Targets:"
	@echo "  init        - Initialize submodules"
	@echo "  build       - Build ROCKNIX image (default)"
	@echo "  image       - Build only the image"
	@echo "  menuconfig  - Configure build options"
	@echo "  clean       - Clean build artifacts"
	@echo "  distclean   - Full clean including downloads"
	@echo ""
	@echo "Supported Devices:"
	@echo "  RGB30       - Powkiddy RGB30 (default)"
	@echo "  RG353P      - Anbernic RG353P"
	@echo "  RG353V      - Anbernic RG353V"
	@echo "  RG503       - Anbernic RG503"
	@echo ""
	@echo "Example: make build DEVICE=RGB30"

init:
	git submodule update --init --recursive

build: init
	cd $(ROCKNIX_DIR) && \
		PROJECT=$(ROCKNIX_PROJECT) DEVICE=$(ROCKNIX_DEVICE) make image

image:
	cd $(ROCKNIX_DIR) && \
		PROJECT=$(ROCKNIX_PROJECT) DEVICE=$(ROCKNIX_DEVICE) make image

menuconfig:
	cd $(ROCKNIX_DIR) && \
		PROJECT=$(ROCKNIX_PROJECT) DEVICE=$(ROCKNIX_DEVICE) make menuconfig

clean:
	cd $(ROCKNIX_DIR) && make clean

distclean:
	cd $(ROCKNIX_DIR) && make distclean
