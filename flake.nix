{
  description = "O2Physics - ALICE Analysis Framework (Phase 3: Development Environment)";

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
            echo "╔═══════════════════════════════════════════════════════════╗"
            echo "║   O2Physics Nix Development Environment (Phase 3: Ready)    ║"
            echo "╚═══════════════════════════════════════════════════════════╝"
            echo ""

            # Environment setup
            export BUILD_DIR="$PWD/build-nix"
            export INSTALL_PREFIX="$PWD/install-nix"
            export ALIBUILD_WORK_DIR="$PWD/sw"

            # Compiler and linker configuration for LLD
            export CC="${pkgs.clang}/bin/clang"
            export CXX="${pkgs.clang}/bin/clang++"
            export LD="${pkgs.lld}/bin/ld.lld"
            export LDFLAGS="-fuse-ld=lld"

            # ROOT environment
            export ROOTSYS="${pkgs.root}"
            export ROOT_INCLUDE_PATH="${pkgs.root}/include"

            # CMake configuration
            export CMAKE_PREFIX_PATH="${pkgs.root}:${pkgs.boost}:$CMAKE_PREFIX_PATH"

            # ccache configuration for faster rebuilds
            export CCACHE_DIR="$PWD/.ccache"
            export CCACHE_MAXSIZE="10G"
            export PATH="${pkgs.ccache}/bin/ccache:$PATH"

            # Define helper functions (alibuild replacements)
            o2p-init() {
              echo "🔧 Initializing O2Physics build environment..."
              mkdir -p "$BUILD_DIR" "$INSTALL_PREFIX" "$ALIBUILD_WORK_DIR"
              echo "✅ Directories created"
            }

            o2p-configure() {
              echo "⚙️  Configuring build with CMake and LLD..."
              mkdir -p "$BUILD_DIR"
              cd "$BUILD_DIR"
              cmake .. \
                -DCMAKE_BUILD_TYPE=''${CMAKE_BUILD_TYPE:-RelWithDebInfo} \
                -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
                -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
                -DCMAKE_LINKER="${pkgs.lld}/bin/ld.lld" \
                -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld" \
                -DCMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld" \
                -G Ninja \
                "$@"
              cd - > /dev/null
            }

            o2p-build() {
              echo "🚀 Building O2Physics with LLD..."
              if [ ! -d "$BUILD_DIR" ]; then
                echo "Build directory not found. Running o2p-configure first..."
                o2p-configure
              fi
              cmake --build "$BUILD_DIR" --parallel $(nproc) "$@"
            }

            o2p-clean() {
              echo "🧹 Cleaning build artifacts..."
              rm -rf "$BUILD_DIR" "$INSTALL_PREFIX"
              echo "✅ Clean complete"
            }

            o2p-test() {
              echo "🧪 Running tests..."
              if [ ! -d "$BUILD_DIR" ]; then
                echo "Error: Build directory not found"
                return 1
              fi
              cd "$BUILD_DIR" && ctest --output-on-failure "$@" && cd - > /dev/null
            }

            o2p-doctor() {
              echo "🔍 Environment Check"
              echo "==================="
              echo "Toolchain:"
              echo "  Clang: $(${pkgs.clang}/bin/clang --version | head -1)"
              echo "  LLD: $(${pkgs.lld}/bin/ld.lld --version | head -1)"
              echo "  CMake: $(cmake --version | head -1)"
              echo "  Ninja: $(ninja --version)"
              echo ""
              echo "Environment:"
              echo "  BUILD_DIR: $BUILD_DIR"
              echo "  INSTALL_PREFIX: $INSTALL_PREFIX"
              echo "  CCACHE_DIR: $CCACHE_DIR"
              echo ""
              echo "Dependencies:"
              if command -v root-config &> /dev/null; then
                echo "  ✅ ROOT $(root-config --version)"
              else
                echo "  ❌ ROOT not found"
              fi
            }

            # Aliases for compatibility
            alias alibuild="echo 'Use o2p-build instead (alibuild replaced by Nix)'"
            alias alienv="echo 'Already in Nix environment (no alienv needed)'"
            alias aliDoctor="o2p-doctor"

            echo "🚀 Environment ready! Available commands:"
            echo ""
            echo "  o2p-init      - Initialize build environment"
            echo "  o2p-configure - Configure with CMake"
            echo "  o2p-build     - Build O2Physics"
            echo "  o2p-clean     - Clean build"
            echo "  o2p-test      - Run tests"
            echo "  o2p-doctor    - Check environment"
            echo ""
            echo "Quick start: o2p-configure && o2p-build"
          '';
        };

      in
      {
        devShells.default = devShell;
      });
}