---@class Claude.Send
local M = {}

---Get the visual line range, handling both in-visual-mode and after-visual-mode
---@return number start_line, number end_line (1-indexed)
function M.get_visual_range()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    -- In visual mode: '< and '> are stale, use live anchor + cursor
    local anchor = vim.fn.getpos("v")[2]
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    return math.min(anchor, cursor), math.max(anchor, cursor)
  else
    return vim.fn.line("'<"), vim.fn.line("'>")
  end
end

---Get the current visual selection as a table of lines
---@return string[]: lines of the visual selection
function M.get_visual_selection()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    -- In visual mode: '< and '> are stale, use live positions
    return vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
  else
    -- After visual mode: marks are updated
    return vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
  end
end

---Send the visual selection text to the Claude terminal
---@param opts? table: command opts with range, line1, line2
function M.send_selection(opts)
  local terminal = require("claude.terminal")
  if not terminal.is_running() then
    vim.notify("claude.nvim: terminal is not running", vim.log.levels.ERROR)
    return
  end

  local lines
  if opts and opts.range and opts.range > 0 then
    -- Range provided by command (e.g. :'<,'>ClaudeSend) — most reliable
    lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
  else
    lines = M.get_visual_selection()
  end

  local text = table.concat(lines, "\n")
  terminal.send(text .. "\n")

  if not terminal.is_open() then
    terminal.open()
  end
end

---Send a file reference with line range to the Claude terminal
function M.send_reference()
  local terminal = require("claude.terminal")
  if not terminal.is_running() then
    vim.notify("claude.nvim: terminal is not running", vim.log.levels.ERROR)
    return
  end

  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
  local start_line, end_line = M.get_visual_range()
  local range = start_line == end_line and ("#L" .. start_line) or ("#L" .. start_line .. "-" .. end_line)
  local ref = " @" .. path .. range .. " "
  terminal.send(ref)

  if not terminal.is_open() then
    terminal.open()
  end
end

return M
