---@class Claude.Terminal
local M = {}

local slots = {} ---@type table<number, {buf: number, job: number?}>
local current = 1
local win = nil ---@type number?
local indicators = {} ---@type table<number, string>
local saved_state = {} ---@type table<number, {mode: string, cursor: {line: integer, col: integer}}>?

---Get the slot entry for a given slot number (nil-safe)
---@param n? number: slot number (defaults to current)
---@return {buf: number, job: number?}?
local function get_slot(n)
  return slots[n or current]
end

---Build the window title showing all active slots with current in brackets
---Includes notification indicators (!, ?, ✓) next to slot numbers
---@return string: formatted title (e.g., " Claude [1] ", " Claude 1 [2!] 3? ")
local function build_title()
  local slot_nums = M.get_active_slots()

  if #slot_nums == 0 then
    local ind = indicators[current] or ""
    return " Claude [" .. ind .. current .. "] "
  end

  local parts = {}
  for _, n in ipairs(slot_nums) do
    local ind = indicators[n] or ""
    if n == current then
      table.insert(parts, "[" .. ind .. n .. "]")
    else
      table.insert(parts, ind .. n)
    end
  end

  return " Claude " .. table.concat(parts, " ") .. " "
end

---Find the nearest active slot to a given slot number (prefers lower on tie)
---@param target number: slot number to find nearest to
---@return number?: nearest active slot number, or nil if none exist
local function find_nearest_slot(target)
  local active = M.get_active_slots()
  if #active == 0 then
    return nil
  end

  local nearest = nil
  local min_dist = math.huge

  for _, n in ipairs(active) do
    local dist = math.abs(n - target)
    if dist < min_dist or (dist == min_dist and n < nearest) then
      nearest = n
      min_dist = dist
    end
  end

  return nearest
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
---@return integer win: the window handle
local function ensure_window(buf)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_config(win, { title = build_title(), title_pos = "center" })
    ---@diagnostic disable-next-line: need-check-nil
    return win
  else
    local w = vim.api.nvim_open_win(buf, true, float_opts())
    win = w
    return w
  end
end

local activate_slot -- forward declaration (used in on_exit callback below)

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
    cmd = "NVIM_SERVER=" .. vim.fn.shellescape(server) .. " CLAUDE_SLOT=" .. n .. " " .. cmd
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
        local is_displayed = win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf

        -- Delete the dead buffer (use a scratch buffer to keep the window valid)
        if vim.api.nvim_buf_is_valid(buf) then
          if is_displayed and win then
            local scratch = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_win_set_buf(win, scratch)
          end
          vim.api.nvim_buf_delete(buf, { force = true })
        end

        if is_displayed then
          ---@diagnostic disable-next-line: assign-type-mismatch
          local w = win --[[@as integer]]
          local nearest = find_nearest_slot(n)
          if nearest then
            current = nearest
            activate_slot(nearest)
            -- Terminal job just started; defer startinsert so the terminal has time to initialize
            vim.defer_fn(function()
              if w and vim.api.nvim_win_is_valid(w) then
                ---@diagnostic disable: need-check-nil
                vim.api.nvim_set_current_win(w)
                ---@diagnostic enable: need-check-nil
                local state = saved_state[nearest]
                local state = saved_state[nearest]
                if state and state.mode == "t" then
                  vim.cmd("startinsert")
                elseif not state then
                  vim.cmd("startinsert")
                end
                -- If state.mode == "n", don't call startinsert
              end
            end, 50)
          else
            vim.api.nvim_win_close(w, true)
            win = nil
          end
        elseif win and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_set_config(win, { title = build_title(), title_pos = "center" })
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
---@param force_terminal? boolean: if true, always enter terminal mode
activate_slot = function(n, force_terminal)
  ensure_slot_buf(n)
  local slot = slots[n]
  local w = ensure_window(slot.buf)
  if not slot.job then
    start_job(n)
  end

  if force_terminal then
    vim.cmd("startinsert")
  else
    -- Restore saved mode and cursor, or default to terminal mode
    local state = saved_state[n]
    if state then
      ---@diagnostic disable: need-check-nil
      vim.api.nvim_win_set_cursor(w, state.cursor)
      ---@diagnostic enable: need-check-nil
      if state.mode == "t" then
        vim.cmd("startinsert")
      end
      -- If mode was "n", we're already in normal mode - do nothing
    else
      vim.cmd("startinsert")
    end
  end
end

---Open the floating terminal (reuses existing buffer/job in current slot)
---@param opts? table: options with force_terminal boolean
function M.open(opts)
  opts = opts or {}
  activate_slot(current, opts.force_terminal)
end

---Close the floating window (all slot processes keep running)
function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    -- Save current mode and cursor position
    local mode = vim.fn.mode()
    local cursor = vim.api.nvim_win_get_cursor(win) --[[@as {line: integer, col: integer}]]
    saved_state[current] = {
      mode = mode,
      cursor = cursor,
    }

    if mode == "t" then
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
  indicators[n] = nil -- clear indicator when visiting
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

---Set the indicator symbol for a slot
---@param n number: slot number
---@param symbol string: indicator symbol (!, ?, ✓)
function M.set_indicator(n, symbol)
  indicators[n] = symbol
end

---Clear the indicator for a slot
---@param n number: slot number
function M.clear_indicator(n)
  indicators[n] = nil
end

---Refresh the window title (noop if window not open)
function M.refresh_title()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_config(win, { title = build_title(), title_pos = "center" })
  end
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

---Switch to the previous active slot (circular navigation)
function M.nav_prev()
  local active = M.get_active_slots()
  if #active <= 1 then
    return
  end

  local idx = nil
  for i, n in ipairs(active) do
    if n == current then
      idx = i
      break
    end
  end

  if not idx then
    idx = 1
  else
    idx = idx - 1
    if idx < 1 then
      idx = #active
    end
  end

  M.switch(active[idx])
end

---Switch to the next active slot (circular navigation)
function M.nav_next()
  local active = M.get_active_slots()
  if #active <= 1 then
    return
  end

  local idx = nil
  for i, n in ipairs(active) do
    if n == current then
      idx = i
      break
    end
  end

  if not idx then
    idx = 1
  else
    idx = idx + 1
    if idx > #active then
      idx = 1
    end
  end

  M.switch(active[idx])
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
    vim.keymap.set({ "n", "t" }, "<C-" .. i .. ">", function()
      M.switch(i)
    end, { buffer = bufnr, desc = "Switch to Claude slot " .. i, silent = true })
  end

  -- Relative navigation keymaps
  vim.keymap.set("t", config.keymaps.nav_left, function()
    M.nav_prev()
  end, { buffer = bufnr, desc = "Navigate to previous Claude slot", silent = true })

  vim.keymap.set("t", config.keymaps.nav_right, function()
    M.nav_next()
  end, { buffer = bufnr, desc = "Navigate to next Claude slot", silent = true })

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
        saved_state[n] = nil
      end
    end,
  })
end

return M
