#!/usr/bin/env bash
# =============================================================================
# save.sh — captures current Mac setup and writes shelve.json
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/detect.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/menu.sh"

# -----------------------------------------------------------------------------
# ARRAY TO JSON
# -----------------------------------------------------------------------------
array_to_json() {
  local items=("$@")
  if [[ ${#items[@]} -eq 0 ]]; then
    echo "[]"
    return
  fi
  local result
  result=$(printf '"%s",' "${items[@]}")
  echo "[${result%,}]"
}

# -----------------------------------------------------------------------------
# WRITE SHELVE.JSON
# -----------------------------------------------------------------------------
write_config() {
  local brews_json="$1"
  local casks_json="$2"
  local manual_json="$3"
  local dotfiles_json="$4"

  local shell macos arch browser terminal editor cli_editor
  shell=$(basename "$SHELL")
  macos=$(sw_vers -productVersion 2>/dev/null)
  arch=$(uname -m)

  local roles
  roles=$(detect_roles)
  browser=$(echo "$roles" | grep "^browser=" | cut -d= -f2)
  terminal=$(echo "$roles" | grep "^terminal=" | cut -d= -f2)
  editor=$(echo "$roles" | grep "^editor=" | cut -d= -f2)
  cli_editor=$(echo "$roles" | grep "^cli_editor=" | cut -d= -f2)

  ensure_shelve_dir

  cat >"$SHELVE_CONFIG" <<EOF
{
  "version": "1.0",
  "saved_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "system": {
    "macos": "$macos",
    "arch": "$arch",
    "shell": "$shell"
  },
  "roles": {
    "browser": "$browser",
    "terminal": "$terminal",
    "editor": "$editor",
    "cli_editor": "$cli_editor"
  },
  "brews": $brews_json,
  "casks": $casks_json,
  "manual_apps": $manual_json,
  "dotfiles": $dotfiles_json
}
EOF

  log_success "Config saved to ${SHELVE_CONFIG}"
}

# -----------------------------------------------------------------------------
# BACKUP DOTFILES
# Copies selected dotfiles into ~/.shelve/dotfiles/ so restore.sh can find them
# Directories (e.g. ~/.config/nvim) are copied recursively with cp -r
# -----------------------------------------------------------------------------
backup_dotfiles() {
  local files=("$@")
  [[ ${#files[@]} -eq 0 ]] && return

  local dotfiles_dir="${SHELVE_DIR}/dotfiles"
  mkdir -p "$dotfiles_dir"

  log_step "Backing up dotfiles"
  for dotfile in "${files[@]}"; do
    local src="${dotfile/#\~/$HOME}"
    if [[ ! -e "$src" ]]; then
      log_warn "Not found, skipping: $dotfile"
      continue
    fi
    cp -r "$src" "$dotfiles_dir/"
    log_success "Backed up $dotfile"
  done
}

# -----------------------------------------------------------------------------
# CHECK OPTIONAL TOOLS
# -----------------------------------------------------------------------------
check_optional_tools() {
  log_step "Optional tools"

  if ! command_exists gh; then
    log_warn "gh not installed — GitHub push won't be automated"
    if menu_confirm "Install GitHub CLI (gh) now?"; then
      brew install gh
      log_success "gh installed"
    fi
  else
    log_success "gh installed"
  fi
}

# -----------------------------------------------------------------------------
# CMD SAVE
# -----------------------------------------------------------------------------
cmd_save() {
  shelve_banner
  log_step "Saving your Mac setup"

  check_optional_tools

  log_step "Select what to save"
  log_info "Go through each category — deselect anything you don't want"
  divider

  local selected_brews=()
  local selected_casks=()
  local selected_manual=()
  local selected_dotfiles=()

  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_brews+=("$line")
  done < <(menu_brews)

  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_casks+=("$line")
  done < <(menu_casks)

  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_manual+=("$line")
  done < <(menu_manual_apps)

  while IFS= read -r line; do
    [[ -n "$line" ]] && selected_dotfiles+=("$line")
  done < <(menu_dotfiles)

  local brews_json casks_json manual_json dotfiles_json
  brews_json=$(array_to_json "${selected_brews[@]}")
  casks_json=$(array_to_json "${selected_casks[@]}")
  manual_json=$(array_to_json "${selected_manual[@]}")
  dotfiles_json=$(array_to_json "${selected_dotfiles[@]}")

  ensure_shelve_dir
  backup_dotfiles "${selected_dotfiles[@]}"

  divider
  write_config \
    "$brews_json" \
    "$casks_json" \
    "$manual_json" \
    "$dotfiles_json"

  log_step "Summary"
  log_success "${#selected_brews[@]} formulae saved"
  log_success "${#selected_casks[@]} casks saved"
  log_success "${#selected_manual[@]} manual apps saved"
  log_success "${#selected_dotfiles[@]} dotfiles saved"

  divider
  log_success "Setup saved. Run 'shelve restore' on your new Mac to restore."
}
