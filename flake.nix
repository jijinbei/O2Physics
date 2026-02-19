{
  description = "O2Physics - ALICE Analysis Framework (Phase 1: Basic Structure)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Basic development shell
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Compilers and build tools
            clang
            cmake
            ninja
            pkg-config
            gnumake

            # Version control
            git

            # Core dependencies
            root
            boost

            # Python for scripts
            python311
            python311Packages.pip

            # System libraries
            zlib
            openssl
            curl
          ];

          shellHook = ''
            echo "O2Physics Nix Development Environment (Phase 1)"
            echo "==============================================="
            echo ""

            # Basic environment setup
            export BUILD_DIR="$PWD/build-nix"
            export INSTALL_PREFIX="$PWD/install-nix"

            echo "Build directory: $BUILD_DIR"
            echo "Install prefix: $INSTALL_PREFIX"
            echo ""
            echo "Phase 1: Basic structure established"
            echo "Next: Add LLD optimization and more dependencies"
          '';
        };

      in
      {
        devShells.default = devShell;
      });
}