local api = require('command.api')
local config = require('command.config')
local state = require('command.state')
local history = require('command.history')

local M = vim.tbl_extend('keep', {}, api)

M._initialized = false

local function ensure_init()
    if M._initialized then
        return
    end
    M._initialized = true

    history.init()
    state.setup_autocmds()
end

---Initialize command.nvim plugin with optional configuration
function M.setup(opts)
    config.setup(opts or {})

    if M._initialized then
        M._initialized = false
    end
    ensure_init()

    return M
end

---Display a prompt to execute a new command
function M.execute()
    ensure_init()
    return api.execute()
end

---Execute the last executed command
function M.execute_last()
    ensure_init()
    return api.execute_last()
end

---Teardown and reset the plugin state
function M.teardown()
    if not M._initialized then
        return
    end

    state.cleanup(true)
    M._initialized = false
end

return M
