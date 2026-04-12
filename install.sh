#!/usr/bin/env bash
# =============================================================================
# install.sh — one-liner bootstrap for shelve
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/D0NC0DE/shelve/main/install.sh | bash
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
ask()     {
  printf "${YELLOW}?${RESET} %s [y/N] " "$*"
  local r; read -r r
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
  # The installer is async — wait for it
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
    # Add brew to PATH for Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
  else
    error "Homebrew is required by shelve. Exiting."
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
# -----------------------------------------------------------------------------
SHELVE_BIN="${SHELVE_INSTALL_DIR}"
PATH_LINE="export PATH=\"\$PATH:${SHELVE_BIN}\""

# Add to ~/.zshrc if not already present
if [[ -f "${HOME}/.zshrc" ]] && ! grep -q "shelve" "${HOME}/.zshrc"; then
  echo "" >> "${HOME}/.zshrc"
  echo "# shelve — shelf your setup" >> "${HOME}/.zshrc"
  echo "$PATH_LINE" >> "${HOME}/.zshrc"
  success "Added shelve to ~/.zshrc"
fi

# Add to ~/.bashrc if it exists and shelve isn't already there
if [[ -f "${HOME}/.bashrc" ]] && ! grep -q "shelve" "${HOME}/.bashrc"; then
  echo "" >> "${HOME}/.bashrc"
  echo "# shelve — shelf your setup" >> "${HOME}/.bashrc"
  echo "$PATH_LINE" >> "${HOME}/.bashrc"
  success "Added shelve to ~/.bashrc"
fi

# Also export for the current session
export PATH="$PATH:${SHELVE_BIN}"

# -----------------------------------------------------------------------------
# DONE
# -----------------------------------------------------------------------------
printf "\n"
printf "${GREEN}${BOLD}  shelve is installed!${RESET}\n\n"
printf "  Restart your terminal (or run ${CYAN}source ~/.zshrc${RESET}), then:\n\n"
printf "  ${BOLD}shelve save${RESET}      — back up your current Mac setup\n"
printf "  ${BOLD}shelve restore${RESET}   — restore from a saved config\n"
printf "  ${BOLD}shelve fresh${RESET}     — set up a brand new Mac from scratch\n"
printf "  ${BOLD}shelve help${RESET}      — show all commands\n\n"
