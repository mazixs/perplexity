# Решение архитектуры PKGBUILD: Локальная + CI/CD сборка

## Проблема
- PKGBUILD ожидал архив `perplexity-${pkgver}.tar.gz` в секции `source`
- Локальная сборка `makepkg -si` не работала из-за отсутствия архива
- CI/CD создавал архив, но локальная сборка была сломана

## Решение: Умная архитектура PKGBUILD

### 1. Условная логика в prepare()

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

### 2. Правильный порядок файлов в PKGBUILD

```bash
# Источники: мета-файлы (архив создается в CI/CD или копируется локально)
source=(
  "default.conf"
  "launcher.sh"
  "perplexity.desktop"
  "perplexity.png"
)

# sha256sum'ы для мета-файлов (в том же порядке что и source)
sha256sums=(
  '0926f58bd0adad27d8cda90feb401cf83350b6d37098d481178bb211cb34e95c'  # default.conf
  '73a2a82540005d5c856efba8b01c04aff2f6a42bf890164e37da57691e662d2b'  # launcher.sh
  'cc0ccc05588907474681a197fd658135625426b0f7de6b5006e5ce06fc0257fd'  # perplexity.desktop
  '36ee4908a30561ee36454cc2319dbb636d6b0091c8ab46bc440ba25ce47a746c'  # perplexity.png
)
```

### 3. Workflow создает архив

```bash
# Создаём perplexity-<version>.tar.gz в build/
VERSION=$(grep '^pkgver=' build/PKGBUILD | cut -d= -f2)
tar czf build/perplexity-${VERSION}.tar.gz \
    --transform "s,^,perplexity-${VERSION}/," \
    -C src .
```

## Результат

- **Локально**: `makepkg -si` работает ✅
- **CI/CD**: Автоматическая сборка и релиз ✅
- **Архитектура**: Чистая, без дублирования ✅

## Ключевые принципы

1. **Условная логика** - PKGBUILD адаптируется к среде
2. **Правильный порядок** - `source` и `sha256sums` должны совпадать
3. **Корректные пути** - Учитывать структуру проекта
4. **Без дублирования** - Один PKGBUILD для всех сценариев

## Использование

### Локальная сборка
```bash
cd aur/
makepkg -si
```

### CI/CD сборка
- Workflow автоматически создает архив из `src/`
- PKGBUILD распаковывает архив
- Пакет загружается в GitHub Releases

## Дата решения
20 июля 2025 года 