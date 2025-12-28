{ pkgs, lib, config, inputs, ... }:

{
  # ROCKNIX Build Environment
  # Based on buildroot requirements

  env = {
    ROCKNIX_ROOT = "${config.env.DEVENV_ROOT}/rocknix";
    # Build output directory
    BUILD_DIR = "${config.env.DEVENV_ROOT}/build";
  };

  packages = with pkgs; [
    # Core build tools
    gnumake
    gcc
    binutils
    coreutils
    diffutils
    findutils
    gawk
    gnugrep
    gnused
    gnutar
    gzip
    bzip2
    xz
    unzip
    zip
    patch
    perl
    python3
    python3Packages.pip

    # Version control
    git
    git-lfs

    # Build dependencies
    ncurses
    which
    file
    bc
    rsync
    wget
    curl

    # Cross-compilation support
    pkgsCross.aarch64-multiplatform.buildPackages.gcc

    # Image creation tools
    squashfsTools
    e2fsprogs
    dosfstools
    mtools
    parted
    util-linux

    # Device tree compiler
    dtc

    # U-Boot and kernel build deps
    bison
    flex
    openssl
    libelf

    # Additional tools
    cpio
    lz4
    zstd

    # For menuconfig
    ncurses
    pkg-config
  ];

  # Shell hook to set up environment
  enterShell = ''
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           ROCKNIX Build Environment                          ║"
    echo "║                                                              ║"
    echo "║  Target: Powkiddy RGB30 (RK3566)                             ║"
    echo "║                                                              ║"
    echo "║  Commands:                                                   ║"
    echo "║    make build      - Build ROCKNIX image                     ║"
    echo "║    make clean      - Clean build artifacts                   ║"
    echo "║    make menuconfig - Configure build options                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    # Ensure submodule is initialized
    if [ ! -f "$ROCKNIX_ROOT/Makefile" ]; then
      echo ""
      echo "⚠ ROCKNIX submodule not initialized. Run: git submodule update --init --recursive"
    fi
  '';

  # Increase file descriptor limit for large builds
  scripts = {
    rocknix-build.exec = ''
      cd $ROCKNIX_ROOT
      make DEVICE=RK3566 PROJECT=Rockchip $@
    '';

    rocknix-clean.exec = ''
      cd $ROCKNIX_ROOT
      make clean
    '';
  };
}
