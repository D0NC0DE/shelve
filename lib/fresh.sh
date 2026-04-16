#!/usr/bin/env bash
# =============================================================================
# fresh.sh — interactive wizard for setting up a brand new Mac from scratch
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"

# Script-level variables — shared between _fresh_run and save_fresh_to_json
selected_languages=()
selected_productivity=()
shell_choice=""

# -----------------------------------------------------------------------------
# INSTALL HELPERS
# -----------------------------------------------------------------------------
fresh_install_brew() {
  local pkg="$1"
  if brew_package_installed "$pkg"; then
    log_dim "$pkg already installed"
  else
    if gum spin --spinner dot --title "Installing $pkg..." \
        -- bash -c "brew install '$pkg' &>/dev/null"; then
      log_success "$pkg"
    else
      log_warn "Failed to install $pkg"
    fi
  fi
}

fresh_install_cask() {
  local cask="$1"
  if brew_cask_installed "$cask"; then
    log_dim "$cask already installed"
  else
    if gum spin --spinner dot --title "Installing $cask..." \
        -- bash -c "brew install --cask '$cask' &>/dev/null"; then
      log_success "$cask"
    else
      log_warn "Failed to install $cask"
    fi
  fi
}

# -----------------------------------------------------------------------------
# PICKS
# -----------------------------------------------------------------------------
pick_dev_type() {
  log_step "What kind of developer are you?" >&2
  gum choose \
    "Web / Frontend" \
    "Backend / DevOps" \
    "Data / ML" \
    "Mobile (iOS / Android)" \
    "General / Not sure" \
    --header="Pick the closest match — you can customise everything next:"
}

pick_browser() {
  log_step "Pick your browser" >&2
  gum choose \
    "Brave" \
    "Chrome" \
    "Firefox" \
    "Arc" \
    "Skip" \
    --header="Which browser do you want?"
}

pick_terminal() {
  log_step "Pick your terminal" >&2
  gum choose \
    "Ghostty" \
    "iTerm2" \
    "Warp" \
    "Alacritty" \
    "Skip" \
    --header="Which terminal emulator do you want?"
}

pick_editor() {
  log_step "Pick your editor" >&2
  gum choose \
    "Cursor" \
    "Zed" \
    "VS Code" \
    "Neovim + LazyVim" \
    "Skip" \
    --header="Which editor do you want?"
}

pick_shell_extras() {
  log_step "Shell extras" >&2
  gum choose \
    "oh-my-zsh" \
    "starship prompt" \
    "Both" \
    "Skip" \
    --header="Any shell enhancements?"
}

pick_languages() {
  log_step "Languages" >&2
  gum choose --no-limit \
    --header="Which languages do you work with?" \
    -- \
    "Python (via pyenv)" \
    "Node (via nvm)" \
    "Go" \
    "Rust" \
    "Ruby" \
    "Java"
}

pick_tools() {
  local dev_type="$1"

  local all_tools=(
    "git"
    "gh"
    "lazygit"
    "fzf"
    "fd"
    "ripgrep"
    "bat"
    "eza"
    "zoxide"
    "tree"
    "delta"
    "git-lfs"
    "jq"
    "wget"
    "httpie"
    "htop"
    "btop"
    "tmux"
    "tealdeer"
    "docker"
    "lazydocker"
    "k9s"
    "terraform"
    "awscli"
  )

  local preselect
  case "$dev_type" in
  "Web / Frontend")
    preselect="git,gh,lazygit,fzf,fd,ripgrep,bat,eza,zoxide,delta,git-lfs,jq,wget,httpie,tealdeer"
    ;;
  "Backend / DevOps")
    preselect="git,gh,lazygit,fzf,fd,ripgrep,bat,eza,zoxide,delta,git-lfs,jq,wget,httpie,htop,btop,tmux,tealdeer,docker,lazydocker,k9s,terraform,awscli"
    ;;
  "Data / ML")
    preselect="git,gh,lazygit,fzf,fd,ripgrep,bat,eza,zoxide,delta,git-lfs,jq,wget,httpie,htop,btop,tealdeer"
    ;;
  "Mobile (iOS / Android)")
    preselect="git,gh,lazygit,fzf,fd,ripgrep,bat,eza,zoxide,delta,git-lfs,jq,tealdeer"
    ;;
  *)
    preselect="git,gh,fzf,fd,ripgrep,bat,eza,zoxide,delta,jq,tealdeer"
    ;;
  esac

  log_step "CLI tools" >&2
  gum choose --no-limit \
    --selected="$preselect" \
    --header="Which CLI tools do you want?" \
    -- "${all_tools[@]}"
}

