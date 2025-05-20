-- TODO:
-- - Tests.
--
-- - Options.
--   - Use or not personal shell.
--   - Prompt
--     - position
--     - size
--     - icon

local utils = require 'command.utils'
local hist = require 'command.history'
local ui = require 'command.ui'

--- @type CommandExecute
local M = {
    executed = false
}

local history = {} --- string[] List of commands executed

function M.new_command()
    local ok = ui.command_prompt(history)
    if not ok then
        utils.print_error("Could not create the prompt window")
    end
end

function M.exec_command_again()
    if not M.executed or #history == 0 then
        utils.print_error("Use first `:CommandExecute`")
        return
    end
    utils.exec_command(history[#history])
end

function M.setup()
    history = hist.get_history()
    vim.api.nvim_create_user_command("CommandExecute", M.new_command, {})
    vim.api.nvim_create_user_command("CommandRexecute", M.exec_command_again, {})
end

M.setup()

return M
