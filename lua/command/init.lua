-- TODO:
-- - Tests.
--
-- - Options.
--   - Use or not personal shell.
--   - Prompt
--     - position
--     - size
--     - icon

local api = require 'command.api'
local config = require 'command.config'

local M = vim.tbl_extend("keep", {}, api)

M._initialized = false

-- Internal function to ensure initialization
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

function M.setup(opts)
    config.setup(opts or {})

    if M._initialized then
        M._initialized = false
    end
    ensure_init()

    return M
end

function M.execute()
    ensure_init()
    return api.execute()
end

function M.execute_last()
    ensure_init()
    return api.execute_last()
end

return M
