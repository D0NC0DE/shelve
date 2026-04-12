#!/usr/bin/env bash
# =============================================================================
# fresh.sh — interactive wizard for setting up a brand new Mac from scratch
# No backup needed — just answer questions and shelve installs everything
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"

# =============================================================================
# INSTALL HELPERS
# =============================================================================

# Install a brew formula with a gum spinner, skip if already installed
fresh_install_brew() {
  local pkg="$1"
  if brew_package_installed "$pkg"; then
    log_dim "$pkg already installed"
  else
    if gum spin --spinner dot --title "Installing $pkg..." \
        -- brew install "$pkg" 2>/dev/null; then
      log_success "$pkg"
    else
      log_warn "Failed to install $pkg"
    fi
  fi
}

# Install a brew cask with a gum spinner, skip if already installed
fresh_install_cask() {
  local cask="$1"
  if brew_cask_installed "$cask"; then
    log_dim "$cask already installed"
  else
    if gum spin --spinner dot --title "Installing $cask..." \
        -- brew install --cask "$cask" 2>/dev/null; then
      log_success "$cask"
    else
      log_warn "Failed to install $cask"
    fi
  fi
}

# =============================================================================
# PICK DEVELOPER TYPE
# =============================================================================

# Ask what kind of developer the user is — used to pre-select relevant tools
pick_dev_type() {
  log_step "What kind of developer are you?"
  gum choose \
    "Web / Frontend" \
    "Backend / DevOps" \
    "Data / ML" \
    "Mobile (iOS / Android)" \
    "General / Not sure" \
    --header="Pick the closest match — you can customise everything next:"
}

# =============================================================================
# PICK BROWSER
# =============================================================================

pick_browser() {
  log_step "Pick your browser"
  gum choose \
    "Brave" \
    "Chrome" \
    "Firefox" \
    "Arc" \
    "Skip" \
    --header="Which browser do you want?"
}

# =============================================================================
# PICK TERMINAL
# =============================================================================

pick_terminal() {
  log_step "Pick your terminal"
  gum choose \
    "Ghostty" \
    "iTerm2" \
    "Warp" \
    "Alacritty" \
    "Skip" \
    --header="Which terminal emulator do you want?"
}

# =============================================================================
# PICK EDITOR
# =============================================================================

pick_editor() {
  log_step "Pick your editor"
  gum choose \
    "Cursor" \
    "Zed" \
    "VS Code" \
    "Neovim + LazyVim" \
    "Skip" \
    --header="Which editor do you want?"
}

# =============================================================================
# PICK SHELL EXTRAS
# =============================================================================

pick_shell_extras() {
  log_step "Shell extras"
  gum choose \
    "oh-my-zsh" \
    "starship prompt" \
    "Both" \
    "Skip" \
    --header="Any shell enhancements?"
}

# =============================================================================
# PICK LANGUAGES
# =============================================================================

# Returns selected language install targets, one per line
pick_languages() {
  log_step "Languages"
  log_dim "Space to toggle, enter to confirm" >&2

  printf '%s\n' \
    "Python (via pyenv)" \
    "Node (via nvm)" \
    "Go" \
    "Rust" \
    "Ruby" \
    "Java" |
  gum choose --no-limit \
    --header="Which languages do you work with?"
}

# =============================================================================
# PICK TOOLS
# =============================================================================

# Builds a default selection based on dev type and presents it to the user
pick_tools() {
  local dev_type="$1"

  # git is always in — but we include it here so users can see it's included
  local all_tools=(
    "git"
    "gh"
    "docker"
    "lazygit"
    "fzf"
    "ripgrep"
    "tmux"
    "wget"
    "tree"
    "htop"
  )

  # Build a comma-separated pre-selection string based on dev type
  local preselect="git"
  case "$dev_type" in
  "Web / Frontend")
    preselect="git,gh,fzf,ripgrep"
    ;;
  "Backend / DevOps")
    preselect="git,gh,docker,lazygit,fzf,ripgrep,tmux,wget,htop"
    ;;
  "Data / ML")
    preselect="git,gh,fzf,ripgrep,wget,htop"
    ;;
  "Mobile (iOS / Android)")
    preselect="git,gh,fzf,ripgrep"
    ;;
  *)
    preselect="git,gh,fzf,ripgrep"
    ;;
  esac

  log_step "CLI tools"
  log_dim "Space to toggle, enter to confirm" >&2

  printf '%s\n' "${all_tools[@]}" |
    gum choose --no-limit \
      --selected="$preselect" \
      --header="Which CLI tools do you want?"
}

# =============================================================================
# PICK DATABASES
# =============================================================================

