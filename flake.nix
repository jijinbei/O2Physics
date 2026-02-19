{
  description = "O2Physics - ALICE Analysis Framework (Phase 4: O2 Framework)";

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

        # Custom O2 framework package
        o2 = pkgs.stdenv.mkDerivation rec {
          pname = "alice-o2";
          version = "dev-2024";

          src = pkgs.fetchFromGitHub {
            owner = "AliceO2Group";
            repo = "AliceO2";
            rev = "dev";
            sha256 = "sha256-JiAJ2nxRFu//z3OEPKHXMtOBGBLeyLb+hRdZMDaUwGc=";
          };

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
            git
          ];

          buildInputs = with pkgs; [
            # Core dependencies
            root
            boost

            # Arrow and data processing
            arrow-cpp

            # Messaging and communication
            zeromq

            # Serialization and data formats
            protobuf
            msgpack-cxx
            nlohmann_json
            fmt

            # System libraries
            openssl
            curl
            zlib

            # Graphics (for event display)
            glfw
            glew

            # Additional scientific libraries
            gsl
            vc  # SIMD vectorization

            # Monitoring and logging
            prometheus-cpp
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
            "-DO2_BUILD_FOR_O2PHYSICS=ON"
            "-DENABLE_CASSERT=OFF"
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # Only use LLD on Linux
            "-DCMAKE_LINKER=${pkgs.lld}/bin/ld.lld"
            "-DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld"
            "-DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld"
          ];

          # Skip tests during build for now
          doCheck = false;
        };

        # KFParticle package
        kfparticle = pkgs.stdenv.mkDerivation rec {
          pname = "kfparticle";
          version = "1.3";

          src = pkgs.fetchFromGitHub {
            owner = "alisw";
            repo = "KFParticle";
            rev = "v1.1-alice9";
            sha256 = "sha256-zxlpHMs82ZdYs9fjbWDHt7aeXo7ZIw3bSy077hEeVrE=";
          };

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
          ];

          buildInputs = with pkgs; [
            root
            vc  # SIMD vectorization library
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            "-DCMAKE_LINKER=${pkgs.lld}/bin/ld.lld"
          ];
        };

        # fjcontrib package - placeholder for now
        # FastJet contrib is typically included with fastjet or needs manual download
        fjcontrib = pkgs.stdenv.mkDerivation rec {
          pname = "fjcontrib";
          version = "1.049";

          # For now, create a stub package
          # TODO: Replace with actual fjcontrib source
          phases = [ "installPhase" ];

          installPhase = ''
            mkdir -p $out/lib $out/include
            echo "fjcontrib stub package" > $out/lib/README
          '';
        };

        # Development shell with O2 framework
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

            # O2Physics dependencies
            # o2  # Takes long time to build
            kfparticle
            fjcontrib

            # Python for scripts
            python311
            python311Packages.pip

            # O2 dependencies
            arrow-cpp
            zeromq
            protobuf
            msgpack-cxx
            nlohmann_json
            fmt
            gsl
            fastjet  # For fjcontrib

            # System libraries
            zlib
            openssl
            curl
            glfw
            glew
          ];

          shellHook = ''
            echo "╔═══════════════════════════════════════════════════════════╗"
            echo "║   O2Physics Nix Development Environment (Phase 4: O2)      ║"
            echo "╚═══════════════════════════════════════════════════════════╝"
            echo ""

            # Environment setup
            export BUILD_DIR="$PWD/build-nix"
            export INSTALL_PREFIX="$PWD/install-nix"
            export ALIBUILD_WORK_DIR="$PWD/sw"

            # Compiler and linker configuration
            export CC="${pkgs.clang}/bin/clang"
            export CXX="${pkgs.clang}/bin/clang++"

            # Platform-specific linker settings
            if [[ "$OSTYPE" == "darwin"* ]]; then
              # macOS: Use default ld64 (already parallelized)
              # No special LDFLAGS needed on macOS
              echo "🔗 Using macOS ld64 (parallel linking)"
            else
              # Linux: Use LLD for faster linking
              export LD="${pkgs.lld}/bin/ld.lld"
              export LDFLAGS="-fuse-ld=lld"
              echo "🔗 Using LLD for fast linking on Linux"
            fi

            # ROOT environment
            export ROOTSYS="${pkgs.root}"
            export ROOT_INCLUDE_PATH="${pkgs.root}/include"

            # CMake configuration
            export CMAKE_PREFIX_PATH="${kfparticle}:${fjcontrib}:${pkgs.root}:${pkgs.boost}:$CMAKE_PREFIX_PATH"

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
              echo "⚙️  Configuring build with CMake..."
              mkdir -p "$BUILD_DIR"
              cd "$BUILD_DIR"

              # Platform-specific flags
              local CMAKE_FLAGS=""
              if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                CMAKE_FLAGS="-DCMAKE_LINKER=${pkgs.lld}/bin/ld.lld -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld"
                echo "  Using LLD linker for faster builds on Linux"
              fi

              cmake .. \
                -DCMAKE_BUILD_TYPE=''${CMAKE_BUILD_TYPE:-RelWithDebInfo} \
                -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
                -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
                $CMAKE_FLAGS \
                -G Ninja \
                "$@"
              cd - > /dev/null
            }

            o2p-build() {
              echo "🚀 Building O2Physics..."
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
        packages = {
          inherit o2 kfparticle fjcontrib;
        };

        devShells.default = devShell;
      });
}