local helpers = require("tests.helpers")
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      helpers.stub_jobstart(child)
      child.lua([[require("claude").setup({ keymaps = { enabled = false } })]])
    end,
    post_once = child.stop,
  },
})

-- ============================================================================
-- open()
-- ============================================================================

T["open()"] = MiniTest.new_set()

T["open()"]["creates a floating window"] = function()
  child.lua([[require("claude.terminal").open()]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, true)

  -- Should have more than 1 window (editor + float)
  local win_count = child.lua_get([[#vim.api.nvim_list_wins()]])
  MiniTest.expect.equality(win_count, 2)
end

T["open()"]["creates a terminal buffer"] = function()
  child.lua([[require("claude.terminal").open()]])

  local buf = child.lua_get([[require("claude.terminal").get_buf()]])
  MiniTest.expect.no_equality(buf, vim.NIL)

  local valid = child.lua_get([[vim.api.nvim_buf_is_valid(require("claude.terminal").get_buf())]])
  MiniTest.expect.equality(valid, true)
end

T["open()"]["starts a job"] = function()
  child.lua([[require("claude.terminal").open()]])

  local is_running = child.lua_get([[require("claude.terminal").is_running()]])
  MiniTest.expect.equality(is_running, true)

  local call_count = child.lua_get([[#_G._test_jobstart_calls]])
  MiniTest.expect.equality(call_count, 1)
end

T["open()"]["sets filetype to claude"] = function()
  child.lua([[require("claude.terminal").open()]])

  local ft = child.lua_get([[vim.bo[require("claude.terminal").get_buf()].filetype]])
  MiniTest.expect.equality(ft, "claude")
end

T["open()"]["configures floating window as relative to editor"] = function()
  child.lua([[require("claude.terminal").open()]])

  child.lua([[
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      if cfg.relative ~= "" then
        _G._test_win_config = { relative = cfg.relative, border = cfg.border }
      end
    end
  ]])
  local relative = child.lua_get([[_G._test_win_config.relative]])
  MiniTest.expect.equality(relative, "editor")
end

T["open()"]["reuses existing buffer on second call"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    _G.buf1 = terminal.get_buf()
    terminal.close()
    terminal.open()
    _G.buf2 = terminal.get_buf()
  ]])

  local buf1 = child.lua_get([[_G.buf1]])
  local buf2 = child.lua_get([[_G.buf2]])
  MiniTest.expect.equality(buf1, buf2)
end

-- ============================================================================
-- close()
-- ============================================================================

T["close()"] = MiniTest.new_set()

T["close()"]["closes window"] = function()
  child.lua([[
    require("claude.terminal").open()
    require("claude.terminal").close()
  ]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, false)

  local win_count = child.lua_get([[#vim.api.nvim_list_wins()]])
  MiniTest.expect.equality(win_count, 1)
end

T["close()"]["keeps buffer alive"] = function()
  child.lua([[
    require("claude.terminal").open()
    require("claude.terminal").close()
  ]])

  local buf = child.lua_get([[require("claude.terminal").get_buf()]])
  MiniTest.expect.no_equality(buf, vim.NIL)

  local valid = child.lua_get([[vim.api.nvim_buf_is_valid(require("claude.terminal").get_buf())]])
  MiniTest.expect.equality(valid, true)
end

-- ============================================================================
-- toggle()
-- ============================================================================

T["toggle()"] = MiniTest.new_set()

T["toggle()"]["opens when closed"] = function()
  child.lua([[require("claude.terminal").toggle()]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, true)
end

T["toggle()"]["closes when open"] = function()
  child.lua([[
    require("claude.terminal").toggle()
    require("claude.terminal").toggle()
  ]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, false)
end

T["toggle()"]["re-opens after close"] = function()
  child.lua([[
    require("claude.terminal").toggle()
    require("claude.terminal").toggle()
    require("claude.terminal").toggle()
  ]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, true)
end

-- ============================================================================
-- is_open() / is_running()
-- ============================================================================

T["is_open()"] = MiniTest.new_set()

T["is_open()"]["returns false when nothing is opened"] = function()
  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, false)
end

T["is_running()"] = MiniTest.new_set()

T["is_running()"]["returns false when nothing is started"] = function()
  local is_running = child.lua_get([[require("claude.terminal").is_running()]])
  MiniTest.expect.equality(is_running, false)
end

T["is_running()"]["returns true after open"] = function()
  child.lua([[require("claude.terminal").open()]])

  local is_running = child.lua_get([[require("claude.terminal").is_running()]])
  MiniTest.expect.equality(is_running, true)
end

-- ============================================================================
-- send()
-- ============================================================================

T["send()"] = MiniTest.new_set()

T["send()"]["sends text to terminal channel"] = function()
  child.lua([[
    _G._sent_text = {}
    local orig = vim.api.nvim_chan_send
    vim.api.nvim_chan_send = function(chan, text)
      table.insert(_G._sent_text, text)
    end
    require("claude.terminal").open()
    require("claude.terminal").send("hello world\n")
  ]])

  local sent = child.lua_get([=[_G._sent_text[1]]=])
  MiniTest.expect.equality(sent, "hello world\n")
end

T["send()"]["notifies when terminal is not running"] = function()
  child.lua([[
    _G._notified = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if msg:match("not running") then _G._notified = true end
    end
    require("claude.terminal").send("test")
  ]])

  local notified = child.lua_get([[_G._notified]])
  MiniTest.expect.equality(notified, true)
end

-- ============================================================================
-- get_buf()
-- ============================================================================

T["get_buf()"] = MiniTest.new_set()

T["get_buf()"]["returns nil when not created"] = function()
  local buf = child.lua_get([[require("claude.terminal").get_buf()]])
  MiniTest.expect.equality(buf, vim.NIL)
end

T["get_buf()"]["returns buffer number after open"] = function()
  child.lua([[require("claude.terminal").open()]])

  local buf = child.lua_get([[require("claude.terminal").get_buf()]])
  MiniTest.expect.no_equality(buf, vim.NIL)
end

-- ============================================================================
-- switch()
-- ============================================================================

T["switch()"] = MiniTest.new_set()

T["switch()"]["creates new instance in empty slot"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    terminal.switch(3)
  ]])

  -- Should have spawned 2 jobs (slot 1 from open, slot 3 from switch)
  local call_count = child.lua_get([[#_G._test_jobstart_calls]])
  MiniTest.expect.equality(call_count, 2)

  local is_running = child.lua_get([[require("claude.terminal").is_running()]])
  MiniTest.expect.equality(is_running, true)
end

T["switch()"]["switches buffer in existing window"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    _G.buf1 = terminal.get_buf()
    terminal.switch(2)
    _G.buf2 = terminal.get_buf()
  ]])

  local buf1 = child.lua_get([[_G.buf1]])
  local buf2 = child.lua_get([[_G.buf2]])
  MiniTest.expect.no_equality(buf1, buf2)

  -- Window should still be open (only one float)
  local win_count = child.lua_get([[#vim.api.nvim_list_wins()]])
  MiniTest.expect.equality(win_count, 2)
end

T["switch()"]["switching back preserves original buffer"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    _G.buf1 = terminal.get_buf()
    terminal.switch(2)
    terminal.switch(1)
    _G.buf_back = terminal.get_buf()
  ]])

  local buf1 = child.lua_get([[_G.buf1]])
  local buf_back = child.lua_get([[_G.buf_back]])
  MiniTest.expect.equality(buf1, buf_back)
end

T["switch()"]["opens window if closed"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    terminal.close()
    terminal.switch(2)
  ]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, true)
end

T["switch()"]["ignores out-of-range slot numbers"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    _G.buf_before = terminal.get_buf()
    terminal.switch(0)
    terminal.switch(10)
    _G.buf_after = terminal.get_buf()
  ]])

  local buf_before = child.lua_get([[_G.buf_before]])
  local buf_after = child.lua_get([[_G.buf_after]])
  MiniTest.expect.equality(buf_before, buf_after)
end

-- ============================================================================
-- get_active_slots()
-- ============================================================================

T["get_active_slots()"] = MiniTest.new_set()

T["get_active_slots()"]["returns empty table when no slots exist"] = function()
  local result = child.lua_get([[require("claude.terminal").get_active_slots()]])
  MiniTest.expect.equality(result, {})
end

T["get_active_slots()"]["returns single slot"] = function()
  child.lua([[require("claude.terminal").open()]])

  local result = child.lua_get([[require("claude.terminal").get_active_slots()]])
  MiniTest.expect.equality(result, { 1 })
end

T["get_active_slots()"]["returns multiple slots sorted ascending"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    terminal.switch(5)
    terminal.switch(3)
  ]])

  local result = child.lua_get([[require("claude.terminal").get_active_slots()]])
  MiniTest.expect.equality(result, { 1, 3, 5 })
end

-- ============================================================================
-- title indicator
-- ============================================================================

T["title indicator"] = MiniTest.new_set()

T["title indicator"]["single slot shows brackets"] = function()
  child.lua([[
    require("claude.terminal").open()
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      if cfg.relative == "editor" then
        _G._test_title = cfg.title[1][1]
      end
    end
  ]])

  local title = child.lua_get([[_G._test_title]])
  MiniTest.expect.equality(title, " Claude [1] ")
end

T["title indicator"]["shows all active slots with current in brackets"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    terminal.switch(3)
    terminal.switch(5)
    terminal.switch(3)
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      if cfg.relative == "editor" then
        _G._test_title = cfg.title[1][1]
      end
    end
  ]])

  local title = child.lua_get([[_G._test_title]])
  MiniTest.expect.equality(title, " Claude 1 [3] 5 ")
end

T["title indicator"]["updates when switching slots"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    terminal.switch(2)
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      if cfg.relative == "editor" then
        _G._test_title = cfg.title[1][1]
      end
    end
  ]])

  local title = child.lua_get([[_G._test_title]])
  MiniTest.expect.equality(title, " Claude 1 [2] ")
end

-- ============================================================================
-- on_exit behavior
-- ============================================================================

T["on_exit"] = MiniTest.new_set()

T["on_exit"]["closes window when last slot exits"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    local buf = terminal.get_buf()
    vim.fn.jobstop(vim.b[buf].terminal_job_id)
    vim.wait(1000, function()
      return not terminal.is_open()
    end)
  ]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, false)
end

T["on_exit"]["deletes buffer when job exits"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    _G.test_buf = terminal.get_buf()
    vim.fn.jobstop(vim.b[_G.test_buf].terminal_job_id)
    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(_G.test_buf)
    end)
  ]])

  local valid = child.lua_get([[vim.api.nvim_buf_is_valid(_G.test_buf)]])
  MiniTest.expect.equality(valid, false)
