#!/usr/bin/env bash
# Antigravity Linux Installer
# Installs/updates Google Antigravity 2.0 and, optionally, Antigravity IDE on Debian/Ubuntu.
# It resolves the latest official Google tarballs from https://antigravity.google/download.
set -euo pipefail

ORIGINAL_ARGS=("$@")
PROJECT_NAME="antigravity-linux"
DEFAULT_INSTALLER_URL="https://raw.githubusercontent.com/marc-cr1810/antigravity-installer/main/install.sh"
DOWNLOAD_PAGE="https://antigravity.google/download"
CLI_INSTALLER="https://antigravity.google/cli/install.sh"
INSTALL_DESKTOP=1
INSTALL_IDE=0
INSTALL_CLI=0
INSTALL_NAUTILUS=1
INSTALL_DEPS=1
DO_UNINSTALL=0
DO_STATUS=0
DO_PRINT_DOWNLOADS=0
DO_CHECK_UPDATE=0
CLEAN_LEGACY=0
PRODUCT_FILTER_SET=0
EXPLICIT_INSTALL=0
FORCE=0
YES=0
INSTALLER_URL="${ANTIGRAVITY_LINUX_INSTALLER_URL:-$DEFAULT_INSTALLER_URL}"
CLEANUP_DIRS=()
cleanup() {
  if [ "${#CLEANUP_DIRS[@]}" -gt 0 ]; then
    for dir in "${CLEANUP_DIRS[@]}"; do
      if [ -n "$dir" ] && [ -d "$dir" ]; then
        rm -rf "$dir"
      fi
    done
  fi
}
trap cleanup EXIT

# Terminal color and typography setup (respects NO_COLOR and non-interactive ttys)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RESET=$'\033[0m'
  TEAL=$'\033[38;5;37m'
  CYAN=$'\033[38;5;45m'
  GREEN=$'\033[38;5;71m'
  YELLOW=$'\033[38;5;214m'
  RED=$'\033[38;5;203m'
  GRAY=$'\033[38;5;244m'
else
  BOLD=""
  DIM=""
  RESET=""
  TEAL=""
  CYAN=""
  GREEN=""
  YELLOW=""
  RED=""
  GRAY=""
fi

log() { printf '%s\n' "$*"; }
log_step() { printf '\n%b\n' "${TEAL}${BOLD}──➤ $*${RESET}"; }
log_info() { printf '%b\n' "${CYAN}  ●${RESET} $*"; }
log_success() { printf '%b\n' "${GREEN}  ✔${RESET} ${BOLD}$*${RESET}"; }
log_item() { printf '%b\n' "${GRAY}    •${RESET} $*"; }
warn() { printf '%b\n' "${YELLOW}  ▲ WARN:${RESET} $*" >&2; }
err() { printf '%b\n' "${RED}  ✖ ERROR:${RESET} $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || err "Required command not found: $1"; }

if [ "$(uname -s)" != "Linux" ]; then
  err "This installer is for Linux only."
fi

case "$(uname -m)" in
  x86_64|amd64) AG_PLATFORM="linux-x64"; DESKTOP_TOP="Antigravity-x64" ;;
  aarch64|arm64) AG_PLATFORM="linux-arm"; DESKTOP_TOP="Antigravity-arm64" ;;
  *) err "Unsupported CPU architecture: $(uname -m). Google currently provides x64 and ARM64 Linux builds." ;;
esac

print_banner() {
  cat <<BANNER
${TEAL}╭──────────────────────────────────────────────────────────╮
│ ${BOLD}Antigravity Linux Installer${RESET}${TEAL}                              │
│ ${DIM}Google Antigravity 2.0 & IDE Setup (${AG_PLATFORM})${RESET}${TEAL}           │
╰──────────────────────────────────────────────────────────╯${RESET}
BANNER
}

