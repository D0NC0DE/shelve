# Roadmap

shelve is an open-source macOS CLI tool that backs up, restores, and sets up your developer environment. This roadmap outlines what's been built, what's coming, and where the project is headed.

Features are grouped by phase. Contributions are welcome at any phase — see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Current — v0.1.0

The core three commands are stable and working.

| Feature | Status |
|---|---|
| `shelve save` — scan Mac, interactive checkboxes, write `shelve.json` | ✅ Done |
| `shelve restore` — read config, interactive checkboxes, install everything | ✅ Done |
| `shelve fresh` — wizard for brand new Mac with no existing backup | ✅ Done |
| `shelve help` — usage and command reference | ✅ Done |
| One-liner install via `curl` | ✅ Done |
| GitHub Actions CI — clean macOS install test on every push | ✅ Done |
| Homebrew formulae — save and restore | ✅ Done |
| Homebrew casks — save and restore | ✅ Done |
| Dotfiles backup and restore | ✅ Done |
| Manual apps detection and listing | ✅ Done |
| Role detection — browser, terminal, editor | ✅ Done |

---

## v0.2.0 — Completeness

Filling the gaps in what's already there. These are small, focused, and high value.

### `shelve uninstall`
Clean removal of shelve from any machine.
- `shelve uninstall` — removes the tool directory, strips PATH from rc file, leaves `shelve.json` intact
- `shelve uninstall --purge` — removes everything including config and dotfile backups
- Confirms before doing anything destructive

### Mac App Store support
App Store apps are completely invisible to Homebrew. When switching Macs, they're the first thing people forget.
- Detect installed App Store apps via `mas list` during `shelve save`
- Save app names and IDs to `shelve.json`
- Restore via `mas install <id>` during `shelve restore`
- Warn gracefully if `mas` is not installed, with instructions to install it

### Git config setup in `shelve fresh`
Developers consistently forget this. Commits end up attributed to "unknown" for weeks.
- Ask for name, email, and preferred default branch during `shelve fresh`
- Write `~/.gitconfig` automatically
- Skip if already configured

### SSH key setup in `shelve fresh`
Not backing up the private key — generating a new one correctly and wiring it to GitHub.
- Generate a new SSH key with a sensible default path
- Copy public key to clipboard automatically
- Open GitHub SSH settings page in the browser
- Guide the user through the final step

### Secrets warning on dotfile selection
Shelve should warn before backing up files that may contain sensitive data.
- Scan selected dotfiles for common secret patterns (`API_KEY`, `TOKEN`, `PASSWORD`, `SECRET`)
- Warn the user and ask for confirmation before including flagged files
- SSH private keys (`~/.ssh/id_*`) are always excluded — no override

---

## v0.3.0 — Sync

Making shelve useful across multiple Macs — the most common real-world scenario for developers.

### `shelve sync push`
Push the current config to a private GitHub repo or Gist.
- Authenticates via `gh` CLI (already a recommended tool)
- Pushes `shelve.json` and `~/.shelve/dotfiles/` to a configured private repo
- No shelve server involved — GitHub is the backend
- Works with any private repo the user controls

### `shelve sync pull`
Pull config from GitHub and prepare for restore.
- Pulls latest `shelve.json` and dotfiles from the configured repo
- Prompts to run `shelve restore` after pulling
- Handles merge conflicts by showing a diff and asking the user to choose

### `shelve sync status`
Show whether the local config is ahead or behind the remote.
- Compares local `shelve.json` with remote
- Shows last synced date and which machine pushed it

### Multi-machine awareness
- `shelve.json` optionally stores a machine name/identifier
- `shelve sync` can push per-machine configs and pull a merged view
- Useful for developers who have different setups on different machines

---

## v0.4.0 — Visibility

Giving developers insight into their environment over time.

### `shelve diff`
Like `git status` for your Mac. No other tool does this.
- Compares current installed packages against saved `shelve.json`
- Shows what's been added since last save (new packages to consider tracking)
- Shows what's missing (packages in config not currently installed)
- Clean, actionable output — not a wall of text

### `shelve status`
A quick health check of the current machine against the saved config.
- Shows save date, machine info, counts of each category
- Highlights drift at a glance
- Good for running after a long period without saving

