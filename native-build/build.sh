#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

pkgbuild="${repo_root}/aur/PKGBUILD"
default_conf="${repo_root}/aur/default.conf"
src_dir="${repo_root}/src"
usr_share_dir="${repo_root}/usr/share"

work_dir="${script_dir}/work"
dist_dir="${script_dir}/dist"

electron_bin="${ELECTRON_BIN:-$(command -v electron || true)}"
skip_npm_install=0
source_mode="auto"
appimage_path="${repo_root}/Perplexity-1.6.0-x86_64.AppImage"

usage() {
  cat <<'EOF'
Usage: ./native-build/build.sh [options]

Options:
  --source MODE         Build source: auto, repo, or appimage
  --appimage PATH       Use a specific AppImage file
  --electron-bin PATH   Use a specific Electron wrapper binary for repo mode
  --skip-npm-install    Reuse existing node_modules in src/ for repo mode
  -h, --help            Show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source)
      [ "$#" -ge 2 ] || { echo "--source requires a mode" >&2; exit 1; }
      source_mode="$2"
      shift 2
      ;;
    --appimage)
      [ "$#" -ge 2 ] || { echo "--appimage requires a path" >&2; exit 1; }
      appimage_path="$2"
      shift 2
      ;;
    --electron-bin)
      [ "$#" -ge 2 ] || { echo "--electron-bin requires a path" >&2; exit 1; }
      electron_bin="$2"
      shift 2
      ;;
    --skip-npm-install)
      skip_npm_install=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_file() {
  local path="$1"
  [ -e "$path" ] || { echo "Missing required path: $path" >&2; exit 1; }
}

read_pkg_value() {
  local key="$1"
  sed -n "s/^${key}=//p" "${pkgbuild}"
}

ensure_clean_dirs() {
  rm -rf "${bundle_dir}" "${extract_dir}"
  mkdir -p "${bundle_dir}" "${dist_dir}"
}

package_installer() {
  local payload_path installer_path
  payload_path="${work_dir}/${bundle_name}.tar.zst"
  installer_path="${dist_dir}/${bundle_name}.run"

  rm -f "${payload_path}" "${installer_path}"
  tar --zstd -cf "${payload_path}" -C "${work_dir}" "${bundle_name}"

  cat > "${installer_path}" <<EOF
#!/usr/bin/env bash

set -euo pipefail

bundle_name="${bundle_name}"
default_target="\${PWD}/\${bundle_name}"
target=""

usage() {
  cat <<'HELP'
Usage: ./$(basename "${installer_path}") [--target DIR]

Options:
  --target DIR   Install the bundle into DIR (default: ./bundle-name)
  -h, --help     Show this help
HELP
}

while [ "\$#" -gt 0 ]; do
  case "\$1" in
    --target)
      [ "\$#" -ge 2 ] || { echo "--target requires a directory" >&2; exit 1; }
      target="\$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: \$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

target="\${target:-\${default_target}}"
mkdir -p "\${target}"

archive_line="\$(awk '/^__ARCHIVE_BELOW__\$/ { print NR + 1; exit 0; }' "\$0")"
tail -n +"\${archive_line}" "\$0" | tar --zstd -xf - -C "\${target}"

install_root="\${target}/\${bundle_name}"
echo "Installed to: \${install_root}"
echo "Launch with: \${install_root}/bin/perplexity"
exit 0
__ARCHIVE_BELOW__
EOF

  cat "${payload_path}" >> "${installer_path}"
  chmod +x "${installer_path}"

  echo "Created installer: ${installer_path}"
}

prepare_common_state() {
  mkdir -p \
    "${bundle_dir}/bin" \
    "${bundle_dir}/state/cache" \
    "${bundle_dir}/state/config/Perplexity" \
    "${bundle_dir}/state/data"
}

