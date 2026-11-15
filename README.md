
# Neovim Configuration

My personal Neovim configuration, built on top of [LazyVim](https://github.com/LazyVim/LazyVim).

This repository contains my Neovim setup, configuration entry points, plugin version lockfile, and formatting settings. It serves as a version-controlled backup and a foundation for future customization.

## Overview

- **Editor:** [Neovim](https://neovim.io/)
- **Framework:** [LazyVim](https://github.com/LazyVim/LazyVim)
- **Plugin manager:** [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Configuration language:** Lua
- **Formatting:** StyLua
- **Plugin versions:** Tracked through `lazy-lock.json`

## Structure

```text
.
├── init.lua
├── lazy-lock.json
├── lazyvim.json
├── stylua.toml
├── LICENSE
└── lua/
    ├── config/
    │   ├── autocmds.lua
    │   ├── keymaps.lua
    │   ├── lazy.lua
    │   └── options.lua
    └── plugins/
        └── example.lua
```

## Configuration

The configuration follows LazyVim's modular structure:

| File | Purpose |
|---|---|
| `init.lua` | Main configuration entry point |
| `config/lazy.lua` | Bootstraps lazy.nvim and loads LazyVim |
| `config/options.lua` | Neovim options |
| `config/keymaps.lua` | Custom keybindings |
| `config/autocmds.lua` | Autocommands |
| `plugins/` | Plugin specifications and overrides |
| `lazy-lock.json` | Locked plugin versions |
| `stylua.toml` | Lua formatting settings |

## Installation

### Requirements

- Neovim
- Git
- A working terminal environment

Additional tools and dependencies may be required by individual plugins.

### Windows

Clone the repository into Neovim's configuration directory:

```powershell
git clone https://github.com/USERNAME/neovim-config.git "$env:LOCALAPPDATA\nvim"
```

Replace `USERNAME` with your GitHub username.

Start Neovim:

```powershell
nvim
```

Lazy.nvim will bootstrap automatically and install the configured plugins.

### Linux

Clone the repository into your Neovim configuration directory:

```bash
git clone https://github.com/USERNAME/neovim-config.git ~/.config/nvim
```

Start Neovim:

```bash
nvim
```

## Plugin Management

Plugins are managed through lazy.nvim.

The `lazy-lock.json` file tracks plugin versions to help maintain reproducible installations.

To open the plugin manager:

```vim
:Lazy
```

## Formatting

Lua formatting is configured through StyLua.

The repository uses:

- Two-space indentation
- A maximum line width of 120 columns
- Space-based indentation

## License

This project is distributed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