### `shelve log`
History of save operations.
- Tracks when `shelve save` was last run
- Shows what changed between saves
- Stored locally in `~/.shelve/history/`

---

## v0.5.0 — Developer Experience

Making `shelve fresh` more complete and opinionated for developers.

### macOS system settings
Every developer setup guide covers the same settings. Shelve can apply them in one step.
- Fast key repeat speed
- Show hidden files in Finder
- Show full path bar in Finder footer
- Disable autocorrect and auto-capitalise
- Reduce Dock auto-hide delay
- Set screenshot format to JPG
- Disable the startup chime (optional)
- All opt-in — presented as a checklist, nothing forced

### Nerd Fonts in `shelve fresh`
Every terminal setup needs a Nerd Font. Everyone forgets which one they used.
- Offer a curated selection during `shelve fresh`
- Install via Homebrew cask
- Popular options: Hack, JetBrains Mono, FiraCode, Meslo

### Shell plugins in `shelve fresh`
Common shell enhancements developers install manually every time.
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- Powerlevel10k theme
- Each opt-in individually

### Node version manager improvement
Current implementation installs nvm but requires manual follow-up.
- Automatically run `nvm install --lts` after installing nvm
- Optionally ask which Node version to install
- Same improvement for pyenv — ask which Python version to install

---

## v1.0.0 — Stable and Shareable

Polishing everything to a point that's production-ready for public use.

### `shelve update`
Update everything tracked in `shelve.json` in one command.
- Runs `brew upgrade` on all tracked formulae and casks
- Shows what was updated, what failed, what was skipped
- Respects the saved config — only upgrades tracked packages

### `shelve export`
Get your config out in formats other tools understand.
- `shelve export --brewfile` — exports as a standard `Brewfile`
- `shelve export --script` — exports as a plain shell script with no shelve dependency
- Makes it easy to share with people who don't use shelve

### `shelve doctor`
Diagnose common setup issues.
- Checks that all saved packages are still installed
- Checks that dotfile symlinks (if any) are not broken
- Checks that `gh`, `mas`, `gum` are installed
- Suggests fixes for any issues found

### Team presets
Share a setup with a team without any server or account.
- New hire runs `shelve restore --from <url>` where the URL points to a raw `shelve.json`
- Works with GitHub Gists, private repos, or any public URL
- Useful for onboarding — no account or service required
- Opt-in — personal installs are completely unaffected

### Vanity install URL
Replace the raw GitHub URL with a clean domain.
- `curl -fsSL https://get.yourdomain.com/shelve -o install.sh && bash install.sh`
- One redirect rule on an existing domain — no new infrastructure

### README and documentation
- Full README with animated terminal demo (built with VHS or asciinema)
- Clear quickstart for all three commands
- Contribution guide
- Security policy

---

## Backlog — Ideas and Nice to Haves

Not committed to any version. Good ideas worth tracking.

| Idea | Notes |
|---|---|
| `shelve schedule` | Auto-run `shelve save` on a schedule via launchd |
| App version pinning | Save and restore specific versions of packages, not just latest |
| Plugin system | Let users define custom detect/save/restore scripts for tools shelve doesn't know about |
| Fish shell support | Currently zsh and bash only |
| Restore dry-run | `shelve restore --dry-run` shows what would be installed without doing it |
| Config validation | `shelve validate` checks `shelve.json` is well-formed before restore |
| Rollback | Undo the last restore if something went wrong |
| Brew tap support | Save and restore custom Homebrew taps |
| VS Code extensions | Save and restore editor extensions alongside packages |
| Shell aliases backup | Capture custom aliases from `.zshrc` as a named category |

---

## Won't Build

Out of scope — intentionally.

| | Reason |
|---|---|
| SSH private key backup | Security. Private keys never leave the machine. |
| `.env` file backup | Security. Secret files are never backed up, even if selected. |
| Linux support | macOS only. Out of scope for now. |
| Web dashboard or accounts | shelve is local-first. No server, no account, no third-party trust required. |
| GUI app | Terminal tool. Always. |
| Windows support | macOS only. No plans to change this. |

---

## Contributing

If you want to work on something from this roadmap, open an issue first so we can discuss approach before you start building. All contributions must work with bash 3.2 — the version shipped with macOS — and follow the patterns established in `lib/`.

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.
