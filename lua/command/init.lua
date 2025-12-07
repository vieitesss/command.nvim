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

---Teardown and reset the plugin state.
---
---Closes all open windows and resets the plugin to an uninitialized state.
---Useful for testing or manually resetting the plugin without restarting Neovim.
---
---Usage:
---```lua
---require('command').teardown()
---```
---
---@return nil
function M.teardown()
    if not M._initialized then
        return
    end

    local state = require 'command.state'

    -- Close all open windows (prompt and terminal)
    for _, window in ipairs(vim.deepcopy(state._windows)) do
        if vim.api.nvim_win_is_valid(window.win) then
            pcall(vim.api.nvim_win_close, window.win, true)
        end
        if vim.api.nvim_buf_is_valid(window.buf) then
            pcall(vim.api.nvim_buf_delete, window.buf, { force = true })
        end
    end

    -- Clear state
    state._windows = {}
    state._has_run = false
    state._main_win = 0
    state._history = {}

    -- Reset initialization flag
    M._initialized = false
end

return M
