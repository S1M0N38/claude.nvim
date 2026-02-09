# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

claude.nvim is a Neovim plugin that integrates Claude Code into Neovim via a floating terminal. It provides commands to toggle the terminal, send visual selections, and send file references to Claude Code. Notifications from Claude Code hooks are forwarded to Neovim's `vim.notify()`.

## Commands

### Testing

```bash
# Run all tests (downloads mini.nvim to deps/ on first run)
make test

# Run a single test file
make test_file FILE=tests/test_config.lua
```

Tests use **mini.test** (from mini.nvim), NOT busted. Test files live in `tests/` and follow the `test_*.lua` naming convention. The test helper at `tests/helpers.lua` provides utilities for resetting plugin state and stubbing `vim.fn.jobstart` in child Neovim processes.

E2E tests (`tests/test_e2e.lua`) use `MiniTest.new_child_neovim()` to spawn a child Neovim process and use reference screenshots for visual assertions.

### Formatting

```bash
stylua .
```

stylua reads formatting rules from `.editorconfig` (2-space indent, double quotes, 120 char lines).

## Architecture

### Module Layout

- `lua/claude/init.lua` — Public API. Delegates to config, terminal, and send modules. Exports `setup()`, `toggle()`, `send_selection()`, `send_reference()`.
- `lua/claude/config.lua` — Configuration with defaults. Merges user opts via `vim.tbl_deep_extend`.
- `lua/claude/terminal.lua` — Floating terminal lifecycle. Manages a single persistent `{buf, win, job}` state. The buffer/job survive window close so the Claude process keeps running. Sets `NVIM_SERVER` env var so hooks can communicate back. Double-Esc exits terminal mode (single Esc is forwarded to the terminal after a timeout).
- `lua/claude/send.lua` — Sends visual selections or file references (`@path#L1-5` format) to the terminal via `nvim_chan_send`.
- `lua/claude/notify.lua` — Receives JSON payloads from the hook script, decodes them, and dispatches `vim.notify()` calls.
- `lua/claude/types.lua` — LuaCATS `@meta` type definitions (not loaded at runtime).
- `lua/claude/health.lua` — `:checkhealth claude` implementation.
- `plugin/claude.lua` — Registers user commands: `ClaudeToggle`, `ClaudeSend`, `ClaudeSendRef`.
- `scripts/nvim-notify.sh` — Shell hook script for Claude Code's Notification/Stop events. Reads JSON from stdin, writes to a temp file, and calls back into Neovim via `--remote-expr`.

### Key Patterns

- All modules use lazy `require()` to avoid circular dependencies — e.g., terminal.lua requires config at call time, not at module load.
- The terminal buffer has filetype `claude`, which can be used for filetype-specific autocommands.
- The plugin is distributed via both LuaRocks (`claude.nvim-scm-1.rockspec`) and GitHub releases.
- Conventional commits are used for automated versioning (`feat:`, `fix:`, `BREAKING CHANGE:`).

### Commit Scopes

Use one of these fixed scopes in conventional commits (e.g., `feat(terminal):`, `fix(config):`). Omit the scope only when a change spans too many areas to pick one. The commit title (first line) must be 72 characters or fewer.

| Scope | Covers |
|---|---|
| `terminal` | Floating terminal lifecycle (`terminal.lua`) |
| `config` | Configuration and defaults (`config.lua`) |
| `send` | Sending selections/references (`send.lua`) |
| `notify` | Notification handling (`notify.lua`) |
| `health` | Checkhealth provider (`health.lua`) |
| `types` | LuaCATS type definitions (`types.lua`) |
| `commands` | User commands in `plugin/claude.lua` |
| `hooks` | Shell hook script (`scripts/nvim-notify.sh`) |
| `tests` | Test files, helpers, and screenshots |
| `ci` | GitHub Actions workflows |
| `docs` | README, CLAUDE.md, and other documentation |
| `deps` | Rockspec, dependencies |
