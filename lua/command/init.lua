-- TODO:
-- - Tests.
--
-- - Options.
--   - Use or not personal shell.
--   - Prompt
--     - position
--     - size
--     - icon

local _ = require 'command.history'
local commands = require 'command.commands'

--- @type Command.Execute
local M = {
    has_setup = true
}

function M.setup()
    commands.init()
end

M.setup()

return M
