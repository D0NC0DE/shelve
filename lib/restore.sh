#!/usr/bin/env bash
# =============================================================================
# restore.sh — reads shelve.json and restores your Mac setup
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/menu.sh"

# Global arrays — shared between functions
brews=()
casks=()
manual=()
dotfiles=()
selected_brews=()
selected_casks=()
selected_manual=()
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
# Uses global arrays — no passing needed
# Returns 0 = confirmed, 1 = start over
# -----------------------------------------------------------------------------
run_selections() {
  selected_brews=()
  selected_casks=()
  selected_manual=()
  selected_dotfiles=()

  if [[ ${#brews[@]} -gt 0 ]]; then
    log_step "Homebrew formulae" >&2
    log_dim "Space to deselect, enter to confirm" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_brews+=("$line")
    done < <(printf '%s\n' "${brews[@]}" |
      gum choose --no-limit --selected="*" \
        --header="Select formulae to install:" \
        --height=20)
  fi

  if [[ ${#casks[@]} -gt 0 ]]; then
    log_step "Casks" >&2
    log_dim "Space to deselect, enter to confirm" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_casks+=("$line")
    done < <(printf '%s\n' "${casks[@]}" |
      gum choose --no-limit --selected="*" \
        --header="Select casks to install:" \
        --height=20)
  fi

  if [[ ${#manual[@]} -gt 0 ]]; then
    log_step "Manual apps" >&2
    log_dim "Space to deselect, enter to confirm" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_manual+=("$line")
    done < <(printf '%s\n' "${manual[@]}" |
      gum choose --no-limit --selected="*" \
        --header="Select manual apps to note:" \
        --height=20)
  fi

  if [[ ${#dotfiles[@]} -gt 0 ]]; then
    log_step "Dotfiles" >&2
    log_dim "Space to deselect, enter to confirm" >&2
    while IFS= read -r line; do
      [[ -n "$line" ]] && selected_dotfiles+=("$line")
    done < <(printf '%s\n' "${dotfiles[@]}" |
      gum choose --no-limit --selected="*" \
        --header="Select dotfiles to restore:" \
        --height=20)
  fi

  # Show summary
  divider
  log_info "Your selections:"
  echo ""

  printf "  ${CYAN}Formulae${RESET}    ${#selected_brews[@]} selected\n"
  for item in "${selected_brews[@]}"; do
    log_dim "  + $item"
  done

  echo ""
  printf "  ${CYAN}Casks${RESET}       ${#selected_casks[@]} selected\n"
  for item in "${selected_casks[@]}"; do
    log_dim "  + $item"
  done

  echo ""
  printf "  ${CYAN}Manual apps${RESET} ${#selected_manual[@]} selected\n"
  for item in "${selected_manual[@]}"; do
    log_dim "  + $item"
  done

  echo ""
  printf "  ${CYAN}Dotfiles${RESET}    ${#selected_dotfiles[@]} selected\n"
  for item in "${selected_dotfiles[@]}"; do
    log_dim "  + $item"
  done

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
    # Strip any invisible characters or whitespace that gum may attach
    pkg=$(echo "$pkg" | tr -d '[:space:]')
    [[ -z "$pkg" ]] && continue

    if brew_package_installed "$pkg"; then
      log_dim "$pkg already installed"
    else
      if gum spin \
        --spinner dot \
        --title "Installing $pkg..." \
        -- brew install "$pkg" 2>/dev/null; then
        log_success "$pkg"
      else
        log_warn "Failed: $pkg"
        failed+=("$pkg")
      fi
    fi
  done

  [[ ${#failed[@]} -gt 0 ]] && log_warn "Failed: ${failed[*]}"
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
        -- brew install --cask "$cask" 2>/dev/null; then
        log_success "$cask"
      else
        log_warn "Failed: $cask"
        failed+=("$cask")
      fi
    fi
  done

  [[ ${#failed[@]} -gt 0 ]] && log_warn "Failed: ${failed[*]}"
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

  # Show saved roles
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

  # Load items from config into global arrays
  while IFS= read -r line; do
    [[ -n "$line" ]] && brews+=("$line")
  done < <(parse_json_array "brews")

  while IFS= read -r line; do
    [[ -n "$line" ]] && casks+=("$line")
  done < <(parse_json_array "casks")

  while IFS= read -r line; do
    [[ -n "$line" ]] && manual+=("$line")
  done < <(parse_json_array "manual_apps")

  while IFS= read -r line; do
    [[ -n "$line" ]] && dotfiles+=("$line")
  done < <(parse_json_array "dotfiles")

  # Selection loop — reruns if user picks "start over"
  while true; do
    log_step "Select what to install"
    log_dim "Everything selected — deselect what you don't want"
    divider
    run_selections && break
  done

  # Install
  install_brews
  install_casks
  show_manual_apps
  restore_dotfiles

  divider
  log_success "Restore complete!"
  [[ ${#selected_manual[@]} -gt 0 ]] &&
    log_dim "Don't forget to download the manual apps listed above"
}
