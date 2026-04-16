# shelve

**shelf your setup** — back up, restore, or start fresh on any Mac.

shelve is a macOS CLI tool that captures your developer environment — Homebrew packages, apps, dotfiles, and roles — into a single `shelve.json` file you can commit, share, or carry to a new machine.

No Node. No Python. No Go. Just bash.

---

<!--
  DEMO PLACEHOLDER
  Record with VHS (https://github.com/charmbracelet/vhs) or asciinema.
  Drop the GIF here before the v1.0.0 release.

  ![shelve demo](./demo.gif)
-->

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/D0NC0DE/shelve/main/install.sh -o install.sh && bash install.sh
```

The installer will:
- Check for Xcode CLI tools (required by Homebrew)
- Install Homebrew if it's not present
- Install [gum](https://github.com/charmbracelet/gum) (the interactive UI library shelve uses)
- Clone shelve to `~/.shelve/tool/`
- Add shelve to your PATH in `~/.zshrc` or `~/.bashrc`

Restart your terminal, then run `shelve help`.

---

## Quick start

### Back up your current Mac

```bash
shelve save
```

Scans your Mac. Shows interactive checkboxes for each category. Copies selected dotfiles to `~/.shelve/dotfiles/`. Writes `~/.shelve/shelve.json`.

### Restore on a new Mac

```bash
shelve restore
```

Reads `~/.shelve/shelve.json`. Lets you pick what to install. Installs everything with progress spinners. Skips already-installed packages automatically.

### Set up a brand new Mac with no backup

```bash
shelve fresh
```

Interactive wizard. Pick your developer type, browser, terminal, editor, languages, CLI tools, and databases. Installs everything. Optionally saves the result to `shelve.json` for next time.

---

## Why not just use Migration Assistant?
 
Migration Assistant clones your entire machine — including years of accumulated cruft, old configs, and apps you forgot you had. Most developers setting up a new Mac want a clean start, not a copy.
 
There are also situations where it simply isn't an option:
 
- Your old Mac was stolen, sold, or wiped before you set up the new one
- Intel → Apple Silicon migrations are notoriously messy — starting clean is often safer
- Company-issued Mac where IT hands you a fresh machine
- You want to share a standard setup with a new hire on your team
- You're setting up a second Mac alongside your existing one
 
shelve gives you a curated, version-controlled snapshot of exactly what you want to carry forward — interactive checkboxes, nothing forced.
 
---

## What gets backed up

| Category | What's included |
|---|---|
| **Homebrew formulae** | Everything from `brew list --formula` |
| **Homebrew casks** | Everything from `brew list --cask` |
| **Manual apps** | Apps in `/Applications` not managed by Homebrew |
| **Dotfiles** | `~/.zshrc`, `~/.gitconfig`, `~/.config/nvim`, `~/.ssh/config`, and more |
| **Roles** | Your browser, terminal, editor, and CLI editor |
| **System info** | macOS version, architecture, shell |

### What is NOT backed up

- SSH private keys (`~/.ssh/id_*`) — never, under any circumstances
- `.env` files or any file containing passwords, tokens, or API keys
- System apps (Safari, Finder, Mail, etc.)
- App Store purchase history

shelve will warn you if a selected dotfile might contain secrets before saving it.

---

## shelve.json

```json
{
  "version": "1.0",
  "saved_at": "2026-04-11T14:01:14Z",
  "system": {
    "macos": "15.4",
    "arch": "arm64",
    "shell": "zsh"
  },
  "roles": {
    "browser": "Brave Browser",
    "terminal": "Ghostty",
    "editor": "Cursor",
    "cli_editor": "neovim"
  },
  "brews": ["git", "node", "gh", "lazygit"],
  "casks": ["tableplus", "ngrok"],
  "manual_apps": ["Android Studio", "Figma"],
  "dotfiles": ["~/.zshrc", "~/.gitconfig", "~/.config/nvim"],
  "manual_installs": ["nvm", "rust (rustup)"]
}
```

`shelve.json` is designed to be public — it contains only package names and role names, never credentials.

---

## Sharing config between machines

1. Run `shelve save` on your current Mac
2. Copy `~/.shelve/` to a **private** GitHub repo (shelve can do this for you if `gh` is installed)
3. On the new Mac: install shelve, clone your private repo to `~/.shelve/`, run `shelve restore`

The dotfile contents are backed up in `~/.shelve/dotfiles/`. Include this directory in your private repo to restore them on the new machine.

> **Keep `~/.shelve/dotfiles/` in a private repo.** It contains the actual contents of your config files. `shelve.json` alone is safe to make public.

---

## Security

- `shelve.json` contains only package names and role names — no credentials
- Dotfile contents live in `~/.shelve/dotfiles/` — **never put this in a public repo**
- shelve warns before backing up files that may contain secrets (`password`, `token`, `key`, `secret`)
- SSH private keys are never backed up under any circumstances
- The install script is downloaded before it runs — you can inspect it first: `curl -fsSL <url> -o install.sh && less install.sh`

---

## Requirements

- macOS Monterey (12) or later
- Homebrew — the installer will offer to install it
- [gum](https://github.com/charmbracelet/gum) — installed automatically by the bootstrap

Works on both Apple Silicon (arm64) and Intel (x86_64) Macs.

---

## Commands

```
shelve save       capture your current Mac setup
shelve restore    restore from a saved config
shelve fresh      spin up a brand new Mac from zero
shelve help       show this help
```

---

## Roadmap

shelve is at v0.1.0. The core three commands are stable. Coming next:

- **v0.2.0** — `shelve uninstall`, Mac App Store support, expanded manual install detection, secrets warning on dotfiles, git config + SSH key setup in `shelve fresh`
- **v0.3.0** — `shelve sync` to push/pull config via a private GitHub repo
- **v0.4.0** — `shelve diff`, `shelve status`, `shelve log`
- **v1.0.0** — `shelve update`, `shelve export`, `shelve doctor`, team presets

See [ROADMAP.md](ROADMAP.md) for the full plan.

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b my-feature`
3. Make your changes (scripts live in `lib/`)
4. Test: `bash shelve save`, `bash shelve restore`, `bash shelve fresh`
5. Open a pull request

All scripts must work with **bash 3.2** — the version shipped with macOS. No bash 4+ features.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

---

## License

MIT