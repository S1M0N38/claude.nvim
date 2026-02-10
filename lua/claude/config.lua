---@class Claude.Config
local M = {}

---@class Claude.DefaultOptions
M.defaults = {
  cmd = "claude",
  float = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
  },
  keymaps = {
    enabled = true,
    toggle = "<C-.>",
    picker = "<C-f>",
  },
}

---@class Claude.Options
M.options = {}

---Extend the defaults options table with the user options
---@param opts Claude.UserOptions?: plugin options
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