usage() {
  cat <<USAGE
${TEAL}${BOLD}Antigravity Linux Installer${RESET}
${DIM}Installs and manages Google Antigravity 2.0 and Antigravity IDE on Linux.${RESET}

${BOLD}Usage:${RESET}
  install.sh [install|update] [options]
  install.sh uninstall [--desktop|--ide|--all]
  install.sh --status
  install.sh --check-update
  install.sh --clean-legacy
  install.sh --print-downloads
  install.sh --uninstall [--desktop|--ide|--all]

${BOLD}Default:${RESET}
  Installs or updates Antigravity 2.0 desktop app system-wide.

${BOLD}Options:${RESET}
  ${CYAN}--desktop${RESET}              Target Antigravity 2.0 desktop app only (default for install/update)
  ${CYAN}--ide${RESET}                  Target Antigravity IDE only
  ${CYAN}--all${RESET}                  Target both Antigravity 2.0 desktop app + Antigravity IDE
  ${CYAN}--cli${RESET}                  Also run Google's official Antigravity CLI installer
  ${CYAN}--clean-legacy${RESET}         Remove legacy Antigravity 1.x Debian package if present
  ${CYAN}--no-nautilus${RESET}          Skip GNOME Files/Nautilus context-menu helper
  ${CYAN}--no-apt${RESET}               Do not install apt dependencies automatically
  ${CYAN}--force${RESET}                Reinstall even when the recorded version matches
  ${CYAN}--install-url URL${RESET}      Store URL used by the antigravity-linux update command
  ${CYAN}--status${RESET}               Show installed helper-managed apps and versions
  ${CYAN}--check-update${RESET}         Check if newer versions are available from Google
  ${CYAN}--print-downloads${RESET}      Print the resolved official Google tarball URLs
  ${CYAN}--uninstall${RESET}            Remove helper-managed Antigravity desktop/IDE files
  ${CYAN}-y, --yes${RESET}              Non-interactive; assume yes where possible
  ${CYAN}-h, --help${RESET}             Show this help

${BOLD}Recommended one-liner:${RESET}
  ${DIM}curl -fsSL https://raw.githubusercontent.com/marc-cr1810/antigravity-installer/main/install.sh | sudo bash -s -- --all${RESET}

${BOLD}Update after install:${RESET}
  ${DIM}sudo antigravity-linux update --all${RESET}
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    install|update) EXPLICIT_INSTALL=1 ;;
    uninstall|--uninstall) DO_UNINSTALL=1 ;;
    desktop|--desktop) INSTALL_DESKTOP=1; INSTALL_IDE=0; PRODUCT_FILTER_SET=1; EXPLICIT_INSTALL=1 ;;
    ide|--ide) INSTALL_DESKTOP=0; INSTALL_IDE=1; PRODUCT_FILTER_SET=1; EXPLICIT_INSTALL=1 ;;
    all|--all) INSTALL_DESKTOP=1; INSTALL_IDE=1; PRODUCT_FILTER_SET=1; EXPLICIT_INSTALL=1 ;;
    cli|--cli) INSTALL_CLI=1; PRODUCT_FILTER_SET=1; EXPLICIT_INSTALL=1 ;;
    check-update|--check-update) DO_CHECK_UPDATE=1 ;;
    clean-legacy|--clean-legacy) CLEAN_LEGACY=1 ;;
    --no-nautilus) INSTALL_NAUTILUS=0 ;;
    --no-apt) INSTALL_DEPS=0 ;;
    --force) FORCE=1 ;;
    --install-url)
      shift
      [ $# -gt 0 ] || err "--install-url needs a URL"
      INSTALLER_URL="$1"
      ;;
    status|--status) DO_STATUS=1 ;;
    --print-downloads) DO_PRINT_DOWNLOADS=1 ;;
    -y|--yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1" ;;
  esac
  shift
done

require_root_or_reexec() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  if command -v sudo >/dev/null 2>&1 && [ -n "${BASH_SOURCE[0]:-}" ] && [ -r "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ "${BASH_SOURCE[0]}" != "sh" ]; then
    exec sudo bash "${BASH_SOURCE[0]}" "${ORIGINAL_ARGS[@]}"
  fi
  err "System-wide install needs root. Run with sudo: sudo bash install.sh or curl -fsSL <url> | sudo bash -s -- [options]"
}

download_file() {
  local url="$1"
  local dest="$2"
  if [ -t 1 ]; then
    curl -# -fSL --retry 3 -o "$dest" "$url"
  else
    curl -fsSL --retry 3 -o "$dest" "$url"
  fi
}

install_deps_debian() {
  [ "$INSTALL_DEPS" -eq 1 ] || return 0
  if command -v apt-get >/dev/null 2>&1; then
    log_info "Updating system packages and verifying dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    local packages=(ca-certificates curl tar python3 desktop-file-utils xdg-utils)
    if [ "$INSTALL_NAUTILUS" -eq 1 ] && [ "$INSTALL_IDE" -eq 1 ]; then
      packages+=(python3-nautilus)
    fi
    apt-get install -y -qq "${packages[@]}" >/dev/null
  else
    for c in curl tar python3; do need "$c"; done
  fi
}

fetch_download_page() {
  local tmpdir="$1"
  local html="$tmpdir/download.html"
  curl -fsSL --compressed --retry 3 -o "$html" "$DOWNLOAD_PAGE"
  printf '%s\n' "$html"
}

