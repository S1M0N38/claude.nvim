---@class Claude.Plugin
local M = {}

---Setup the claude plugin
---@param opts Claude.UserOptions?: plugin options
M.setup = function(opts)
  require("claude.config").setup(opts)

  local config = require("claude.config").options
  if config.keymaps.enabled then
    vim.keymap.set("n", config.keymaps.toggle, function()
      require("claude.terminal").toggle()
    end, { desc = "Toggle Claude terminal", silent = true })

    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function(ev)
        local claude_buf = require("claude.terminal").get_buf()
        if claude_buf and claude_buf == ev.buf then
          require("claude.terminal").setup_keymaps(ev.buf)
        end
      end,
    })
  end
end

---Toggle the Claude floating terminal
M.toggle = function()
  require("claude.terminal").toggle()
end

---Send visual selection text to the Claude terminal
---@param opts? table: command opts with range, line1, line2
M.send_selection = function(opts)
  require("claude.send").send_selection(opts)
end

---Send file reference with line range to the Claude terminal
M.send_reference = function()
  require("claude.send").send_reference()
end

return M
