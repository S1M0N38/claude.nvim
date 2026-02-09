---@class Claude.Health
local M = {}

---Validate the options table obtained from merging defaults and user options
local function validate_opts()
  local opts = require("claude.config").options

  local ok, err = pcall(function()
    vim.validate({
      cmd = { opts.cmd, "string" },
      float = { opts.float, "table" },
    })
    vim.validate({
      ["float.width"] = { opts.float.width, "number" },
      ["float.height"] = { opts.float.height, "number" },
      ["float.border"] = { opts.float.border, "string" },
    })
  end)

  if not ok then
    vim.health.error("Invalid setup options: " .. err)
  else
    vim.health.ok("Config options are valid")
  end
end

---Check if the configured command is executable
local function check_cmd()
  local cmd = require("claude.config").options.cmd
  if vim.fn.executable(cmd) == 1 then
    vim.health.ok("`" .. cmd .. "` is executable")
  else
    vim.health.error("`" .. cmd .. "` is not found or not executable")
  end
end

---Check Neovim version meets minimum requirement
local function check_nvim_version()
  if vim.fn.has("nvim-0.11") == 1 then
    vim.health.ok("Neovim >= 0.11")
  else
    vim.health.error("Neovim >= 0.11 is required")
  end
end

---Check if jq is available (needed by the notification hook script)
local function check_jq()
  if vim.fn.executable("jq") == 1 then
    vim.health.ok("`jq` is executable (needed by notification hook)")
  else
    vim.health.warn("`jq` is not found (needed by scripts/nvim-notify.sh hook)")
  end
end

---Check Neovim server socket is available (needed for notification hooks)
local function check_server()
  local server = vim.v.servername
  if server and server ~= "" then
    vim.health.ok("Neovim server: " .. server)
  else
    vim.health.warn("Neovim server socket not available (notifications won't work)")
  end
end

---Perform health check for the plugin
---@return nil
M.check = function()
  vim.health.start("claude.nvim health check")
  check_nvim_version()
  check_cmd()
  validate_opts()
  check_jq()
  check_server()
end

return M