pick_databases() {
  log_step "Databases" >&2
  gum choose --no-limit \
    --header="Any databases? (skip with enter if none)" \
    -- \
    "PostgreSQL" \
    "MySQL" \
    "Redis" \
    "MongoDB" \
    "SQLite"
}

pick_productivity() {
  log_step "Productivity & utilities" >&2
  gum choose --no-limit \
    --header="Any productivity or utility apps?" \
    -- \
    "Raycast" \
    "Rectangle" \
    "Alfred" \
    "Maccy" \
    "AppCleaner" \
    "1Password" \
    "Notion" \
    "Obsidian" \
    "Slack" \
    "Zoom" \
    "Spotify" \
    "Shottr" \
    "TablePlus" \
    "Postman" \
    "OrbStack"
}

# -----------------------------------------------------------------------------
# INSTALLERS
# -----------------------------------------------------------------------------
install_browser() {
  case "$1" in
  "Brave")   fresh_install_cask "brave-browser" ;;
  "Chrome")  fresh_install_cask "google-chrome" ;;
  "Firefox") fresh_install_cask "firefox" ;;
  "Arc")     fresh_install_cask "arc" ;;
  "Skip")    log_dim "Skipping browser" ;;
  esac
}

install_terminal() {
  case "$1" in
  "Ghostty")   fresh_install_cask "ghostty" ;;
  "iTerm2")    fresh_install_cask "iterm2" ;;
  "Warp")      fresh_install_cask "warp" ;;
  "Alacritty") fresh_install_cask "alacritty" ;;
  "Skip")      log_dim "Skipping terminal" ;;
  esac
}

install_editor() {
  case "$1" in
  "Cursor")  fresh_install_cask "cursor" ;;
  "Zed")     fresh_install_cask "zed" ;;
  "VS Code") fresh_install_cask "visual-studio-code" ;;
  "Neovim + LazyVim")
    fresh_install_brew "neovim"
    if [[ ! -d "${HOME}/.config/nvim" ]]; then
      if gum spin --spinner dot --title "Cloning LazyVim starter..." \
          -- bash -c "git clone https://github.com/LazyVim/starter '${HOME}/.config/nvim' &>/dev/null"; then
        if [[ -d "${HOME}/.config/nvim/.git" ]]; then rm -rf "${HOME}/.config/nvim/.git"; fi
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

install_shell_extras() {
  case "$1" in
  "oh-my-zsh")
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
      log_dim "oh-my-zsh already installed"
    else
      if gum spin --spinner dot --title "Installing oh-my-zsh..." \
          -- bash -c "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" -- --unattended &>/dev/null"; then
        log_success "oh-my-zsh"
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

