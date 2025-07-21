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
├── deploy_aur/
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

### Ключевые этапы пайплайна

#### 1. build-bin
- **Контейнер**: `archlinux:base`
- **Действия**:
  - Инициализация keyring, установка зависимостей
  - Создание пользователя `builder`
  - Патчинг PKGBUILD (замена `<COMMIT>` на `${{ github.sha }}`)
  - Генерация `.SRCINFO`
  - Сборка исходного пакета (makepkg)

#### 2. create-binary-release
- **Контейнер**: `archlinux:base`
- **Действия**:
  - Инкрементирование `pkgrel` в `deploy_aur/PKGBUILD`
  - Генерация `.SRCINFO`
  - Клонирование AUR-репозитория через SSH
  - Копирование и коммит новых файлов в AUR
  - Сборка бинарного пакета (`makepkg --syncdeps --clean --cleanbuild`)
  - Загрузка артефакта (`actions/upload-artifact`)
  - Публикация релиза (`softprops/action-gh-release`)

#### 3. deploy-to-aur
- **Контейнер**: `archlinux:base`
- **Действия**:
  - Патчинг PKGBUILD с текущим SHA
  - Генерация `.SRCINFO`
  - Публикация в AUR

---

## 4. Примеры и точное позиционирование

### Пример: Патчинг PKGBUILD с SHA коммита
```yaml
- name: Patch PKGBUILD with current commit sha
  run: |
    cd ${{ env.BIN_DIR }}
    sed -i "s|<COMMIT>|${{ github.sha }}|g" PKGBUILD
    sudo -u builder makepkg --printsrcinfo > .SRCINFO
```

### Пример: Инкрементирование pkgrel
```yaml
- name: Update PKGBUILD version
  run: |
    cd deploy_aur
    CURRENT_REL=$(grep '^pkgrel=' PKGBUILD | cut -d= -f2)
    NEW_REL=$((CURRENT_REL + 1))
    sed -i "s/pkgrel=.*/pkgrel=${NEW_REL}/" PKGBUILD
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
    cp ../deploy_aur/PKGBUILD .
    cp ../deploy_aur/.SRCINFO .
    sudo -u builder git add PKGBUILD .SRCINFO
    sudo -u builder git commit -m "Update to version from release ${{ github.sha }}" || true
    sudo -u builder git push origin master || sudo -u builder git push origin main
```

### Пример: Сборка бинарного пакета
```yaml
- name: Build package (.pkg.tar.zst)
  run: |
    cd ${{ env.DEPLOY_DIR }}
    sudo -u builder makepkg --syncdeps --clean --cleanbuild --noconfirm --force
```

### Пример: Публикация релиза
```yaml
- name: Create GitHub release with package
  uses: softprops/action-gh-release@v2
  with:
    tag_name: binary-${{ github.sha }}
    name: Binary Release ${{ github.sha }}
    files: ${{ env.DEPLOY_DIR }}/*.pkg.tar.zst
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 5. PKGBUILD: шаблоны и best practices

- **Исходная сборка** (`aur/PKGBUILD`): 
  - Использует исходники с GitHub, патчится SHA коммита
  - Сборка через `npm install --production`
  - Копирование node_modules, launcher, desktop-файла, иконки

- **Бинарная сборка** (`deploy_aur/PKGBUILD`):
  - Динамически скачивает последний бинарный релиз с GitHub Releases
  - Распаковывает через `bsdtar`
  - Копирует файлы в `${pkgdir}`

---

## 6. launcher.sh: конфигурируемость и безопасность

- **Автоматическое копирование default.conf** при первом запуске
- **Поддержка переменных**: `ELECTRON_ARGS`, `TRAY_ENABLED`, `DEV_TOOLS`
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