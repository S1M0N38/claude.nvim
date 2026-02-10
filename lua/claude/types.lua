---@meta

-- lua/claude/init.lua -----------------------------------------------------------

---@class Claude.Plugin
---@field setup function setup the plugin with user options
---@field toggle function toggle the Claude floating terminal
---@field send_selection function send visual selection text to Claude
---@field send_reference function send file reference with line range to Claude

-- lua/claude/config.lua ---------------------------------------------------------

---@class Claude.Config
---@field defaults Claude.DefaultOptions default plugin options
---@field options Claude.Options merged user and default options
---@field setup function setup the plugin configuration

---@class Claude.UserOptions
---@field cmd? string The command to run (optional, default "claude")
---@field float? Claude.FloatOptions Floating window options (optional)
---@field keymaps? Claude.KeymapOptions Keymap configuration (optional)

---@class Claude.DefaultOptions
---@field cmd string The command to run
---@field float Claude.FloatOptions Floating window options
---@field keymaps Claude.KeymapOptions Keymap configuration

---@class Claude.Options
---@field cmd string The command to run (merged from user/default options)
---@field float Claude.FloatOptions Floating window options (merged from user/default options)
---@field keymaps Claude.KeymapOptions Keymap configuration (merged from user/default options)

---@class Claude.FloatOptions
---@field width number Width as fraction of editor (0.0-1.0)
---@field height number Height as fraction of editor (0.0-1.0)
---@field border string Border style for the floating window

---@class Claude.KeymapOptions
---@field enabled boolean Whether to set default keymaps
---@field toggle string Keymap for toggling the terminal
---@field picker string Keymap for opening file picker in terminal mode
---@field explorer string Keymap for opening file explorer in terminal mode

-- lua/claude/terminal.lua -------------------------------------------------------

---@class Claude.Terminal
---@field open function open the floating terminal
---@field close function close the floating terminal window
---@field toggle function toggle the floating terminal
---@field is_open function check if the terminal window is open
---@field is_running function check if the terminal process is running
---@field send function send text to the terminal
---@field get_buf function get the terminal buffer number
---@field setup_keymaps function setup terminal-mode keymaps for a buffer

-- lua/claude/send.lua -----------------------------------------------------------

---@class Claude.Send
---@field get_visual_range function get the visual line range
---@field get_visual_selection function get the current visual selection
---@field send_selection function send visual selection text to terminal
---@field send_reference function send file reference with line range to terminal

-- lua/claude/notify.lua --------------------------------------------------------

---@class Claude.Notify
---@field from_hook fun(path: string): string process a hook notification from a temp file

-- lua/claude/picker.lua ---------------------------------------------------------

---@class Claude.Picker
---@field pick_files fun(): nil open snacks file picker and send selections to terminal
---@field is_available fun(): boolean check if snacks.nvim is available

-- lua/claude/explorer.lua -------------------------------------------------------

---@class Claude.Explorer
---@field browse_files fun(): nil open mini.files explorer and send selection to terminal
---@field is_available fun(): boolean check if mini.files is available

-- lua/claude/health.lua ---------------------------------------------------------

---@class Claude.Health
---@field check fun(): nil perform health check for the plugin
