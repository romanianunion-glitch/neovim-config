#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# Neovim Configuration Installer
# Termux (Android)
# ==========================================

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_CONFIG="$SCRIPT_DIR/nvim"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly TARGET_CONFIG="$CONFIG_HOME/nvim"

# ------------------------------------------
# Helpers
# ------------------------------------------

info() {
  printf '\033[1;36m[INFO]\033[0m %s\n' "$1"
}

success() {
  printf '\033[1;32m[SUCCESS]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
}

# ------------------------------------------
# System checks
# ------------------------------------------

if [[ -z "${TERMUX_VERSION:-}" && ! -d "/data/data/com.termux/files/usr" ]]; then
  error "This installer is intended for Termux on Android."
  exit 1
fi

if ! command -v pkg >/dev/null 2>&1; then
  error "The 'pkg' command was not found. Is this a proper Termux install?"
  exit 1
fi

if [[ ! -d "$SOURCE_CONFIG" ]]; then
  error "Configuration directory not found: $SOURCE_CONFIG"
  error "Run this script from a valid repository checkout."
  exit 1
fi

info "Termux detected."

# ------------------------------------------
# Neovim dependency
# ------------------------------------------

if ! command -v nvim >/dev/null 2>&1; then
  info "Neovim is not installed."

  read -r -p "Install Neovim using pkg? [y/N] " answer

  case "$answer" in
  [yY] | [yY][eE][sS])
    pkg install -y neovim
    ;;
  *)
    error "Neovim is required. Installation cancelled."
    exit 1
    ;;
  esac
fi

# ------------------------------------------
# Optional tooling (plugins commonly need these)
# ------------------------------------------

OPTIONAL_PACKAGES=(git ripgrep fd clang make nodejs)
MISSING_PACKAGES=()

for package in "${OPTIONAL_PACKAGES[@]}"; do
  if ! dpkg -s "$package" >/dev/null 2>&1; then
    MISSING_PACKAGES+=("$package")
  fi
done

if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
  info "Recommended packages not installed: ${MISSING_PACKAGES[*]}"
  info "(git for plugin managers, ripgrep/fd for searching, clang/make for Treesitter parsers, nodejs for some LSPs)"

  read -r -p "Install them using pkg? [y/N] " answer

  case "$answer" in
  [yY] | [yY][eE][sS])
    pkg install -y "${MISSING_PACKAGES[@]}"
    ;;
  *)
    info "Skipping optional packages."
    ;;
  esac
fi

# ------------------------------------------
# Prepare installation
# ------------------------------------------

mkdir -p "$CONFIG_HOME"

BACKUP_CONFIG=""

if [[ -e "$TARGET_CONFIG" || -L "$TARGET_CONFIG" ]]; then
  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  BACKUP_CONFIG="$CONFIG_HOME/nvim.backup-$TIMESTAMP"

  while [[ -e "$BACKUP_CONFIG" || -L "$BACKUP_CONFIG" ]]; do
    BACKUP_CONFIG="${BACKUP_CONFIG}-$(printf '%04d' "$RANDOM")"
  done

  info "Existing Neovim configuration detected."
  info "Backing it up to: $BACKUP_CONFIG"

  mv -- "$TARGET_CONFIG" "$BACKUP_CONFIG"
fi

# ------------------------------------------
# Install configuration
# ------------------------------------------

if cp -a -- "$SOURCE_CONFIG" "$TARGET_CONFIG"; then
  success "Neovim configuration installed."

  if [[ -n "$BACKUP_CONFIG" ]]; then
    success "Previous configuration backed up successfully."
  fi
else
  error "Failed to install the configuration."

  if [[ -n "$BACKUP_CONFIG" && -d "$BACKUP_CONFIG" ]]; then
    mv -- "$BACKUP_CONFIG" "$TARGET_CONFIG"
    info "Previous configuration restored."
  fi

  exit 1
fi

# ------------------------------------------
# Finished
# ------------------------------------------

printf '\n'
success "Installation complete!"
info "Configuration: $TARGET_CONFIG"
info "Start Neovim with: nvim"

if [[ -n "$BACKUP_CONFIG" ]]; then
  info "Backup: $BACKUP_CONFIG"
fi
