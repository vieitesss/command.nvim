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
local state = require 'command.state'
local history = require 'command.history'

local M = vim.tbl_extend("keep", {}, api)

function M.setup(opts)
    config.setup(opts or {})
    state.setup()
    history.setup(config.values.history)
end

return M
