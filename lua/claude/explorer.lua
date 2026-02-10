---@class Claude.Explorer
local M = {}

---Check if mini.files is available
---@return boolean
function M.is_available()
  return pcall(require, "mini.files")
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

---Open mini.files explorer and send selected entry as @path reference to Claude terminal
function M.browse_files()
  if not M.is_available() then
    vim.notify("claude.nvim: mini.files is required for file explorer", vim.log.levels.WARN)
    return
  end

  local terminal = require("claude.terminal")
  if not terminal.is_running() then
    vim.notify("claude.nvim: terminal is not running", vim.log.levels.ERROR)
    return
  end

  local MiniFiles = require("mini.files")
  MiniFiles.open(nil, false)

  local group = vim.api.nvim_create_augroup("ClaudeExplorer", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      vim.keymap.set("n", "<CR>", function()
        local entry = MiniFiles.get_fs_entry()
        if not entry then
          return
        end

        local path = entry.path
        if not path or path == "" then
          return
        end

        -- Strip any minifiles:// prefix
        path = path:gsub("^minifiles://", "")
        path = vim.fn.fnamemodify(path, ":~:.")

        MiniFiles.close()
        vim.api.nvim_del_augroup_by_name("ClaudeExplorer")

        if terminal.is_running() then
          terminal.send(" @" .. path .. " ")
        end

        focus_terminal(terminal)
      end, { buffer = args.data.buf_id, desc = "Send reference to Claude" })
    end,
  })
end

return M
