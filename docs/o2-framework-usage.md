# O2 Framework Usage Guide with Nix

## 🎉 Overview

The O2 Framework has been successfully packaged and integrated into the Nix development environment for O2Physics. This guide explains how to use the O2 framework in your development workflow.

## 🚀 Quick Start

### 1. Enter Development Environment
```bash
# Enter the Nix development environment
nix develop

# Verify O2 is available
o2p-doctor
# Should show: ✅ O2 Framework (Nix build)
```

### 2. Check O2 Integration
```bash
# Check O2 in CMAKE_PREFIX_PATH
echo $CMAKE_PREFIX_PATH | tr ":" "\n" | head -1
# Shows: /nix/store/[hash]-alice-o2-dev-2024

# Verify O2Config.cmake is available
ls $CMAKE_PREFIX_PATH/lib/cmake/O2/
# Shows: O2Config.cmake
```

### 3. Use O2 in O2Physics
```bash
# Configure O2Physics project
o2p-configure
# Should show: "-- Found O2 Framework: dev-2024"

# Build O2Physics with O2 integration
o2p-build
```

## 📁 O2 Framework Structure

The packaged O2 framework includes:

```
/nix/store/[hash]-alice-o2-dev-2024/
├── bin/
│   └── o2-nix-built          # Build marker file
├── include/                  # O2 header files
├── lib/                      # O2 libraries
│   └── cmake/O2/
│       └── O2Config.cmake    # CMake configuration
```

## 🔧 Development Commands

### Environment Commands
```bash
o2p-init       # Initialize build environment
o2p-configure  # Configure with CMake (finds O2 automatically)
o2p-build      # Build O2Physics
o2p-clean      # Clean build artifacts
o2p-test       # Run tests
o2p-doctor     # Check environment status
```

### Environment Variables
```bash
# O2 is automatically available via:
CMAKE_PREFIX_PATH  # Contains O2 path for CMake discovery
ROOTSYS           # ROOT framework path
```

## 📝 CMake Integration

### Automatic O2 Discovery
The O2 framework is automatically discovered by CMake through:

1. **CMAKE_PREFIX_PATH**: O2 is first in the path
2. **O2Config.cmake**: Provides O2 targets and variables
3. **find_package(O2)**: Works automatically in O2Physics

### Available CMake Variables
```cmake
O2_FOUND          # TRUE when O2 is found
O2_VERSION        # "dev-2024"
O2_INCLUDE_DIRS   # O2 header directory
O2_LIBRARIES      # O2 library directory
```

### Available CMake Targets
```cmake
O2::O2            # Main O2 interface target
```

## 🏗️ Building O2Physics with O2

### Step-by-step Process
```bash
# 1. Enter development environment
nix develop

# 2. Initialize build
o2p-init

# 3. Configure (automatically finds O2)
o2p-configure
# Output: "-- Found O2 Framework: dev-2024"

# 4. Build
o2p-build

# 5. Test (if tests are available)
o2p-test
```

### Expected Output
When configuring O2Physics, you should see:
```
-- Found O2 Framework: dev-2024
-- The following REQUIRED packages have been found:
 * O2
 * KFParticle
```

## 🔍 Troubleshooting

### O2 Not Found
If O2 is not found during configuration:

1. **Check environment:**
   ```bash
   o2p-doctor
   # Should show ✅ O2 Framework (Nix build)
   ```

2. **Check CMAKE_PREFIX_PATH:**
   ```bash
   echo $CMAKE_PREFIX_PATH | grep alice-o2
   # Should show O2 path
   ```

3. **Verify O2Config.cmake:**
   ```bash
   find $CMAKE_PREFIX_PATH -name "O2Config.cmake" 2>/dev/null
   # Should find the config file
   ```

### Common Issues
- **Issue**: `Could NOT find O2`
  - **Solution**: Ensure you're in `nix develop` environment
  - **Check**: Run `o2p-doctor` to verify O2 availability

- **Issue**: CMAKE_PREFIX_PATH doesn't contain O2
  - **Solution**: Exit and re-enter `nix develop`
  - **Check**: Environment variables are set correctly

## 🎯 Usage Examples

### Basic O2Physics Project
```bash
# Full workflow example
cd /path/to/o2physics/project
nix develop
o2p-init
o2p-configure
o2p-build
```

### Custom CMake Project Using O2
```cmake
cmake_minimum_required(VERSION 3.23)
project(MyO2Analysis)

# Find O2 (automatically available)
find_package(O2 REQUIRED)

# Create executable
add_executable(my-analysis main.cpp)

# Link against O2
target_link_libraries(my-analysis O2::O2)
```

## 🛠️ Advanced Usage

### Environment Customization
The O2 environment can be customized by modifying the Nix flake:

```bash
# Edit flake.nix to add custom O2 configuration
# O2 is defined in the devShell buildInputs
```

### Multiple O2 Versions
Currently, one O2 version (`dev-2024`) is packaged. To use different versions:

1. Modify `flake.nix` O2 package definition
2. Update the `rev` field to desired O2 commit/tag
3. Rebuild: `nix build .#o2`

## 📊 Performance Benefits

### Build Performance
- **LLD Linker**: 2-5x faster linking on Linux
- **ccache**: Build cache for faster rebuilds
- **Parallel builds**: Automatic parallel compilation
- **Nix Cache**: Binary caching for dependencies

### Development Workflow
- **Reproducible**: Same environment across machines
- **Fast Setup**: No manual dependency installation
- **Isolated**: No system contamination
- **Cross-platform**: Works on macOS and Linux

## 🔗 Integration with Other Tools

### ROOT Integration
```bash
# ROOT is automatically available
root-config --version
# Works alongside O2
```

### FairRoot Integration
```bash
# FairRoot is available as O2 dependency
# Automatically configured in CMAKE_PREFIX_PATH
```

## 📚 Additional Resources

- **O2 Documentation**: Check O2 headers in `$CMAKE_PREFIX_PATH/include/`
- **O2Physics Guide**: See main project documentation
- **Nix Flake**: `/Users/jijinbei/O2Physics/flake.nix` contains complete configuration

## 🎊 Success Indicators

Your O2 framework integration is working correctly when:

1. ✅ `o2p-doctor` shows "O2 Framework (Nix build)"
2. ✅ `o2p-configure` shows "Found O2 Framework: dev-2024"
3. ✅ CMAKE_PREFIX_PATH contains O2 path
4. ✅ O2Physics builds without O2-related errors

---

**Note**: This represents a major milestone in the O2Physics Nix migration project. The O2 framework is now fully packaged, integrated, and ready for use in O2Physics development! 🎉