prepare_repo_bundle() {
  local electron_wrapper runtime_name runtime_dir

  require_file "${pkgbuild}"
  require_file "${default_conf}"
  require_file "${src_dir}"

  if [ -z "${electron_bin}" ]; then
    echo "Electron binary not found. Install electron or pass --electron-bin." >&2
    exit 1
  fi

  electron_wrapper="$(readlink -f "${electron_bin}")"
  runtime_name="$(basename "${electron_wrapper}")"
  runtime_dir="/usr/lib/${runtime_name}"

  require_file "${electron_wrapper}"
  require_file "${runtime_dir}"

  bundle_version="$(read_pkg_value pkgver)-$(read_pkg_value pkgrel)"
  bundle_name="perplexity-native-arch-x86_64-${bundle_version}"
  bundle_dir="${work_dir}/${bundle_name}"
  extract_dir="${work_dir}/extract-${bundle_version}"

  ensure_clean_dirs
  prepare_common_state

  mkdir -p \
    "${bundle_dir}/app" \
    "${bundle_dir}/config" \
    "${bundle_dir}/electron/bin" \
    "${bundle_dir}/electron/lib" \
    "${bundle_dir}/share"

  cp -a "${src_dir}/." "${bundle_dir}/app/"

  if [ "${skip_npm_install}" -eq 0 ]; then
    (
      cd "${bundle_dir}/app"
      npm ci --omit=dev
    )
  elif [ ! -d "${bundle_dir}/app/node_modules" ]; then
    echo "--skip-npm-install requires src/node_modules to already be present." >&2
    exit 1
  fi

  cp "${default_conf}" "${bundle_dir}/config/default.conf"
  cp "${default_conf}" "${bundle_dir}/state/config/Perplexity/perplexity.conf"

  if [ -d "${usr_share_dir}" ]; then
    cp -a "${usr_share_dir}/." "${bundle_dir}/share/"
  fi

  cp -a "${runtime_dir}" "${bundle_dir}/electron/lib/${runtime_name}"

  cat > "${bundle_dir}/electron/bin/electron" <<EOF
#!/usr/bin/env bash

set -euo pipefail

script_dir="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
runtime_dir="\${script_dir}/../lib/${runtime_name}"
flags_file="\${XDG_CONFIG_HOME:-\$HOME/.config}/${runtime_name}-flags.conf"
fallback_file="\${XDG_CONFIG_HOME:-\$HOME/.config}/electron-flags.conf"

lines=()
if [[ -f "\${flags_file}" ]]; then
    mapfile -t lines < "\${flags_file}"
elif [[ -f "\${fallback_file}" ]]; then
    mapfile -t lines < "\${fallback_file}"
fi

flags=()
for line in "\${lines[@]}"; do
    if [[ ! "\${line}" =~ ^[[:space:]]*#.* ]] && [[ -n "\${line}" ]]; then
        flags+=("\${line}")
    fi
done

: \${ELECTRON_IS_DEV:=0}
export ELECTRON_IS_DEV
: \${ELECTRON_FORCE_IS_PACKAGED:=true}
export ELECTRON_FORCE_IS_PACKAGED

exec "\${runtime_dir}/electron" "\${flags[@]}" "\$@"
EOF
  chmod +x "${bundle_dir}/electron/bin/electron"

  cat > "${bundle_dir}/bin/perplexity" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_root="$(cd "${script_dir}/.." && pwd)"

portable_state_dir="${PERPLEXITY_STATE_DIR:-${app_root}/state}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${portable_state_dir}/config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${portable_state_dir}/data}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${portable_state_dir}/cache}"

mkdir -p "${XDG_CONFIG_HOME}/Perplexity" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}"

config_file="${PERPLEXITY_CONFIG:-${XDG_CONFIG_HOME}/Perplexity/perplexity.conf}"
default_conf="${app_root}/config/default.conf"

if [ ! -f "${config_file}" ]; then
  cp "${default_conf}" "${config_file}"
fi

# shellcheck source=/dev/null
source "${config_file}"

if [ ! -S "/run/dbus/system_bus_socket" ] && [ ! -S "/var/run/dbus/system_bus_socket" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/dev/null"
fi

if ! command -v hostname >/dev/null 2>&1; then
  export HOSTNAME="${HOSTNAME:-localhost}"
fi

session_flags=""
if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
  session_flags=""
elif [ "${XDG_SESSION_TYPE:-}" = "x11" ] || [ -n "${DISPLAY:-}" ]; then
  session_flags="--ozone-platform=x11 --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blacklist"
  ELECTRON_ARGS="$(printf '%s' "${ELECTRON_ARGS:-}" | sed 's/--disable-gpu//g')"
else
  session_flags="--disable-gpu --disable-software-rasterizer"
fi

electron_bin="${app_root}/electron/bin/electron"
app_dir="${app_root}/app"

export DEV_TOOLS="${DEV_TOOLS:-0}"

all_flags="${ELECTRON_ARGS:-} ${session_flags}"
if [ "${DEV_TOOLS}" = "1" ] || [ "${DEV_TOOLS}" = "true" ]; then
  debug_port="${DEVTOOLS_PORT:-9223}"
  all_flags="--remote-debugging-port=${debug_port} --auto-open-devtools-for-tabs ${all_flags}"
fi

exec "${electron_bin}" "${app_dir}" ${all_flags} "$@"
EOF
  chmod +x "${bundle_dir}/bin/perplexity"
}

prepare_appimage_bundle() {
  local appimage_version desktop_file

  require_file "${appimage_path}"
  require_file "${default_conf}"

  desktop_file="${work_dir}/appimage-desktop.desktop"
  appimage_version="$(sed -n 's/^X-AppImage-Version=//p' "${repo_root}/squashfs-root/Perplexity.desktop" 2>/dev/null | head -n1 || true)"
  if [ -z "${appimage_version}" ]; then
    appimage_version="$(basename "${appimage_path}" | sed -E 's/^Perplexity-([0-9.]+)-x86_64\.AppImage$/\1/')"
  fi

  bundle_name="perplexity-native-arch-x86_64-${appimage_version}"
  bundle_dir="${work_dir}/${bundle_name}"
  extract_dir="${work_dir}/extract-${appimage_version}"

  ensure_clean_dirs
  prepare_common_state

  mkdir -p "${extract_dir}"
  (
    cd "${extract_dir}"
    chmod +x "${appimage_path}"
    "${appimage_path}" --appimage-extract >/tmp/perplexity-native-build-appimage.log 2>&1
  )

  require_file "${extract_dir}/squashfs-root/AppRun"
  cp -a "${extract_dir}/squashfs-root" "${bundle_dir}/appdir"
  cp "${default_conf}" "${bundle_dir}/state/config/Perplexity/perplexity.conf"

  # Патчим app.asar: убираем menubar по умолчанию, показываем только при DEV_TOOLS=1
  local app_asar="${bundle_dir}/appdir/resources/app.asar"
  if [ -f "${app_asar}" ]; then
    local asar_extract="${work_dir}/asar-patch-${appimage_version}"
    rm -rf "${asar_extract}"
    npx @electron/asar extract "${app_asar}" "${asar_extract}"
    if [ -f "${asar_extract}/main.js" ]; then
      sed -i 's/t.setMenuBarVisibility(!0)/t.setMenuBarVisibility(process.env.DEV_TOOLS==="1"||process.env.DEV_TOOLS===true||process.env.DEV_TOOLS==="true")/g' "${asar_extract}/main.js"
      sed -i 's/async function ebt(e,t){let r=await FFr(e,t);Zh.Menu.setApplicationMenu(r)}/async function ebt(e,t){let r=await FFr(e,t);Zh.Menu.setApplicationMenu((process.env.DEV_TOOLS==="1"||process.env.DEV_TOOLS===true||process.env.DEV_TOOLS==="true")?r:null)}/g' "${asar_extract}/main.js"
      npx @electron/asar pack "${asar_extract}" "${app_asar}"
    fi
    rm -rf "${asar_extract}"
  fi

  # Копируем иконки из репозитория (или из AppImage как fallback)
  mkdir -p "${bundle_dir}/share"
  if [ -d "${usr_share_dir}" ]; then
    cp -a "${usr_share_dir}/." "${bundle_dir}/share/"
  elif [ -d "${extract_dir}/squashfs-root/usr/share/icons" ]; then
    cp -a "${extract_dir}/squashfs-root/usr/share/icons" "${bundle_dir}/share/"
  fi

  cat > "${bundle_dir}/bin/perplexity" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_root="$(cd "${script_dir}/.." && pwd)"
appdir="${app_root}/appdir"

portable_state_dir="${PERPLEXITY_STATE_DIR:-${app_root}/state}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${portable_state_dir}/config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${portable_state_dir}/data}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${portable_state_dir}/cache}"

mkdir -p "${XDG_CONFIG_HOME}/Perplexity" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}"

# Регистрируем desktop файл и иконки для KDE/GNOME (пересоздаём при каждом запуске, чтобы путь оставался актуальным)
local_desktop_dir="${HOME}/.local/share/applications"
local_icons_dir="${HOME}/.local/share/icons"
portable_desktop_file="${local_desktop_dir}/perplexity-portable.desktop"
mkdir -p "${local_desktop_dir}" "${local_icons_dir}"
if [ -d "${app_root}/share/icons" ]; then
  cp -a "${app_root}/share/icons/." "${local_icons_dir}/"
fi
cat > "${portable_desktop_file}" <<DESKTOP
[Desktop Entry]
Name=Perplexity
Exec=${app_root}/bin/perplexity
Terminal=false
Type=Application
Icon=Perplexity
StartupWMClass=Perplexity
Categories=Utility;
DESKTOP
update-desktop-database "${local_desktop_dir}" 2>/dev/null || true

export DEV_TOOLS="${DEV_TOOLS:-0}"
export APPDIR="${appdir}"
export PATH="${APPDIR}:${APPDIR}/usr/sbin:${PATH}"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${LD_LIBRARY_PATH:-}"
export XDG_DATA_DIRS="${app_root}/share:${APPDIR}/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GSETTINGS_SCHEMA_DIR="${APPDIR}/usr/share/glib-2.0/schemas:${GSETTINGS_SCHEMA_DIR:-}"

exec "${APPDIR}/Perplexity" \
  --no-sandbox \
  --class=Perplexity \
  --user-data-dir="${XDG_CONFIG_HOME}/Perplexity" \
  --disk-cache-dir="${XDG_CACHE_HOME}" \
  "$@"
EOF
  chmod +x "${bundle_dir}/bin/perplexity"
}

case "${source_mode}" in
  auto)
    if [ -d "${src_dir}/node_modules" ]; then
      selected_source="repo"
    elif [ -f "${appimage_path}" ]; then
      selected_source="appimage"
    else
      selected_source="repo"
    fi
    ;;
  repo|appimage)
    selected_source="${source_mode}"
    ;;
  *)
    echo "Unsupported source mode: ${source_mode}" >&2
    exit 1
    ;;
esac

case "${selected_source}" in
  repo)
    prepare_repo_bundle
    ;;
  appimage)
    prepare_appimage_bundle
    ;;
esac

cat > "${bundle_dir}/VERSION" <<EOF
${bundle_name}
EOF

package_installer
echo "Source mode: ${selected_source}"
echo "Bundle root: ${bundle_dir}"
