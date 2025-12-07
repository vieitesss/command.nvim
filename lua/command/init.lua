-- TODO:
-- - Tests.
--
-- - Options.
--   - Use or not personal shell.
--   - Prompt
--     - position
--     - size
--     - icon

---@alias CommandSetupOpts table Configuration options for command.nvim
---@alias CommandModule table Command module with setup and API functions

local api = require 'command.api'
local config = require 'command.config'

local M = vim.tbl_extend("keep", {}, api)

M._initialized = false

---Internal function to ensure initialization.
---Lazily initializes history and UI subsystems on first use.
---@return nil
local function ensure_init()
    if M._initialized then
        return
    end
    M._initialized = true

    local history = require 'command.history'
    local ui = require 'command.ui'

    history.setup(config.values.history)
    ui.setup(config.values.ui)
end

---Initialize command.nvim plugin with optional configuration.
---
---Usage:
---```lua
---require('command').setup({
---    history = { max = 200, picker = 'fzf-lua' },
---    ui = {
---        prompt = { max_width = 40, ghost_text = true },
---        terminal = { height = 0.25, split = 'below' }
---    }
---})
---```
---
---All options are optional. If not provided, defaults are used.
---The plugin will auto-initialize on first use if setup() is not called.
---
---@param opts? CommandSetupOpts Optional configuration table
---@return CommandModule
function M.setup(opts)
    config.setup(opts or {})

    if M._initialized then
        M._initialized = false
    end
    ensure_init()

    return M
end

---Display a prompt to execute a new command.
---Opens an interactive command input window where users can type and execute shell commands.
---The command is stored in history and can be re-executed later.
---@return nil
function M.execute()
    ensure_init()
    return api.execute()
end

---Execute the last executed command.
---Re-runs the most recently executed command without opening the prompt.
---Requires that at least one command has been executed in the current session.
---@return nil
function M.execute_last()
    ensure_init()
    return api.execute_last()
end

return M