pick_databases() {
  log_step "Databases"
  log_dim "Space to toggle, enter to confirm" >&2

  printf '%s\n' \
    "PostgreSQL" \
    "MySQL" \
    "Redis" \
    "MongoDB" \
    "SQLite" |
  gum choose --no-limit \
    --header="Any databases? (skip with enter if none)"
}

# =============================================================================
# PICK PRODUCTIVITY APPS
# =============================================================================

pick_productivity() {
  log_step "Productivity apps"
  log_dim "Space to toggle, enter to confirm" >&2

  printf '%s\n' \
    "Raycast" \
    "Rectangle" \
    "Alfred" \
    "Notion" \
    "Obsidian" |
  gum choose --no-limit \
    --header="Any productivity apps?"
}

# =============================================================================
# INSTALL BROWSER
# =============================================================================

install_browser() {
  local choice="$1"
  case "$choice" in
  "Brave")   fresh_install_cask "brave-browser" ;;
  "Chrome")  fresh_install_cask "google-chrome" ;;
  "Firefox") fresh_install_cask "firefox" ;;
  "Arc")     fresh_install_cask "arc" ;;
  "Skip")    log_dim "Skipping browser" ;;
  esac
}

# =============================================================================
# INSTALL TERMINAL
# =============================================================================

install_terminal() {
  local choice="$1"
  case "$choice" in
  "Ghostty")   fresh_install_cask "ghostty" ;;
  "iTerm2")    fresh_install_cask "iterm2" ;;
  "Warp")      fresh_install_cask "warp" ;;
  "Alacritty") fresh_install_cask "alacritty" ;;
  "Skip")      log_dim "Skipping terminal" ;;
  esac
}

# =============================================================================
# INSTALL EDITOR
# =============================================================================

install_editor() {
  local choice="$1"
  case "$choice" in
  "Cursor")          fresh_install_cask "cursor" ;;
  "Zed")             fresh_install_cask "zed" ;;
  "VS Code")         fresh_install_cask "visual-studio-code" ;;
  "Neovim + LazyVim")
    fresh_install_brew "neovim"
    # LazyVim requires a starter config — clone it if nvim config doesn't exist
    if [[ ! -d "${HOME}/.config/nvim" ]]; then
      log_info "Setting up LazyVim starter config..."
      if gum spin --spinner dot --title "Cloning LazyVim starter..." \
          -- git clone https://github.com/LazyVim/starter \
             "${HOME}/.config/nvim" 2>/dev/null; then
        rm -rf "${HOME}/.config/nvim/.git"
        log_success "LazyVim starter config installed"
      else
        log_warn "Could not clone LazyVim starter — set it up manually"
      fi
    else
      log_dim "~/.config/nvim already exists, skipping LazyVim starter"
    fi
    ;;
  "Skip") log_dim "Skipping editor" ;;
  esac
}

# =============================================================================
# INSTALL SHELL EXTRAS
# =============================================================================

install_shell_extras() {
  local choice="$1"
  case "$choice" in
  "oh-my-zsh")
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
      log_dim "oh-my-zsh already installed"
    else
      if gum spin --spinner dot --title "Installing oh-my-zsh..." \
          -- sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
        log_success "oh-my-zsh installed"
      else
        log_warn "oh-my-zsh install failed"
      fi
    fi
    ;;
  "starship prompt")
    fresh_install_brew "starship"
    log_info "Add 'eval \"\$(starship init zsh)\"' to your ~/.zshrc"
    ;;
  "Both")
    install_shell_extras "oh-my-zsh"
    install_shell_extras "starship prompt"
    ;;
  "Skip") log_dim "Skipping shell extras" ;;
  esac
}

# =============================================================================
# INSTALL LANGUAGES
# =============================================================================

install_languages() {
  local languages=("$@")
  for lang in "${languages[@]}"; do
    case "$lang" in
    "Python (via pyenv)")
      fresh_install_brew "pyenv"
      log_info "Run 'pyenv install 3.12' to install Python 3.12"
      ;;
    "Node (via nvm)")
      if [[ ! -d "${HOME}/.nvm" ]]; then
        if gum spin --spinner dot --title "Installing nvm..." \
            -- bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash" 2>/dev/null; then
          log_success "nvm installed — restart terminal then run: nvm install --lts"
        else
          log_warn "nvm install failed"
        fi
      else
        log_dim "nvm already installed"
      fi
      ;;
    "Go")    fresh_install_brew "go" ;;
    "Rust")
      if ! command_exists rustup; then
        if gum spin --spinner dot --title "Installing Rust via rustup..." \
            -- bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" 2>/dev/null; then
          log_success "Rust installed"
        else
          log_warn "Rust install failed"
        fi
      else
        log_dim "rustup already installed"
      fi
      ;;
    "Ruby")  fresh_install_brew "rbenv" ;;
    "Java")  fresh_install_cask "temurin" ;;
    esac
  done
}

# =============================================================================
# INSTALL TOOLS
# =============================================================================

