# ROCKNIX Build Wrapper
# Supported devices: RGB30 (RK3566)

PROJECT_DIR := $(shell pwd)
ROCKNIX_DIR := $(PROJECT_DIR)/source
DOCKER_IMAGE := ghcr.io/rocknix/rocknix-build:latest

# Get user/group IDs for Docker
UID := $(shell id -u)
GID := $(shell id -g)

# Default device
DEVICE ?= RGB30

# Determine ROCKNIX device identifier
ifeq ($(DEVICE),RGB30)
    ROCKNIX_DEVICE := RK3566
endif

ifeq ($(DEVICE),RG353P)
    ROCKNIX_DEVICE := RK3566
endif

ifeq ($(DEVICE),RG353V)
    ROCKNIX_DEVICE := RK3566
endif

ifeq ($(DEVICE),RG503)
    ROCKNIX_DEVICE := RK3566
endif

.PHONY: all build clean menuconfig distclean image help init docker-build docker-shell

all: build

help:
	@echo "ROCKNIX Build System"
	@echo ""
	@echo "Usage: make [target] [DEVICE=<device>]"
	@echo ""
	@echo "Targets:"
	@echo "  init         - Initialize submodules"
	@echo "  build        - Build ROCKNIX image using Docker (recommended)"
	@echo "  docker-shell - Open shell in Docker build environment"
	@echo "  image        - Build only the image (requires devenv shell)"
	@echo "  menuconfig   - Configure build options"
	@echo "  clean        - Clean build artifacts"
	@echo "  distclean    - Full clean including downloads"
	@echo ""
	@echo "Supported Devices:"
	@echo "  RGB30        - Powkiddy RGB30 (default)"
	@echo "  RG353P       - Anbernic RG353P"
	@echo "  RG353V       - Anbernic RG353V"
	@echo "  RG503        - Anbernic RG503"
	@echo ""
	@echo "Example: make build DEVICE=RGB30"

init:
	git submodule update --init --recursive

# Use Docker for building (recommended - handles all dependencies)
build: init docker-build

docker-build:
	docker run --rm --user $(UID):$(GID) \
		-v "$(PROJECT_DIR)":"$(PROJECT_DIR)" \
		-w "$(ROCKNIX_DIR)" \
		$(DOCKER_IMAGE) \
		/bin/bash -c "make $(ROCKNIX_DEVICE)"

docker-shell:
	docker run --rm -it --user $(UID):$(GID) \
		-v "$(PROJECT_DIR)":"$(PROJECT_DIR)" \
		-w "$(ROCKNIX_DIR)" \
		$(DOCKER_IMAGE) \
		/bin/bash

# Direct build (requires devenv shell with all dependencies)
image: init
	cd $(ROCKNIX_DIR) && \
		DEVICE_ROOT=$(ROCKNIX_DEVICE) PROJECT=ROCKNIX DEVICE=$(ROCKNIX_DEVICE) ARCH=aarch64 \
		./scripts/build_distro

menuconfig:
	docker run --rm -it --user $(UID):$(GID) \
		-v "$(PROJECT_DIR)":"$(PROJECT_DIR)" \
		-w "$(ROCKNIX_DIR)" \
		$(DOCKER_IMAGE) \
		/bin/bash -c "PROJECT=ROCKNIX DEVICE=$(ROCKNIX_DEVICE) make kconfig-menuconfig-$(ROCKNIX_DEVICE)"

clean:
	cd $(ROCKNIX_DIR) && make clean

distclean:
	cd $(ROCKNIX_DIR) && make distclean
