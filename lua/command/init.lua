-- TODO:
-- - Tests.
--
-- - Options.
--   - Use or not personal shell.
--   - Prompt
--     - position
--     - size
--     - icon

local hist = require 'command.history'
local commands = require 'command.commands'

--- @type Command.Execute
local M = {}

function M.setup()
    commands.init()
end

M.setup()

return M
