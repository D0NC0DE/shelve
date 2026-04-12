#!/usr/bin/env bash
# =============================================================================
# install.sh — one-liner bootstrap for shelve
# Usage:
#   curl -fsSL https://get.yourdomain.com/shelve -o install.sh && bash install.sh
# =============================================================================

set -eo pipefail

SHELVE_REPO="https://github.com/D0NC0DE/shelve.git"
SHELVE_INSTALL_DIR="${HOME}/.shelve/tool"

if tput setaf 1 &>/dev/null 2>&1; then
  RESET="$(tput sgr0)"
  BOLD="$(tput bold)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  CYAN="$(tput setaf 6)"
  RED="$(tput setaf 1)"
  DIM="$(tput setaf 8)"
else
  RESET="" BOLD="" GREEN="" YELLOW="" CYAN="" RED="" DIM=""
fi

info()    { printf "${CYAN}•${RESET} %s\n" "$*"; }
success() { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}⚠${RESET} %s\n" "$*" >&2; }
error()   { printf "${RED}✗${RESET} ${BOLD}%s${RESET}\n" "$*" >&2; }
divider() { printf "${DIM}%s${RESET}\n" "────────────────────────────────────────────────"; }
ask() {
  printf "${YELLOW}?${RESET} %s [y/N] " "$*"
  local r; read -r r </dev/tty
  [[ "$r" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# Runs a command in the background and shows an animated spinner until it finishes
# Usage: spin "title" command args...
# -----------------------------------------------------------------------------
spin() {
  local title="$1"
  shift
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  "$@" &>/dev/null &
  local pid=$!
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${CYAN}${frames[$((i % 10))]}${RESET} %s" "$title"
    i=$((i + 1))
    sleep 0.08
  done

  wait "$pid"
  printf "\r%-50s\r" " "
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
printf "  ${DIM}shelf your setup — installing shelve${RESET}\n\n"
divider
printf "\n"

# -----------------------------------------------------------------------------
# CHECK macOS
# -----------------------------------------------------------------------------
if [[ "$(uname)" != "Darwin" ]]; then
  error "shelve only works on macOS."
  exit 1
fi

success "macOS $(sw_vers -productVersion)"

# -----------------------------------------------------------------------------
# XCODE CLI TOOLS
# -----------------------------------------------------------------------------
if ! xcode-select -p &>/dev/null; then
  spin "Installing Xcode CLI tools..." xcode-select --install
  until xcode-select -p &>/dev/null 2>&1; do sleep 5; done
  success "Xcode CLI tools"
else
  success "Xcode CLI tools"
fi

# -----------------------------------------------------------------------------
# HOMEBREW
# Cannot be backgrounded — needs sudo and user interaction
# -----------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  if ask "Homebrew is not installed. Install it now?"; then
    info "Installing Homebrew — you may be prompted for your password..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew"
  else
    error "Homebrew is required. Exiting."
    exit 1
  fi
else
  success "Homebrew"
fi

# -----------------------------------------------------------------------------
# GUM
# -----------------------------------------------------------------------------
if ! command -v gum &>/dev/null; then
  spin "Installing gum..." brew install gum
  success "gum"
else
  success "gum"
fi

printf "\n"
divider
printf "\n"

# -----------------------------------------------------------------------------
# CLONE / UPDATE SHELVE
# bash -c wraps git so the redirection silences git, not gum
# -----------------------------------------------------------------------------
if [[ -d "$SHELVE_INSTALL_DIR" ]]; then
  gum spin --spinner dot --title "Checking for updates..." -- \
    bash -c "git -C '$SHELVE_INSTALL_DIR' pull --ff-only &>/dev/null" || true
  success "shelve (up to date)"
else
  gum spin --spinner dot --title "Installing shelve..." -- \
    bash -c "git clone '$SHELVE_REPO' '$SHELVE_INSTALL_DIR' &>/dev/null"
  success "shelve installed"
fi

chmod +x "${SHELVE_INSTALL_DIR}/shelve"

# -----------------------------------------------------------------------------
# ADD TO PATH
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
  success "PATH (already configured)"
else
  printf "\n# shelve — shelf your setup\n" >> "$RC_FILE"
  printf "%s\n" "$PATH_LINE" >> "$RC_FILE"
  success "PATH → ${RC_FILE}"
fi

export PATH="$PATH:${SHELVE_BIN}"

# -----------------------------------------------------------------------------
# DONE
# -----------------------------------------------------------------------------
printf "\n"
divider
printf "\n"

gum style \
  --border rounded \
  --padding "1 3" \
  --border-foreground 6 \
  --bold \
  "  shelve is installed!"

printf "\n"
printf "  ${DIM}Restart your terminal or run:${RESET}\n"
printf "  ${CYAN}source %s${RESET}\n\n" "$RC_FILE"
printf "  ${BOLD}shelve save${RESET}      — back up your current Mac setup\n"
printf "  ${BOLD}shelve restore${RESET}   — restore from a saved config\n"
printf "  ${BOLD}shelve fresh${RESET}     — set up a brand new Mac from scratch\n"
printf "  ${BOLD}shelve help${RESET}      — show all commands\n\n"
divider
printf "\n"