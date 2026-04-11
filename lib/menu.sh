#!/usr/bin/env bash
# =============================================================================
# menu.sh — interactive checkbox menus using gum
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"

# -----------------------------------------------------------------------------
# MENU SELECT
# Generic function — takes a header and a list of items, shows checkboxes
# with everything selected by default, returns what the user picked
#
# Usage: menu_select "Pick your tools" "git" "node" "python"
# Returns: selected items one per line
# -----------------------------------------------------------------------------
menu_select() {
  local header="$1"
  shift
  local items=("$@")

  # --selected="*" means all items start selected
  printf '%s\n' "${items[@]}" | gum choose \
    --no-limit \
    --selected="*" \
    --header="$header" \
    --height=20
}

# -----------------------------------------------------------------------------
# MENU CONFIRM
# Simple yes/no confirmation using gum
# Usage: menu_confirm "Are you sure?" && do_something
# -----------------------------------------------------------------------------
menu_confirm() {
  local prompt="${1:-Are you sure?}"
  gum confirm "$prompt"
}

# -----------------------------------------------------------------------------
# MENU INPUT
# Single line text input
# Usage: name=$(menu_input "What is your name?")
# -----------------------------------------------------------------------------
menu_input() {
  local prompt="${1:-Enter value:}"
  local placeholder="${2:-}"
  gum input --prompt="$prompt " --placeholder="$placeholder"
}

# -----------------------------------------------------------------------------
# MENU BREWS
# Shows all detected brew formulae as checkboxes
# Returns selected ones
# -----------------------------------------------------------------------------
menu_brews() {
  local brews=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && brews+=("$line")
  done < <(detect_brews)

  if [[ ${#brews[@]} -eq 0 ]]; then
    log_warn "No Homebrew formulae found"
    return
  fi

  log_step "Homebrew formulae"
  log_dim "Space to deselect, enter to confirm"
  menu_select "Select formulae to save:" "${brews[@]}"
}

# -----------------------------------------------------------------------------
# MENU CASKS
# -----------------------------------------------------------------------------
menu_casks() {
  local casks=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && casks+=("$line")
  done < <(detect_casks)

  if [[ ${#casks[@]} -eq 0 ]]; then
    log_warn "No casks found"
    return
  fi

  log_step "Homebrew casks"
  log_dim "Space to deselect, enter to confirm"
  menu_select "Select casks to save:" "${casks[@]}"
}

# -----------------------------------------------------------------------------
# MENU MAS APPS
# -----------------------------------------------------------------------------
menu_mas_apps() {
  if ! command_exists mas; then
    log_dim "mas not installed — skipping App Store apps"
    return
  fi

  local apps=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && apps+=("$line")
  done < <(mas list 2>/dev/null | awk '{$1=""; print $0}' |
    sed 's/^ //' |
    sed 's/ (.*//')

  if [[ ${#apps[@]} -eq 0 ]]; then
    log_warn "No App Store apps found"
    return
  fi

  log_step "App Store apps"
  log_dim "Space to deselect, enter to confirm"
  menu_select "Select App Store apps to save:" "${apps[@]}"
}

# -----------------------------------------------------------------------------
# MENU MANUAL APPS
# -----------------------------------------------------------------------------
menu_manual_apps() {
  local apps=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && apps+=("$line")
  done < <(detect_manual_apps)

  if [[ ${#apps[@]} -eq 0 ]]; then
    log_dim "No manual apps found"
    return
  fi

  log_step "Manual apps"
  log_dim "These apps have no automated install — a download URL will be saved"
  log_dim "Space to deselect, enter to confirm"
  menu_select "Select manual apps to save:" "${apps[@]}"
}

# -----------------------------------------------------------------------------
# MENU DOTFILES
# -----------------------------------------------------------------------------
menu_dotfiles() {
  local files=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && files+=("$line")
  done < <(detect_dotfiles)

  if [[ ${#files[@]} -eq 0 ]]; then
    log_warn "No dotfiles found"
    return
  fi

  log_step "Dotfiles"
  log_dim "Space to deselect, enter to confirm"
  menu_select "Select dotfiles to back up:" "${files[@]}"
}
