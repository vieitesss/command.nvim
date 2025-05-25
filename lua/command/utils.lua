local ui = require 'command.ui'

local M = {}

--- Print an error message prefixed for this plugin
--- @param msg string Error message
function M.print_error(msg)
    vim.api.nvim_err_writeln("[command] " .. msg)
end

--- Execute the command in a terminal split and set up error navigation
--- @param command string The command to execute
function M.exec_command(command)
    if not ui.terminal_win() then
        utils.print_error("Could not create the window to show the command execution")
        return
    end
    -- local cmd = { "/usr/bin/env", "bash", "-c", command }
    local shell = vim.env.SHELL or "/bin/sh"
    local cmd = { shell, "-ic", command }
    vim.fn.termopen(cmd)
end

--- @param buf int The prompt buffer
--- @param win int The prompt window
--- @param command string The command to insert in the prompt
function M.set_cmd_prompt(buf, win, command)
    command = command:gsub("%s+", "")
    local prompt = " " .. command
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt })
    vim.api.nvim_win_set_cursor(win, { 1, #prompt + 1 })
end

return M