install_tools() {
  local tools=("$@")
  for tool in "${tools[@]}"; do
    case "$tool" in
    "git")     fresh_install_brew "git" ;;
    "gh")      fresh_install_brew "gh" ;;
    "docker")  fresh_install_cask "docker" ;;
    "lazygit") fresh_install_brew "lazygit" ;;
    "fzf")     fresh_install_brew "fzf" ;;
    "ripgrep") fresh_install_brew "ripgrep" ;;
    "tmux")    fresh_install_brew "tmux" ;;
    "wget")    fresh_install_brew "wget" ;;
    "tree")    fresh_install_brew "tree" ;;
    "htop")    fresh_install_brew "htop" ;;
    esac
  done
}

# =============================================================================
# INSTALL DATABASES
# =============================================================================

install_databases() {
  local dbs=("$@")
  for db in "${dbs[@]}"; do
    case "$db" in
    "PostgreSQL") fresh_install_brew "postgresql@16" ;;
    "MySQL")      fresh_install_brew "mysql" ;;
    "Redis")      fresh_install_brew "redis" ;;
    "MongoDB")    fresh_install_cask "mongodb-compass" && fresh_install_brew "mongosh" ;;
    "SQLite")     fresh_install_brew "sqlite" ;;
    esac
  done
}

# =============================================================================
# INSTALL PRODUCTIVITY
# =============================================================================

install_productivity() {
  local apps=("$@")
  for app in "${apps[@]}"; do
    case "$app" in
    "Raycast")   fresh_install_cask "raycast" ;;
    "Rectangle") fresh_install_cask "rectangle" ;;
    "Alfred")    fresh_install_cask "alfred" ;;
    "Notion")    fresh_install_cask "notion" ;;
    "Obsidian")  fresh_install_cask "obsidian" ;;
    esac
  done
}

# =============================================================================
# SAVE TO SHELVE.JSON
# Optionally persists the fresh setup so 'shelve restore' can use it later
# =============================================================================

save_fresh_to_json() {
  local browser="$1"
  local terminal_choice="$2"
  local editor_choice="$3"
  shift 3
  local tools=("$@")

  local macos arch shell_name cli_editor
  macos=$(sw_vers -productVersion 2>/dev/null)
  arch=$(uname -m)
  shell_name=$(basename "$SHELL")
  cli_editor="none"
  command_exists nvim && cli_editor="neovim"
  command_exists vim  && [[ "$cli_editor" == "none" ]] && cli_editor="vim"

  # Map display names to cask names for brews/casks arrays
  local casks_list=()
  case "$browser" in
  "Brave")   casks_list+=("brave-browser") ;;
  "Chrome")  casks_list+=("google-chrome") ;;
  "Firefox") casks_list+=("firefox") ;;
  "Arc")     casks_list+=("arc") ;;
  esac

  case "$terminal_choice" in
  "Ghostty")   casks_list+=("ghostty") ;;
  "iTerm2")    casks_list+=("iterm2") ;;
  "Warp")      casks_list+=("warp") ;;
  "Alacritty") casks_list+=("alacritty") ;;
  esac

  case "$editor_choice" in
  "Cursor")          casks_list+=("cursor") ;;
  "Zed")             casks_list+=("zed") ;;
  "VS Code")         casks_list+=("visual-studio-code") ;;
  esac

  local brews_installed=()
  for tool in "${tools[@]}"; do
    case "$tool" in
    "git")     brews_installed+=("git") ;;
    "gh")      brews_installed+=("gh") ;;
    "lazygit") brews_installed+=("lazygit") ;;
    "fzf")     brews_installed+=("fzf") ;;
    "ripgrep") brews_installed+=("ripgrep") ;;
    "tmux")    brews_installed+=("tmux") ;;
    "wget")    brews_installed+=("wget") ;;
    "tree")    brews_installed+=("tree") ;;
    "htop")    brews_installed+=("htop") ;;
    esac
  done

  source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/save.sh"

  local brews_json casks_json
  brews_json=$(array_to_json "${brews_installed[@]}")
  casks_json=$(array_to_json "${casks_list[@]}")

  local browser_role="$browser"
  [[ "$browser_role" == "Skip" ]] && browser_role="none"

  cat >"$SHELVE_CONFIG" <<EOF
{
  "version": "1.0",
  "saved_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "system": {
    "macos": "$macos",
    "arch": "$arch",
    "shell": "$shell_name"
  },
  "roles": {
    "browser": "$browser_role",
    "terminal": "$terminal_choice",
    "editor": "$editor_choice",
    "cli_editor": "$cli_editor"
  },
  "brews": $brews_json,
  "casks": $casks_json,
  "manual_apps": [],
  "dotfiles": []
}
EOF

  log_success "Saved to ${SHELVE_CONFIG}"
}

