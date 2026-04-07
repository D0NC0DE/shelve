#!/usr/bin/env bash
# =============================================================================
# detect.sh — scans the current Mac and reports what is installed
# Never installs anything — read only
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"

# -----------------------------------------------------------------------------
# HOMEBREW FORMULAE
# -----------------------------------------------------------------------------
detect_brews() {
  if ! command_exists brew; then
    log_warn "Homebrew not found — skipping formula detection"
    return
  fi
  brew list --formula 2>/dev/null
}

# -----------------------------------------------------------------------------
# HOMEBREW CASKS
# -----------------------------------------------------------------------------
detect_casks() {
  if ! command_exists brew; then
    log_warn "Homebrew not found — skipping cask detection"
    return
  fi
  brew list --cask 2>/dev/null
}

# -----------------------------------------------------------------------------
# MAC APP STORE
# -----------------------------------------------------------------------------
detect_mas_apps() {
  if ! command_exists mas; then
    log_dim "mas not installed — App Store apps won't be captured"
    log_dim "To enable: brew install mas"
    return
  fi
  mas list 2>/dev/null
}

# -----------------------------------------------------------------------------
# MANUAL APPS
# Apps in /Applications not managed by brew cask or mas
# We build two exclusion lists then filter — no fuzzy matching, no loops
# -----------------------------------------------------------------------------
detect_manual_apps() {
  # System apps to always skip
  local -a system_apps=(
    "safari" "finder" "mail" "calendar" "reminders" "notes" "maps"
    "photos" "facetime" "messages" "music" "podcasts" "tv" "books"
    "news" "stocks" "weather" "calculator" "dictionary" "automator"
    "preview" "textedit" "font book" "system preferences"
    "system settings" "app store" "xcode" "activity monitor"
    "disk utility" "terminal" "time machine" "migration assistant"
    "freeform" "shortcuts" "home" "voice memos" "screen sharing"
    "utilities" "developer" "python 3.10" "python 3.11"
    "python 3.12" "python 3.13" "smart switch"
  )

  # Build exclusion list from mas — just app names, lowercased
  local mas_names=""
  if command_exists mas; then
    mas_names=$(mas list 2>/dev/null |
      awk '{$1=""; print $0}' |
      sed 's/^ //' |
      sed 's/ (.*//' |
      tr '[:upper:]' '[:lower:]')
  fi

  # Build exclusion list from brew casks
  # Convert cask names to app-like names: brave-browser → brave browser
  local cask_names=""
  if command_exists brew; then
    cask_names=$(brew list --cask 2>/dev/null |
      sed 's/-/ /g' |
      tr '[:upper:]' '[:lower:]')
  fi

  # Scan /Applications — use /bin/ls to bypass any aliases
  /bin/ls -1 /Applications 2>/dev/null |
    sed 's|[/@*]$||' |
    grep '\.app$' |
    sed 's/\.app$//' |
    sort |
    while IFS= read -r app; do
      local lower
      lower=$(echo "$app" | tr '[:upper:]' '[:lower:]')

      # Check system apps
      local skip=0
      for s in "${system_apps[@]}"; do
        if [[ "$lower" == "$s" ]]; then
          skip=1
          break
        fi
      done
      [[ $skip -eq 1 ]] && continue

      # Check mas — exact match
      if echo "$mas_names" | grep -qx "$lower" 2>/dev/null; then
        continue
      fi

      # Check casks — compare lowercased app name against
      # cask names with dashes replaced by spaces
      if echo "$cask_names" | grep -qx "$lower" 2>/dev/null; then
        continue
      fi

      echo "$app"
    done
}

# -----------------------------------------------------------------------------
# DOTFILES
# -----------------------------------------------------------------------------
detect_dotfiles() {
  local candidates=(
    "${HOME}/.zshrc"
    "${HOME}/.zshenv"
    "${HOME}/.zprofile"
    "${HOME}/.bashrc"
    "${HOME}/.gitconfig"
    "${HOME}/.gitignore_global"
    "${HOME}/.ssh/config"
    "${HOME}/.config/nvim"
    "${HOME}/.config/ghostty"
    "${HOME}/.config/alacritty"
    "${HOME}/.config/kitty"
    "${HOME}/.config/starship.toml"
    "${HOME}/.config/tmux"
    "${HOME}/.tmux.conf"
    "${HOME}/.config/zed"
    "${HOME}/.tool-versions"
    "${HOME}/.npmrc"
  )

  for item in "${candidates[@]}"; do
    if [[ -f "$item" ]] || [[ -d "$item" ]]; then
      echo "${item/#$HOME/~}"
    fi
  done
}

# -----------------------------------------------------------------------------
# VERSIONS
# -----------------------------------------------------------------------------
detect_versions() {
  printf "shell=%s\n" "$(basename "$SHELL")"
  printf "macos=%s\n" "$(sw_vers -productVersion 2>/dev/null)"
  printf "arch=%s\n" "$(uname -m)"

  if command_exists pyenv; then
    printf "python_manager=pyenv\n"
    printf "python_version=%s\n" "$(pyenv version-name 2>/dev/null)"
  elif command_exists python3; then
    printf "python_version=%s\n" \
      "$(python3 --version 2>&1 | awk '{print $2}')"
  fi

  if command_exists node; then
    printf "node_version=%s\n" "$(node --version | sed 's/v//')"
  fi

  if command_exists git; then
    printf "git_user=%s\n" "$(git config --global user.name 2>/dev/null)"
    printf "git_email=%s\n" "$(git config --global user.email 2>/dev/null)"
  fi
}

# -----------------------------------------------------------------------------
# ROLES
# -----------------------------------------------------------------------------
detect_roles() {
  local browser="none"
  for b in "Brave Browser" "Google Chrome" "Firefox" "Arc" "Opera"; do
    if app_installed "$b"; then
      browser="$b"
      break
    fi
  done
  printf "browser=%s\n" "$browser"

  local terminal="none"
  for t in "Ghostty" "iTerm" "Warp" "Alacritty" "kitty" "Hyper"; do
    if app_installed "$t"; then
      terminal="$t"
      break
    fi
  done
  printf "terminal=%s\n" "$terminal"

  local editor="none"
  for e in "Cursor" "Zed" "Visual Studio Code" "Sublime Text"; do
    if app_installed "$e"; then
      editor="$e"
      break
    fi
  done
  printf "editor=%s\n" "$editor"

  if command_exists nvim; then
    printf "cli_editor=neovim\n"
  elif command_exists vim; then
    printf "cli_editor=vim\n"
  fi
}

# -----------------------------------------------------------------------------
# DETECT ALL
# -----------------------------------------------------------------------------
detect_all() {
  log_step "Scanning your Mac"
  divider

  log_info "Homebrew formulae"
  detect_brews | while IFS= read -r p; do log_dim "$p"; done

  log_info "Casks"
  detect_casks | while IFS= read -r p; do log_dim "$p"; done

  log_info "App Store apps"
  detect_mas_apps | while IFS= read -r p; do log_dim "$p"; done

  log_info "Manual apps"
  detect_manual_apps | while IFS= read -r p; do log_dim "$p"; done

  log_info "Dotfiles"
  detect_dotfiles | while IFS= read -r p; do log_dim "$p"; done

  log_info "Versions"
  detect_versions | while IFS= read -r p; do log_dim "$p"; done

  log_info "Roles"
  detect_roles | while IFS= read -r p; do log_dim "$p"; done

  divider
}
