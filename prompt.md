I am building a public open-source macOS CLI tool called "shelve" — 
a developer tool that helps back up and restore a Mac setup. The 
tagline is "shelf your setup".

The project is written in shell script for maximum compatibility 
(no Node, Python, or Go required — just bash which every Mac has).

## Project structure
shelve/
├── shelve          ← entry point, chmod +x
├── install.sh      ← one-liner bootstrap for new users
├── README.md
└── lib/
    ├── utils.sh    ← colours, logging, helpers
    ├── detect.sh   ← scans current Mac (read only)
    ├── menu.sh     ← interactive UI using gum
    ├── save.sh     ← shelve save command
    ├── restore.sh  ← shelve restore command
    └── fresh.sh    ← shelve fresh command (not started yet)

## Three commands
- `shelve save`    — scans current Mac, user selects what to 
                     track via checkboxes, writes shelve.json 
                     to ~/.shelve/shelve.json
- `shelve restore` — reads shelve.json, user selects what to 
                     install via checkboxes with start-over 
                     option, installs everything
- `shelve fresh`   — for someone who never had shelve, brand 
                     new Mac, interactive wizard that asks 
                     what kind of developer they are and 
                     installs common tools

## What shelve saves in shelve.json
- Homebrew formulae (brew list --formula)
- Homebrew casks (brew list --cask)
- Manual apps — everything in /Applications not from brew 
  (shown to user on restore as "download these yourself")
- Dotfiles — ~/.zshrc, ~/.gitconfig, ~/.config/nvim, 
  ~/.config/ghostty, ~/.ssh/config etc.
- Roles — browser (Brave, Chrome etc), terminal (Ghostty, 
  iTerm etc), editor (Cursor, VSCode etc), cli_editor (neovim)
- System info — macos version, arch, shell

## shelve.json structure
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
  "brews": ["git","node","python@3.12","gh","lazygit"],
  "casks": ["tableplus","ngrok"],
  "manual_apps": ["Android Studio","Docker","Figma"],
  "dotfiles": ["~/.zshrc","~/.gitconfig","~/.config/nvim"]
}

## UI library
We use gum by Charmbracelet for the interactive UI.
Install: brew install gum

IMPORTANT BUG: gum 0.17.0 conflicts with a BOLD environment 
variable that zsh sets. Fix by wrapping gum in a function:
  gum() { env -u BOLD command gum "$@"; }
Put this in utils.sh.

The UI should feel premium and intentional. Use gum's full
feature set:
- gum spin for all installs — never let the screen look frozen
- gum choose for all selections with --no-limit --selected="*"
- gum confirm for yes/no prompts
- gum input for any text input needed
- gum style for styled headers and section titles
- gum table if displaying structured data like app lists
- Clear section headers between each step
- Progress indication — user should always know what is 
  happening and what is coming next
- Errors should be visible and actionable, not buried