end

T["on_exit"]["switches to nearest slot when displayed slot exits"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()        -- slot 1
    terminal.switch(3)     -- slot 3 (current)
    _G.buf3 = terminal.get_buf()
    vim.fn.jobstop(vim.b[_G.buf3].terminal_job_id)
    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(_G.buf3)
    end)
  ]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, true)

  local active = child.lua_get([[require("claude.terminal").get_active_slots()]])
  MiniTest.expect.equality(active, { 1 })
end

T["on_exit"]["switches to closest active slot"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()        -- slot 1
    terminal.switch(4)     -- slot 4
    terminal.switch(5)     -- slot 5 (current)
    _G.buf5 = terminal.get_buf()
    vim.fn.jobstop(vim.b[_G.buf5].terminal_job_id)
    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(_G.buf5)
    end)
  ]])

  -- Should switch to slot 4 (distance 1) not slot 1 (distance 4)
  child.lua([[
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      if cfg.relative == "editor" then
        _G._test_title = cfg.title[1][1]
      end
    end
  ]])
  local title = child.lua_get([[_G._test_title]])
  MiniTest.expect.equality(title, " Claude 1 [4] ")
end

T["on_exit"]["prefers lower slot number on equidistant tie"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()        -- slot 1
    terminal.switch(5)     -- slot 5
    terminal.switch(3)     -- slot 3 (current, equidistant from 1 and 5)
    _G.buf3 = terminal.get_buf()
    vim.fn.jobstop(vim.b[_G.buf3].terminal_job_id)
    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(_G.buf3)
    end)
  ]])

  -- Should switch to slot 1 (lower on tie, both distance 2)
  child.lua([[
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      if cfg.relative == "editor" then
        _G._test_title = cfg.title[1][1]
      end
    end
  ]])
  local title = child.lua_get([[_G._test_title]])
  MiniTest.expect.equality(title, " Claude [1] 5 ")