resolve_download() {
  local html_file="$1"
  local product="$2"
  python3 - "$html_file" "$AG_PLATFORM" "$product" "$DOWNLOAD_PAGE" <<'PY'
import html, re, subprocess, sys
from pathlib import Path
from urllib.parse import unquote, urljoin

html_file = sys.argv[1]
platform = sys.argv[2]
product = sys.argv[3]
page_url = sys.argv[4]

page_text = Path(html_file).read_text(errors='replace')

def fail(msg):
    raise SystemExit(msg)

def version_from_url(url):
    decoded = unquote(url)
    # Known current layouts include antigravity-hub/<version>/ and stable/<version>/.
    for pattern in (r'/antigravity-hub/([^/]+)/', r'/stable/([^/]+)/', r'/(\d+\.\d+\.\d+(?:-[^/]+)?)/'):
        m = re.search(pattern, decoded)
        if m:
            return m.group(1).split('-', 1)[0]
    return 'unknown'

if product == 'desktop':
    markers = [
        r'id=[\'"]antigravity-2[\'"]',
        r'id:\s*[\'"]antigravity-2[\'"]',
        r'<h[1-4][^>]*>[^<]*Antigravity\s+2(?:\.0)?[^<]*</h[1-4]>'
    ]
    next_markers = [
        r'id=[\'"]antigravity-cli[\'"]',
        r'id:\s*[\'"]antigravity-cli[\'"]',
        r'<h[1-4][^>]*>[^<]*Antigravity\s+CLI[^<]*</h[1-4]>'
    ]
    filename_patterns = [r'Antigravity\.tar\.gz']
    label = 'Antigravity 2.0'
elif product == 'ide':
    markers = [
        r'id=[\'"]antigravity-ide[\'"]',
        r'id:\s*[\'"]antigravity-ide[\'"]',
        r'<h[1-4][^>]*>[^<]*Antigravity\s+IDE[^<]*</h[1-4]>'
    ]
    next_markers = [
        r'id=[\'"]antigravity-sdk[\'"]',
        r'id:\s*[\'"]antigravity-sdk[\'"]',
        r'<h[1-4][^>]*>[^<]*Antigravity\s+SDK[^<]*</h[1-4]>'
    ]
    filename_patterns = [r'Antigravity(?:%20|\+| )IDE\.tar\.gz']
    label = 'Antigravity IDE'
else:
    fail(f'Unknown product: {product}')

def search_text(raw_text):
    text = html.unescape(raw_text).replace('\\/', '/')
    sections = []
    start_pos = -1
    for m in markers:
        match = re.search(m, text, re.IGNORECASE)
        if match:
            start_pos = match.start()
            break

    if start_pos != -1:
        end_pos = -1
        for nm in next_markers:
            match = re.search(nm, text[start_pos:], re.IGNORECASE)
            if match:
                end_pos = start_pos + match.start()
                break
        sections.append(text[start_pos:end_pos if end_pos != -1 else None])

    sections.append(text)

    for section in sections:
        for filename_re in filename_patterns:
            pattern = r'https?://[^"\'\s<>)]*/' + re.escape(platform) + r'/' + filename_re
            matches = re.findall(pattern, section)
            if matches:
                return matches[0]
    return None

# 1. Search directly in page HTML
found_url = search_text(page_text)
if found_url:
    print(version_from_url(found_url), found_url)
    sys.exit(0)

# 2. Fallback: Search script bundles referenced in the HTML
script_srcs = re.findall(r'<script[^>]+src=[\'"]([^\'"]+\.js(?:\?[^\'"]*)?)[\'"]', page_text, re.IGNORECASE)
for src in script_srcs:
    full_js_url = urljoin(page_url, src)
    try:
        cmd = ['curl', '-fsSL', '--compressed', '--retry', '2', full_js_url]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=15)
        if res.returncode == 0:
            js_text = res.stdout.decode('utf-8', errors='replace')
            found_url = search_text(js_text)
            if found_url:
                print(version_from_url(found_url), found_url)
                sys.exit(0)
    except Exception:
        pass

fail(f'Could not find official {label} tarball for {platform} on official Antigravity download page')
PY
}

resolve_desktop_download() { resolve_download "$1" desktop; }
resolve_ide_download() { resolve_download "$1" ide; }

asar_extract_icon_png() {
  local asar="$1"
  local out="$2"
  python3 - "$asar" "$out" <<'PY'
import json, struct, sys
from pathlib import Path
asar = Path(sys.argv[1])
out = Path(sys.argv[2])
with asar.open('rb') as f:
    f.read(4)
    header_size = struct.unpack('<I', f.read(4))[0]
    f.read(4)
    json_size = struct.unpack('<I', f.read(4))[0]
    header = json.loads(f.read(json_size).decode())
icon = header.get('files', {}).get('icon.png')
if not icon:
    raise SystemExit('icon.png not found in app.asar')
with asar.open('rb') as f:
    f.seek(8 + header_size + int(icon['offset']))
    out.write_bytes(f.read(int(icon['size'])))
PY
}

safe_replace_dir() {
  local newdir="$1"
  local target="$2"
  rm -rf "${target}.previous"
  if [ -d "$target" ]; then
    mv "$target" "${target}.previous"
  fi
  mv "$newdir" "$target"
}

fix_chrome_sandbox() {
  local sandbox="$1"
  if [ -f "$sandbox" ]; then
    chown root:root "$sandbox"
    chmod 4755 "$sandbox"
  fi
}

refresh_desktop_caches() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
  fi
}

installed_version() {
  local file="$1"
  cat "$file" 2>/dev/null || true
}

