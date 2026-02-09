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

--- Helper: intercept nvim_chan_send calls in the child process
local function setup_send_spy()
  child.lua([[
    _G._sent_text = {}
    vim.api.nvim_chan_send = function(_, text)
      table.insert(_G._sent_text, text)
    end
  ]])
end

-- ============================================================================
-- send_selection()
-- ============================================================================

T["send_selection()"] = MiniTest.new_set()

T["send_selection()"]["sends visual selection text to terminal"] = function()
  setup_send_spy()
  child.lua([[
    require("claude.terminal").open()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello", "world" })
    vim.api.nvim_set_current_buf(buf)

    -- Set visual marks for both lines
    vim.api.nvim_buf_set_mark(buf, "<", 1, 0, {})
    vim.api.nvim_buf_set_mark(buf, ">", 2, 4, {})
    vim.fn.visualmode = function() return "V" end

    require("claude.send").send_selection()
  ]])

  local sent = child.lua_get([=[_G._sent_text[1]]=])
  MiniTest.expect.equality(sent, "hello\nworld\n")
end

T["send_selection()"]["notifies when terminal is not running"] = function()
  child.lua([[
    _G._notified = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if msg:match("not running") then _G._notified = true end
    end
    require("claude.send").send_selection()
  ]])

  local notified = child.lua_get([[_G._notified]])
  MiniTest.expect.equality(notified, true)
end

-- ============================================================================
-- send_reference()
-- ============================================================================

T["send_reference()"] = MiniTest.new_set()

T["send_reference()"]["notifies when terminal is not running"] = function()
  child.lua([[
    _G._notified = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if msg:match("not running") then _G._notified = true end
    end
    require("claude.send").send_reference()
  ]])

  local notified = child.lua_get([[_G._notified]])
  MiniTest.expect.equality(notified, true)
end

T["send_reference()"]["sends file path with line range"] = function()
  setup_send_spy()
  child.lua([[
    require("claude.terminal").open()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "line 1", "line 2", "line 3", "line 4", "line 5",
      "line 6", "line 7", "line 8", "line 9", "line 10",
    })
    vim.api.nvim_buf_set_name(buf, "/tmp/test_file.lua")
    vim.api.nvim_set_current_buf(buf)

    -- Set visual marks for lines 3-7
    vim.api.nvim_buf_set_mark(buf, "<", 3, 0, {})
    vim.api.nvim_buf_set_mark(buf, ">", 7, 0, {})

    require("claude.send").send_reference()
  ]])

  local sent = child.lua_get([=[_G._sent_text[1]]=])
  MiniTest.expect.no_equality(sent, vim.NIL)
  -- Should contain the path and line range
  local match = sent:find("#L3%-7")
  MiniTest.expect.no_equality(match, nil)
end

return T
