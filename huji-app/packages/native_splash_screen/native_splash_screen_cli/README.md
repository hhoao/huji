# 🎨 native_splash_screen_cli

> A powerful CLI tool for generating fully native, high-performance splash screens for Flutter applications.

**native_splash_screen_cli** works in tandem with the [native_splash_screen](https://pub.dev/packages/native_splash_screen) package to generate optimized platform native code that delivers fast, smooth splash screens on **Linux**, **Windows** and **Macos**.

## 📚 Table of Contents

- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🚀 Usage](#-usage)
  - [1. Initialize Configuration](#1-initialize-configuration)
  - [2. Setup Build Files](#2-setup-build-files)
  - [3. Generate Splash Screen](#3-generate-splash-screen)
- [⚙️ CLI Reference](#️-cli-reference)
  - [Global Flags](#global-flags)
  - [Subcommands](#subcommands)
- [📝 Configuration Reference](#-configuration-reference)
  - [Platform Configuration](#platform-configuration)
  - [Release Configuration](#release-configuration)
  - [Debug/Profile/Custom Flavors](#debugprofilecustom-flavors)
  - [Color Format Reference](#color-format-reference)
- [🧩 Example Configuration](#-example-configuration)
- [📄 License](#-license)

---

## ✨ Features

- 📊 Generate native splash screens that are **truly native** (GTK/Cairo on Linux, Win32 GDI on Windows, AppKit on Macos)
- 🛠️ Easy CLI interface for setup, configuration, and generation
- 🔄 Automatic CMake integration for seamless build process
- 🎭 Support for multiple build flavors (debug, profile, and custom flavors)
- 🎨 Extensive customization of splash screen appearance
- 🚄 Blazing fast performance with minimal impact on startup time
- 📺 Smooth animations for showing and closing splash screens

## 📦 Installation

Add `native_splash_screen_cli` to the **dev_dependencies** in `pubspec.yaml` by running :

```sh
flutter pub add --dev native_splash_screen_cli
```

> 💡 Make sure both native_splash_screen and native_splash_screen_cli use the same major version to ensure compatibility between the runtime plugin and the code generator.

Then run:

```sh
flutter pub get
```

## 🚀 Usage

### 1. Initialize Configuration

Create a default configuration file in your project root:

```sh
dart run native_splash_screen_cli init
```

This creates `native_splash_screen.yaml` with detailed documentation on all available options.

### 2. Setup Build Files

After customizing your configuration, set up the necessary build files:

```sh
dart run native_splash_screen_cli setup
```

This will generate the required CMake files for each enabled platform.

### 3. Generate Splash Screen

Generate the splash screen assets and native code:

```sh
dart run native_splash_screen_cli gen
```

For flavor-specific builds:

```sh
dart run native_splash_screen_cli gen --flavor=staging
```

## ⚙️ CLI Reference

### Global Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--help` | `-h` | Print usage information |
| `--verbose` | `-v` | Log all generation steps |
| `--config=<path>` | `-c` | Path to config file (default: native_splash_screen.yaml) |
| `--color` | | Enable/disable colored output (default: true) |

### Subcommands

#### `init` - Create config file

```sh
dart run native_splash_screen_cli init [options]
```

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Print usage information |
| `--force` | `-f` | Force overwrite existing config file |

#### `setup` - Add build files

```sh
dart run native_splash_screen_cli setup [options]
```

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Print usage information |
| `--no-runner` | `-n` | Skip runner directory check |
| `--force` | `-f` | Force overwrite existing CMake files |

#### `gen` - Generate splash screen

```sh
dart run native_splash_screen_cli gen [options]
```

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Print usage information |
| `--flavor=<name>` | `-f` | Build flavor to use (default: release) |

## 📝 Configuration Reference

The `native_splash_screen.yaml` file controls all aspects of your splash screen generation.

### Platform Configuration

Configure which platforms should have splash screens generated:

```yaml
platforms:
  linux:
    enabled: true       # Enable Linux splash screen
    fallback: true      # Use release config if flavor is missing
    path: linux/runner  # Optional: custom path (must end with /runner)
  
  windows:
    enabled: true       # Enable Windows splash screen
    fallback: false     # Don't fall back to release config
  
  macos:
    enabled: true       # Enable Macos splash screen
    fallback: true     # Use release config if flavor is missing
```

### Release Configuration

The default splash screen configuration:

```yaml
release:
  linux:
    window_width: 500
    window_height: 300
    window_title: "My App"
    window_color: "#2C2C2C"
    background_color: "#FFFFFF"
    background_width: 400
    background_height: 250
    background_border_radius: 12.0
    image_path: "assets/splash_logo.png"
    image_width: 200
    image_height: 200
    image_scaling: true
    image_border_radius: 0.0
    blur_radius: 0.0
    with_animation: true
```

### Debug/Profile/Custom Flavors

Override settings for different build types:

```yaml
debug:
  linux:
    # Debug-specific settings
    window_title: "Debug Build"
    background_color: "#FFE0E0"
    image_path: "assets/debug.png"

profile:
  linux:
    # Profile-specific settings
    window_title: "Profile Build"
    background_color: "#E0FFE0"
    image_path: "assets/profile.png"

flavors:
  staging:
    linux:
      # Staging-specific settings
      window_title: "Staging Build"
      background_color: "#E0E0FF"
      image_path: "assets/staging.png"

```

### Color Format Reference

Colors can be specified in multiple formats:

1. **Hex formats**:
   - `#RGB` - 4-bit Red, Green, Blue
   - `#RGBA` - 4-bit Red, Green, Blue, Alpha
   - `#RRGGBB` - 8-bit Red, Green, Blue
   - `#RRGGBBAA` - 8-bit Red, Green, Blue, Alpha

2. **Functional notation**:
   - `rgb(r, g, b)` - e.g., `rgb(255, 128, 0)`
   - `rgba(r, g, b, a)` - e.g., `rgba(255, 128, 0, 0.5)` where `0 < a < 1`
   - `argb(a, r, g, b)` - e.g., `argb(128, 0, 255, 128)` where `0 < a < 255`

3. **Comma-separated**:
   - `r, g, b` - e.g., `255, 128, 0`
   - `r, g, b, a` - e.g., `255, 128, 0, 128` where `0 < a < 255`

## 🧩 Example Configuration

Here's a complete example configuration:

```yaml
platforms:
  linux:
    enabled: true
    fallback: true
  windows:
    enabled: true
    fallback: true
  macos:
    enabled: true
    fallback: true

release:
  linux:
    window_width: 600
    window_height: 400
    window_title: "MyApp"
    window_color: "#2C2C2C"
    background_color: "#FFFFFF"
    background_width: 550
    background_height: 350
    background_border_radius: 16.0
    image_path: "assets/logo.png"
    image_width: 300
    image_height: 200
    image_scaling: true
    with_animation: true
  
  windows:
    window_width: 600
    window_height: 400
    window_title: "MyApp"
    window_class: "MySplashClass"
    background_color: "#FFFFFF"
    background_width: 550
    background_height: 350
    background_border_radius: 16.0
    image_path: "assets/logo.png"
    image_width: 300
    image_height: 200
    image_scaling: true
    with_animation: true

  macos:
    window_width: 600
    window_height: 400
    window_title: "MyApp"
    background_color: "#FFFFFF"
    background_width: 550
    background_height: 350
    background_border_radius: 16.0
    image_path: "assets/logo.png"
    image_width: 300
    image_height: 200
    image_scaling: true
    with_animation: true

flavors:
  dev:
    linux:
      window_title: "MyApp Dev"
      background_color: "#E0F7FA"
      image_path: "assets/dev.png"
      
    windows:
      window_title: "MyApp Dev"
      background_color: "#E0F7FA"
      image_path: "assets/dev.png"

    macos:
      window_title: "MyApp Dev"
      background_color: "#E0F7FA"
      image_path: "assets/dev.png"

```

## 📄 License

```
BSD 3-Clause License

Copyright (c) 2025, Anicine Project

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```