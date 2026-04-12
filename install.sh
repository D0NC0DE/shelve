#!/usr/bin/env bash
# =============================================================================
# install.sh — one-liner bootstrap for shelve
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/D0NC0DE/shelve/refs/heads/main/install.sh -o install.sh && bash install.sh
# =============================================================================

set -eo pipefail

SHELVE_REPO="https://github.com/D0NC0DE/shelve.git"
SHELVE_INSTALL_DIR="${HOME}/.shelve/tool"

# Colours — keep it minimal, no dependency on utils.sh yet
if tput setaf 1 &>/dev/null 2>&1; then
  RESET="$(tput sgr0)"
  BOLD="$(tput bold)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  CYAN="$(tput setaf 6)"
  RED="$(tput setaf 1)"
else
  RESET="" BOLD="" GREEN="" YELLOW="" CYAN="" RED=""
fi

info()    { printf "${CYAN}•${RESET} %s\n" "$*"; }
success() { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}⚠${RESET} %s\n" "$*" >&2; }
error()   { printf "${RED}✗${RESET} ${BOLD}%s${RESET}\n" "$*" >&2; }
ask() {
  printf "${YELLOW}?${RESET} %s [y/N] " "$*"
  local r; read -r r </dev/tty
  [[ "$r" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# BANNER
# -----------------------------------------------------------------------------
printf "\n${BOLD}${CYAN}"
printf "  ░██████╗██╗░░██╗███████╗██╗░░░░░██╗░░░██╗███████╗\n"
printf "  ██╔════╝██║░░██║██╔════╝██║░░░░░██║░░░██║██╔════╝\n"
printf "  ╚█████╗░███████║█████╗░░██║░░░░░╚██╗░██╔╝█████╗░░\n"
printf "  ░╚═══██╗██╔══██║██╔══╝░░██║░░░░░░╚████╔╝░██╔══╝░░\n"
printf "  ██████╔╝██║░░██║███████╗███████╗░░╚██╔╝░░███████╗\n"
printf "  ╚═════╝░╚═╝░░╚═╝╚══════╝╚══════╝░░░╚═╝░░░╚══════╝\n"
printf "${RESET}"
printf "  shelf your setup — installing shelve bootstrap\n\n"

# -----------------------------------------------------------------------------
# CHECK macOS
# -----------------------------------------------------------------------------
if [[ "$(uname)" != "Darwin" ]]; then
  error "shelve only works on macOS."
  exit 1
fi

success "macOS detected ($(sw_vers -productVersion))"

# -----------------------------------------------------------------------------
# XCODE CLI TOOLS
# -----------------------------------------------------------------------------
if ! xcode-select -p &>/dev/null; then
  info "Xcode CLI tools not found — installing..."
  xcode-select --install 2>/dev/null || true
  until xcode-select -p &>/dev/null 2>&1; do
    sleep 5
  done
  success "Xcode CLI tools installed"
else
  success "Xcode CLI tools already installed"
fi

# -----------------------------------------------------------------------------
# HOMEBREW
# -----------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  if ask "Homebrew is not installed. Install it now?"; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
  else
    error "Homebrew is required. Exiting."
    exit 1
  fi
else
  success "Homebrew already installed"
fi

# -----------------------------------------------------------------------------
# GUM
# -----------------------------------------------------------------------------
if ! command -v gum &>/dev/null; then
  info "Installing gum (interactive UI)..."
  brew install gum
  success "gum installed"
else
  success "gum already installed"
fi

# -----------------------------------------------------------------------------
# CLONE SHELVE
# -----------------------------------------------------------------------------
if [[ -d "$SHELVE_INSTALL_DIR" ]]; then
  info "Updating existing shelve installation..."
  git -C "$SHELVE_INSTALL_DIR" pull --ff-only 2>/dev/null || true
  success "shelve updated"
else
  info "Installing shelve to ${SHELVE_INSTALL_DIR}..."
  mkdir -p "$(dirname "$SHELVE_INSTALL_DIR")"
  git clone "$SHELVE_REPO" "$SHELVE_INSTALL_DIR"
  success "shelve cloned"
fi

chmod +x "${SHELVE_INSTALL_DIR}/shelve"

# -----------------------------------------------------------------------------
# ADD TO PATH
# Detect which shell the user is running, write to the correct rc file.
# touch creates the file if it doesn't exist yet.
# -----------------------------------------------------------------------------
SHELVE_BIN="${SHELVE_INSTALL_DIR}"
PATH_LINE="export PATH=\"\$PATH:${SHELVE_BIN}\""

SHELL_NAME=$(basename "$SHELL")

if [[ "$SHELL_NAME" == "zsh" ]]; then
  RC_FILE="${HOME}/.zshrc"
elif [[ "$SHELL_NAME" == "bash" ]]; then
  RC_FILE="${HOME}/.bashrc"
else
  warn "Unknown shell: $SHELL_NAME — adding to ~/.profile as fallback"
  RC_FILE="${HOME}/.profile"
fi

touch "$RC_FILE"

if grep -q "shelve" "$RC_FILE"; then
  success "shelve already in ${RC_FILE}"
else
  printf "\n# shelve — shelf your setup\n" >> "$RC_FILE"
  printf "%s\n" "$PATH_LINE" >> "$RC_FILE"
  success "Added shelve to ${RC_FILE}"
fi

# Export for current session so shelve works immediately
export PATH="$PATH:${SHELVE_BIN}"

# -----------------------------------------------------------------------------
# DONE
# -----------------------------------------------------------------------------
printf "\n"
printf "${GREEN}${BOLD}  shelve is installed!${RESET}\n\n"
printf "  Run ${CYAN}source %s${RESET} or restart your terminal, then:\n\n" "$RC_FILE"
printf "  ${BOLD}shelve save${RESET}      — back up your current Mac setup\n"
printf "  ${BOLD}shelve restore${RESET}   — restore from a saved config\n"
printf "  ${BOLD}shelve fresh${RESET}     — set up a brand new Mac from scratch\n"
printf "  ${BOLD}shelve help${RESET}      — show all commands\n\n"