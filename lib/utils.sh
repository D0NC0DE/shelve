#!/usr/bin/env bash
# =============================================================================
# utils.sh — colours, logging, and shared helpers
# Every other lib file sources this first
# =============================================================================

# -----------------------------------------------------------------------------
# COLOURS
# We check if the terminal supports colour before using it
# tput reads terminal capabilities — works on any Unix terminal
# 2>/dev/null silences errors on terminals that don't support it
# -----------------------------------------------------------------------------
if tput setaf 1 &>/dev/null; then
  RESET="$(tput sgr0)"
  BOLD="$(tput bold)"
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"
  MAGENTA="$(tput setaf 5)"
  CYAN="$(tput setaf 6)"
  DIM="$(tput setaf 8)"
else
  RESET="" BOLD="" RED="" GREEN="" YELLOW=""
  BLUE="" MAGENTA="" CYAN="" DIM=""
fi

# -----------------------------------------------------------------------------
# LOGGING
# Every function writes to stdout EXCEPT log_error and log_warn
# which write to stderr (>&2)
# -----------------------------------------------------------------------------
log_info() {
  printf "${BLUE}•${RESET} %s\n" "$*"
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
# SYSTEM DETECTION
# -----------------------------------------------------------------------------
is_apple_silicon() {
  [[ "$(uname -m)" == "arm64" ]]
}

is_intel() {
  [[ "$(uname -m)" == "x86_64" ]]
}

brew_prefix() {
  if is_apple_silicon; then
    echo "/opt/homebrew"
  else
    echo "/usr/local"
  fi
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
# PROMPTS
# -----------------------------------------------------------------------------
shelve_ask() {
  local response
  printf "${YELLOW}?${RESET} %s ${DIM}[y/N]${RESET} " "$*"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

divider() {
  printf "${DIM}%s${RESET}\n" "────────────────────────────────────────────────"
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
# GUM WRAPPER
# gum 0.17.0 conflicts with our BOLD variable — unset it before every call
# -----------------------------------------------------------------------------
gum() {
  env -u BOLD command gum "$@"
}
