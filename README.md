# Perplexity Native (Electron)

Нативный десктоп-клиент Perplexity AI для Linux на базе Electron.

---

## Описание

Этот проект автоматизирует превращение Windows-версии Perplexity в полноценное Linux-приложение с интеграцией в систему, поддержкой AUR и гибкой конфигурацией.

- **Безопасно**: не требует Wine, работает на Electron.
- **Интеграция**: поддержка ярлыка, иконки, стандартных путей хранения данных.
- **Гибко**: все переменные и флаги задаются через launcher-скрипт и конфиг.

---

## Структура проекта

- `src/` — исходники приложения (распакованный app-src)
- `aur/` — файлы для сборки пакета (PKGBUILD, launcher.sh, архив исходников)
- `usr/bin/perplexity` — launcher-скрипт (копируется из aur/launcher.sh)
- `usr/share/applications/perplexity.desktop` — ярлык для меню
- `usr/share/icons/hicolor/512x512/apps/perplexity.png` — иконка
- `docs/` — документация (архитектура, TODO)

---

## Сборка и установка (Arch Linux/AUR)

1. Перейдите в папку `aur/`:
   ```sh
   cd aur
   makepkg -si
   ```
2. После установки приложение запускается командой:
   ```sh
   perplexity
   ```
   или через меню приложений.

---

## Конфигурирование

- Все переменные и флаги задаются через `~/.config/perplexity/perplexity.conf`.
- При первом запуске создаётся дефолтный конфиг, который можно редактировать вручную.
- Примеры переменных:
  - `ELECTRON_CUSTOM_BIN` — путь к кастомному electron
  - `TRAY_ENABLED`, `DEV_TOOLS` — включение трея, dev-режима
  - `ELECTRON_ARGS` — дополнительные флаги для Electron

---

## Документация
- [docs/architecture.md](docs/architecture.md) — архитектура и автоматизация
- [docs/todos.md](docs/todos.md) — внутренний TODO-лист

---

## Лицензия

Проект распространяется под лицензией Apache 2.0. См. файл [LICENSE](LICENSE). 
