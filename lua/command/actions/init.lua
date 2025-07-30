local ui = require 'command.ui'
local utils = require 'command.utils'

local M = {}

local ERROR_TERMINAL_NOT_CREATED = "Could not create the terminal window"

function M.exec_command(command)
    if not ui.show_terminal() then
        utils.print_error(ERROR_TERMINAL_NOT_CREATED)
        return
    end

    local shell = vim.env.SHELL or "/bin/sh"
    local cmd = { shell, "-ic", command }
    vim.fn.jobstart(cmd, { term = true })

    vim.cmd("stopinsert")

    require('command.ui.keymaps.terminal').apply()
end

return M
