local M = {}

local expansion = require('command.expansion')
local validation = require('command.validation')
local terminal = require('command.terminal')
local state = require('command.state')

---Executes a command in the terminal
function M.run_command(cmd)
    local context = state.get_context()
    local expanded = expansion.expand(cmd, context)

    if not validation.validate_command(expanded) then
        return false
    end

    terminal.send_command(expanded)
    return true
end

return M
