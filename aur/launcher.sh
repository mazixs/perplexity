#!/bin/bash

set -e

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_FILE="${PERPLEXITY_CONFIG:-$CONFIG_HOME/perplexity.conf}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Конфиг не найден, копирую дефолтный"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cp /usr/lib/perplexity/default.conf "$CONFIG_FILE"
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

WAYLAND_FLAGS=""
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    WAYLAND_FLAGS="--ozone-platform=wayland"
fi

ELECTRON_BIN=${ELECTRON_CUSTOM_BIN:-/usr/bin/electron}

export TRAY_ENABLED=${TRAY_ENABLED:-0}
export DEV_TOOLS=${DEV_TOOLS:-0}

exec "$ELECTRON_BIN" "/usr/lib/perplexity" "$ELECTRON_ARGS" "$WAYLAND_FLAGS" "$@"
