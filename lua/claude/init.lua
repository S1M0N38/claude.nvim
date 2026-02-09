---@class Claude.Plugin
local M = {}

---Setup the claude plugin
---@param opts Claude.UserOptions: plugin options
M.setup = function(opts)
  require("claude.config").setup(opts)
end

---Say hello to the user
---@return string: message to the user
M.hello = function()
  local str = "Hello " .. require("claude.config").options.name
  vim.print(str)
  return str
end

---Say bye to the user
---@return string: message to the user
M.bye = function()
  local str = "Bye " .. require("claude.config").options.name
  vim.print(str)
  return str
end

return M
