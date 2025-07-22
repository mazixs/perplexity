# Perplexity Native (Electron)  

![Build](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square)
![License](https://img.shields.io/github/license/mazixs/perplexity?style=flat-square)
![AUR](https://img.shields.io/aur/version/perplexity?color=1793d1&label=AUR&style=flat-square)
![Downloads](https://img.shields.io/github/downloads/mazixs/perplexity/total?style=flat-square)

_Native Perplexity AI desktop client for Linux, powered by Electron._

---

## Overview

This project provides a **safe**, **native** Linux desktop app for Perplexity AI, with full system integration, AUR support, and flexible configuration.

- ⚡ **No Wine required**: runs natively on Electron
- 🖥️ **System integration**: desktop shortcut, icon, standard Linux paths
- 🛠️ **Configurable**: all flags and variables are set via launcher script and config file
- 🏆 **Best practice**: follows Linux and Electron/ToDesktop conventions
- 🔒 **No auto-updates**: update checks and menu entries are disabled for privacy and stability

---

## 📁 Project Structure

- `src/` — application sources (unpacked app-src)
- `aur/` — AUR packaging files (PKGBUILD, launcher.sh, source archive)
- `usr/bin/perplexity` — launcher script (from aur/launcher.sh)
- `usr/share/applications/perplexity.desktop` — desktop entry
- `usr/share/icons/hicolor/512x512/apps/perplexity.png` — app icon
- `docs/` — documentation (architecture, TODO)

---

## 🏗️ Build & Install (Arch Linux/AUR)

```sh
cd aur
makepkg -si
```

After installation, launch the app with:
```sh
perplexity
```
or via your application menu.

---

## ⚙️ Configuration

- All variables and flags are set via `$HOME/.config/Perplexity/perplexity.conf` (user config)
- On first launch, a default config is created (edit as needed)
- Example variables:
  - `ELECTRON_CUSTOM_BIN` — custom Electron binary path
  - `TRAY_ENABLED`, `DEV_TOOLS` — enable tray, dev mode
  - `ELECTRON_ARGS` — extra Electron flags ([see Electron docs](https://www.electronjs.org/docs/latest/api/command-line-switches/))
- All config comments and examples are in English for international users

---

## 🖱️ Tray & Updates

- The tray icon is enabled by default (can be disabled via config)
- The tray menu includes: **Open**, **Launch at startup**, **Quit**
- **Update checks are fully disabled**: no auto-update, no "Check for updates" menu entry
- This ensures privacy and avoids unexpected background network activity

---

## 📚 Documentation
- [docs/architecture.md](docs/architecture.md) — architecture & automation
- [docs/todos.md](docs/todos.md) — internal TODO list

---

## 📜 License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

---
