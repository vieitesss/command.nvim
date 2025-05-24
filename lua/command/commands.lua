--- @type Command.Commands
local M = {}

local ui = require 'command.ui'
local hist = require 'command.history'
local utils = require 'command.utils'

-- Displays a prompt to execute a new command.
function M.new_command()
    local buf, win = ui.command_prompt()
    if buf == -1 then
        utils.print_error("Could not create the prompt window")
        return
    end

    require('command.keymaps.prompt')({
        buf = buf,
        win = win,
        history = M.history,
    })
end

-- Executes the last executed command.
function M.exec_command_again()
    if not M.executed or #M.history == 0 then
        utils.print_error("Use first `:CommandExecute`")
        return
    end
    utils.exec_command(M.history[#M.history])
end

--- @param e boolean
function M._set_executed(e)
    M.executed = e
end

function M.init()
    M.history = hist.get_history() or {}
    M.executed = false

    vim.api.nvim_create_user_command("CommandExecute", M.new_command, {})
    vim.api.nvim_create_user_command("CommandRexecute", M.exec_command_again, {})
end

return M
