local M = {}

local new_set = MiniTest.new_set
local expect = MiniTest.expect
local eq = MiniTest.expect.equality

-- Re-export for convenience
M.new_set = new_set
M.expect = expect
M.eq = eq

--- Reset all plugin modules so they reload cleanly
function M.reset_plugin()
  package.loaded["claude"] = nil
  package.loaded["claude.config"] = nil
  package.loaded["claude.terminal"] = nil
  package.loaded["claude.send"] = nil
  package.loaded["claude.notify"] = nil
  package.loaded["claude.health"] = nil
  package.loaded["claude.picker"] = nil
  package.loaded["claude.explorer"] = nil
end

--- Setup plugin with given options (resets first)
---@param opts table?
function M.setup_plugin(opts)
  M.reset_plugin()
  require("claude").setup(opts or {})
end

--- Stub vim.fn.jobstart in a child Neovim process to avoid spawning real CLI.
--- Uses `cat` as a harmless terminal process.
---@param child table: MiniTest child process object
function M.stub_jobstart(child)
  child.lua([[
    _G._test_jobstart_calls = {}
    local _real_jobstart = vim.fn.jobstart
    vim.fn.jobstart = function(cmd, opts)
      table.insert(_G._test_jobstart_calls, { cmd = cmd, opts = opts })
      if opts and opts.term then
        local safe_opts = vim.tbl_extend("force", {}, opts)
        safe_opts.on_exit = function()
          if opts.on_exit then opts.on_exit() end
        end
        return _real_jobstart("cat", safe_opts)
      end
      return 42
    end
  ]])
end

return M