# =============================================================================
# CMD FRESH
# =============================================================================

cmd_fresh() {
  shelve_banner

  gum style \
    --border normal \
    --padding "1 2" \
    --border-foreground 212 \
    "Welcome to shelve fresh" \
    "" \
    "This wizard sets up a brand new Mac from scratch." \
    "Answer a few questions and shelve installs everything for you." \
    "You can customise every selection — nothing is forced."

  echo ""

  if ! gum confirm "Ready to begin?"; then
    log_warn "Aborted"
    exit 0
  fi

  # ── Step 1: Developer type ─────────────────────────────────────────────────
  local dev_type
  dev_type=$(pick_dev_type)

  # ── Step 2: Picks ──────────────────────────────────────────────────────────
  local browser_choice terminal_choice editor_choice shell_choice
  browser_choice=$(pick_browser)
  terminal_choice=$(pick_terminal)
  editor_choice=$(pick_editor)
  shell_choice=$(pick_shell_extras)

  local selected_languages=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_languages+=("$line")
  done < <(pick_languages)

  local selected_tools=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_tools+=("$line")
  done < <(pick_tools "$dev_type")

  local selected_dbs=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_dbs+=("$line")
  done < <(pick_databases)

  local selected_productivity=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_productivity+=("$line")
  done < <(pick_productivity)

  # ── Confirm screen ─────────────────────────────────────────────────────────
  divider
  log_step "Here's what will be installed"
  echo ""
  printf "  ${CYAN}Developer type${RESET}  %s\n" "$dev_type"
  printf "  ${CYAN}Browser${RESET}         %s\n" "$browser_choice"
  printf "  ${CYAN}Terminal${RESET}        %s\n" "$terminal_choice"
  printf "  ${CYAN}Editor${RESET}          %s\n" "$editor_choice"
  printf "  ${CYAN}Shell extras${RESET}    %s\n" "$shell_choice"
  echo ""

  if [[ ${#selected_languages[@]} -gt 0 ]]; then
    printf "  ${CYAN}Languages${RESET}\n"
    for l in "${selected_languages[@]}"; do log_dim "  + $l"; done
    echo ""
  fi

  if [[ ${#selected_tools[@]} -gt 0 ]]; then
    printf "  ${CYAN}CLI tools${RESET}\n"
    for t in "${selected_tools[@]}"; do log_dim "  + $t"; done
    echo ""
  fi

  if [[ ${#selected_dbs[@]} -gt 0 ]]; then
    printf "  ${CYAN}Databases${RESET}\n"
    for d in "${selected_dbs[@]}"; do log_dim "  + $d"; done
    echo ""
  fi

  if [[ ${#selected_productivity[@]} -gt 0 ]]; then
    printf "  ${CYAN}Productivity${RESET}\n"
    for p in "${selected_productivity[@]}"; do log_dim "  + $p"; done
    echo ""
  fi

  divider

  local action
  action=$(gum choose \
    "Start install" \
    "Start over" \
    "Abort" \
    --header="What would you like to do?" </dev/tty)

  case "$action" in
  "Start over")
    cmd_fresh
    return
    ;;
  "Abort")
    log_warn "Aborted"
    exit 0
    ;;
  esac

  # ── Install ────────────────────────────────────────────────────────────────
  log_step "Installing — this may take a few minutes"
  divider

  log_step "Browser"
  install_browser "$browser_choice"

  log_step "Terminal"
  install_terminal "$terminal_choice"

  log_step "Editor"
  install_editor "$editor_choice"

  log_step "Shell extras"
  install_shell_extras "$shell_choice"

  if [[ ${#selected_languages[@]} -gt 0 ]]; then
    log_step "Languages"
    install_languages "${selected_languages[@]}"
  fi

  if [[ ${#selected_tools[@]} -gt 0 ]]; then
    log_step "CLI tools"
    install_tools "${selected_tools[@]}"
  fi

  if [[ ${#selected_dbs[@]} -gt 0 ]]; then
    log_step "Databases"
    install_databases "${selected_dbs[@]}"
  fi

  if [[ ${#selected_productivity[@]} -gt 0 ]]; then
    log_step "Productivity"
    install_productivity "${selected_productivity[@]}"
  fi

  # ── Post-install ───────────────────────────────────────────────────────────
  divider
  log_success "All done! Your Mac is set up."
  echo ""

  ensure_shelve_dir
  if gum confirm "Save this setup to shelve.json for next time?"; then
    save_fresh_to_json \
      "$browser_choice" \
      "$terminal_choice" \
      "$editor_choice" \
      "${selected_tools[@]}"
    log_info "Run 'shelve restore' on your next Mac to replicate this setup."
  fi

  echo ""
  log_success "Welcome to your new Mac. Happy hacking."
}
