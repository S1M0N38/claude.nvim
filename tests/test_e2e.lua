local helpers = require("tests.helpers")
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      helpers.stub_jobstart(child)
      -- Set consistent screen size for reproducible screenshots
      child.o.lines = 24
      child.o.columns = 80
      child.lua([[require("claude").setup({ keymaps = { enabled = false } })]])
    end,
    post_once = child.stop,
  },
})

--- Passthrough spy: captures sent text while allowing it to reach the terminal
local function setup_passthrough_spy()
  child.lua([[
    _G._sent_text = {}
    local orig = vim.api.nvim_chan_send
    vim.api.nvim_chan_send = function(chan, text)
      table.insert(_G._sent_text, text)
      return orig(chan, text)
    end
  ]])
end

--- Wait for cat to echo back text and terminal to re-render
local function wait_for_terminal()
  child.lua([[vim.wait(100, function() return false end)]])
end

-- ============================================================================
-- ClaudeToggle
-- ============================================================================

T["ClaudeToggle"] = MiniTest.new_set()

T["ClaudeToggle"]["opens terminal"] = function()
  child.cmd("ClaudeToggle")
  wait_for_terminal()
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["ClaudeToggle"]["closes terminal"] = function()
  child.cmd("ClaudeToggle")
  wait_for_terminal()
  child.cmd("stopinsert")
  child.cmd("ClaudeToggle")
  wait_for_terminal()
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["ClaudeToggle"]["re-opens terminal"] = function()
  child.cmd("ClaudeToggle")
  wait_for_terminal()
  child.cmd("stopinsert")
  child.cmd("ClaudeToggle")
  wait_for_terminal()
  child.cmd("ClaudeToggle")
  wait_for_terminal()
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

-- ============================================================================
-- ClaudeSend
-- ============================================================================

T["ClaudeSend"] = MiniTest.new_set()

T["ClaudeSend"]["sends selection to terminal"] = function()
  setup_passthrough_spy()
  child.lua([[
    require("claude.terminal").open()
  ]])
  wait_for_terminal()

  -- Leave terminal insert mode, create a buffer with content
  child.cmd("stopinsert")
  child.lua([[
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello", "world" })
    vim.api.nvim_set_current_buf(buf)

    -- Set visual marks for both lines
    vim.api.nvim_buf_set_mark(buf, "<", 1, 0, {})
    vim.api.nvim_buf_set_mark(buf, ">", 2, 4, {})
    vim.fn.visualmode = function() return "V" end

    require("claude.send").send_selection()
  ]])
  wait_for_terminal()

  -- Verify correct text was sent
  local sent = child.lua_get([=[_G._sent_text[1]]=])
  MiniTest.expect.equality(sent, "hello\nworld\n")

  -- Verify terminal is visible with the sent text
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["ClaudeSend"]["auto-opens terminal when closed"] = function()
  setup_passthrough_spy()
  child.lua([[require("claude.terminal").open()]])
  wait_for_terminal()

  -- Close the window (but keep the job alive)
  child.cmd("stopinsert")
  child.lua([[require("claude.terminal").close()]])
  wait_for_terminal()

  -- Send selection — should re-open the terminal
  child.lua([[
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello", "world" })
    vim.api.nvim_set_current_buf(buf)

    vim.api.nvim_buf_set_mark(buf, "<", 1, 0, {})
    vim.api.nvim_buf_set_mark(buf, ">", 2, 4, {})
    vim.fn.visualmode = function() return "V" end

    require("claude.send").send_selection()
  ]])
  wait_for_terminal()

  -- Terminal should be re-opened showing the sent text
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

-- ============================================================================
-- ClaudeSendRef
-- ============================================================================

T["ClaudeSendRef"] = MiniTest.new_set()

T["ClaudeSendRef"]["sends reference to terminal"] = function()
  setup_passthrough_spy()
  child.lua([[require("claude.terminal").open()]])
  wait_for_terminal()

  child.cmd("stopinsert")
  child.lua([[
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
  wait_for_terminal()

  -- Verify sent text contains the path and line range
  local sent = child.lua_get([=[_G._sent_text[1]]=])
  MiniTest.expect.no_equality(sent, vim.NIL)
  local match = sent:find("#L3%-7")
  MiniTest.expect.no_equality(match, nil)

  -- Verify terminal shows the reference
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["ClaudeSendRef"]["single line reference"] = function()
  setup_passthrough_spy()
  child.lua([[require("claude.terminal").open()]])
  wait_for_terminal()

  child.cmd("stopinsert")
  child.lua([[
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "line 1", "line 2", "line 3", "line 4", "line 5",
    })
    vim.api.nvim_buf_set_name(buf, "/tmp/test_file.lua")
    vim.api.nvim_set_current_buf(buf)

    -- Set visual marks on same line
    vim.api.nvim_buf_set_mark(buf, "<", 3, 0, {})
    vim.api.nvim_buf_set_mark(buf, ">", 3, 5, {})

    require("claude.send").send_reference()
  ]])
  wait_for_terminal()

  -- Verify single-line format (no range)
  local sent = child.lua_get([=[_G._sent_text[1]]=])
  MiniTest.expect.no_equality(sent, vim.NIL)
  local match_single = sent:find("#L3 ")
  MiniTest.expect.no_equality(match_single, nil)
  -- Should NOT contain a range
  local match_range = sent:find("#L3%-")
  MiniTest.expect.equality(match_range, nil)

  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

return T
