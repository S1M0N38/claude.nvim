local claude = require("claude")

-- If you need to setup other plugins for integration testing, implment a setup that looks like the repro/repro.lua

-- Test claude.nvim with default options
describe("Default options", function()
  claude.setup({})
  it("can say hello", function()
    assert.are.equal("Hello John Doe", claude.hello())
  end)
  it("can say bye", function()
    assert.are.equal("Bye John Doe", claude.bye())
  end)
end)

-- Test claude.nvim with user defined options
describe("User defined options", function()
  claude.setup({ name = "John Smith" })
  it("can say hello", function()
    assert.are.equal("Hello John Smith", claude.hello())
  end)
  it("can say bye", function()
    assert.are.equal("Bye John Smith", claude.bye())
  end)
end)

-- RESOURCES:
--   - https://github.com/lunarmodules/busted
--   - https://hiphish.github.io/blog/2024/01/29/testing-neovim-plugins-with-busted/
