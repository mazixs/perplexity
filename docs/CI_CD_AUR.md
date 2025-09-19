# Практика CI/CD для Arch Linux/Electron-пакетов (AUR)

## 1. Архитектурные принципы
- **Изоляция**: Все сборки выполняются в контейнере ArchLinux (`archlinux:base`)
- **Безопасность**: Использование непривилегированного пользователя `builder`, секреты (SSH-ключи) только через GitHub Secrets
- **Автоматизация**: Весь цикл — от коммита до публикации в AUR и GitHub Releases — полностью автоматизирован
- **Версионирование**: `pkgrel` инкрементируется автоматически, теги релизов формируются по шаблону `binary-{commit_sha}`

---

## 2. Структура репозитория
```
project-root/
├── .github/workflows/
│   └── build_and_publish.yml
├── aur/
│   ├── PKGBUILD
│   ├── launcher.sh
│   ├── default.conf
│   ├── perplexity.desktop
│   └── perplexity.png
├── src/
│   └── ... (исходники Electron)
└── docs/
    └── CI_CD_AUR.md
```

---

## 3. Workflow GitHub Actions: build_and_publish.yml

### Единый job: build-release-aur
- **Контейнер**: `archlinux:base`
- **Основные шаги**:
  1. Инициализация keyring, установка инструментов (`base-devel`, `git`, `openssh`, `libarchive`, `sudo`)
  2. Создание пользователя `builder`
  3. Патчинг `aur/PKGBUILD`: замена `<COMMIT>` на `${{ github.sha }}`
  4. Сборка пакета: `makepkg --syncdeps --clean --cleanbuild`
  5. Генерация `.SRCINFO`: `makepkg --printsrcinfo > .SRCINFO`
  6. Создание GitHub Release с тегом `v<pkgver>-<pkgrel>` и загрузкой `.pkg.tar.zst`
  7. Настройка SSH и пуш `PKGBUILD` + `.SRCINFO` в AUR (`perplexity.git`)

---

## 4. Примеры и точное позиционирование

### Пример: Патчинг PKGBUILD с SHA коммита
```yaml
- name: Patch PKGBUILD with current commit sha
  run: |
    cd ${{ env.PKG_DIR }}
    sed -i "s|<COMMIT>|${{ github.sha }}|g" PKGBUILD
    sudo -u builder makepkg --printsrcinfo > .SRCINFO
```

### Пример: Клонирование и обновление AUR
```yaml
- name: Clone AUR repository
  run: |
    sudo -u builder git clone ssh://aur@aur.archlinux.org/perplexity.git aur_repo || true
    # ...инициализация, если пусто...
- name: Update AUR package
  run: |
    cd aur_repo
    cp ../${{ env.PKG_DIR }}/PKGBUILD .
    cp ../${{ env.PKG_DIR }}/.SRCINFO .
    sudo -u builder git add PKGBUILD .SRCINFO
    sudo -u builder git commit -m "Update to version from release ${{ github.sha }}" || true
    sudo -u builder git push origin master || sudo -u builder git push origin main
```

### Пример: Сборка пакета
```yaml
- name: Build package (.pkg.tar.zst)
  run: |
    cd ${{ env.PKG_DIR }}
    sudo -u builder makepkg --syncdeps --clean --cleanbuild --noconfirm --force
```

### Пример: Публикация релиза
```yaml
- name: Create GitHub release with package
  uses: softprops/action-gh-release@v2
  with:
    tag_name: v${{ steps.vars.outputs.ver }}-${{ steps.vars.outputs.rel }}
    name: Perplexity v${{ steps.vars.outputs.ver }}-${{ steps.vars.outputs.rel }}
    files: ${{ env.PKG_DIR }}/*.pkg.tar.zst
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 5. PKGBUILD: шаблоны и best practices

- **Сборка из исходников** (`aur/PKGBUILD`): 
  - Источник: `git+https://…#commit=<COMMIT>` (заменяется в CI на `${{ github.sha }}`)
  - Сборка: `npm install --production`, копирование `node_modules`, launcher, `.desktop`, иконок
  - Вендорные библиотеки при необходимости кладутся в `/usr/lib/perplexity/vendor-libs` и активируются через `LD_LIBRARY_PATH` в `launcher.sh`

---

## 6. launcher.sh: конфигурируемость и безопасность

- **Автоматическое копирование default.conf** при первом запуске
- **Поддержка переменных**: `ELECTRON_ARGS`, `DEV_TOOLS`
- **Детекция среды**: Wayland/X11, D-Bus
- **Экспорт переменных** для Electron
- **Безопасность**: неиспользуемые переменные не экспортируются, все пути проверяются

---

## 7. Безопасность и best practices

- **SSH-ключи**: только через GitHub Secrets, не хранятся в репозитории
- **mktemp**: для временных файлов в скриптах и CI/CD
- **Изолированные контейнеры**: все сборки только в контейнере
- **Rollback**: откат возможен через git history и ручной пуш в AUR

---

## 8. Типовые ошибки и их предотвращение

- **Ошибка: отсутствует default.conf** — всегда добавлять в source и устанавливать в package()
- **Ошибка: неправильный SHA** — патчить PKGBUILD на каждом этапе
- **Ошибка: невалидный .SRCINFO** — всегда генерировать после изменений PKGBUILD
- **Ошибка: права доступа** — использовать пользователя builder, не root

---

## 9. Расширение и адаптация

- **Добавление новых дистрибутивов**: вынести специфичные шаги в отдельные workflow/jobs
- **Flatpak/Snap**: аналогичная структура, отдельные PKGBUILD/manifest
- **Тестирование**: добавить отдельный job для makepkg --nobuild

---

## 10. Минимальный шаблон для повторения

```yaml
# .github/workflows/build_and_publish.yml
name: build-and-publish
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    container: archlinux:base
    steps:
      - uses: actions/checkout@v4
      - run: pacman -Syu --noconfirm base-devel git sudo
      - run: useradd -m builder
      - run: echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
      # ... остальные шаги ...
```

---

## 11. Рекомендации по документации

- **Документировать** каждый шаг пайплайна с примерами и ссылками на реальные файлы
- **Вести changelog** для всех изменений в workflow и PKGBUILD
- **Добавлять примеры ошибок и их решений** в отдельный раздел

---

*Документ подготовлен на основе анализа реального CI/CD пайплайна Perplexity Native. Для адаптации под другой проект — скорректировать только PKGBUILD, launcher.sh и workflow, структура и подходы остаются неизменными.* 