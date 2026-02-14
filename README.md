<div align="center">

# Perplexity
### Native Linux wrapper

<p align="center">
  <img src="aur/perplexity.png" alt="Perplexity Logo" width="128" height="128">
</p>

**Native desktop wrapper for Perplexity on Linux**  
*Electron-based launcher with Arch/AUR packaging*

[![AUR Version](https://img.shields.io/aur/version/perplexity?style=for-the-badge&logo=archlinux&logoColor=white&color=1793d1)](https://aur.archlinux.org/packages/perplexity)
[![Build Status](https://img.shields.io/github/actions/workflow/status/mazixs/perplexity/build_and_publish.yml?style=for-the-badge&logo=github&logoColor=white)](https://github.com/mazixs/perplexity/actions)
[![License Scope](https://img.shields.io/badge/License-Mixed%20(UNLICENSED%20upstream%20%2B%20Apache--2.0%20wrapper)-blue?style=for-the-badge)](LICENSE)
[![Electron](https://img.shields.io/badge/Electron-38.2.0%20target-47848f?style=for-the-badge&logo=electron&logoColor=white)](https://electronjs.org/)

</div>

---

## Features

- Native Linux packaging (no Wine/emulation).
- System Electron runtime with launcher-based configuration.
- AUR-first distribution with automated CI pipeline.
- Desktop integration: menu entry, icons, URI handler.
- DevTools disabled by default (`DEV_TOOLS=0`).

---

## Project Structure

```
perplexity/
├── src/                        # Application sources (Electron)
│   ├── main.js                 # Electron main process
│   ├── preload.js              # Preload script
│   ├── package.json            # Dependencies (v1.5.1)
│   └── icons/                  # Application icons
├── aur/                        # AUR package assets
│   ├── PKGBUILD               # AUR build script (CI-injected commit pin)
│   ├── launcher.sh            # Runtime launcher (/usr/bin/perplexity)
│   ├── perplexity.desktop     # Desktop entry
│   └── default.conf           # Default runtime config
├── .github/workflows/          # CI/CD automation
│   ├── build_and_publish.yml  # Build, release, AUR push
│   └── cleanup-artifacts.yml  # Artifact retention cleanup
└── usr/                        # Linux system files
    ├── bin/perplexity         # Executable file
    └── share/                 # Resources (icons, desktop files)
```

---

## Installation

### Arch Linux / AUR (Recommended)

Use an AUR helper:
```bash
yay -S perplexity
paru -S perplexity
```

### Running the Application

```bash
# From terminal
perplexity

# Or through application menu
# Applications → Internet → Perplexity
```

### System Requirements

- **OS:** Arch Linux (or compatible distributions)
- **Runtime dependencies:** `electron`, `desktop-file-utils`, `xdg-utils`
- **Optional:** `libappindicator-gtk3` (tray icon support)
- **Architecture:** x86_64
- **Memory:** Minimum 512 MB RAM

---

## Configuration

### Configuration File

All settings are stored at: `$XDG_CONFIG_HOME/Perplexity/perplexity.conf` (falls back to `$HOME/.config/Perplexity/perplexity.conf`). You can override via the `PERPLEXITY_CONFIG` environment variable.

On first run, the launcher copies `/etc/perplexity/default.conf` to the user configuration path.

<details>
<summary><b>Configuration Example</b></summary>

```bash
# Perplexity Configuration File
# Created automatically on first run

# Path to custom Electron binary (optional)
ELECTRON_CUSTOM_BIN="/usr/bin/electron"

# Tray is managed by ToDesktop runtime; not configurable via config file

# Enable developer tools (0/1, false/true)
DEV_TOOLS=0

# Additional Electron flags
ELECTRON_ARGS="--disable-web-security --disable-features=VizDisplayCompositor"

```

</details>

### Available Parameters

| Parameter | Description | Values |
|-----------|-------------|--------|
| `ELECTRON_CUSTOM_BIN` | Path to custom Electron | File path |
| `DEV_TOOLS` | Developer tools | `0`/`1` or `false`/`true` |
| `ELECTRON_ARGS` | Additional flags | [Electron Flags](https://www.electronjs.org/docs/latest/api/command-line-switches/) |

### Launch Flow

`perplexity.desktop` -> `/usr/bin/perplexity` (`aur/launcher.sh`) -> `/usr/lib/perplexity`

---

## Runtime Notes

### System Tray

- Managed by ToDesktop runtime and not configurable via `default.conf`.

### Privacy and Security

- Auto-updates are disabled in the wrapper.
- Configuration is local (`$XDG_CONFIG_HOME` or `$HOME/.config`).
- Network traffic comes from the upstream Perplexity web application runtime.

### Desktop Integration

- Native icons (freedesktop.org layout)
- Desktop entry and URI handler integration
- XDG-compatible config path behavior

---

## CI/CD

Pipeline jobs in `.github/workflows/build_and_publish.yml`:

- `build-package`: build `.pkg.tar.zst` + generate `.SRCINFO`
- `publish-release`: publish GitHub Release with package artifact
- `push-aur`: sync PKGBUILD/.SRCINFO/assets to AUR

Note: commit pinning in `aur/PKGBUILD` is injected in CI.

## Technical Specifications

| Component | Version | Description |
|-----------|---------|-------------|
| **Electron** | System package | Uses system-provided Electron (Arch package) |
| **Target Electron** | 38.2.0 | Version used in upstream development |
| **ToDesktop Runtime** | ^2.1.2 | Additional capabilities |
| **Package Version** | 1.5.1 | Current application version |

> **Note:** You can use a specific Electron version by setting `ELECTRON_CUSTOM_BIN` in the configuration file.

---

## Contributing

<div align="center">

### Contributions are welcome

[![Contributors](https://img.shields.io/github/contributors/mazixs/perplexity?style=for-the-badge)](https://github.com/mazixs/perplexity/graphs/contributors)
[![Issues](https://img.shields.io/github/issues/mazixs/perplexity?style=for-the-badge)](https://github.com/mazixs/perplexity/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/mazixs/perplexity?style=for-the-badge)](https://github.com/mazixs/perplexity/pulls)

</div>

### How to Help the Project

- Report bugs with reproducible steps
- Suggest improvements in discussions
- Submit pull requests with focused changes
- Star the project

---

## License

<div align="center">

**Mixed licensing (important)**

- Upstream Perplexity application files synced from AppImage: **UNLICENSED** (upstream terms).
- Repository-authored wrapper/integration files (AUR packaging, launcher, CI): **Apache-2.0**.

See full scope details in the [LICENSE](LICENSE) file.

[![License Scope](https://img.shields.io/badge/License-Mixed%20(UNLICENSED%20upstream%20%2B%20Apache--2.0%20wrapper)-blue?style=for-the-badge)](LICENSE)

---

<p align="center">
  <strong>Perplexity Native for Linux</strong><br>
  <em>Maintained by mazixs • 2026</em>
</p>

</div>
