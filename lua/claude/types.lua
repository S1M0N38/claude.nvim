---@meta
--- This is a simple "definition file" (https://luals.github.io/wiki/definition-files/),
--- the @meta tag at the top is its hallmark.

-- lua/claude/init.lua -----------------------------------------------------------

---@class Claude.Plugin
---@field setup function setup the plugin with user options
---@field hello function Say hello to the user using configured name
---@field bye function Say goodbye to the user using configured name

-- lua/claude/config.lua ---------------------------------------------------------

---@class Claude.Config
---@field defaults Claude.DefaultOptions default plugin options
---@field options Claude.Options merged user and default options
---@field setup function setup the plugin configuration

---@class Claude.UserOptions
---@field name? string The name of the user to greet (optional)

---@class Claude.DefaultOptions
---@field name string The default name of the user to greet

---@class Claude.Options
---@field name string The name of the user to greet (merged from user/default options)

-- lua/claude/health.lua ---------------------------------------------------------

---@class Claude.Health
---@field check fun(): nil perform health check for the plugin
