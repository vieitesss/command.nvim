local M = {}

local ui = require 'command.ui'
local utils = require 'command.utils'
local state = require 'command.state'
local actions = require 'command.actions'

-- Displays a prompt to execute a new command.
function M.execute()
    state.set_main_win(vim.api.nvim_get_current_win())

    local ok = ui.show_prompt()
    if not ok then
        utils.print_error("Could not create the prompt window")
        return
    end

    vim.cmd("startinsert")

    require('command.ui.keymaps.prompt').apply()
end

-- Executes the last executed command.
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