install_languages() {
  local languages=("$@")
  for lang in "${languages[@]}"; do
    case "$lang" in
    "Python (via pyenv)") fresh_install_brew "pyenv" ;;
    "Node (via nvm)")
      if [[ ! -d "${HOME}/.nvm" ]]; then
        local nvm_version
        nvm_version=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
          2>/dev/null | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
        [[ -z "$nvm_version" ]] && nvm_version="0.40.1"
        if gum spin --spinner dot --title "Installing nvm..." \
            -- bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v${nvm_version}/install.sh | bash &>/dev/null"; then
          log_success "nvm — restart terminal then run: nvm install --lts"
        else
          log_warn "nvm install failed"
        fi
      else
        log_dim "nvm already installed"
      fi
      ;;
    "Go")   fresh_install_brew "go" ;;
    "Rust")
      if ! command_exists rustup; then
        if gum spin --spinner dot --title "Installing Rust..." \
            -- bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null"; then
          log_success "Rust"
        else
          log_warn "Rust install failed"
        fi
      else
        log_dim "rustup already installed"
      fi
      ;;
    "Ruby") fresh_install_brew "rbenv" ;;
    "Java") fresh_install_cask "temurin" ;;
    esac
  done
}

install_tools() {
  local tools=("$@")
  for tool in "${tools[@]}"; do
    case "$tool" in
    "git")        fresh_install_brew "git" ;;
    "gh")         fresh_install_brew "gh" ;;
    "lazygit")    fresh_install_brew "lazygit" ;;
    "fzf")        fresh_install_brew "fzf" ;;
    "fd")         fresh_install_brew "fd" ;;
    "ripgrep")    fresh_install_brew "ripgrep" ;;
    "bat")        fresh_install_brew "bat" ;;
    "eza")        fresh_install_brew "eza" ;;
    "zoxide")     fresh_install_brew "zoxide" ;;
    "tree")       fresh_install_brew "tree" ;;
    "delta")      fresh_install_brew "git-delta" ;;
    "git-lfs")    fresh_install_brew "git-lfs" ;;
    "jq")         fresh_install_brew "jq" ;;
    "wget")       fresh_install_brew "wget" ;;
    "httpie")     fresh_install_brew "httpie" ;;
    "htop")       fresh_install_brew "htop" ;;
    "btop")       fresh_install_brew "btop" ;;
    "tmux")       fresh_install_brew "tmux" ;;
    "tealdeer")   fresh_install_brew "tealdeer" ;;
    "docker")     fresh_install_cask "docker" ;;
    "lazydocker") fresh_install_brew "lazydocker" ;;
    "k9s")        fresh_install_brew "k9s" ;;
    "terraform")  fresh_install_brew "terraform" ;;
    "awscli")     fresh_install_brew "awscli" ;;
    esac
  done
}

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

install_productivity() {
  local apps=("$@")
  for app in "${apps[@]}"; do
    case "$app" in
    "Raycast")    fresh_install_cask "raycast" ;;
    "Rectangle")  fresh_install_cask "rectangle" ;;
    "Alfred")     fresh_install_cask "alfred" ;;
    "Maccy")      fresh_install_cask "maccy" ;;
    "AppCleaner") fresh_install_cask "appcleaner" ;;
    "1Password")  fresh_install_cask "1password" ;;
    "Notion")     fresh_install_cask "notion" ;;
    "Obsidian")   fresh_install_cask "obsidian" ;;
    "Slack")      fresh_install_cask "slack" ;;
    "Zoom")       fresh_install_cask "zoom" ;;
    "Spotify")    fresh_install_cask "spotify" ;;
    "Shottr")     fresh_install_cask "shottr" ;;
    "TablePlus")  fresh_install_cask "tableplus" ;;
    "Postman")    fresh_install_cask "postman" ;;
    "OrbStack")   fresh_install_cask "orbstack" ;;
    esac
  done
}

