---@class Command
---@field execute fun(): nil
---@field execute_last fun(): nil
---@field teardown fun(): nil

local M = {}

local ui = require 'command.ui'
local utils = require 'command.utils'
local state = require 'command.state'
local actions = require 'command.actions'

---Display a prompt to execute a new command.
---Opens an interactive command input window where users can type and execute shell commands.
---The command is stored in history and can be re-executed later.
---@return nil
function M.execute()
    local win = state.get_window_by_name('prompt')
    if win then
        return
    end

    state.set_main_win(vim.api.nvim_get_current_win())

    local ok = ui.show_prompt()
    if not ok then
        utils.print_error("Could not create the prompt window")
        return
    end

    vim.cmd("startinsert")

    require('command.ui.keymaps.prompt').apply()
end

---Execute the last executed command.
---Re-runs the most recently executed command without opening the prompt.
---Requires that at least one command has been executed in the current session.
---@return nil
function M.execute_last()
    state.set_main_win(vim.api.nvim_get_current_win())

    if not state._has_run or #state.history_list() == 0 then
        utils.print_error("Use first `:CommandExecute`")
        return
    end

    local last = state.history_last()
    actions.exec_command(last)

    require('command.ui.keymaps.terminal').apply()
end

return M
