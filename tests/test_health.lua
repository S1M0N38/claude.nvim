local helpers = require("tests.helpers")
local eq = helpers.eq

local T = MiniTest.new_set({
  hooks = {
    pre_case = helpers.reset_plugin,
  },
})

T["check()"] = MiniTest.new_set()

T["check()"]["runs without errors with default config"] = function()
  helpers.setup_plugin()
  MiniTest.expect.no_error(function()
    require("claude.health").check()
  end)
end

T["check()"]["runs without errors with custom config"] = function()
  helpers.setup_plugin({
    cmd = "claude",
    float = { width = 0.9, height = 0.9, border = "single" },
    keymaps = { enabled = false },
  })
  MiniTest.expect.no_error(function()
    require("claude.health").check()
  end)
end

T["check()"]["handles non-existent command gracefully"] = function()
  -- Setup with a command that doesn't exist
  helpers.setup_plugin({ cmd = "nonexistent-command-xyz" })
  -- Health check should not throw — it reports errors via vim.health
  MiniTest.expect.no_error(function()
    require("claude.health").check()
  end)
end

T["check()"]["handles invalid float config gracefully"] = function()
  helpers.setup_plugin({ float = { width = "invalid" } })
  MiniTest.expect.no_error(function()
    require("claude.health").check()
  end)
end

return T
