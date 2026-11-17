#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BASH_INSTALLER="$SCRIPT_DIR/install-linux.bash"

if [ ! -f "$BASH_INSTALLER" ]; then
  printf '[ERROR] Linux installer not found: %s\n' "$BASH_INSTALLER" >&2
  exit 1
fi

if command -v bash >/dev/null 2>&1; then
  exec bash "$BASH_INSTALLER" "$@"
fi

# Alpine's minimal install does not include Bash by default. Bootstrap only
# this small interpreter prerequisite, then hand off to the full installer.
if [ -r /etc/os-release ]; then
  . /etc/os-release
fi

if [ "${ID:-}" != "alpine" ] || ! command -v apk >/dev/null 2>&1; then
  printf '[ERROR] Bash is required to run the Linux installer. Install Bash, then rerun this script.\n' >&2
  exit 1
fi

printf '[INFO] Bash is missing. The Alpine package "bash" is required by the installer.\n'
printf 'Install Bash now? [Y/n] '
read -r answer || answer=Y

case "${answer:-Y}" in
  [nN]|[nN][oO])
    printf '[ERROR] Installation cancelled.\n' >&2
    exit 1
    ;;
esac

if [ "$(id -u)" -eq 0 ]; then
  apk add bash
elif command -v doas >/dev/null 2>&1; then
  doas apk add bash
elif command -v sudo >/dev/null 2>&1; then
  sudo apk add bash
else
  printf '[ERROR] Install Bash as root (apk add bash), then rerun this script.\n' >&2
  exit 1
fi

exec bash "$BASH_INSTALLER" "$@"
