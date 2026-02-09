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
-- User commands existence
-- ============================================================================

T["user commands"] = MiniTest.new_set()

T["user commands"]["ClaudeToggle is registered"] = function()
  local exists = child.lua_get([[vim.fn.exists(":ClaudeToggle") == 2]])
  MiniTest.expect.equality(exists, true)
end

T["user commands"]["ClaudeSend is registered"] = function()
  local exists = child.lua_get([[vim.fn.exists(":ClaudeSend") == 2]])
  MiniTest.expect.equality(exists, true)
end

T["user commands"]["ClaudeSendRef is registered"] = function()
  local exists = child.lua_get([[vim.fn.exists(":ClaudeSendRef") == 2]])
  MiniTest.expect.equality(exists, true)
end

-- ============================================================================
-- ClaudeToggle
-- ============================================================================

T["ClaudeToggle"] = MiniTest.new_set()

T["ClaudeToggle"]["opens terminal"] = function()
  child.cmd("ClaudeToggle")

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, true)
end

T["ClaudeToggle"]["closes terminal on second call"] = function()
  child.cmd("ClaudeToggle")
  child.cmd("ClaudeToggle")

  local is_open = child.lua_get([[require("claude.terminal").is_open()]])
  MiniTest.expect.equality(is_open, false)
end

return T
