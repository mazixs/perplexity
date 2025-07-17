## 🧩 Project Purpose

The goal is to **automatically download, extract, and convert the Windows `.exe` installer for Perplexity** (Electron-based), into a **native Linux application** and publish it to the **AUR (Arch User Repository)**.

This is the **starting point** of the project. No prior code or automation exists yet.

---

## 🧱 Source Installer

* **Download link (Windows app installer):**
  [https://www.perplexity.ai/api/download/windows](https://www.perplexity.ai/api/download/windows)
* **Format:** `.exe`, based on Electron

---

## 🧾 Expected File Structure After Extraction

```bash
~/Downloads/Perplexity Setup 1.1.3/
├── chrome_100_percent.pak
├── chrome_200_percent.pak
├── d3dcompiler_47.dll
├── ffmpeg.dll
├── icudtl.dat
├── libEGL.dll
├── libGLESv2.dll
├── LICENSE.electron.txt
├── LICENSES.chromium.html
├── locales/
├── Perplexity.exe
├── resources/
│   ├── app.asar
│   ├── app-update.yml
│   ├── elevate.exe
│   └── todesktop-runtime-config.json
├── resources.pak
├── snapshot_blob.bin
├── v8_context_snapshot.bin
├── vk_swiftshader.dll
├── vk_swiftshader_icd.json
├── vulkan-1.dll
└── win_clang_x64/
```

---

## 📦 app.asar Contents

After unpacking:

```bash
npx asar extract app.asar app-src
```

You get:

```bash
resources/app-src/
├── android_checkin.proto
├── builderStaticFiles/
├── checkin.proto
├── find-in-page.html
├── icons/
│   ├── icon-16.png
│   ├── icon-32.png
│   ├── ...
├── inject/
├── main.js
├── mcs.proto
├── node_modules/
├── package.json
├── preload.js
├── td-password-form.html
└── todesktop.json
```

---

## ⚙️ Local Test Run

You can run the app locally in Linux with:

```bash
electron .
```

from inside `resources/app-src`.

---

## 🔧 Objective

Refactor this into a **fully automated architecture** suitable for AI-driven workflows. The pipeline must:

* Download the latest `.exe`
* Extract its contents
* Unpack `app.asar`
* Structure as a native Linux app
* Generate `PKGBUILD`
* Publish to AUR

---

## ⚠️ Technical Considerations

1. **Version Detection**
   No version information is present in the URL. A workaround using `Python` or `JS` parsing may be required (e.g., parse `package.json` or extract version from `Perplexity.exe` properties).

2. **Auto-Updater Built-in (Tray Icon)**
   Perplexity has a built-in updater that won’t work in Linux. Disable it or patch its reference if possible.

3. **App Icons (all sizes)**
   Properly extract icons from `resources/app-src/icons/`, ensure they're included in `usr/share/icons/hicolor/`.

4. **Filesystem Layout Planning**
   The final app should reside in `/opt/perplexity` and symlink to `/usr/bin/perplexity`.

5. **PKGBUILD Awareness**
   Respect Arch packaging conventions and avoid using hardcoded home paths.

6. **Config File**
   A config file (e.g., `config.json`) should be created in `~/.config/perplexity`.

7. **System Integration**

   * CLI invocation: `perplexity`
   * GUI menu name: `Perplexity`
   * Add a `.desktop` entry in `/usr/share/applications`

8. **Testing Philosophy**
   This is a **personal project**, not a production-level system. Do not overengineer with enterprise-grade testing.

---

## 📌 Summary

You’re building an AI-compatible, automated, minimal, AUR-ready repackaging system for an Electron-based `.exe` app.
It will turn a Windows-only `.exe` into a proper Linux `.desktop` application, installable via `yay` or `paru`.

