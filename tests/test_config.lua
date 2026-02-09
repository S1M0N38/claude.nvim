local helpers = require("tests.helpers")
local eq = helpers.eq

local T = MiniTest.new_set({
  hooks = {
    pre_case = helpers.reset_plugin,
  },
})

T["setup()"] = MiniTest.new_set()

T["setup()"]["uses default options when called with no arguments"] = function()
  require("claude.config").setup()
  local opts = require("claude.config").options

  eq(opts.cmd, "claude")
  eq(opts.float.width, 0.8)
  eq(opts.float.height, 0.8)
  eq(opts.float.border, "rounded")
  eq(opts.keymaps.enabled, true)
  eq(opts.keymaps.toggle, "<C-.>")
end

T["setup()"]["uses default options when called with empty table"] = function()
  require("claude.config").setup({})
  local opts = require("claude.config").options

  eq(opts.cmd, "claude")
  eq(opts.float.width, 0.8)
end

T["setup()"]["merges user options with defaults"] = function()
  require("claude.config").setup({ cmd = "my-claude", float = { width = 0.5 } })
  local opts = require("claude.config").options

  eq(opts.cmd, "my-claude")
  eq(opts.float.width, 0.5)
  -- Unspecified defaults are preserved
  eq(opts.float.height, 0.8)
  eq(opts.float.border, "rounded")
end

T["setup()"]["deep merges nested tables"] = function()
  require("claude.config").setup({ keymaps = { toggle = "<leader>c" } })
  local opts = require("claude.config").options

  eq(opts.keymaps.toggle, "<leader>c")
  eq(opts.keymaps.enabled, true) -- default preserved
end

T["defaults"] = MiniTest.new_set()

T["defaults"]["are not mutated by setup"] = function()
  local defaults_before = vim.deepcopy(require("claude.config").defaults)
  require("claude.config").setup({ cmd = "mutated" })
  local defaults_after = require("claude.config").defaults

  eq(defaults_before.cmd, defaults_after.cmd)
end

return T
