{
  description = "O2Physics - ALICE Analysis Framework (Phase 2: LLD Optimization)";

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
            # Compilers and build tools with LLD
            clang
            lld
            mold  # Alternative fast linker
            cmake
            ninja
            pkg-config
            gnumake
            ccache  # Build cache

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
            echo "O2Physics Nix Development Environment (Phase 2: LLD Optimized)"
            echo "=============================================================="
            echo ""

            # Environment setup
            export BUILD_DIR="$PWD/build-nix"
            export INSTALL_PREFIX="$PWD/install-nix"

            # Compiler and linker configuration for LLD
            export CC="${pkgs.clang}/bin/clang"
            export CXX="${pkgs.clang}/bin/clang++"
            export LD="${pkgs.lld}/bin/ld.lld"
            export LDFLAGS="-fuse-ld=lld"

            # ccache configuration for faster rebuilds
            export CCACHE_DIR="$PWD/.ccache"
            export CCACHE_MAXSIZE="10G"
            export PATH="${pkgs.ccache}/bin/ccache:$PATH"

            echo "Build configuration:"
            echo "  Compiler: $(${pkgs.clang}/bin/clang --version | head -1)"
            echo "  Linker: LLD (fast linking enabled)"
            echo "  Build cache: ccache configured"
            echo ""
            echo "Environment variables:"
            echo "  CC=$CC"
            echo "  CXX=$CXX"
            echo "  LD=$LD"
            echo "  BUILD_DIR=$BUILD_DIR"
            echo ""
            echo "Phase 2: LLD optimization added"
            echo "Next: Add development helper functions"
          '';
        };

      in
      {
        devShells.default = devShell;
      });
}