# -----------------------------------------------------------------------------
# SAVE FRESH SETUP TO SHELVE.JSON
# -----------------------------------------------------------------------------
save_fresh_to_json() {
  local browser="$1"
  local terminal_choice="$2"
  local editor_choice="$3"
  local tools=("${@:4}")

  local macos arch shell_name cli_editor
  macos=$(sw_vers -productVersion 2>/dev/null)
  arch=$(uname -m)
  shell_name=$(basename "$SHELL")
  cli_editor="none"
  command_exists nvim && cli_editor="neovim"
  if command_exists vim && [[ "$cli_editor" == "none" ]]; then
    cli_editor="vim"
  fi

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
  "Cursor")  casks_list+=("cursor") ;;
  "Zed")     casks_list+=("zed") ;;
  "VS Code") casks_list+=("visual-studio-code") ;;
  esac

  for app in "${selected_productivity[@]}"; do
    case "$app" in
    "Raycast")    casks_list+=("raycast") ;;
    "Rectangle")  casks_list+=("rectangle") ;;
    "Alfred")     casks_list+=("alfred") ;;
    "Maccy")      casks_list+=("maccy") ;;
    "AppCleaner") casks_list+=("appcleaner") ;;
    "1Password")  casks_list+=("1password") ;;
    "Notion")     casks_list+=("notion") ;;
    "Obsidian")   casks_list+=("obsidian") ;;
    "Slack")      casks_list+=("slack") ;;
    "Zoom")       casks_list+=("zoom") ;;
    "Spotify")    casks_list+=("spotify") ;;
    "Shottr")     casks_list+=("shottr") ;;
    "TablePlus")  casks_list+=("tableplus") ;;
    "Postman")    casks_list+=("postman") ;;
    "OrbStack")   casks_list+=("orbstack") ;;
    esac
  done

  # Map languages to brews, casks, or manual_installs
  local manual_installs_list=()
  for lang in "${selected_languages[@]}"; do
    case "$lang" in
    "Python (via pyenv)") tools+=("pyenv") ;;
    "Go")                 tools+=("go") ;;
    "Ruby")               tools+=("rbenv") ;;
    "Java")               casks_list+=("temurin") ;;
    "Node (via nvm)")     manual_installs_list+=("nvm") ;;
    "Rust")               manual_installs_list+=("rust (rustup)") ;;
    esac
  done

  # Add oh-my-zsh to manual_installs if selected
  if [[ "$shell_choice" == "oh-my-zsh" || "$shell_choice" == "Both" ]]; then
    manual_installs_list+=("oh-my-zsh")
  fi
  local browser_role="$browser"
  if [[ "$browser_role" == "Skip" ]]; then
    browser_role="none"
  fi

  local brews_json casks_json manual_installs_json
  brews_json=$(array_to_json "${tools[@]}")
  casks_json=$(array_to_json "${casks_list[@]}")
  manual_installs_json=$(array_to_json "${manual_installs_list[@]}")

  ensure_shelve_dir

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
  "manual_installs": $manual_installs_json,
  "dotfiles": []
}
EOF

  log_success "Saved to ${SHELVE_CONFIG}"
}

# -----------------------------------------------------------------------------
# CMD FRESH
# -----------------------------------------------------------------------------
_fresh_run() {
  shelve_banner

  gum style \
    --border rounded \
    --padding "1 2" \
    --border-foreground 6 \
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

  local dev_type
  dev_type=$(pick_dev_type)

  local browser_choice terminal_choice editor_choice
  browser_choice=$(pick_browser)
  terminal_choice=$(pick_terminal)
  editor_choice=$(pick_editor)
  shell_choice=$(pick_shell_extras)

  selected_languages=()
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

  selected_productivity=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_productivity+=("$line")
  done < <(pick_productivity)

  # Confirm screen
  divider
  log_step "Here's what will be installed" >&2
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
  "Start over") return 1 ;;
  "Abort")
    log_warn "Aborted"
    exit 0
    ;;
  esac

  # Install
  log_step "Installing — this may take a few minutes"
  divider

  log_step "Browser";      install_browser "$browser_choice"
  log_step "Terminal";     install_terminal "$terminal_choice"
  log_step "Editor";       install_editor "$editor_choice"
  log_step "Shell extras"; install_shell_extras "$shell_choice"

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

cmd_fresh() {
  while true; do
    _fresh_run && break
  done
}