## Key technical decisions
1. Scripts run in bash (#!/usr/bin/env bash), NOT zsh
   - Always test with: bash shelve save
   - Never source lib files directly in zsh for testing
   
2. set -eo pipefail in the shelve entry point
   - Do NOT use -u (unset variable flag) — bash 3.2 on Mac 
     treats empty arrays as unset which causes crashes
   
3. Logging functions in utils.sh:
   - log_info, log_success go to stdout
   - log_warn, log_error go to stderr (>&2)
   - Inside menu functions, ALL log calls must use >&2 so 
     only selected items go to stdout for capture

4. JSON parsing without jq — parse shelve.json with grep/sed:
   parse_json_array() greps for "^  \"key\":" anchored to 
   line start to avoid collisions between similar key names

5. Array scoping — bash functions don't share scope. 
   Global arrays declared at top of restore.sh:
   brews=() casks=() manual=() dotfiles=()
   selected_brews=() selected_casks=() 
   selected_manual=() selected_dotfiles=()

6. The final gum choose (confirm/start over/abort) must use 
   < /dev/tty because stdin is consumed by the previous 
   gum pipes:
   choice=$(gum choose "Start install" "Start over" "Abort" \
     --header="What would you like to do?" < /dev/tty)

7. brew_package_installed and brew_cask_installed are in 
   utils.sh — check before installing to skip already 
   installed packages

8. Manual apps detection uses /bin/ls (not lsd alias) with 
   -1 flag, strips trailing / @ * characters that lsd adds

9. Dotfiles backup — save.sh MUST copy selected dotfiles 
   to ~/.shelve/dotfiles/ before writing shelve.json. 
   restore.sh reads from ~/.shelve/dotfiles/ to restore.
   THIS IS NOT IMPLEMENTED YET.

## Current known bugs to fix first
1. install_brews runs twice in restore.sh — the while true 
   loop in cmd_restore is looping twice before breaking. 
   Debug the run_selections return code.

2. brew_package_installed fails inside install_brews even 
   though it works standalone — the pkg variable likely has 
   whitespace or invisible characters attached. Strip it:
   pkg=$(echo "$pkg" | tr -d '[:space:]')

3. Dotfile backup not implemented in save.sh — after user 
   selects dotfiles, copy each one to ~/.shelve/dotfiles/ 
   before writing shelve.json. For directories like 
   ~/.config/nvim use cp -r.

## Full feature list — implement all of these

### shelve save
- Scan Mac for: brews, casks, manual apps, dotfiles, roles
- Show scan results summary before selection menus
- Interactive checkbox menus for each category
- Mark items that might be duplicates across categories
  (e.g. an app in both manual and already tracked by cask)
- Copy selected dotfiles to ~/.shelve/dotfiles/
- Write shelve.json
- Ask if they want to push to a private GitHub repo
  (use gh CLI if available, guide them if not)
- Show final summary of what was saved

### shelve restore  
- Read shelve.json — fail clearly if not found with 
  instructions on how to get it
- Show saved setup summary (roles, counts per category, 
  date saved, mac it was saved from)
- Interactive menus — select what to install this time
- Start over option if user made a mistake
- Confirm screen showing exactly what will be installed
- Install with gum spin progress per item
- Show already-installed items as skipped (not errors)
- Manual apps section — show as a list with checkboxes, 
  for each selected app attempt to find and open the 
  download URL automatically:
    * Check if a Homebrew cask exists for it: 
      brew search --cask "appname" 
      If found, offer to install via brew instead
    * If no cask, search for it with open command:
      open "https://www.google.com/search?q=download+appname+mac"
    * User can also mark it as "already installed" to skip
- Restore dotfiles from ~/.shelve/dotfiles/
- Final summary — what installed, what failed, what was skipped
- Log output to ~/.shelve/restore.log

### shelve fresh (brand new Mac, no backup needed)
- Welcome screen explaining what fresh does
- Ask developer type:
    * Web / Frontend
    * Backend / DevOps  
    * Data / ML
    * Mobile (iOS/Android)
    * General / Not sure
- Based on type, pre-select relevant tools but let user 
  customise everything
- Pick browser: Brave, Chrome, Firefox, Arc, Safari (skip)
- Pick terminal: Ghostty, iTerm2, Warp, Alacritty, skip
- Pick editor: Cursor, Zed, VS Code, Neovim+LazyVim, skip
- Pick shell extras: oh-my-zsh, starship prompt, both, skip
- Pick languages (multi-select):
    * Python (via pyenv)
    * Node (via nvm)  
    * Go
    * Rust
    * Ruby
    * Java
- Pick tools (multi-select based on developer type):
    * git (always included, can't deselect)
    * gh (GitHub CLI)
    * docker
    * lazygit
    * fzf
    * ripgrep
    * tmux
    * wget / curl
    * tree
    * htop
- Pick databases (multi-select):
    * PostgreSQL
    * MySQL
    * Redis
    * MongoDB
    * SQLite
- Pick productivity apps (multi-select):
    * Raycast
    * Rectangle (window manager)
    * Alfred
    * Notion
    * Obsidian
- Confirm screen with full list of everything that will install
- Install with gum spin progress
- At end ask: "Save this setup to shelve.json for next time?"
  If yes, write shelve.json so they can use shelve restore later

### shelve help
- Show banner
- Show all commands with descriptions
- Show current config location if it exists
- Show version

## Manual app install improvement
When a manual app is selected during restore, shelve should:
1. Check if a Homebrew cask exists:
   brew search --casks "$app" 2>/dev/null | grep -i "$app"
   If found: "Found '$app' as a Homebrew cask — install 
   automatically instead?" → brew install --cask
2. If no cask found, open browser to download page:
   open "https://www.google.com/search?q=${app}+download+mac+official"
3. User can also select "already have it" to skip
This turns manual apps from "figure it out yourself" into 
a guided experience.

## Security rules — never violate these
- Never store SSH private keys (~/.ssh/id_* files)
- Never store files containing passwords or API keys
- .env files should never be backed up
- shelve.json can be public — it should contain no secrets
- Warn user if any selected dotfile might contain secrets:
  grep -l "password\|secret\|token\|key\|api" in selected files
  Show warning: "This file may contain secrets — are you sure?"

## install.sh — one-liner bootstrap
curl -fsSL https://raw.githubusercontent.com/USER/shelve/main/install.sh | bash

Should:
1. Check macOS (exit clearly if not Mac)
2. Check/install Xcode CLI tools
3. Check/install Homebrew (ask first)
4. Install gum via brew
5. Clone shelve repo to ~/.shelve/tool/
6. Add shelve to PATH by appending to ~/.zshrc and ~/.bashrc
7. Print success message with next steps

## README.md should include
- What shelve is (1 paragraph)
- The one-liner install command prominently at top
- Quick start: save, restore, fresh with examples
- What gets backed up and what doesn't
- Security section — what is and isn't stored
- How to share config between machines
- Contributing section
- License (MIT)

## Code quality requirements
- Every function must have a comment explaining what it does
- Error messages must be actionable — tell user what to do, 
  not just what went wrong
- All installs must show progress — never silent
- Test each command works before moving to the next
- The tool must work on both Intel and Apple Silicon Macs
- Must work on macOS Monterey (12) and above
- Must work with bash 3.2 (ships with Mac) — no bash 4+ features
  Specifically: no -n nameref, no associative arrays (declare -A),
  guard all array expansions against empty arrays

## Testing checklist for Claude Code
After writing each file, test it:
- bash shelve help
- bash shelve save (go through full flow)
- cat ~/.shelve/shelve.json (verify clean JSON)
- bash shelve restore (go through full flow)
- bash shelve fresh (go through full flow)
- bash install.sh (test bootstrap)

## Current files
All files exist at:
~/don/personal/portfolio/projects/shelve/

The developer (Yonko) uses:
- LazyVim as editor
- Ghostty terminal  
- Brave browser
- Apple Silicon Mac (arm64)
- zsh as default shell
- The project is PUBLIC on GitHub
- Personal config will be in a SEPARATE private repo
