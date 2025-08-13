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
local history = require 'command.history'
local ui = require 'command.ui'

local M = vim.tbl_extend("keep", {}, api)

function M.setup(opts)
    config.setup(opts or {}) -- Populate 'config.values'

    history.setup(config.values.history)
    ui.setup(config.values.ui)

    return M
end

return M