install_desktop_app() {
  local tmpdir="$1"
  local page_file="$2"
  local version url
  read -r version url < <(resolve_desktop_download "$page_file")
  local root="/opt/antigravity"
  local target="$root/$DESKTOP_TOP/antigravity"
  local version_file="$root/.antigravity-linux-version"
  if [ "$FORCE" -eq 0 ] && [ -x "$target" ] && [ "$(installed_version "$version_file")" = "$version" ]; then
    log_info "Antigravity 2.0 v$version is already up to date."
    return
  fi

  log_step "Installing Antigravity 2.0 (v$version for $AG_PLATFORM)"
  log_info "Downloading official tarball from Google..."
  local archive="$tmpdir/Antigravity.tar.gz"
  download_file "$url" "$archive"
  
  log_info "Extracting and validating archive..."
  tar -tzf "$archive" > "$tmpdir/desktop-list.txt"
  local top_dir
  top_dir=$(sed -n '1{s#/.*##;p;q}' "$tmpdir/desktop-list.txt")
  [ "$top_dir" = "$DESKTOP_TOP" ] || err "Unexpected Antigravity archive layout: $top_dir"
  tar -xzf "$archive" -C "$tmpdir"
  [ -x "$tmpdir/$top_dir/antigravity" ] || err "Antigravity launcher not found inside tarball."

  local icon_staged="$tmpdir/antigravity.png"
  if [ -f "$tmpdir/$top_dir/resources/app.asar" ]; then
    asar_extract_icon_png "$tmpdir/$top_dir/resources/app.asar" "$icon_staged" || warn "Could not extract desktop icon; continuing."
  fi

  rm -rf "${root}.new"
  mkdir -p "${root}.new"
  cp -a "$tmpdir/$top_dir" "${root}.new/"
  printf '%s\n' "$version" > "${root}.new/.antigravity-linux-version"
  printf '%s\n' "$url" > "${root}.new/.antigravity-linux-source-url"
  fix_chrome_sandbox "${root}.new/$top_dir/chrome-sandbox"
  safe_replace_dir "${root}.new" "$root"

  log_info "Configuring desktop integration and launcher symlinks..."
  ln -sfn "$root/$top_dir/antigravity" /usr/local/bin/antigravity
  mkdir -p /usr/share/icons/hicolor/512x512/apps /usr/share/applications
  if [ -f "$icon_staged" ]; then
    install -m 0644 "$icon_staged" /usr/share/icons/hicolor/512x512/apps/antigravity.png
  fi
  cat > /usr/share/applications/antigravity.desktop <<DESKTOP
[Desktop Entry]
Name=Antigravity
Comment=Google Antigravity 2.0 agent platform
Exec=/usr/local/bin/antigravity %U
Icon=antigravity
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Antigravity
DESKTOP
  refresh_desktop_caches
  log_success "Installed Antigravity 2.0 v$version at $root/$top_dir"
}

install_ide_app() {
  local tmpdir="$1"
  local page_file="$2"
  local version url
  read -r version url < <(resolve_ide_download "$page_file")
  local root="/opt/antigravity-ide"
  local install_dir="Antigravity-IDE"
  local version_file="$root/.antigravity-linux-version"
  if [ "$FORCE" -eq 0 ] && [ -x "$root/$install_dir/antigravity-ide" ] && [ "$(installed_version "$version_file")" = "$version" ]; then
    log_info "Antigravity IDE v$version is already up to date."
    return
  fi

  log_step "Installing Antigravity IDE (v$version for $AG_PLATFORM)"
  log_info "Downloading official tarball from Google..."
  local archive="$tmpdir/Antigravity-IDE.tar.gz"
  download_file "$url" "$archive"

  log_info "Extracting and validating archive..."
  tar -tzf "$archive" > "$tmpdir/ide-list.txt"
  local top_dir
  top_dir=$(sed -n '1{s#/.*##;p;q}' "$tmpdir/ide-list.txt")
  [ "$top_dir" = "Antigravity IDE" ] || err "Unexpected Antigravity IDE archive layout: $top_dir"
  tar -xzf "$archive" -C "$tmpdir"
  [ -x "$tmpdir/$top_dir/antigravity-ide" ] || err "Antigravity IDE launcher not found inside tarball."

  rm -rf "${root}.new"
  mkdir -p "${root}.new/$install_dir"
  cp -a "$tmpdir/$top_dir/." "${root}.new/$install_dir/"
  printf '%s\n' "$version" > "${root}.new/.antigravity-linux-version"
  printf '%s\n' "$url" > "${root}.new/.antigravity-linux-source-url"
  fix_chrome_sandbox "${root}.new/$install_dir/chrome-sandbox"
  safe_replace_dir "${root}.new" "$root"

  log_info "Configuring desktop integration and launcher symlinks..."
  ln -sfn "$root/$install_dir/antigravity-ide" /usr/local/bin/antigravity-ide
  mkdir -p /usr/share/icons/hicolor/512x512/apps /usr/share/applications
  local icon_source="$root/$install_dir/resources/app/resources/linux/code.png"
  if [ -f "$icon_source" ]; then
    install -m 0644 "$icon_source" /usr/share/icons/hicolor/512x512/apps/antigravity-ide.png
  fi
  cat > /usr/share/applications/antigravity-ide.desktop <<DESKTOP
[Desktop Entry]
Name=Antigravity IDE
Comment=Google Antigravity IDE
Exec=/usr/local/bin/antigravity-ide %F
Icon=antigravity-ide
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=inode/directory;text/plain;application/x-code-workspace;application/x-antigravity-workspace;x-scheme-handler/antigravity-ide;
StartupNotify=true
StartupWMClass=antigravity-ide
DESKTOP
  refresh_desktop_caches
  log_success "Installed Antigravity IDE v$version at $root/$install_dir"
}

