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

T["is_available()"]["returns false when mini.files not loaded"] = function()
  -- Unload mini.files so it cannot be found
  child.lua([[package.loaded["mini.files"] = nil]])
  child.lua([[package.preload["mini.files"] = nil]])
  -- Remove mini.nvim from runtimepath so require can't find it
  child.lua([[vim.opt.rtp:remove("deps/mini.nvim")]])
  child.lua([[package.loaded["claude.explorer"] = nil]])

  local available = child.lua_get([[require("claude.explorer").is_available()]])
  MiniTest.expect.equality(available, false)
end

-- ============================================================================
-- browse_files()
-- ============================================================================

T["browse_files()"] = MiniTest.new_set()

T["browse_files()"]["notifies when mini.files not available"] = function()
  -- Unload mini.files so it cannot be found
  child.lua([[package.loaded["mini.files"] = nil]])
  child.lua([[package.preload["mini.files"] = nil]])
  child.lua([[vim.opt.rtp:remove("deps/mini.nvim")]])
  child.lua([[package.loaded["claude.explorer"] = nil]])

  child.lua([[
    _G._test_notifies = {}
    vim.notify = function(msg, level)
      table.insert(_G._test_notifies, { msg = msg, level = level })
    end
  ]])

  child.lua([[require("claude.explorer").browse_files()]])

  local notifies = child.lua_get([[_G._test_notifies]])
  MiniTest.expect.equality(#notifies, 1)
  MiniTest.expect.equality(notifies[1].msg, "claude.nvim: mini.files is required for file explorer")
  MiniTest.expect.equality(notifies[1].level, vim.log.levels.WARN)
end

T["browse_files()"]["notifies when terminal not running"] = function()
  -- Mock mini.files as available
  child.lua([[
    package.loaded["mini.files"] = {
      open = function() end,
      close = function() end,
      get_fs_entry = function() end,
    }
  ]])
  child.lua([[package.loaded["claude.explorer"] = nil]])

  child.lua([[
    _G._test_notifies = {}
    vim.notify = function(msg, level)
      table.insert(_G._test_notifies, { msg = msg, level = level })
    end
  ]])

  child.lua([[require("claude.explorer").browse_files()]])

  local notifies = child.lua_get([[_G._test_notifies]])
  MiniTest.expect.equality(#notifies, 1)
  MiniTest.expect.equality(notifies[1].msg, "claude.nvim: terminal is not running")
  MiniTest.expect.equality(notifies[1].level, vim.log.levels.ERROR)
end

T["browse_files()"]["calls MiniFiles.open when terminal is running"] = function()
  child.lua([[
    _G._mini_files_opened = false
    package.loaded["mini.files"] = {
      open = function(path, fresh)
        _G._mini_files_opened = true
        _G._mini_files_open_path_is_nil = (path == nil)
        _G._mini_files_open_fresh = fresh
      end,
      close = function() end,
      get_fs_entry = function() end,
    }
  ]])

  -- Need to reload explorer module to pick up the mock
  child.lua([[package.loaded["claude.explorer"] = nil]])

  -- Start terminal so is_running() returns true
  child.lua([[require("claude.terminal").open()]])

  child.lua([[require("claude.explorer").browse_files()]])

  local opened = child.lua_get([[_G._mini_files_opened]])
  MiniTest.expect.equality(opened, true)

  local path_is_nil = child.lua_get([[_G._mini_files_open_path_is_nil]])
  MiniTest.expect.equality(path_is_nil, true)

  local fresh = child.lua_get([[_G._mini_files_open_fresh]])
  MiniTest.expect.equality(fresh, false)
end

return T
