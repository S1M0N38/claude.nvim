local helpers = require("tests.helpers")
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      helpers.stub_jobstart(child)
      child.lua([[require("claude").setup()]])
    end,
    post_once = child.stop,
  },
})

-- ============================================================================
-- is_available()
-- ============================================================================

T["is_available()"] = MiniTest.new_set()

T["is_available()"]["returns false when snacks not loaded"] = function()
  local available = child.lua_get([[require("claude.picker").is_available()]])
  MiniTest.expect.equality(available, false)
end

-- ============================================================================
-- pick_files()
-- ============================================================================

T["pick_files()"] = MiniTest.new_set()

T["pick_files()"]["notifies when snacks not available"] = function()
  child.lua([[
    _G._test_notifies = {}
    local _real_notify = vim.notify
    vim.notify = function(msg, level)
      table.insert(_G._test_notifies, { msg = msg, level = level })
    end
  ]])

  child.lua([[require("claude.picker").pick_files()]])

  local notifies = child.lua_get([[_G._test_notifies]])
  MiniTest.expect.equality(#notifies, 1)
  MiniTest.expect.equality(notifies[1].msg, "claude.nvim: snacks.nvim is required for file picker")
  MiniTest.expect.equality(notifies[1].level, vim.log.levels.WARN)
end

T["pick_files()"]["notifies when terminal not running"] = function()
  -- Mock snacks as available
  child.lua([[
    package.loaded["snacks"] = { picker = { files = function() end } }
  ]])

  child.lua([[
    _G._test_notifies = {}
    local _real_notify = vim.notify
    vim.notify = function(msg, level)
      table.insert(_G._test_notifies, { msg = msg, level = level })
    end
  ]])

  child.lua([[require("claude.picker").pick_files()]])

  local notifies = child.lua_get([[_G._test_notifies]])
  MiniTest.expect.equality(#notifies, 1)
  MiniTest.expect.equality(notifies[1].msg, "claude.nvim: terminal is not running")
  MiniTest.expect.equality(notifies[1].level, vim.log.levels.ERROR)
end

T["pick_files()"]["calls snacks picker when terminal is running"] = function()
  child.lua([[
    _G._picker_called = false
    package.loaded["snacks"] = {
      picker = {
        files = function(opts)
          _G._picker_called = true
          _G._picker_opts = opts
        end,
      },
    }
  ]])

  -- Need to reload picker module to pick up the mock
  child.lua([[package.loaded["claude.picker"] = nil]])

  -- Start terminal so is_running() returns true
  child.lua([[require("claude.terminal").open()]])

  child.lua([[require("claude.picker").pick_files()]])

  local called = child.lua_get([[_G._picker_called]])
  MiniTest.expect.equality(called, true)

  local has_confirm = child.lua_get([[type(_G._picker_opts.confirm) == "function"]])
  MiniTest.expect.equality(has_confirm, true)
end

return T
