# Changelog

All notable changes to shelve are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.1.0] — 2026-04-14

Initial release. The core three commands are stable and working.

### Added

- `shelve save` — scans the Mac, interactive checkboxes per category, copies dotfiles to `~/.shelve/dotfiles/`, writes `~/.shelve/shelve.json`
- `shelve restore` — reads `shelve.json`, interactive checkboxes to select what to install, installs Homebrew formulae and casks with progress spinners, shows reminders for manual installs and apps, restores dotfiles
- `shelve fresh` — wizard for brand new Mac setup with no existing backup — picks developer type, browser, terminal, editor, shell extras, languages, CLI tools, databases, and productivity apps; optionally saves result to `shelve.json`
- `shelve help` — usage and command reference
- One-liner install via `curl` — installs Homebrew and gum if missing, clones the repo, adds shelve to PATH
- GitHub Actions CI — clean macOS install test on every push and pull request
- Homebrew formulae detection, backup, and restore
- Homebrew cask detection, backup, and restore
- Dotfiles detection and backup (`~/.zshrc`, `~/.gitconfig`, `~/.config/nvim`, `~/.ssh/config`, and more)
- Dotfile restore with automatic `.bak` backup of existing files
- Manual app detection from `/Applications` (filters out system apps)
- Manual install detection: nvm, rustup, oh-my-zsh
- Role detection: browser, terminal, editor, CLI editor
- System info capture: macOS version, architecture, shell
