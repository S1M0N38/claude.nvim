---@class Claude.Terminal
local M = {}

local state = {
  buf = nil,
  win = nil,
  job = nil,
}

---Compute float window dimensions from config
---@return table: nvim_open_win config
local function float_opts()
  local config = require("claude.config").options
  local editor_w = vim.o.columns
  local editor_h = vim.o.lines
  local width = math.floor(editor_w * config.float.width)
  local height = math.floor(editor_h * config.float.height)
  local row = math.floor((editor_h - height) / 2)
  local col = math.floor((editor_w - width) / 2)

  return {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = config.float.border,
    style = "minimal",
    title = " Claude ",
    title_pos = "center",
  }
end

---Open the floating terminal (reuses existing buffer/job)
function M.open()
  local config = require("claude.config").options
  local need_job = not state.buf or not vim.api.nvim_buf_is_valid(state.buf)

  if need_job then
    if state.job then
      pcall(vim.fn.jobstop, state.job)
    end
    state.buf = vim.api.nvim_create_buf(false, true)
    state.job = nil
  end

  state.win = vim.api.nvim_open_win(state.buf, true, float_opts())

  if need_job then
    local cmd = config.cmd
    local server = vim.v.servername
    if server and server ~= "" then
      cmd = "NVIM_SERVER=" .. vim.fn.shellescape(server) .. " " .. cmd
    end
    state.job = vim.fn.jobstart(cmd, {
      term = true,
      on_exit = function()
        state.job = nil
        vim.schedule(function()
          if state.win and vim.api.nvim_win_is_valid(state.win) then
            vim.api.nvim_win_close(state.win, true)
            state.win = nil
          end
          if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
            vim.api.nvim_buf_delete(state.buf, { force = true })
            state.buf = nil
          end
        end)
      end,
    })
    vim.bo[state.buf].filetype = "claude"
  end

  vim.cmd("startinsert")
end

---Close the floating window (buffer stays alive)
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    if vim.fn.mode() == "t" then
      vim.cmd("stopinsert")
    end
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

---Toggle the floating terminal
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

---Check if the terminal window is currently open
---@return boolean
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

---Check if the terminal process is running (regardless of window visibility)
---@return boolean
function M.is_running()
  return state.job ~= nil
end

---Get the terminal buffer number
---@return number?: buffer number or nil if not created
function M.get_buf()
  return state.buf
end

---Send text to the terminal
---@param text string: text to send
function M.send(text)
  if not state.job then
    vim.notify("claude.nvim: terminal is not running", vim.log.levels.ERROR)
    return
  end
  local ok = pcall(vim.api.nvim_chan_send, state.job, text)
  if not ok then
    vim.notify("claude.nvim: failed to send to terminal", vim.log.levels.ERROR)
    state.job = nil
  end
end

local ESC_TIMEOUT_MS = 200

---Setup terminal-mode keymaps for the Claude buffer
---@param bufnr number: buffer number to attach keymaps to
function M.setup_keymaps(bufnr)
  local config = require("claude.config").options

  vim.keymap.set("t", config.keymaps.toggle, function()
    M.toggle()
  end, { buffer = bufnr, desc = "Toggle Claude terminal", silent = true })

  vim.keymap.set("t", config.keymaps.picker, function()
    vim.cmd("stopinsert")
    vim.schedule(function()
      require("claude.picker").pick_files()
    end)
  end, { buffer = bufnr, desc = "Open file picker", silent = true })

  local esc_timer = nil
  local esc_pending = false

  local function clear_esc_timer()
    if esc_timer then
      esc_timer:stop()
      esc_timer:close()
      esc_timer = nil
    end
  end

  vim.keymap.set("t", "<Esc>", function()
    if not state.job then
      return
    end

    if esc_pending then
      -- Second Esc within timeout - exit terminal mode (no Esc sent to terminal)
      clear_esc_timer()
      esc_pending = false
      vim.cmd("stopinsert")
    else
      -- First Esc - wait for possible second press before sending to terminal
      esc_pending = true
      clear_esc_timer()
      esc_timer = vim.uv.new_timer()
      esc_timer:start(
        ESC_TIMEOUT_MS,
        0,
        vim.schedule_wrap(function()
          esc_pending = false
          clear_esc_timer()
          -- Timeout expired without second Esc - send Esc to the terminal
          if state.job then
            pcall(vim.api.nvim_chan_send, state.job, "\27")
          end
        end)
      )
    end
  end, { buffer = bufnr, desc = "Double-Esc to exit terminal mode", silent = true })

  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = bufnr,
    once = true,
    callback = function()
      clear_esc_timer()
    end,
  })
end

return M