end

T["on_exit"]["keeps window on current slot when non-displayed slot exits"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()        -- slot 1
    terminal.switch(3)     -- slot 3
    -- Grab slot 1's job id
    terminal.switch(1)
    _G.buf1 = terminal.get_buf()
    _G.job1 = vim.b[_G.buf1].terminal_job_id
    terminal.switch(3)     -- back to slot 3
    vim.fn.jobstop(_G.job1)
    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(_G.buf1)
    end)
  ]])

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, true)

  local active = child.lua_get([[require("claude.terminal").get_active_slots()]])
  MiniTest.expect.equality(active, { 3 })

  -- Title should reflect only slot 3
  child.lua([[
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local cfg = vim.api.nvim_win_get_config(w)
      if cfg.relative == "editor" then
        _G._test_title = cfg.title[1][1]
      end
    end
  ]])
  local title = child.lua_get([[_G._test_title]])
  MiniTest.expect.equality(title, " Claude [3] ")
end

T["on_exit"]["removes exited slot from active list"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()        -- slot 1
    terminal.switch(2)     -- slot 2
    terminal.switch(3)     -- slot 3
    -- Grab slot 2's job id
    terminal.switch(2)
    _G.buf2 = terminal.get_buf()
    _G.job2 = vim.b[_G.buf2].terminal_job_id
    terminal.switch(3)     -- back to slot 3
    vim.fn.jobstop(_G.job2)
    vim.wait(1000, function()
      return not vim.api.nvim_buf_is_valid(_G.buf2)
    end)
  ]])

  local active = child.lua_get([[require("claude.terminal").get_active_slots()]])
  MiniTest.expect.equality(active, { 1, 3 })
