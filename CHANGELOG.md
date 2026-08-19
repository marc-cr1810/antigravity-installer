# Changelog

## 0.1.1

- Fix download URL resolution after upstream Antigravity download page transitioned to Astro/server-rendered HTML.
- Add support for direct HTML parsing with script bundle fallback.
- Modernize terminal user interface with ANSI typography, styled cards, banners, step indicators, and progress bars.
- Add `--check-update` feature for instant lightweight version comparison against upstream Google releases.
- Add legacy Antigravity 1.x `.deb` package detection and cleanup (`--clean-legacy` option and interactive prompt).
- Add `--check-update` and `--all --print-downloads` checks in CI test suite.

## 0.1.0 - Initial public project

- One-command installer for official Google Antigravity 2.0 Linux tarball.
- Optional Antigravity IDE install.
- App menu entries and icons.
- `/usr/local/bin` launchers.
- `antigravity-linux` update helper.
- Folder open integration for Antigravity IDE.
- GitHub Pages landing page and deploy workflow.
