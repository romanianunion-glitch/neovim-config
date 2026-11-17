# Neovim Configuration

My personal Neovim configuration, built on top of [LazyVim](https://github.com/LazyVim/LazyVim).

This repository contains the configuration, plugin lockfile, and installers for Windows and Linux. The Linux installer detects the distribution and package manager before installing missing dependencies.

## Overview

- **Editor:** [Neovim](https://neovim.io/)
- **Framework:** [LazyVim](https://github.com/LazyVim/LazyVim)
- **Plugin manager:** [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Configuration language:** Lua
- **Formatting:** StyLua
- **Plugin versions:** Tracked through `nvim/lazy-lock.json`

## Repository structure

```text
.
├── install.ps1
├── install.sh
├── install-linux.bash
├── LICENSE
├── README.md
└── nvim/
    ├── init.lua
    ├── lazy-lock.json
    ├── lazyvim.json
    ├── stylua.toml
    └── lua/
        ├── config/
        │   ├── autocmds.lua
        │   ├── keymaps.lua
        │   ├── lazy.lua
        │   └── options.lua
        └── plugins/
            └── example.lua
```

## Requirements

The current LazyVim release requires:

- Neovim **0.11.2 or newer**, built with LuaJIT.
- Git **2.19.0 or newer**.
- `curl`, `unzip`, and `ripgrep` are installed by the Linux installer when missing.
- A C compiler is recommended for compiling Treesitter parsers.
- A Nerd Font is optional, but recommended for icons.

The installer checks the Neovim and Git versions before replacing your existing configuration. Some older distribution repositories may provide a Neovim version below the required minimum. In that case, the installer stops and asks you to install a newer Neovim build rather than leaving you with a broken setup.

## Installation

### Linux

Clone the repository somewhere outside your Neovim config directory, then run the installer:

```bash
git clone https://github.com/romanianunion-glitch/neovim-config.git ~/.local/share/neovim-config
cd ~/.local/share/neovim-config
chmod +x install.sh
./install.sh
```

The POSIX `install.sh` entrypoint hands off to the Bash installer. On minimal Alpine systems it can bootstrap Bash first. The installer reads `/etc/os-release`, detects the distribution and package manager, checks dependencies, and installs missing packages after one confirmation.

#### Supported package managers

| Distribution family | Package manager | Package names |
|---|---|---|
| Debian, Ubuntu and derivatives | APT | `neovim git curl unzip ripgrep` |
| Arch and derivatives | pacman | `neovim git curl unzip ripgrep` |
| Fedora and RHEL derivatives | DNF | `neovim git curl unzip ripgrep` |
| openSUSE | zypper | `neovim git curl unzip ripgrep` |
| Gentoo | Portage | `app-editors/neovim dev-vcs/git net-misc/curl app-arch/unzip sys-apps/ripgrep` |
| Alpine | apk | `neovim git curl unzip ripgrep` |
| Void Linux | XBPS | `neovim git curl unzip ripgrep` |
| NixOS | Nix profile | `neovim git curl unzip ripgrep` |
| Solus | eopkg | `neovim git curl unzip ripgrep` |
| GNU Guix | Guix profile | `neovim git curl unzip ripgrep` |
| Mageia | urpmi | `neovim git curl unzip ripgrep` |
| Fedora Atomic / Universal Blue variants | rpm-ostree | `neovim git curl unzip ripgrep` |

For package managers that modify the system, the installer uses `sudo` or `doas` when needed. Nix and Guix install into the current user's profile. Fedora Atomic-style systems layer packages and require a reboot; rerun the installer after rebooting.

If your distribution is not recognized, or its package manager is unavailable, install the requirements manually and rerun `install.sh`.

**Important:** some stable distribution repositories ship Neovim older than 0.11.2. The installer checks the actual installed version and will not replace your config unless the minimum version is met.

### Windows

Install Neovim and Git, then clone the repository and run the PowerShell installer:

```powershell
git clone https://github.com/romanianunion-glitch/neovim-config.git "$env:USERPROFILE\neovim-config"
cd "$env:USERPROFILE\neovim-config"
.\install.ps1
```

The installer places the configuration in `%LOCALAPPDATA%\nvim` and backs up an existing configuration before replacing it.

## First launch

Start Neovim:

```bash
nvim
```

On first launch, `lazy.nvim` bootstraps automatically and installs LazyVim and the configured plugins. Run `:LazyHealth` inside Neovim to check the setup.

## Plugin management

Plugins are managed through lazy.nvim.

```vim
:Lazy
```

The `nvim/lazy-lock.json` file tracks plugin versions.

## Formatting

Lua formatting is configured through StyLua:

- Two-space indentation
- A maximum line width of 120 columns
- Space-based indentation

## License

This project is distributed under the MIT License. See [LICENSE](LICENSE) for details.
