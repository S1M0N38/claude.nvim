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

return T
