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
    end,
    post_once = child.stop,
  },
})

-- ============================================================================
-- Float window appearance
-- ============================================================================

T["float window"] = MiniTest.new_set()

T["float window"]["rounded border (default)"] = function()
  child.lua([[require("claude").setup({ keymaps = { enabled = false } })]])
  child.lua([[require("claude.terminal").open()]])
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["float window"]["single border"] = function()
  child.lua([[
    require("claude").setup({
      keymaps = { enabled = false },
      float = { border = "single" },
    })
  ]])
  child.lua([[require("claude.terminal").open()]])
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["float window"]["custom dimensions"] = function()
  child.lua([[
    require("claude").setup({
      keymaps = { enabled = false },
      float = { width = 0.5, height = 0.5 },
    })
  ]])
  child.lua([[require("claude.terminal").open()]])
  MiniTest.expect.reference_screenshot(child.get_screenshot())
end

T["float window"]["title is displayed"] = function()
  child.lua([[require("claude").setup({ keymaps = { enabled = false } })]])
  child.lua([[require("claude.terminal").open()]])

  -- The float window has title " Claude " centered
  local screenshot = child.get_screenshot()
  -- Check that "Claude" appears in the screenshot text
  local found = false
  for i = 1, #screenshot.text do
    local line = table.concat(screenshot.text[i])
    if line:find("Claude") then
      found = true
      break
    end
  end
  MiniTest.expect.equality(found, true)
end

return T
