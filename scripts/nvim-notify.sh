#!/usr/bin/env bash
# Claude Code hook: forward notifications to Neovim via vim.notify()
#
# This script is called by Claude Code on Notification and Stop hook events.
# It reads JSON from stdin and sends a vim.notify() call to the Neovim instance
# that spawned the Claude terminal (identified by $NVIM_SERVER).
#
# Environment:
#   NVIM_SERVER - Neovim RPC socket path (set by claude.nvim terminal.lua)
#
# Dependencies: jq, nvim
#
# Usage in ~/.claude/settings.json:
#   {
#     "hooks": {
#       "Notification": [{
#         "matcher": "*",
#         "hooks": [{
#           "type": "command",
#           "command": "/path/to/claude.nvim/scripts/nvim-notify.sh"
#         }]
#       }],
#       "Stop": [{
#         "hooks": [{
#           "type": "command",
#           "command": "/path/to/claude.nvim/scripts/nvim-notify.sh"
#         }]
#       }]
#     }
#   }

set -euo pipefail

# Exit silently if NVIM_SERVER is not set (not launched from claude.nvim)
if [[ -z "${NVIM_SERVER:-}" ]]; then
  exit 0
fi

# Exit silently if jq is not available
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Read JSON input from stdin
INPUT=$(cat)

# Build a JSON payload with just the fields we need, then let Neovim decode it
# safely. This avoids any shell/Lua injection through message content.
PAYLOAD=$(echo "$INPUT" | jq -c '{
  hook_event_name: (.hook_event_name // "unknown"),
  notification_type: (.notification_type // "unknown"),
  title: (.title // ""),
  message: (.message // ""),
  cwd: (.cwd // "")
}')

# Write payload to a temp file so we don't pass user data via command line
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
printf '%s' "$PAYLOAD" > "$TMPFILE"

# Send a Lua expression to Neovim that reads and decodes the JSON safely
nvim --server "$NVIM_SERVER" --remote-expr "v:lua.require('claude.notify').from_hook('$TMPFILE')" 2>/dev/null || true

exit 0
