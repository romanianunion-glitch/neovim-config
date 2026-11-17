#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# Neovim Configuration Installer
# Linux distributions
# ==========================================

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_CONFIG="$SCRIPT_DIR/nvim"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly TARGET_CONFIG="$CONFIG_HOME/nvim"
readonly MIN_NVIM_VERSION="0.11.2"
readonly MIN_GIT_VERSION="2.19.0"

# ------------------------------------------
# Output helpers
# ------------------------------------------

info() {
  printf '\033[1;36m[INFO]\033[0m %s\n' "$1"
}

success() {
  printf '\033[1;32m[SUCCESS]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[WARN]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
}

# ------------------------------------------
# Privilege helper
# ------------------------------------------

run_as_root() {
  if [[ "$EUID" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  elif command -v doas >/dev/null 2>&1; then
    doas "$@"
  else
    error "This package manager needs administrator privileges, but neither sudo nor doas is installed."
    return 1
  fi
}

# ------------------------------------------
# Version helpers
# ------------------------------------------

version_at_least() {
  local current="$1"
  local required="$2"

  [[ "$(printf '%s\n%s\n' "$required" "$current" | sort -V | tail -n 1)" == "$current" ]]
}

get_nvim_version() {
  nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9.]*\).*$/\1/p'
}

get_git_version() {
  git --version 2>/dev/null | sed -n 's/^git version \([0-9][0-9.]*\).*$/\1/p'
}

# ------------------------------------------
# Distro detection
# ------------------------------------------

if [[ ! -r /etc/os-release ]]; then
  error "Cannot identify this Linux distribution: /etc/os-release is missing."
  exit 1
fi

# os-release is a shell-compatible file provided by the operating system.
# shellcheck disable=SC1091
. /etc/os-release

DISTRO_ID="${ID:-unknown}"
DISTRO_LIKE="${ID_LIKE:-}"
DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"

PACKAGE_MANAGER=""
PACKAGE_MODE=""

case "$DISTRO_ID" in
  bazzite|ublue-os|silverblue|kinoite|sericea|onyx)
    PACKAGE_MANAGER="rpm-ostree"
    PACKAGE_MODE="rpm-ostree"
    ;;
  debian|ubuntu|linuxmint|pop|elementary|zorin|kali|parrot|mx)
    PACKAGE_MANAGER="apt-get"
    PACKAGE_MODE="apt"
    ;;
  arch|cachyos|manjaro|endeavouros|garuda|arcolinux)
    PACKAGE_MANAGER="pacman"
    PACKAGE_MODE="pacman"
    ;;
  fedora|nobara|ultramarine|rhel|centos|rocky|almalinux)
    PACKAGE_MANAGER="dnf"
    PACKAGE_MODE="dnf"
    ;;
  opensuse*|opensuse-tumbleweed|opensuse-leap|suse)
    PACKAGE_MANAGER="zypper"
    PACKAGE_MODE="zypper"
    ;;
  gentoo)
    PACKAGE_MANAGER="emerge"
    PACKAGE_MODE="emerge"
    ;;
  alpine)
    PACKAGE_MANAGER="apk"
    PACKAGE_MODE="apk"
    ;;
  void)
    PACKAGE_MANAGER="xbps-install"
    PACKAGE_MODE="xbps"
    ;;
  nixos)
    PACKAGE_MANAGER="nix"
    PACKAGE_MODE="nix"
    ;;
  solus)
    PACKAGE_MANAGER="eopkg"
    PACKAGE_MODE="eopkg"
    ;;
  guix)
    PACKAGE_MANAGER="guix"
    PACKAGE_MODE="guix"
    ;;
  mageia)
    PACKAGE_MANAGER="urpmi"
    PACKAGE_MODE="urpmi"
    ;;
  *)
    # Fall back to ID_LIKE for derivatives with an unrecognized ID.
    case " $DISTRO_LIKE " in
      *" debian "*|*" ubuntu "*)
        PACKAGE_MANAGER="apt-get"
        PACKAGE_MODE="apt"
        ;;
      *" arch "*)
        PACKAGE_MANAGER="pacman"
        PACKAGE_MODE="pacman"
        ;;
      *" fedora "*|*" rhel "*)
        PACKAGE_MANAGER="dnf"
        PACKAGE_MODE="dnf"
        ;;
      *" suse "*)
        PACKAGE_MANAGER="zypper"
        PACKAGE_MODE="zypper"
        ;;
      *" gentoo "*)
        PACKAGE_MANAGER="emerge"
        PACKAGE_MODE="emerge"
        ;;
    esac
    ;;
