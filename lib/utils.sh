#!/usr/bin/env bash
# =============================================================================
# utils.sh — colours, logging, and shared helpers
# Every other lib file sources this first
# =============================================================================

# -----------------------------------------------------------------------------
# COLOURS
# -----------------------------------------------------------------------------
if tput setaf 1 &>/dev/null; then
  RESET="$(tput sgr0)"
  BOLD="$(tput bold)"
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  MAGENTA="$(tput setaf 5)"
  CYAN="$(tput setaf 6)"
  DIM="$(tput setaf 8)"
else
  RESET="" BOLD="" RED="" GREEN="" YELLOW="" MAGENTA="" CYAN="" DIM=""
fi

# -----------------------------------------------------------------------------
# LOGGING
# -----------------------------------------------------------------------------
log_info() {
  printf "${CYAN}•${RESET} %s\n" "$*"
}

log_success() {
  printf "${GREEN}✓${RESET} %s\n" "$*"
}

log_warn() {
  printf "${YELLOW}⚠${RESET} %s\n" "$*" >&2
}

log_error() {
  printf "${RED}✗${RESET} ${BOLD}%s${RESET}\n" "$*" >&2
}

log_step() {
  printf "\n${BOLD}${CYAN}▶ %s${RESET}\n" "$*"
}

log_dim() {
  printf "${DIM}  %s${RESET}\n" "$*"
}

# -----------------------------------------------------------------------------
# BANNER
# -----------------------------------------------------------------------------
shelve_banner() {
  printf "\n"
  printf "${BOLD}${MAGENTA}"
  printf "  ░██████╗██╗░░██╗███████╗██╗░░░░░██╗░░░██╗███████╗\n"
  printf "  ██╔════╝██║░░██║██╔════╝██║░░░░░██║░░░██║██╔════╝\n"
  printf "  ╚█████╗░███████║█████╗░░██║░░░░░╚██╗░██╔╝█████╗░░\n"
  printf "  ░╚═══██╗██╔══██║██╔══╝░░██║░░░░░░╚████╔╝░██╔══╝░░\n"
  printf "  ██████╔╝██║░░██║███████╗███████╗░░╚██╔╝░░███████╗\n"
  printf "  ╚═════╝░╚═╝░░╚═╝╚══════╝╚══════╝░░░╚═╝░░░╚══════╝\n"
  printf "${RESET}"
  printf "  ${DIM}shelf your setup — backup, restore, or start fresh${RESET}\n\n"
}

# -----------------------------------------------------------------------------
# DIVIDER
# -----------------------------------------------------------------------------
divider() {
  printf "${DIM}%s${RESET}\n" "────────────────────────────────────────────────"
}

# -----------------------------------------------------------------------------
# PROMPTS
# -----------------------------------------------------------------------------
shelve_ask() {
  local response
  printf "${YELLOW}?${RESET} %s ${DIM}[y/N]${RESET} " "$*"
  read -r response </dev/tty
  [[ "$response" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# COMMAND CHECKS
# -----------------------------------------------------------------------------
command_exists() {
  command -v "$1" &>/dev/null
}

app_installed() {
  [[ -d "/Applications/${1}.app" ]] ||
    [[ -d "${HOME}/Applications/${1}.app" ]]
}

# -----------------------------------------------------------------------------
# BREW CHECKS
# -----------------------------------------------------------------------------
brew_package_installed() {
  [[ -d "${BREW_PREFIX}/Cellar/${1}" ]]
}

brew_cask_installed() {
  [[ -d "${BREW_PREFIX}/Caskroom/${1}" ]]
}

# -----------------------------------------------------------------------------
# JSON HELPERS
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
# SHELVE PATHS
# -----------------------------------------------------------------------------
export SHELVE_DIR="${HOME}/.shelve"
export SHELVE_CONFIG="${SHELVE_DIR}/shelve.json"

ensure_shelve_dir() {
  [[ -d "$SHELVE_DIR" ]] || mkdir -p "$SHELVE_DIR"
}

# -----------------------------------------------------------------------------
# SAFE REMOVE
# Guards against empty variables or paths outside ~/.shelve/
# -----------------------------------------------------------------------------
safe_remove() {
  local target="$1"
  if [[ -z "$target" || "$target" != "${HOME}/.shelve/"* ]]; then
    log_warn "Refusing to remove unsafe path: $target"
    return 1
  fi
  rm -rf "$target"
}

# -----------------------------------------------------------------------------
# DEGIT
# Removes .git from a directory copy — safe to call even if .git doesn't exist
# -----------------------------------------------------------------------------
degit() {
  local dir="$1"
  [[ ! -d "${dir}/.git" ]] && return
  chmod -R u+w "${dir}/.git" 2>/dev/null || true
  safe_remove "${dir}/.git"
}

# -----------------------------------------------------------------------------
# BREW PREFIX CACHE
# -----------------------------------------------------------------------------
export BREW_PREFIX="$(brew --prefix 2>/dev/null || echo '')"

# -----------------------------------------------------------------------------
# GUM WRAPPER
# -----------------------------------------------------------------------------
gum() {
  env -u BOLD command gum "$@"
}