<div align="center">

# Perplexity
### (native app for linux)

<p align="center">
  <img src="aur/perplexity.png" alt="Perplexity Logo" width="128" height="128">
</p>

**Native desktop client for Perplexity on Linux**  
*Powered by Electron • Secure • Private*

[![Build Status](https://img.shields.io/github/actions/workflow/status/mazixs/perplexity/build_and_publish.yml?style=for-the-badge&logo=github&logoColor=white)](https://github.com/mazixs/perplexity/actions)[![AUR Version](https://img.shields.io/aur/version/perplexity?style=for-the-badge&logo=archlinux&logoColor=white&color=1793d1)](https://aur.archlinux.org/packages/perplexity)
[![License](https://img.shields.io/github/license/mazixs/perplexity?style=for-the-badge&color=green)](LICENSE)[![Downloads](https://img.shields.io/github/downloads/mazixs/perplexity/total?style=for-the-badge&logo=github&logoColor=white&color=blue)](https://github.com/mazixs/perplexity/releases)[![Electron](https://img.shields.io/badge/Electron-33.3.2-47848f?style=for-the-badge&logo=electron&logoColor=white)](https://electronjs.org/)

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🚀 **Performance**
- ⚡ **Native operation** — no Wine or emulation
- 🔧 **Electron 33.3.2** — latest stable version
- 💾 **Lightweight** — minimal resource consumption
- 🎯 **Optimization** — tuned configuration for Linux

</td>
<td width="50%">

### 🔒 **Security**
- 🛡️ **Auto-updates disabled** — full control
- 🔐 **Privacy** — no background connections
- 🏠 **Local configuration** — all settings on your PC
- ✅ **Open source** — transparency and trust

</td>
</tr>
<tr>
<td width="50%">

### 🖥️ **Integration**
- 📱 **System integration** — shortcut, icon, menu
- 🎨 **Native look** — follows Linux standards
- 🔧 **Flexible configuration** — configuration file
- 📋 **Tray** — convenient panel management

</td>
<td width="50%">

### 📦 **Installation**
- 🏗️ **AUR package** — simple installation via makepkg
- 🤖 **CI/CD** — automated builds
- 📋 **Dependencies** — only Electron and Node.js
- 🔄 **Updates** — through standard Arch tools

</td>
</tr>
</table>

---

## 📁 Project Structure

```
perplexity/
├── 🎯 src/                     # Application sources (Electron)
│   ├── main.js                 # Electron main process
│   ├── preload.js              # Preload script
│   ├── package.json            # Dependencies (v1.1.3)
│   └── icons/                  # Application icons
├── 📦 aur/                     # AUR package (source build)
│   ├── PKGBUILD               # AUR build script
│   ├── launcher.sh            # Application launcher
│   ├── perplexity.desktop     # Desktop entry
│   └── default.conf           # Default configuration
├── 🚀 deploy_aur/             # Binary build for releases
├── 📚 docs/                   # Documentation
│   ├── architecture.md        # Project architecture
│   └── *.md                   # Technical documentation
├── ⚙️ .github/workflows/      # CI/CD automation
│   └── build_and_publish.yml  # Auto-build and publish
└── 🗂️ usr/                    # Linux system files
    ├── bin/perplexity         # Executable file
    └── share/                 # Resources (icons, desktop files)
```

---

## 🚀 Installation

### 📦 Arch Linux / AUR (Recommended)

<details>
<summary><b>🔧 Installation from AUR</b></summary>

```bash
# Clone the repository
git clone https://github.com/mazixs/perplexity.git
cd perplexity/aur

# Build and install the package
makepkg -si
```

**Or use an AUR helper:**
```bash
# With yay
yay -S perplexity

# With paru
paru -S perplexity
```

</details>

### 🎯 Running the Application

```bash
# From terminal
perplexity

# Or through application menu
# Applications → Internet → Perplexity
```

### 📋 System Requirements

- **OS:** Arch Linux (or compatible distributions)
- **Dependencies:** `electron`, `nodejs`, `npm`
- **Architecture:** x86_64
- **Memory:** Minimum 512 MB RAM

---

## ⚙️ Configuration

### 📝 Configuration File

All settings are stored in: `$HOME/.config/Perplexity/perplexity.conf`

<details>
<summary><b>🔧 Configuration Example</b></summary>

```bash
# Perplexity Configuration File
# Created automatically on first run

# Path to custom Electron binary (optional)
ELECTRON_CUSTOM_BIN="/usr/bin/electron"

# Enable tray icon (true/false)
TRAY_ENABLED=true

# Enable developer tools (true/false)
DEV_TOOLS=false

# Additional Electron flags
ELECTRON_ARGS="--disable-web-security --disable-features=VizDisplayCompositor"

# Debug mode (true/false)
DEBUG_MODE=false
```

</details>

### 🎛️ Available Parameters

| Parameter | Description | Values |
|-----------|-------------|--------|
| `ELECTRON_CUSTOM_BIN` | Path to custom Electron | File path |
| `TRAY_ENABLED` | Show tray icon | `true`/`false` |
| `DEV_TOOLS` | Developer tools | `true`/`false` |
| `ELECTRON_ARGS` | Additional flags | [Electron Flags](https://www.electronjs.org/docs/latest/api/command-line-switches/) |
| `DEBUG_MODE` | Debug mode | `true`/`false` |

---

## 🖱️ Features and Capabilities

### 📱 System Tray

- 🎯 **Enabled by default** (can be disabled in configuration)
- 📋 **Tray menu:**
  - 🚀 **Open** — launch main window
  - ⚡ **Autostart** — launch at system startup
  - ❌ **Exit** — close application

### 🔒 Privacy and Security

- ✅ **Auto-updates disabled** — no unexpected updates
- 🚫 **No background activity** — application doesn't "phone home"
- 🛡️ **Local settings** — all data stays on your computer
- 🔐 **Update control** — updates only through package manager

### 🎨 Desktop Integration

- 🖼️ **Native icons** — follows freedesktop.org standards
- 📱 **Desktop entry** — correct display in application menu
- 🎯 **Standard paths** — uses XDG Base Directory Specification
- ⌨️ **Hotkeys** — support for system key combinations

---

## 🛠️ Development and Build

### 🔄 CI/CD Pipeline

The project uses automated builds through GitHub Actions:

- 🤖 **Auto-build** on every commit to `main`
- 📦 **Creating AUR packages** (source and binary builds)
- 🚀 **Automatic publishing** to AUR repository
- 📋 **Creating releases** with ready `.pkg.tar.zst` files

### 🏗️ Local Build

<details>
<summary><b>🔧 Build Instructions</b></summary>

```bash
# Clone the repository
git clone https://github.com/mazixs/perplexity.git
cd perplexity

# Navigate to AUR directory
cd aur

# Install build dependencies
sudo pacman -S base-devel nodejs npm electron

# Build the package
makepkg -s

# Install the built package
sudo pacman -U perplexity-*.pkg.tar.zst
```

</details>

### 📊 Technical Specifications

| Component | Version | Description |
|-----------|---------|-------------|
| **Electron** | 33.3.2 | Desktop application framework |
| **Node.js** | Latest | JavaScript runtime |
| **ToDesktop Runtime** | 1.5.7-beta.1 | Additional capabilities |
| **Package Version** | 1.1.3 | Current application version |

---

## 📚 Documentation

- 📖 [Project Architecture](docs/architecture.md) — technical documentation
- 🔍 [Security Audit](docs/audit.md) — security analysis
- 📋 [Development Tasks](docs/task.md) — plans and TODO
- 🏗️ [PKGBUILD Solutions](docs/pkgbuild-architecture-solution.md) — architectural decisions

---

## 🤝 Contributing

<div align="center">

### We welcome your contributions! 🎉

[![Contributors](https://img.shields.io/github/contributors/mazixs/perplexity?style=for-the-badge)](https://github.com/mazixs/perplexity/graphs/contributors)
[![Issues](https://img.shields.io/github/issues/mazixs/perplexity?style=for-the-badge)](https://github.com/mazixs/perplexity/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/mazixs/perplexity?style=for-the-badge)](https://github.com/mazixs/perplexity/pulls)

</div>

### 🚀 How to Help the Project

- 🐛 **Report bugs** — create issues with detailed descriptions
- 💡 **Suggest improvements** — share ideas in discussions
- 🔧 **Submit Pull Requests** — fixes and new features
- ⭐ **Star the project** — help the project become more popular
- 📢 **Tell your friends** — spread the word about the project

---

## 📜 License

<div align="center">

**Apache License 2.0**

This project is distributed under the Apache 2.0 license.  
Details in the [LICENSE](LICENSE) file.

[![License](https://img.shields.io/github/license/mazixs/perplexity?style=for-the-badge&color=green)](LICENSE)

---

<p align="center">
  <strong>Made with ❤️ for the Linux community</strong><br>
  <em>Perplexity Native • 2024</em>
</p>

</div>
