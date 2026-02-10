---@class Claude.Picker
local M = {}

---Check if snacks.nvim is available
---@return boolean
function M.is_available()
  return pcall(require, "snacks")
end

---Focus the terminal window and enter insert mode
---@param terminal Claude.Terminal
local function focus_terminal(terminal)
  vim.defer_fn(function()
    local buf = terminal.get_buf()
    if buf then
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 and pcall(vim.api.nvim_set_current_win, win) then
        vim.cmd("startinsert")
      end
    end
  end, 50)
end

---Open snacks file picker and send selected files to Claude terminal
function M.pick_files()
  if not M.is_available() then
    vim.notify("claude.nvim: snacks.nvim is required for file picker", vim.log.levels.WARN)
    return
  end

  local terminal = require("claude.terminal")
  if not terminal.is_running() then
    vim.notify("claude.nvim: terminal is not running", vim.log.levels.ERROR)
    return
  end

  local Snacks = require("snacks")
  Snacks.picker.files({
    on_close = function()
      focus_terminal(terminal)
    end,
    confirm = function(picker, item)
      local items = picker:selected({ fallback = true })
      picker:close()

      if not items or #items == 0 then
        return
      end

      local refs = {}
      for _, sel in ipairs(items) do
        local path = sel.file or sel.text
        if path then
          path = vim.fn.fnamemodify(path, ":~:.")
          refs[#refs + 1] = "@" .. path
        end
      end

      if #refs > 0 and terminal.is_running() then
        terminal.send(" " .. table.concat(refs, " ") .. " ")
      end
    end,
  })
end

return M
