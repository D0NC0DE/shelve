# shelve

**shelf your setup** — back up, restore, or start fresh on any Mac.

shelve is a macOS CLI tool that captures your developer environment — Homebrew packages, apps, dotfiles, and roles — into a single `shelve.json` file you can commit, share, or carry to a new machine. No Node, Python, or Go required. Just bash.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/winnerolusola/shelve/main/install.sh | bash
```

Restart your terminal, then run `shelve help`.

---

## Quick start

### Back up your current Mac

```bash
shelve save
```

Scans your Mac, shows interactive checkboxes for each category, copies selected dotfiles to `~/.shelve/dotfiles/`, and writes `~/.shelve/shelve.json`.

### Restore on a new Mac

```bash
shelve restore
```

Reads `~/.shelve/shelve.json`, lets you pick what to install, then installs everything with progress spinners. Skips already-installed packages automatically.

### Set up a brand new Mac with no backup

```bash
shelve fresh
```

Interactive wizard — pick your developer type, browser, terminal, editor, languages, CLI tools, and databases. Installs everything, then optionally saves the setup to `shelve.json` for next time.

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

- SSH private keys (`~/.ssh/id_*`)
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
  "dotfiles": ["~/.zshrc", "~/.gitconfig", "~/.config/nvim"]
}
```

`shelve.json` is designed to be public — it contains no secrets.

---

## Sharing config between machines

1. Run `shelve save` on your current Mac
2. Push `~/.shelve/shelve.json` to a **private** GitHub repo (shelve can do this for you if `gh` is installed)
3. On the new Mac: install shelve, clone your private repo, then run `shelve restore`

For dotfiles, the actual file contents are backed up to `~/.shelve/dotfiles/` — include this directory in your private repo to restore them on the new machine.

---

## Security

- `shelve.json` contains only package names and role names — no credentials
- Dotfile contents are stored locally in `~/.shelve/dotfiles/` — **do not put this in a public repo**
- shelve warns before backing up files that may contain secrets (`password`, `token`, `key`, `secret`)
- SSH private keys are never backed up under any circumstances

---

## Requirements

- macOS Monterey (12) or later
- Homebrew (shelve's installer will offer to install it)
- [gum](https://github.com/charmbracelet/gum) — installed automatically by the bootstrap

Works on both Apple Silicon and Intel Macs.

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b my-feature`
3. Make your changes (scripts are in `lib/`)
4. Test: `bash shelve save`, `bash shelve restore`, `bash shelve fresh`
5. Open a pull request

All scripts must work with bash 3.2 (the version shipped with macOS) — no bash 4+ features.

---

## License

MIT