install_nautilus_extension() {
  [ "$INSTALL_NAUTILUS" -eq 1 ] || return 0
  [ "$INSTALL_IDE" -eq 1 ] || return 0
  if ! command -v nautilus >/dev/null 2>&1; then
    return 0
  fi
  if ! python3 - <<'PY' >/dev/null 2>&1
try:
    import gi
    gi.require_version('Nautilus', '4.0')
except Exception:
    raise SystemExit(1)
PY
  then
    warn "Skipping Nautilus extension because Python Nautilus bindings are unavailable."
    return 0
  fi
  mkdir -p /usr/share/nautilus-python/extensions
  cat > /usr/share/nautilus-python/extensions/open-in-antigravity-ide.py <<'PY'
import subprocess
from urllib.parse import unquote, urlparse
from gi.repository import Nautilus, GObject

class OpenInAntigravityIDE(GObject.GObject, Nautilus.MenuProvider):
    def _path(self, file_info):
        uri = file_info.get_uri()
        parsed = urlparse(uri)
        if parsed.scheme != 'file':
            return None
        return unquote(parsed.path)

    def get_file_items(self, files):
        if not files or len(files) != 1:
            return []
        path = self._path(files[0])
        if not path:
            return []
        item = Nautilus.MenuItem(
            name='OpenInAntigravityIDE::open',
            label='Open in Antigravity IDE',
            tip='Open this folder or file in Antigravity IDE'
        )
        item.connect('activate', lambda _item: subprocess.Popen(['antigravity-ide', path]))
        return [item]

    def get_background_items(self, folder):
        path = self._path(folder)
        if not path:
            return []
        item = Nautilus.MenuItem(
            name='OpenInAntigravityIDE::open_background',
            label='Open Folder in Antigravity IDE',
            tip='Open the current folder in Antigravity IDE'
        )
        item.connect('activate', lambda _item: subprocess.Popen(['antigravity-ide', path]))
        return [item]
PY
  log_info "Installed GNOME Files/Nautilus context menu helper."
}

install_manager_command() {
  local installer_url="${INSTALLER_URL:-$DEFAULT_INSTALLER_URL}"
  if [ "$installer_url" = "$DEFAULT_INSTALLER_URL" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local origin_url
    origin_url="$(git config --get remote.origin.url 2>/dev/null || true)"
    if [[ "$origin_url" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)? ]]; then
      local gh_user="${BASH_REMATCH[1]}"
      local gh_repo="${BASH_REMATCH[2]}"
      installer_url="https://raw.githubusercontent.com/$gh_user/$gh_repo/main/install.sh"
    fi
  fi
  installer_url="${installer_url:-$DEFAULT_INSTALLER_URL}"

  cat > /usr/local/bin/antigravity-linux <<SH
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_URL="$installer_url"
case "\${1:-}" in
  --status|--print-downloads|--check-update|check-update|status|-h|--help)
    curl -fsSL "\$SCRIPT_URL" | bash -s -- "\$@"
    ;;
  clean-legacy|--clean-legacy)
    if [ "\$(id -u)" -eq 0 ]; then
      curl -fsSL "\$SCRIPT_URL" | bash -s -- "\$@"
    else
      curl -fsSL "\$SCRIPT_URL" | sudo bash -s -- "\$@"
    fi
    ;;
  *)
    if [ "\$(id -u)" -eq 0 ]; then
      curl -fsSL "\$SCRIPT_URL" | bash -s -- "\$@"
    else
      curl -fsSL "\$SCRIPT_URL" | sudo bash -s -- "\$@"
    fi
    ;;
esac
SH
  chmod +x /usr/local/bin/antigravity-linux
  cat > /usr/local/bin/update-antigravity <<'SH'
#!/usr/bin/env bash
exec antigravity-linux update --desktop "$@"
SH
  chmod +x /usr/local/bin/update-antigravity
  cat > /usr/local/bin/update-antigravity-ide <<'SH'
#!/usr/bin/env bash
exec antigravity-linux update --ide "$@"
SH
  chmod +x /usr/local/bin/update-antigravity-ide
  cat > /usr/local/bin/uninstall-antigravity <<'SH'
#!/usr/bin/env bash
exec antigravity-linux uninstall --desktop "$@"
SH
  chmod +x /usr/local/bin/uninstall-antigravity
  cat > /usr/local/bin/uninstall-antigravity-ide <<'SH'
#!/usr/bin/env bash
exec antigravity-linux uninstall --ide "$@"
SH
  chmod +x /usr/local/bin/uninstall-antigravity-ide
}

has_legacy_deb_package() {
  if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W -f='${Status}' antigravity 2>/dev/null | grep -q "ok installed" && return 0
  elif command -v dpkg >/dev/null 2>&1; then
    dpkg -s antigravity 2>/dev/null | grep -q "Status: install ok installed" && return 0
  fi
  [ -d /usr/share/antigravity ] && return 0
  return 1
}

get_legacy_deb_version() {
  local ver=""
  if command -v dpkg-query >/dev/null 2>&1; then
    ver="$(dpkg-query -W -f='${Version}' antigravity 2>/dev/null || true)"
  fi
  if [ -z "$ver" ] && [ -f /usr/share/antigravity/version ]; then
    ver="$(cat /usr/share/antigravity/version 2>/dev/null || true)"
  fi
  printf '%s\n' "${ver:-unknown}"
}