esac

# ------------------------------------------
# Validate checkout and package manager
# ------------------------------------------

if [[ ! -d "$SOURCE_CONFIG" ]]; then
  error "Configuration directory not found: $SOURCE_CONFIG"
  error "Run this installer from a valid repository checkout."
  exit 1
fi

if [[ -z "$PACKAGE_MODE" ]]; then
  error "Automatic dependency installation is not configured for: $DISTRO_NAME"
  error "Install Neovim >= $MIN_NVIM_VERSION, Git >= $MIN_GIT_VERSION, curl, unzip, and ripgrep manually, then rerun this installer."
  exit 1
fi

if ! command -v "$PACKAGE_MANAGER" >/dev/null 2>&1; then
  error "Detected $DISTRO_NAME, but its expected package manager '$PACKAGE_MANAGER' is unavailable."
  error "Install dependencies manually, then rerun this installer."
  exit 1
fi

info "Detected: $DISTRO_NAME"
info "Package manager: $PACKAGE_MANAGER"

# ------------------------------------------
# Determine missing dependencies
# ------------------------------------------

PACKAGES=()

if ! command -v nvim >/dev/null 2>&1; then
  PACKAGES+=("neovim")
else
  NVIM_VERSION="$(get_nvim_version || true)"
  if [[ -z "$NVIM_VERSION" ]] || ! version_at_least "$NVIM_VERSION" "$MIN_NVIM_VERSION"; then
    warn "Installed Neovim version '${NVIM_VERSION:-unknown}' is older than the required $MIN_NVIM_VERSION."
    PACKAGES+=("neovim")
  fi
fi

if ! command -v git >/dev/null 2>&1; then
  PACKAGES+=("git")
else
  GIT_VERSION="$(get_git_version || true)"
  if [[ -z "$GIT_VERSION" ]] || ! version_at_least "$GIT_VERSION" "$MIN_GIT_VERSION"; then
    warn "Installed Git version '${GIT_VERSION:-unknown}' is older than the required $MIN_GIT_VERSION."
    PACKAGES+=("git")
  fi
fi

command -v curl >/dev/null 2>&1 || PACKAGES+=("curl")
command -v unzip >/dev/null 2>&1 || PACKAGES+=("unzip")
command -v rg >/dev/null 2>&1 || PACKAGES+=("ripgrep")

# Remove duplicate package names while preserving order.
if (("${#PACKAGES[@]}" > 0)); then
  mapfile -t PACKAGES < <(printf '%s\n' "${PACKAGES[@]}" | awk '!seen[$0]++')
fi

# ------------------------------------------
# Install missing dependencies
# ------------------------------------------

install_missing_packages() {
  local -a args=()

  case "$PACKAGE_MODE" in
    apt)
      info "Refreshing APT package indexes..."
      run_as_root apt-get update
      args=(apt-get install -y --no-install-recommends "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    pacman)
      args=(pacman -S --needed --noconfirm "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    dnf)
      args=(dnf install -y "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    zypper)
      args=(zypper --non-interactive install "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    emerge)
      local -a gentoo_packages=()
      local package
      for package in "${PACKAGES[@]}"; do
        case "$package" in
          neovim) gentoo_packages+=("app-editors/neovim") ;;
          git) gentoo_packages+=("dev-vcs/git") ;;
          curl) gentoo_packages+=("net-misc/curl") ;;
          unzip) gentoo_packages+=("app-arch/unzip") ;;
          ripgrep) gentoo_packages+=("sys-apps/ripgrep") ;;
        esac
      done
      run_as_root emerge --ask=n "${gentoo_packages[@]}"
      ;;
    apk)
      args=(apk add "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    xbps)
      args=(xbps-install -S "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    nix)
      local -a nix_packages=()
      local package
      for package in "${PACKAGES[@]}"; do
        nix_packages+=("nixpkgs#$package")
      done
      info "Installing into the current user's Nix profile (no system configuration files will be changed)."
      nix profile install "${nix_packages[@]}"
      ;;
    eopkg)
      args=(eopkg install -y "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    guix)
      info "Installing into the current user's Guix profile."
      guix install "${PACKAGES[@]}"
      ;;
    urpmi)
      args=(urpmi --auto "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      ;;
    rpm-ostree)
      args=(rpm-ostree install "${PACKAGES[@]}")
      run_as_root "${args[@]}"
      warn "Packages have been layered onto the immutable system."
      warn "Reboot, then run this installer again to finish the Neovim configuration setup."
      exit 0
      ;;
    *)
      error "Internal error: unsupported package manager mode '$PACKAGE_MODE'."
      return 1
      ;;
  esac
}

