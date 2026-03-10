---@class Claude.Notify
local M = {}

---Map Claude Code notification types to vim.log.levels
---@type table<string, number>
local level_map = {
  permission_prompt = vim.log.levels.WARN,
  idle_prompt = vim.log.levels.WARN,
  auth_success = vim.log.levels.INFO,
  elicitation_dialog = vim.log.levels.WARN,
}

---Map notification types to indicator symbols
---@type table<string, string>
local indicator_map = {
  permission_prompt = "!",
  idle_prompt = "?",
  elicitation_dialog = "?",
  -- auth_success intentionally omitted (no indicator)
}

---Process a notification from the Claude Code hook script.
---Called via nvim --remote-expr from scripts/nvim-notify.sh.
---@param path string: path to a temp file containing JSON payload
---@return string: empty string (required by --remote-expr)
function M.from_hook(path)
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok or #content == 0 then
    return ""
  end

  local decode_ok, data = pcall(vim.json.decode, content[1])
  if not decode_ok or type(data) ~= "table" then
    return ""
  end

  local event = data.hook_event_name or "unknown"
  local dir = vim.fn.fnamemodify(data.cwd or "", ":t")
  if dir == "" then
    dir = "claude"
  end

  -- Determine slot number from payload (defaults to 1)
  local slot = tonumber(data.slot) or 1

  -- Set indicator based on event/type
  local terminal = require("claude.terminal")
  if event == "Notification" then
    local indicator = indicator_map[data.notification_type]
    if indicator then
      terminal.set_indicator(slot, indicator)
    end
  elseif event == "Stop" then
    terminal.set_indicator(slot, "✓")
  end
  terminal.refresh_title()

  local msg, level

  if event == "Notification" then
    local title = data.title or ""
    local message = data.message or "Notification"
    msg = title ~= "" and (dir .. ": " .. title) or (dir .. ": " .. message)
    level = level_map[data.notification_type] or vim.log.levels.INFO
  elseif event == "Stop" then
    msg = dir .. ": Task completed"
    level = vim.log.levels.INFO
  else
    msg = dir .. ": " .. event
    level = vim.log.levels.INFO
  end

  vim.schedule(function()
    vim.notify(msg, level)
  end)

  return ""
end

return M
