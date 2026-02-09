<div align="center">
  <h1>claude.nvim</h1>

  <p align="center">
    <a href="https://github.com/S1M0N38/claude.nvim/actions/workflows/run-tests.yml">
      <img alt="Run Tests badge" src="https://img.shields.io/github/actions/workflow/status/S1M0N38/claude.nvim/run-tests.yml?style=for-the-badge&label=Tests"/>
    </a>
    <a href="https://luarocks.org/modules/S1M0N38/claude.nvim">
      <img alt="LuaRocks badge" src="https://img.shields.io/luarocks/v/S1M0N38/claude.nvim?style=for-the-badge&color=5d2fbf"/>
    </a>
    <a href="https://github.com/S1M0N38/claude.nvim/releases">
      <img alt="GitHub badge" src="https://img.shields.io/github/v/release/S1M0N38/claude.nvim?style=for-the-badge&label=GitHub"/>
    </a>
  </p>
  <p><em>A simple plugin to integrate Claude Code in Neovim</em></p>
</div>

______________________________________________________________________

## Requirements

- **[Neovim](https://github.com/neovim/neovim)** >= 0.11

## Installation

```lua
-- Install and configure your plugin during development
{
  "S1M0N38/claude.nvim",
  dir = "/path/to/claude.nvim", -- So we are using the local version of the plugin
  branch = "main", -- Select the branch of the plugin to use
  lazy = false,
  opts = {},
}
```

## Usage

Get started by reading the comprehensive documentation with [`:help claude`](https://github.com/S1M0N38/claude.nvim/blob/main/doc/claude.txt), which covers all plugin features and configuration options.

> [!NOTE]
> Most Vim/Neovim plugins include built-in `:help` documentation. If you're new to this, start with `:help` to learn the basics.

## Acknowledgments

- [base.nvim](https://github.com/S1M0N38/base.nvim): template used to bootstrap this plugin
- [claudecode.nvim](https://github.com/S1M0N38/claudecode.nvim): Claude integration for Neovim
- [sidekick.nvim](https://github.com/S1M0N38/sidekick.nvim): AI sidekick plugin for Neovim
