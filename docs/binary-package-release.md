# Создание бинарного Arch пакета в релиз

## Обзор

Workflow `build.yml` автоматически создает бинарный Arch Linux пакет (`.pkg.tar.zst`) и загружает его в GitHub Releases при пуше в ветку `main`.

## Процесс

### 1. Подготовка окружения
```bash
# Установка зависимостей
pacman -Syu --noconfirm git base-devel nodejs npm sudo

# Создание пользователя builder
useradd -m builder
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
```

### 2. Создание архива исходников
```bash
# Создание директории build/
rm -rf build && mkdir build
cp -r aur/* build/

# Создание архива из src/
VERSION=$(grep '^pkgver=' build/PKGBUILD | cut -d= -f2)
tar czf build/perplexity-${VERSION}.tar.gz \
    --transform "s,^,perplexity-${VERSION}/," \
    -C src .
```

### 3. Сборка пакета
```bash
# Запуск makepkg от имени builder
runuser -u builder -- bash -lc \
  "cd build && makepkg -f --nodeps --skipinteg --nocheck"
```

### 4. Загрузка в релиз
```yaml
- name: Upload binary package to release
  if: github.ref == 'refs/heads/main'
  uses: softprops/action-gh-release@v2.3.2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    files: build/*.pkg.tar.zst
    tag_name: binary-${{ github.sha }}
    name: Binary Release ${{ github.sha }}
    generate_release_notes: true
    draft: false
    prerelease: false
```

## Результат

- **Файл пакета**: `perplexity-1.1.3-1-x86_64.pkg.tar.zst`
- **Размер**: ~3.2MB
- **Релиз**: `binary-{commit_hash}`
- **Установка**: `sudo pacman -U perplexity-*.pkg.tar.zst`

## Архитектура

### PKGBUILD условная логика
```bash
prepare() {
  cd "$srcdir"
  
  # Проверяем наличие архива (CI/CD) или используем локальные файлы
  if [[ -f "perplexity-${pkgver}.tar.gz" ]]; then
    # CI/CD: распаковываем архив
    tar xzf "perplexity-${pkgver}.tar.gz"
  else
    # Локальная сборка: копируем файлы из ../../src/
    mkdir -p "perplexity-${pkgver}"
    cp -r "../../src/"* "perplexity-${pkgver}/"
  fi
  
  cd "perplexity-${pkgver}"
  npm install --production --no-optional
}
```

### Workflow структура
1. **Подготовка** - Создание архива из `src/`
2. **Сборка** - `makepkg -f` создает `.pkg.tar.zst`
3. **Загрузка** - `action-gh-release` загружает пакет

## Отличия от aur.yml

- **aur.yml**: Публикует в AUR + создает релиз с исходниками
- **build.yml**: Создает бинарный пакет + загружает в релиз

## Тестирование

### Локальная проверка
```bash
# Создание тестового окружения
mkdir -p test-build
cp -r aur/* test-build/
VERSION=$(grep '^pkgver=' test-build/PKGBUILD | cut -d= -f2)

# Создание архива
tar czf test-build/perplexity-${VERSION}.tar.gz \
    --transform "s,^,perplexity-${VERSION}/," \
    -C src .

# Тест PKGBUILD
cd test-build && makepkg --nobuild --nodeps --skipinteg
```

## Требования

- **Права**: `contents: read`, `actions: write`
- **Токен**: `GITHUB_TOKEN` с правами на релизы
- **Ветка**: Только `main` ветка

## Дата создания
20 июля 2025 года 