if (("${#PACKAGES[@]}" > 0)); then
  info "The following missing or outdated dependencies will be installed:"
  printf '  - %s\n' "${PACKAGES[@]}"
  printf '\n'
  info "This uses your distribution's package manager. Administrator authentication may be required."

  read -r -p "Continue with dependency installation? [Y/n] " answer
  case "${answer:-Y}" in
    [nN]|[nN][oO])
      error "Dependency installation cancelled."
      exit 1
      ;;
  esac

  install_missing_packages
else
  success "All checked dependencies are already installed."
fi

# Nix may need its user profile added to PATH in non-login shells.
if [[ "$PACKAGE_MODE" == "nix" ]]; then
  if [[ -d "$HOME/.nix-profile/bin" ]]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
  fi
  if [[ -d "$HOME/.local/state/nix/profile/bin" ]]; then
    export PATH="$HOME/.local/state/nix/profile/bin:$PATH"
  fi
fi

# ------------------------------------------
# Verify requirements before touching config
# ------------------------------------------

if ! command -v nvim >/dev/null 2>&1; then
  error "Neovim is still unavailable after dependency installation."
  exit 1
fi

NVIM_VERSION="$(get_nvim_version || true)"
if [[ -z "$NVIM_VERSION" ]] || ! version_at_least "$NVIM_VERSION" "$MIN_NVIM_VERSION"; then
  error "Neovim $MIN_NVIM_VERSION or newer is required by the current LazyVim release."
  error "The package provided by $DISTRO_NAME is '${NVIM_VERSION:-unknown}'."
  error "Install a newer Neovim build from https://neovim.io/ and rerun this installer."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  error "Git is still unavailable after dependency installation."
  exit 1
fi

GIT_VERSION="$(get_git_version || true)"
if [[ -z "$GIT_VERSION" ]] || ! version_at_least "$GIT_VERSION" "$MIN_GIT_VERSION"; then
  error "Git $MIN_GIT_VERSION or newer is required. Detected: ${GIT_VERSION:-unknown}"
  exit 1
fi

success "Requirements verified: Neovim $NVIM_VERSION and Git $GIT_VERSION."

# ------------------------------------------
# Prepare installation and backup
# ------------------------------------------

mkdir -p "$CONFIG_HOME"

BACKUP_CONFIG=""
TEMP_CONFIG="$CONFIG_HOME/.nvim.install.$$"

cleanup() {
  if [[ -e "$TEMP_CONFIG" || -L "$TEMP_CONFIG" ]]; then
    rm -rf -- "$TEMP_CONFIG"
  fi
}
trap cleanup EXIT

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

if cp -a -- "$SOURCE_CONFIG" "$TEMP_CONFIG" && mv -- "$TEMP_CONFIG" "$TARGET_CONFIG"; then
  success "Neovim configuration installed."
else
  error "Failed to install the configuration."

  if [[ -n "$BACKUP_CONFIG" && ( -e "$BACKUP_CONFIG" || -L "$BACKUP_CONFIG" ) ]]; then
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
info "First launch will bootstrap lazy.nvim and install LazyVim plugins."

if [[ -n "$BACKUP_CONFIG" ]]; then
  info "Previous configuration backup: $BACKUP_CONFIG"
fi
