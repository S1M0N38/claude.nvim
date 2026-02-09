-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Set up 'mini.test' only when calling headless Neovim (for child process safety)
if #vim.api.nvim_list_uis() == 0 then
  -- Add 'mini.nvim' to 'runtimepath' to use 'mini.test'
  -- Assumed to be installed in 'deps/mini.nvim'
  vim.cmd("set rtp+=deps/mini.nvim")

  -- Set up 'mini.test'
  require("mini.test").setup()
end

-- Ensure consistent test environment
vim.o.swapfile = false
