#!/usr/bin/env bash
# =============================================================================
# restore.sh — reads shelve.json and restores your Mac setup
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/menu.sh"

# Global arrays — shared between functions
selected_brews=()
selected_casks=()
selected_manual=()
selected_manual_installs=()
selected_dotfiles=()

# -----------------------------------------------------------------------------
# PARSE JSON ARRAY
# -----------------------------------------------------------------------------
parse_json_array() {
  local key="$1"
  local file="${2:-$SHELVE_CONFIG}"

  grep "^  \"${key}\":" "$file" |
    sed 's/.*\[//;s/\].*//' |
    tr ',' '\n' |
    sed 's/"//g' |
    sed 's/^ *//;s/ *$//' |
    grep -v '^$'
}

# -----------------------------------------------------------------------------
# PARSE JSON VALUE
# -----------------------------------------------------------------------------
parse_json_value() {
  local key="$1"
  local file="${2:-$SHELVE_CONFIG}"

  grep "\"${key}\":" "$file" |
    head -1 |
    sed 's/.*": *//' |
    sed 's/"//g' |
    sed 's/,$//' |
    sed 's/^ *//;s/ *$//'
}

# -----------------------------------------------------------------------------
# RUN SELECTIONS
# Parses each category inline so JSON parsing overlaps with gum initialising
# Returns 0 = confirmed, 1 = start over
# -----------------------------------------------------------------------------
run_selections() {
  selected_brews=()
  selected_casks=()
  selected_manual=()
  selected_manual_installs=()
  selected_dotfiles=()

  local items=()

  while IFS= read -r line; do
    [[ -n "$line" ]] && items+=("$line")
  done < <(parse_json_array "brews")
  if [[ ${#items[@]} -gt 0 ]]; then
    log_step "Homebrew formulae" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_brews+=("$line")
    done < <(menu_select "Select formulae to install:" "${items[@]}")
  fi

  items=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && items+=("$line")
  done < <(parse_json_array "casks")
  if [[ ${#items[@]} -gt 0 ]]; then
    log_step "Casks" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_casks+=("$line")
    done < <(menu_select "Select casks to install:" "${items[@]}")
  fi

  items=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && items+=("$line")
  done < <(parse_json_array "manual_apps")
  if [[ ${#items[@]} -gt 0 ]]; then
    log_step "Manual apps" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_manual+=("$line")
    done < <(menu_select "Select manual apps to note:" "${items[@]}")
  fi

  items=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && items+=("$line")
  done < <(parse_json_array "manual_installs")
  if [[ ${#items[@]} -gt 0 ]]; then
    log_step "Manual installs" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_manual_installs+=("$line")
    done < <(menu_select "Select manual installs to note:" "${items[@]}")
  fi

  items=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && items+=("$line")
  done < <(parse_json_array "dotfiles")
  if [[ ${#items[@]} -gt 0 ]]; then
    log_step "Dotfiles" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_dotfiles+=("$line")
    done < <(menu_select "Select dotfiles to restore:" "${items[@]}")
  fi

  # Show summary
  divider
  log_info "Your selections:"
  echo ""

  printf "  ${CYAN}Formulae${RESET}    ${#selected_brews[@]} selected\n"
  for item in "${selected_brews[@]}"; do log_dim "  + $item"; done

  echo ""
  printf "  ${CYAN}Casks${RESET}       ${#selected_casks[@]} selected\n"
  for item in "${selected_casks[@]}"; do log_dim "  + $item"; done

  echo ""
  printf "  ${CYAN}Manual apps${RESET} ${#selected_manual[@]} selected\n"
  for item in "${selected_manual[@]}"; do log_dim "  + $item"; done

  echo ""
  printf "  ${CYAN}Manual installs${RESET} ${#selected_manual_installs[@]} selected\n"
  for item in "${selected_manual_installs[@]}"; do log_dim "  + $item"; done

  echo ""
  printf "  ${CYAN}Dotfiles${RESET}    ${#selected_dotfiles[@]} selected\n"
  for item in "${selected_dotfiles[@]}"; do log_dim "  + $item"; done

  echo ""
  divider

  local choice
  choice=$(gum choose \
    "Start install" \
    "Start over" \
    "Abort" \
    --header="What would you like to do?" </dev/tty)

  case "$choice" in
  "Start install") return 0 ;;
  "Start over") return 1 ;;
  "Abort")
    log_warn "Aborted"
    exit 0
    ;;
  esac
}

# -----------------------------------------------------------------------------
# INSTALL BREWS
# -----------------------------------------------------------------------------
install_brews() {
  [[ ${#selected_brews[@]} -eq 0 ]] && return

  log_step "Installing Homebrew formulae"
  local failed=()

  for pkg in "${selected_brews[@]}"; do
    pkg=$(echo "$pkg" | tr -d '[:space:]')
    [[ -z "$pkg" ]] && continue

    if brew_package_installed "$pkg"; then
      log_dim "$pkg already installed"
    else
      if gum spin \
        --spinner dot \
        --title "Installing $pkg..." \
        -- bash -c "brew install '$pkg' &>/dev/null"; then
        log_success "$pkg"
      else
        log_warn "Failed: $pkg"
        failed+=("$pkg")
      fi
    fi
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    log_warn "Failed: ${failed[*]}"
  fi
}

# -----------------------------------------------------------------------------
# INSTALL CASKS
# -----------------------------------------------------------------------------
install_casks() {
  [[ ${#selected_casks[@]} -eq 0 ]] && return

  log_step "Installing casks"
  local failed=()

  for cask in "${selected_casks[@]}"; do
    if brew_cask_installed "$cask"; then
      log_dim "$cask already installed"
    else
      if gum spin \
        --spinner dot \
        --title "Installing $cask..." \
        -- bash -c "brew install --cask '$cask' &>/dev/null"; then
        log_success "$cask"
      else
        log_warn "Failed: $cask"
        failed+=("$cask")
      fi
    fi
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    log_warn "Failed: ${failed[*]}"
  fi
}

# -----------------------------------------------------------------------------
# SHOW MANUAL INSTALLS
# -----------------------------------------------------------------------------
show_manual_installs() {
  [[ ${#selected_manual_installs[@]} -eq 0 ]] && return

  log_step "Manual installs — re-install these yourself"
  log_dim "These tools were installed outside Homebrew"
  echo ""

  for item in "${selected_manual_installs[@]}"; do
    case "$item" in
    "nvm")
      printf "  ${YELLOW}•${RESET} nvm\n"
      printf "    ${DIM}curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash${RESET}\n"
      ;;
    "rust (rustup)")
      printf "  ${YELLOW}•${RESET} Rust\n"
      printf "    ${DIM}curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh${RESET}\n"
      ;;
    "oh-my-zsh")
      printf "  ${YELLOW}•${RESET} oh-my-zsh\n"
      printf "    ${DIM}sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"${RESET}\n"
      ;;
    *)
      printf "  ${YELLOW}•${RESET} %s\n" "$item"
      ;;
    esac
  done
  echo ""
}

# -----------------------------------------------------------------------------
# SHOW MANUAL APPS
# -----------------------------------------------------------------------------
show_manual_apps() {
  [[ ${#selected_manual[@]} -eq 0 ]] && return

  log_step "Manual apps — download these yourself"
  log_dim "Search for each app and download from the official website"
  echo ""

  for app in "${selected_manual[@]}"; do
    printf "  ${YELLOW}•${RESET} %s\n" "$app"
  done
  echo ""
}

# -----------------------------------------------------------------------------
# RESTORE DOTFILES
# -----------------------------------------------------------------------------
restore_dotfiles() {
  [[ ${#selected_dotfiles[@]} -eq 0 ]] && return

  log_step "Restoring dotfiles"

  local dotfiles_dir="${SHELVE_DIR}/dotfiles"

  if [[ ! -d "$dotfiles_dir" ]]; then
    log_warn "No dotfiles backup found at ${dotfiles_dir}"
    log_info "Run 'shelve save' first to back up your dotfiles"
    return
  fi

  for dotfile in "${selected_dotfiles[@]}"; do
    local target="${dotfile/#\~/$HOME}"
    local filename
    filename=$(basename "$target")
    local source="${dotfiles_dir}/${filename}"

    if [[ ! -e "$source" ]]; then
      log_warn "No backup found for $dotfile"
      continue
    fi

    mkdir -p "$(dirname "$target")"

    if [[ -e "$target" ]]; then
      mv "$target" "${target}.bak"
      log_dim "Backed up existing $dotfile → ${dotfile}.bak"
    fi

    cp -r "$source" "$target"
    log_success "Restored $dotfile"
  done
}

# -----------------------------------------------------------------------------
# CMD RESTORE
# -----------------------------------------------------------------------------
cmd_restore() {
  shelve_banner

  if [[ ! -f "$SHELVE_CONFIG" ]]; then
    log_error "No shelve.json found at ${SHELVE_CONFIG}"
    log_info "Run 'shelve save' first, or copy your shelve.json to ${SHELVE_DIR}"
    exit 1
  fi

  log_step "Restoring your Mac setup"
  log_info "Reading config from ${SHELVE_CONFIG}"
  divider

  local browser terminal editor cli_editor
  browser=$(parse_json_value "browser")
  terminal=$(parse_json_value "terminal")
  editor=$(parse_json_value "editor")
  cli_editor=$(parse_json_value "cli_editor")

  log_info "Saved setup:"
  log_dim "browser:    $browser"
  log_dim "terminal:   $terminal"
  log_dim "editor:     $editor"
  log_dim "cli editor: $cli_editor"
  divider

  while true; do
    log_step "Select what to install"
    log_dim "Everything selected — deselect what you don't want"
    divider
    run_selections && break
  done

  install_brews
  install_casks
  show_manual_installs
  show_manual_apps
  restore_dotfiles

  divider
  log_success "Restore complete!"
  [[ ${#selected_manual_installs[@]} -gt 0 ]] &&
    log_dim "Don't forget to run the manual install commands listed above"
  [[ ${#selected_manual[@]} -gt 0 ]] &&
    log_dim "Don't forget to download the manual apps listed above"
}