clean_legacy_installation() {
  log_step "Cleaning legacy Antigravity 1.x package"
  if command -v apt-get >/dev/null 2>&1 && dpkg -s antigravity 2>/dev/null | grep -q "Status: install ok installed"; then
    log_info "Removing legacy 'antigravity' Debian package via apt-get..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get remove -y -qq antigravity >/dev/null 2>&1 || warn "Could not remove legacy package via apt-get."
  fi
  rm -f /usr/share/applications/antigravity-url-handler.desktop
  rm -rf /usr/share/antigravity
  refresh_desktop_caches
  log_success "Cleaned legacy Antigravity 1.x files and package entries."
}

handle_legacy_conflict() {
  has_legacy_deb_package || return 0
  local lv
  lv="$(get_legacy_deb_version)"
  if [ "$CLEAN_LEGACY" -eq 1 ]; then
    clean_legacy_installation
  elif [ "$YES" -eq 1 ]; then
    log_info "Legacy Antigravity 1.x package (v$lv) detected. Pass --clean-legacy to remove."
  elif [ -t 0 ]; then
    printf '\n%b\n' "${YELLOW}  ▲ Legacy Antigravity 1.x package detected (${DIM}v$lv at /usr/share/antigravity${RESET}${YELLOW}).${RESET}"
    read -r -p "    Remove legacy 1.x package to prevent duplicate app entries? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      clean_legacy_installation
    else
      log_info "Preserving legacy 1.x package. Launch via /usr/bin/antigravity."
    fi
  else
    log_info "Legacy Antigravity 1.x package (v$lv) detected. Pass --clean-legacy to remove."
  fi
}

print_status() {
  print_banner
  printf '\n%b\n' "${TEAL}${BOLD}──➤ Installation Status${RESET}"

  if [ -x /usr/local/bin/antigravity ]; then
    local v
    v="$(installed_version /opt/antigravity/.antigravity-linux-version)"
    [ -n "$v" ] && v="v$v" || v="installed"
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity 2.0:${RESET} ${GREEN}installed${RESET} ${DIM}($v)${RESET}"
    printf '%b\n' "${GRAY}    • Launcher:${RESET} /usr/local/bin/antigravity"
    printf '%b\n' "${GRAY}    • Location:${RESET} /opt/antigravity"
  else
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity 2.0:${RESET} ${GRAY}not installed${RESET}"
  fi

  if [ -x /usr/local/bin/antigravity-ide ]; then
    local v
    v="$(installed_version /opt/antigravity-ide/.antigravity-linux-version)"
    [ -n "$v" ] && v="v$v" || v="installed"
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity IDE:${RESET} ${GREEN}installed${RESET} ${DIM}($v)${RESET}"
    printf '%b\n' "${GRAY}    • Launcher:${RESET} /usr/local/bin/antigravity-ide"
    printf '%b\n' "${GRAY}    • Location:${RESET} /opt/antigravity-ide"
  else
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity IDE:${RESET} ${GRAY}not installed${RESET}"
  fi

  if [ -x /usr/local/bin/antigravity-linux ]; then
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Update Helper:${RESET}   ${GREEN}installed${RESET}"
    printf '%b\n' "${GRAY}    • Command:${RESET}  /usr/local/bin/antigravity-linux"
  else
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Update Helper:${RESET}   ${GRAY}not installed${RESET}"
  fi

  if has_legacy_deb_package; then
    local lv
    lv="$(get_legacy_deb_version)"
    printf '\n%b\n' "${YELLOW}  ▲${RESET} ${BOLD}Legacy 1.x (.deb):${RESET} ${YELLOW}detected${RESET} ${DIM}(v$lv at /usr/share/antigravity)${RESET}"
    printf '%b\n' "${GRAY}    • Clean Command:${RESET} ${CYAN}sudo apt remove antigravity${RESET} ${DIM}or run with --clean-legacy${RESET}"
  fi
  printf '\n'
}

