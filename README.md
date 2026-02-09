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
- **[luarocks](https://luarocks.org/)**: install Lua packages
- **[busted](https://lunarmodules.github.io/busted/)**: unit testing framework for Lua
- **[nlua](https://github.com/mfussenegger/nlua)**: Neovim as Lua interpreter
- **[lazy.nvim](https://github.com/folke/lazy.nvim)**: plugin manager for Neovim
- **[lazydev.nvim](https://github.com/folke/lazydev.nvim)** (optional): enhanced plugin dev experience.

## Installation

```lua
-- Install and configure your plugin during development
{
  "S1M0N38/claude.nvim",
  dir = "/path/to/claude.nvim", -- So we are using the local version of the plugin
  branch = "main", -- Select the branch of the plugin to use
  lazy = false,
  opts = {},
  keys = {
    {
      "<leader>rb", -- Choose a key binding for reloading the plugin
      "<cmd>Lazy reload claude.nvim<cr>",
      desc = "Reload claude.nvim",
      mode = { "n", "v" },
    },
  },
}

-- Enable Lua language server support external libraries
{
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      "${3rd}/luassert/library",
      "${3rd}/busted/library",
      "claude.nvim",
    }
  },
}
```

## Usage

Get started by reading the comprehensive documentation with [`:help claude`](https://github.com/S1M0N38/claude.nvim/blob/main/doc/claude.txt), which covers all plugin features and configuration options.

> [!NOTE]
> Most Vim/Neovim plugins include built-in `:help` documentation. If you're new to this, start with `:help` to learn the basics.

## Acknowledgments

- [base.nvim](https://github.com/S1M0N38/base.nvim): template used to bootstrap this plugin
