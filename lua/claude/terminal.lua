---@class Claude.Terminal
local M = {}

local slots = {} ---@type table<number, {buf: number, job: number?}>
local current = 1
local win = nil ---@type number?

---Get the slot entry for a given slot number (nil-safe)
---@param n? number: slot number (defaults to current)
---@return {buf: number, job: number?}?
local function get_slot(n)
  return slots[n or current]
end

---Build the window title showing all active slots with current in brackets
---@return string: formatted title (e.g., " Claude [1] ", " Claude 1 [2] 3 ")
local function build_title()
  local slot_nums = M.get_active_slots()

  if #slot_nums == 0 then
    return " Claude [" .. current .. "] "
  end

  local parts = {}
  for _, n in ipairs(slot_nums) do
    if n == current then
      table.insert(parts, "[" .. n .. "]")
    else
      table.insert(parts, tostring(n))
    end
  end

  return " Claude " .. table.concat(parts, " ") .. " "
end

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
    title = build_title(),
    title_pos = "center",
  }
end

---Ensure the float window is open and showing the given buffer
---@param buf number: buffer to display
local function ensure_window(buf)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_config(win, { title = build_title(), title_pos = "center" })
  else
    win = vim.api.nvim_open_win(buf, true, float_opts())
  end
end

---Start a terminal job in a slot that has a buffer but no job.
---The buffer must already be displayed in the current window (jobstart term=true requires this).
---@param n number: slot number
local function start_job(n)
  local slot = slots[n]
  if not slot or slot.job then
    return
  end

  local config = require("claude.config").options
  local cmd = config.cmd
  local server = vim.v.servername
  if server and server ~= "" then
    cmd = "NVIM_SERVER=" .. vim.fn.shellescape(server) .. " " .. cmd
  end

  local buf = slot.buf
  slot.job = vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function()
      -- Verify this callback still owns the slot (guards against rapid slot reuse)
      if not slots[n] or slots[n].buf ~= buf then
        return
      end
      slots[n] = nil
      vim.schedule(function()
        if win and vim.api.nvim_win_is_valid(win) then
          local win_buf = vim.api.nvim_win_get_buf(win)
          if win_buf == buf then
            vim.api.nvim_win_close(win, true)
            win = nil
          end
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
    end,
  })
  vim.bo[buf].filetype = "claude"
end

---Ensure a slot exists with a buffer (creates buffer if needed, does not start job)
---@param n number: slot number
local function ensure_slot_buf(n)
  local slot = slots[n]
  if slot and vim.api.nvim_buf_is_valid(slot.buf) then
    return
  end
  if slot and slot.job then
    pcall(vim.fn.jobstop, slot.job)
  end
  slots[n] = { buf = vim.api.nvim_create_buf(false, true), job = nil }
end

---Activate a slot: ensure buffer exists, show it in the window, start job if needed
---@param n number: slot number
local function activate_slot(n)
  ensure_slot_buf(n)
  local slot = slots[n]
  ensure_window(slot.buf)
  if not slot.job then
    start_job(n)
  end
  vim.cmd("startinsert")
end

---Open the floating terminal (reuses existing buffer/job in current slot)
function M.open()
  activate_slot(current)
end

---Close the floating window (all slot processes keep running)
function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    if vim.fn.mode() == "t" then
      vim.cmd("stopinsert")
    end
    vim.api.nvim_win_close(win, true)
  end
  win = nil
end

---Toggle the floating terminal
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

---Switch to a specific slot (1-9). Creates instance if slot is empty.
---@param n number: slot number (1-9)
function M.switch(n)
  if n < 1 or n > 9 then
    return
  end
  current = n
  activate_slot(current)
end

---Check if the terminal window is currently open
---@return boolean
function M.is_open()
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

---Check if the current slot's terminal process is running
---@return boolean
function M.is_running()
  local slot = get_slot()
  return slot ~= nil and slot.job ~= nil
end

---Get the current slot's terminal buffer number
---@return number?: buffer number or nil if not created
function M.get_buf()
  local slot = get_slot()
  return slot and slot.buf or nil
end

---Check if a buffer belongs to any Claude terminal slot
---@param bufnr number: buffer number to check
---@return boolean
function M.is_claude_buf(bufnr)
  for _, slot in pairs(slots) do
    if slot.buf == bufnr then
      return true
    end
  end
  return false
end

---Get all active slot numbers (slots with buffers/jobs), sorted ascending
---@return number[]: array of slot numbers
function M.get_active_slots()
  local slot_nums = {}
  for n in pairs(slots) do
    table.insert(slot_nums, n)
  end
  table.sort(slot_nums)
  return slot_nums
end

---Send text to the current slot's terminal
---@param text string: text to send
function M.send(text)
  local slot = get_slot()
  if not slot or not slot.job then
    vim.notify("claude.nvim: terminal is not running", vim.log.levels.ERROR)
    return
  end
  local ok = pcall(vim.api.nvim_chan_send, slot.job, text)
  if not ok then
    vim.notify("claude.nvim: failed to send to terminal", vim.log.levels.ERROR)
    slot.job = nil
  end
end

---Find which slot owns a given buffer
---@param bufnr number
---@return number?: slot number or nil
local function slot_for_buf(bufnr)
  for n, slot in pairs(slots) do
    if slot.buf == bufnr then
      return n
    end
  end
  return nil
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

  vim.keymap.set("t", config.keymaps.explorer, function()
    vim.cmd("stopinsert")
    vim.schedule(function()
      require("claude.explorer").browse_files()
    end)
  end, { buffer = bufnr, desc = "Open file explorer", silent = true })

  -- Slot-switching keymaps (<C-1> through <C-9>)
  for i = 1, 9 do
    vim.keymap.set("t", "<C-" .. i .. ">", function()
      M.switch(i)
    end, { buffer = bufnr, desc = "Switch to Claude slot " .. i, silent = true })
  end

  -- Double-Esc: find which slot owns this buffer for correct job targeting
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
    local n = slot_for_buf(bufnr)
    local slot = n and slots[n]
    if not slot or not slot.job then
      return
    end

    if esc_pending then
      clear_esc_timer()
      esc_pending = false
      vim.cmd("stopinsert")
    else
      esc_pending = true
      clear_esc_timer()
      esc_timer = vim.uv.new_timer()
      esc_timer:start(
        ESC_TIMEOUT_MS,
        0,
        vim.schedule_wrap(function()
          esc_pending = false
          clear_esc_timer()
          local s = n and slots[n]
          if s and s.job then
            pcall(vim.api.nvim_chan_send, s.job, "\27")
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
      local n = slot_for_buf(bufnr)
      if n then
        slots[n] = nil
      end
    end,
  })
end

return M
