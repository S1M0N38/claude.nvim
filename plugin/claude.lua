vim.api.nvim_create_user_command("ClaudeToggle", function()
  require("claude").toggle()
end, { desc = "Toggle Claude floating terminal" })

vim.api.nvim_create_user_command("ClaudeSend", function(opts)
  require("claude").send_selection(opts)
end, { range = true, desc = "Send visual selection to Claude" })

vim.api.nvim_create_user_command("ClaudeSendRef", function()
  require("claude").send_reference()
end, { range = true, desc = "Send file reference with line range to Claude" })
