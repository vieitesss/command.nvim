-- TODO:
-- - Window options.
-- - Use or not personal shell.
-- - Structure in more files.

local actions = require 'command.actions'
local utils = require 'command.utils'
local hist = require 'command.history'
local ui = require 'command.ui'

local history = {} --- string[] List of commands executed
local orig_win = nil --- int|nil The window before the command execution
local command = "" --- string The command to execute
local executed = false

--- @type CommandExecute
local M = {}

function M.new_command()
    executed = true
    ui.command_prompt(history)
end

function M.exec_command_again()
    if not executed then
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
