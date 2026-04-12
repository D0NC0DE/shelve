#!/usr/bin/env bash
# =============================================================================
# menu.sh — interactive checkbox menus using gum
# =============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/utils.sh"

# -----------------------------------------------------------------------------
# MENU SELECT
# Generic checkbox — all items selected by default
# Only selected items go to stdout — log messages go to stderr
# -----------------------------------------------------------------------------
menu_select() {
  local header="$1"
  shift
  local items=("$@")

  printf '%s\n' "${items[@]}" | gum choose \
    --no-limit \
    --selected="*" \
    --header="$header" \
    --height=20
}

# -----------------------------------------------------------------------------
# MENU CONFIRM
# -----------------------------------------------------------------------------
menu_confirm() {
  local prompt="${1:-Are you sure?}"
  gum confirm "$prompt"
}

# -----------------------------------------------------------------------------
# MENU INPUT
# -----------------------------------------------------------------------------
menu_input() {
  local prompt="${1:-Enter value:}"
  local placeholder="${2:-}"
  gum input --prompt="$prompt " --placeholder="$placeholder"
}

# -----------------------------------------------------------------------------
# MENU BREWS
# -----------------------------------------------------------------------------
menu_brews() {
  local brews=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && brews+=("$line")
  done < <(detect_brews)

  if [[ ${#brews[@]} -eq 0 ]]; then
    log_warn "No Homebrew formulae found" >&2
    return
  fi

  log_step "Homebrew formulae" >&2
  log_dim "Space to deselect, enter to confirm" >&2
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
    log_warn "No casks found" >&2
    return
  fi

  log_step "Homebrew casks" >&2
  log_dim "Space to deselect, enter to confirm" >&2
  menu_select "Select casks to save:" "${casks[@]}"
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
    log_dim "No manual apps found" >&2
    return
  fi

  log_step "Manual apps" >&2
  log_dim "These apps have no automated install — a download URL will be saved" >&2
  log_dim "Space to deselect, enter to confirm" >&2
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
    log_warn "No dotfiles found" >&2
    return
  fi

  log_step "Dotfiles" >&2
  log_dim "Space to deselect, enter to confirm" >&2
  menu_select "Select dotfiles to back up:" "${files[@]}"
}