check_updates() {
  need curl
  need python3
  local tmp_parent="${TMPDIR:-/tmp}"
  local tmpdir
  tmpdir=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  CLEANUP_DIRS+=("$tmpdir")
  local page_file
  page_file=$(fetch_download_page "$tmpdir")
  print_banner
  printf '\n%b\n' "${TEAL}${BOLD}──➤ Checking for Updates (${AG_PLATFORM})${RESET}"

  local show_desktop=1
  local show_ide=1
  local updates_available=0

  if [ "$PRODUCT_FILTER_SET" -eq 1 ]; then
    show_desktop=$INSTALL_DESKTOP
    show_ide=$INSTALL_IDE
  fi

  if [ "$show_desktop" -eq 1 ]; then
    local installed_v
    installed_v="$(installed_version /opt/antigravity/.antigravity-linux-version)"
    local remote_v remote_url
    read -r remote_v remote_url < <(resolve_desktop_download "$page_file")

    if [ -z "$installed_v" ]; then
      printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity 2.0:${RESET} ${GRAY}not installed${RESET} ${DIM}(Latest available: v$remote_v)${RESET}"
    elif [ "$installed_v" = "$remote_v" ]; then
      printf '%b\n' "${GREEN}  ✔${RESET} ${BOLD}Antigravity 2.0:${RESET} ${GREEN}up to date${RESET} ${DIM}(v$installed_v)${RESET}"
    else
      printf '%b\n' "${YELLOW}  ▲${RESET} ${BOLD}Antigravity 2.0:${RESET} ${YELLOW}${BOLD}update available!${RESET} ${DIM}(v$installed_v ➔ ${BOLD}v$remote_v${RESET}${DIM})${RESET}"
      updates_available=1
    fi
  fi

  if [ "$show_ide" -eq 1 ]; then
    local installed_v
    installed_v="$(installed_version /opt/antigravity-ide/.antigravity-linux-version)"
    local remote_v remote_url
    read -r remote_v remote_url < <(resolve_ide_download "$page_file")

    if [ -z "$installed_v" ]; then
      printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity IDE:${RESET} ${GRAY}not installed${RESET} ${DIM}(Latest available: v$remote_v)${RESET}"
    elif [ "$installed_v" = "$remote_v" ]; then
      printf '%b\n' "${GREEN}  ✔${RESET} ${BOLD}Antigravity IDE:${RESET} ${GREEN}up to date${RESET} ${DIM}(v$installed_v)${RESET}"
    else
      printf '%b\n' "${YELLOW}  ▲${RESET} ${BOLD}Antigravity IDE:${RESET} ${YELLOW}${BOLD}update available!${RESET} ${DIM}(v$installed_v ➔ ${BOLD}v$remote_v${RESET}${DIM})${RESET}"
      updates_available=1
    fi
  fi

  printf '\n'
  if [ "$updates_available" -eq 1 ]; then
    printf '%b\n' "${CYAN}  • To install updates:${RESET} ${BOLD}sudo antigravity-linux update --all${RESET}\n"
  else
    printf '%b\n' "${GREEN}  ✔ All checked installed components are up to date.${RESET}\n"
  fi

  rm -rf "$tmpdir"
}

print_downloads() {
  need curl
  need python3
  local tmp_parent="${TMPDIR:-/tmp}"
  local tmpdir
  tmpdir=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  CLEANUP_DIRS+=("$tmpdir")
  local page_file
  page_file=$(fetch_download_page "$tmpdir")
  print_banner
  printf '\n%b\n' "${TEAL}${BOLD}──➤ Resolved Official Downloads (${AG_PLATFORM})${RESET}"

  local show_desktop=1
  local show_ide=1
  local show_cli=1

  if [ "$PRODUCT_FILTER_SET" -eq 1 ]; then
    show_desktop=$INSTALL_DESKTOP
    show_ide=$INSTALL_IDE
    show_cli=$INSTALL_CLI
  fi

  if [ "$show_desktop" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_desktop_download "$page_file")
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity 2.0${RESET} ${DIM}(v$version)${RESET}"
    printf '%b\n' "${GRAY}    URL:${RESET} $url"
  fi
  if [ "$show_ide" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_ide_download "$page_file")
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity IDE${RESET} ${DIM}(v$version)${RESET}"
    printf '%b\n' "${GRAY}    URL:${RESET} $url"
  fi
  if [ "$show_cli" -eq 1 ]; then
    printf '%b\n' "${CYAN}  ●${RESET} ${BOLD}Antigravity CLI Installer${RESET}"
    printf '%b\n' "${GRAY}    URL:${RESET} $CLI_INSTALLER"
  fi
  printf '\n'
  rm -rf "$tmpdir"
}

print_success_summary() {
  cat <<SUMMARY

${GREEN}╭──────────────────────────────────────────────────────────╮
│ ${BOLD}✔ Antigravity Linux Setup Complete${RESET}${GREEN}                       │
├──────────────────────────────────────────────────────────┤
│${RESET}  ${BOLD}Installed Launchers:${RESET}${GREEN}                                    │$([ "$INSTALL_DESKTOP" -eq 1 ] && printf "\n%b" "${GREEN}│${RESET}  ${GRAY}• Antigravity 2.0 :${RESET} /usr/local/bin/antigravity          ${GREEN}│${RESET}")$([ "$INSTALL_IDE" -eq 1 ] && printf "\n%b" "${GREEN}│${RESET}  ${GRAY}• Antigravity IDE :${RESET} /usr/local/bin/antigravity-ide      ${GREEN}│${RESET}")$([ "$INSTALL_DESKTOP" -eq 0 ] && [ "$INSTALL_IDE" -eq 0 ] && printf "\n%b" "${GREEN}│${RESET}  ${GRAY}• Antigravity CLI :${RESET} ~/.antigravity/bin/agy              ${GREEN}│${RESET}")
${GREEN}│                                                          │
│${RESET}  ${BOLD}Management Commands:${RESET}${GREEN}                                    │
│${RESET}  ${GRAY}• Status          :${RESET} ${CYAN}antigravity-linux --status${RESET}          ${GREEN}│
│${RESET}  ${GRAY}• Check Updates   :${RESET} ${CYAN}antigravity-linux --check-update${RESET}    ${GREEN}│
│${RESET}  ${GRAY}• Update All      :${RESET} ${CYAN}sudo antigravity-linux update --all${RESET} ${GREEN}│
│${RESET}  ${GRAY}• Uninstall       :${RESET} ${CYAN}sudo antigravity-linux --uninstall${RESET}  ${GREEN}│
╰──────────────────────────────────────────────────────────╯${RESET}
SUMMARY

  if [ "$INSTALL_IDE" -eq 1 ]; then
    printf '%b\n' "${GRAY}  • File Manager:${RESET} ${DIM}Use 'Open With' or Nautilus right-click after restarting Files.${RESET}"
  fi
  printf '\n'
}

