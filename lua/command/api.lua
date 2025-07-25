local M = {}

local ui = require 'command.ui'
local km_prompt = require 'command.ui.keymaps.prompt'
-- local history = require 'command.history'
local utils = require 'command.utils'
-- local state = require 'command.state'

-- local function exec_command(command)
--     if not ui.terminal_win() then
--         M.print_error("Could not create the window to show the command execution")
--         return
--     end
--     -- local cmd = { "/usr/bin/env", "bash", "-c", command }
--     local shell = vim.env.SHELL or "/bin/sh"
--     local cmd = { shell, "-ic", command }
--     vim.fn.termopen(cmd)
-- end

-- Displays a prompt to execute a new command.
function M.run()
    local ok = ui.show_prompt()
    if not ok then
        utils.print_error("Could not create the prompt window")
        return
    end

    vim.cmd("startinsert")

    km_prompt.apply()
end

-- Executes the last executed command.
function M.repeat_last()
    vim.print("hello from api repeat")
    -- if not state._has_run or #history.list() == 0 then
    --     utils.print_error("Use first `:CommandExecute`")
    --     return
    -- end
    -- utils.exec_command(history.last() or "")
end

return M