end

-- ============================================================================
-- is_claude_buf()
-- ============================================================================

T["is_claude_buf()"] = MiniTest.new_set()

T["is_claude_buf()"]["returns true for claude buffer"] = function()
  child.lua([[require("claude.terminal").open()]])

  local result = child.lua_get([[
    require("claude.terminal").is_claude_buf(require("claude.terminal").get_buf())
  ]])
  MiniTest.expect.equality(result, true)
end

T["is_claude_buf()"]["returns false for non-claude buffer"] = function()
  local result = child.lua_get([[require("claude.terminal").is_claude_buf(1)]])
  MiniTest.expect.equality(result, false)
end

T["is_claude_buf()"]["detects buffers from any slot"] = function()
  child.lua([[
    local terminal = require("claude.terminal")
    terminal.open()
    _G.buf1 = terminal.get_buf()
    terminal.switch(3)
    _G.buf3 = terminal.get_buf()
  ]])

  local buf1_is_claude = child.lua_get([[require("claude.terminal").is_claude_buf(_G.buf1)]])
  local buf3_is_claude = child.lua_get([[require("claude.terminal").is_claude_buf(_G.buf3)]])
  MiniTest.expect.equality(buf1_is_claude, true)
  MiniTest.expect.equality(buf3_is_claude, true)
end

return T
