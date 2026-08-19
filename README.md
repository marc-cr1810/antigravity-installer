# Antigravity Linux Installer

```
 █████╗ ███╗   ██╗████████╗██╗ ██████╗ ██████╗  █████╗ ██╗   ██╗██╗████████╗██╗   ██╗
██╔══██╗████╗  ██║╚══██╔══╝██║██╔════╝ ██╔══██╗██╔══██╗██║   ██║██║╚══██╔══╝╚██╗ ██╔╝
███████║██╔██╗ ██║   ██║   ██║██║  ███╗██████╔╝███████║██║   ██║██║   ██║    ╚████╔╝
██╔══██║██║╚██╗██║   ██║   ██║██║   ██║██╔══██╗██╔══██║╚██╗ ██╔╝██║   ██║     ╚██╔╝
██║  ██║██║ ╚████║   ██║   ██║╚██████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║   ██║      ██║
╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝   ╚═╝      ╚═╝

                   ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
                   ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
                   ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
                   ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
                   ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
                   ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
```

[![CI](https://github.com/marc-cr1810/antigravity-installer/actions/workflows/ci.yml/badge.svg)](https://github.com/marc-cr1810/antigravity-installer/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20(x86__64%20%7C%20ARM64)-teal.svg)](#supported-systems)
[![Release](https://img.shields.io/badge/Release-v0.1.1-green.svg)](CHANGELOG.md)

> **Disclaimer:** This is an open-source community helper. It is not affiliated with, endorsed by, or supported by Google. Google Antigravity is a trademark of Google LLC.

A modern, one-command Linux installer and package manager for **Google Antigravity 2.0** and **Antigravity IDE** using Google's official Linux tarball downloads.

This project does **not** mirror, modify, or redistribute Google binaries. It resolves the latest official release directly from [https://antigravity.google/download](https://antigravity.google/download) at install/update time and sets up native Linux desktop integration.

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Managing & Updating](#managing--updating)
- [Legacy 1.x Migration](#legacy-1x-migration)
- [Options & CLI Flags](#options--cli-flags)
- [What It Installs](#what-it-installs)
- [Supported Systems](#supported-systems)
- [Local Development & GitHub Pages](#local-development--github-pages)
- [Security & Transparency](#security--transparency)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Official Downloads:** Resolves and downloads upstream tarballs directly from Google.
- **Multi-Architecture:** Automatically detects CPU architecture (`x86_64` / `amd64` and `aarch64` / `arm64`).
- **Complete Desktop Integration:** Installs `.desktop` menu launchers, high-resolution icons, and MIME types.
- **Command-Line Launchers:** Provides global `/usr/local/bin/antigravity` and `/usr/local/bin/antigravity-ide` binaries.
- **Update Checker:** Fast `--check-update` tool to compare installed vs upstream versions without downloading large tarballs.
- **Self-Updating Manager:** Includes `antigravity-linux` for seamless updates and maintenance.
- **Legacy 1.x Cleanup:** Detects and cleanly removes obsolete `antigravity` `.deb` packages to avoid duplicate launchers.
- **File Manager Integration:** Optional GNOME Files / Nautilus right-click context menu extension for Antigravity IDE.
- **Security-First:** Preserves Chromium/Electron sandbox permissions (`chrome-sandbox`) rather than disabling the sandbox.

---

## Quick Start

### 1. Install Antigravity 2.0 and Antigravity IDE (Recommended)

```bash
INSTALLER_URL="https://marc-cr1810.github.io/antigravity-installer/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all
```

### 2. Install Only Antigravity 2.0 Desktop App

```bash
INSTALLER_URL="https://marc-cr1810.github.io/antigravity-installer/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --desktop
```

### 3. Install Only Antigravity IDE

```bash
INSTALLER_URL="https://marc-cr1810.github.io/antigravity-installer/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --ide
```

### 4. Install with Official Google CLI Tool

```bash
INSTALLER_URL="https://marc-cr1810.github.io/antigravity-installer/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all --cli
```

### Alternative: Raw GitHub One-Liner

If GitHub Pages is unavailable or if you prefer the raw repository source:

```bash
INSTALLER_URL="https://raw.githubusercontent.com/marc-cr1810/antigravity-installer/main/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all
```

---

## Managing & Updating

Once installed, the `antigravity-linux` manager command is available system-wide.

### Check for Updates (Instant, No Download)
Check if newer versions are available on Google without downloading packages *(no `sudo` required)*:

```bash
antigravity-linux --check-update
```

```text
╭──────────────────────────────────────────────────────────╮
│ Antigravity Linux Installer                              │
│ Google Antigravity 2.0 & IDE Setup (linux-x64)           │
╰──────────────────────────────────────────────────────────╯

──➤ Checking for Updates (linux-x64)
  ✔ Antigravity 2.0: up to date (v2.8.1)
  ▲ Antigravity IDE: update available! (v2.5.4 ➔ v2.5.5)

  • To install updates: sudo antigravity-linux update --all
```

### Apply Updates
Update all installed components to the latest Google releases:

```bash
sudo antigravity-linux update --all
```

Update only the desktop app or IDE:

```bash
sudo update-antigravity       # Desktop app only
sudo update-antigravity-ide   # IDE only
```

### View Installation Status
Inspect currently installed versions and launcher locations *(no `sudo` required)*:

```bash
antigravity-linux --status
```

### Inspect Official Download URLs
View the exact Google tarball URLs and versions resolved from the official page:

```bash
antigravity-linux --print-downloads
```

### Uninstall
Remove all helper-managed binaries, desktop entries, icons, and file-manager extensions:

```bash
sudo antigravity-linux --uninstall
```

> **Note:** User configurations and personal workspaces in your home directory (`~/.config`, `~/.gemini`) are preserved.

---

## Legacy 1.x Migration

If you previously installed the older Google Antigravity 1.x Debian package (`antigravity` package registered with `apt` / `/usr/share/antigravity`):

- **Automatic Detection:** `antigravity-linux --status` and `install.sh` automatically detect if a legacy 1.x package is present.
- **Interactive Cleanup:** During installation, you will be prompted if you'd like to remove the legacy package to avoid duplicate app launchers and path conflicts.
- **Automated Removal:** Pass `--clean-legacy` to remove it non-interactively:

```bash
INSTALLER_URL="https://marc-cr1810.github.io/antigravity-installer/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all --clean-legacy -y
```

---

## Options & CLI Flags

```text
Usage:
  install.sh [install|update] [options]
  install.sh --status
  install.sh --check-update
  install.sh --print-downloads
  install.sh --uninstall

Options:
  --desktop          Install/update Antigravity 2.0 desktop app only (default)
  --ide              Install/update Antigravity IDE only
  --all              Install/update Antigravity 2.0 desktop app + Antigravity IDE
  --cli              Also run Google's official Antigravity CLI installer
  --clean-legacy     Remove legacy Antigravity 1.x Debian package if present
  --no-nautilus      Skip GNOME Files/Nautilus context-menu helper
  --no-apt           Do not install apt dependencies automatically
  --force            Reinstall even when the recorded version matches
  --install-url URL  Store URL used by the antigravity-linux update command
  --status           Show installed helper-managed apps and versions
  --check-update     Check if newer versions are available from Google
  --print-downloads  Print the resolved official Google tarball URLs
  --uninstall        Remove helper-managed Antigravity desktop/IDE files
  -y, --yes          Non-interactive; assume yes where possible
  -h, --help         Show help message
```

---

## What It Installs

| Component | Path | Description |
|---|---|---|
| **Antigravity 2.0** | `/opt/antigravity` | Official extracted Google Antigravity 2.0 application |
| **Antigravity IDE** | `/opt/antigravity-ide` | Official extracted Google Antigravity IDE application |
| **CLI Launchers** | `/usr/local/bin/antigravity`<br>`/usr/local/bin/antigravity-ide` | Terminal launcher commands |
| **Manager / Updater** | `/usr/local/bin/antigravity-linux`<br>`/usr/local/bin/update-antigravity`<br>`/usr/local/bin/update-antigravity-ide` | Update and management utilities |
| **Desktop Entries** | `/usr/share/applications/antigravity.desktop`<br>`/usr/share/applications/antigravity-ide.desktop` | Application menu & launcher entries |
| **Application Icons** | `/usr/share/icons/hicolor/512x512/apps/` | High-resolution application icons |
| **Nautilus Extension** | `/usr/share/nautilus-python/extensions/open-in-antigravity-ide.py` | "Open Folder in Antigravity IDE" right-click menu |

> **Tip (GNOME Files / Nautilus):** After installing the IDE, run `nautilus -q` in your terminal to restart the file manager and activate the right-click context menu.

---

## Supported Systems

### Minimum System Requirements
- **glibc:** `≥ 2.28`
- **glibcxx:** `≥ 3.4.25`
- Supported on Ubuntu 20.04+, Debian 10+, Fedora 36+, RHEL 8+, Arch Linux, and modern Linux distributions.

### Dependencies
On Debian/Ubuntu-based systems, `apt-get` automatically installs prerequisites:
- `ca-certificates`, `curl`, `tar`, `python3`, `desktop-file-utils`, `xdg-utils`
- `python3-nautilus` *(optional, for GNOME Files right-click integration)*

On other Linux distributions (Fedora, Arch, openSUSE), ensure `curl`, `tar`, `python3`, and `desktop-file-utils` are installed before running.

---

## Local Development & GitHub Pages

### Local Clone & Development
```bash
git clone https://github.com/marc-cr1810/antigravity-installer.git
cd antigravity-installer

# Run repository tests and linters
bash scripts/check.sh

# Sync changes to docs/ for GitHub Pages
bash scripts/sync-site.sh

# Test local install
sudo bash install.sh --all
```

### GitHub Pages Setup for Forks
1. Fork or push to your repository: `https://github.com/YOUR_USERNAME/antigravity-installer`.
2. Go to **Settings → Pages**.
3. Under **Build and deployment → Source**, select **GitHub Actions**.
4. Pushing to `main` will automatically deploy your installer to `https://YOUR_USERNAME.github.io/antigravity-installer/install.sh`.

---

## Security & Transparency

- **100% Open Source:** Inspect the entire installer before executing:
  ```bash
  curl -fsSL "https://marc-cr1810.github.io/antigravity-installer/install.sh" -o install.sh
  less install.sh
  sudo bash install.sh --all
  ```
- **Direct Official Sources:** Downloads only from Google official domains (`https://antigravity.google`, `storage.googleapis.com`, `edgedl.me.gvt1.com`).
- **No Binary Modification:** Tarballs are verified, uncompressed directly, and desktop wrappers are placed cleanly.
- **Reversible:** Clean uninstallation with `sudo antigravity-linux --uninstall`.

---

## Contributing

Contributions, bug reports, and pull requests are welcome!

1. Check the [Contributing Guidelines](CONTRIBUTING.md).
2. Open an issue or bug report on [GitHub Issues](https://github.com/marc-cr1810/antigravity-installer/issues).

---

## License

MIT License. See [LICENSE](LICENSE) for details.