uninstall_desktop() {
  log_info "Removing Antigravity 2.0 desktop app..."
  rm -rf /opt/antigravity /opt/antigravity.new /opt/antigravity.previous
  rm -f /usr/local/bin/antigravity /usr/local/bin/update-antigravity /usr/local/bin/uninstall-antigravity
  rm -f /usr/share/applications/antigravity.desktop
  rm -f /usr/share/icons/hicolor/512x512/apps/antigravity.png
  log_success "Removed Antigravity 2.0 desktop app."
}

uninstall_ide() {
  log_info "Removing Antigravity IDE..."
  rm -rf /opt/antigravity-ide /opt/antigravity-ide.new /opt/antigravity-ide.previous
  rm -f /usr/local/bin/antigravity-ide /usr/local/bin/update-antigravity-ide /usr/local/bin/uninstall-antigravity-ide
  rm -f /usr/share/applications/antigravity-ide.desktop
  rm -f /usr/share/icons/hicolor/512x512/apps/antigravity-ide.png
  rm -f /usr/share/nautilus-python/extensions/open-in-antigravity-ide.py
  log_success "Removed Antigravity IDE."
}

uninstall_selected() {
  require_root_or_reexec
  print_banner
  log_step "Uninstalling Antigravity Linux components"

  local remove_desktop=0
  local remove_ide=0

  if [ "$PRODUCT_FILTER_SET" -eq 1 ]; then
    remove_desktop=$INSTALL_DESKTOP
    remove_ide=$INSTALL_IDE
  else
    remove_desktop=1
    remove_ide=1
  fi

  [ "$remove_desktop" -eq 1 ] && uninstall_desktop
  [ "$remove_ide" -eq 1 ] && uninstall_ide

  # If neither Desktop nor IDE remains installed, remove helper manager command
  if [ ! -d /opt/antigravity ] && [ ! -d /opt/antigravity-ide ]; then
    rm -f /usr/local/bin/antigravity-linux /usr/local/bin/update-antigravity /usr/local/bin/update-antigravity-ide /usr/local/bin/uninstall-antigravity /usr/local/bin/uninstall-antigravity-ide
  fi

  refresh_desktop_caches
  printf '%b\n' "${DIM}  User settings under home directories were left untouched.${RESET}"

  if [ "$remove_desktop" -eq 1 ] && has_legacy_deb_package; then
    if [ "$CLEAN_LEGACY" -eq 1 ]; then
      clean_legacy_installation
    else
      local lv
      lv="$(get_legacy_deb_version)"
      printf '\n%b\n' "${YELLOW}  ▲ Note: Legacy 'antigravity' 1.x package (v$lv) is still registered with APT.${RESET}"
      printf '%b\n' "${GRAY}    To remove it completely:${RESET} ${CYAN}sudo apt remove antigravity${RESET}\n"
    fi
  fi
}

main() {
  if [ "$DO_STATUS" -eq 1 ]; then
    print_status
    exit 0
  fi
  if [ "$DO_CHECK_UPDATE" -eq 1 ]; then
    check_updates
    exit 0
  fi
  if [ "$DO_PRINT_DOWNLOADS" -eq 1 ]; then
    print_downloads
    exit 0
  fi
  if [ "$DO_UNINSTALL" -eq 1 ]; then
    uninstall_selected
    exit 0
  fi
  if [ "$CLEAN_LEGACY" -eq 1 ] && [ "$EXPLICIT_INSTALL" -eq 0 ]; then
    require_root_or_reexec
    print_banner
    clean_legacy_installation
    exit 0
  fi

  require_root_or_reexec
  print_banner
  install_deps_debian
  handle_legacy_conflict

  local tmp_parent="${TMPDIR:-/var/tmp}"
  mkdir -p "$tmp_parent"
  local tmpdir
  tmpdir=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  CLEANUP_DIRS+=("$tmpdir")
  
  log_step "Resolving official Google downloads"
  local page_file
  page_file=$(fetch_download_page "$tmpdir")
  
  [ "$INSTALL_DESKTOP" -eq 1 ] && install_desktop_app "$tmpdir" "$page_file"
  [ "$INSTALL_IDE" -eq 1 ] && install_ide_app "$tmpdir" "$page_file"
  install_nautilus_extension
  
  if [ "$INSTALL_CLI" -eq 1 ]; then
    log_step "Installing official Antigravity CLI"
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER:-}" != "root" ]; then
      sudo -u "$SUDO_USER" -H bash -lc "curl -fsSL '$CLI_INSTALLER' | bash"
    else
      curl -fsSL "$CLI_INSTALLER" | bash
    fi
  fi
  
  install_manager_command
  print_success_summary
}

main "$@"

