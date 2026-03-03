{ pkgs, lib, config, inputs, ... }:

{
  # ROCKNIX Build Environment (Docker-based)

  env = {
    ROCKNIX_ROOT = "${config.env.DEVENV_ROOT}/source";
  };

  packages = with pkgs; [
    docker
    docker-compose
    gnumake
    git
  ];

  enterShell = ''
    echo "╔══════════════════════════════════════════════╗"
    echo "║        ROCKNIX Build Environment             ║"
    echo "║                                              ║"
    echo "║  make build        - Build image (Docker)    ║"
    echo "║  make docker-shell - Docker build shell      ║"
    echo "║  make help         - Show all commands       ║"
    echo "╚══════════════════════════════════════════════╝"

    if [ ! -f "$ROCKNIX_ROOT/Makefile" ]; then
      echo ""
      echo "WARNING: ROCKNIX submodule not initialized."
      echo "Run: make init"
    fi
  '';
}
