{ pkgs, lib, config, inputs, ... }:

let
  # FHS environment for ROCKNIX builds
  # Buildroot requires standard Linux filesystem layout
  rocknixFHS = pkgs.buildFHSEnv {
    name = "rocknix-fhs";

    targetPkgs = pkgs: with pkgs; [
      # Core build tools
      gcc
      gcc.cc.lib
      glibc
      glibc.static
      binutils
      gnumake
      cmake
      ninja
      meson

      # Standard utilities
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
      file
      which
      bc

      # Scripting languages
      perl
      python3
      python3Packages.pip
      python3Packages.pyyaml
      python3Packages.pyelftools

      # Version control
      git
      git-lfs

      # Network tools
      wget
      curl
      rsync

      # Image creation tools
      squashfsTools
      e2fsprogs
      dosfstools
      mtools
      parted
      util-linux
      ubootTools

      # Device tree compiler
      dtc

      # Kernel/U-Boot build deps
      bison
      flex
      openssl
      openssl.dev
      libelf
      elfutils

      # Compression
      cpio
      lz4
      zstd
      lzo
      lzop

      # For menuconfig
      ncurses
      ncurses.dev
      pkg-config

      # Additional build dependencies
      autoconf
      automake
      libtool
      gettext
      texinfo
      help2man

      # Libraries commonly needed
      zlib
      zlib.dev
      libffi
      libffi.dev
      libxml2
      libxslt

      # Graphics/display tools (for image generation)
      imagemagick

      # Archive tools
      p7zip

      # Development headers
      linux-headers

      # Ccache for faster rebuilds
      ccache
    ];

    multiPkgs = null;  # No 32-bit multilib needed for ARM64 builds

    runScript = "bash";

    profile = ''
      # Build environment setup
      export PS1="(rocknix-fhs) \u@\h:\w$ "
      export MAKEFLAGS="-j$(nproc)"

      # Ccache configuration
      export CCACHE_DIR="''${CCACHE_DIR:-$HOME/.ccache}"
      export CCACHE_MAXSIZE="20G"
      export USE_CCACHE=1

      # Ensure pkg-config finds libraries
      export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig"

      # Library paths
      export C_INCLUDE_PATH="/usr/include"
      export CPLUS_INCLUDE_PATH="/usr/include"
      export LD_LIBRARY_PATH="/usr/lib:/lib"

      # SSL certificates
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    '';

    extraBuildCommands = ''
      # Ensure standard directories exist
      mkdir -p usr/include
      mkdir -p usr/lib/pkgconfig
    '';
  };
in
{
  # ROCKNIX Build Environment
  # Uses FHS (Filesystem Hierarchy Standard) environment for Buildroot compatibility

  env = {
    ROCKNIX_ROOT = "${config.env.DEVENV_ROOT}/source";
    BUILD_DIR = "${config.env.DEVENV_ROOT}/build";
  };

  packages = with pkgs; [
    # Include the FHS environment
    rocknixFHS

    # Docker for containerized builds (alternative method)
    docker
    docker-compose
  ];

  # Shell hook
  enterShell = ''
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           ROCKNIX Build Environment                          ║"
    echo "║                                                              ║"
    echo "║  Target: Powkiddy RGB30 (RK3566)                             ║"
    echo "║                                                              ║"
    echo "║  Commands:                                                   ║"
    echo "║    rocknix-fhs       - Enter FHS build environment           ║"
    echo "║    make build        - Build using Docker (recommended)      ║"
    echo "║    make docker-shell - Docker build shell                    ║"
    echo "║                                                              ║"
    echo "║  FHS Build (native):                                         ║"
    echo "║    rocknix-fhs                                               ║"
    echo "║    cd source && make RK3566                                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    # Ensure submodule is initialized
    if [ ! -f "$ROCKNIX_ROOT/Makefile" ]; then
      echo ""
      echo "WARNING: ROCKNIX submodule not initialized."
      echo "Run: git submodule update --init --recursive"
    fi
  '';

  scripts = {
    # Enter FHS environment for native builds
    rocknix-build-fhs.exec = ''
      cd $ROCKNIX_ROOT
      rocknix-fhs -c "make $@"
    '';

    # Build specific device in FHS
    rocknix-build-rk3566.exec = ''
      cd $ROCKNIX_ROOT
      rocknix-fhs -c "make RK3566"
    '';

    # Clean build
    rocknix-clean.exec = ''
      cd $ROCKNIX_ROOT
      rocknix-fhs -c "make clean"
    '';

    # Enter FHS shell in source directory
    rocknix-shell.exec = ''
      cd $ROCKNIX_ROOT
      rocknix-fhs
    '';
  };
}
