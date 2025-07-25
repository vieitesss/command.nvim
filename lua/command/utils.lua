local M = {}

--- Print an error message prefixed for this plugin
--- @param msg string Error message
function M.print_error(msg)
    vim.notify("[command] " .. msg, vim.log.levels.ERROR)
end


--- @param buf integer The prompt buffer
--- @param win integer The prompt window
--- @param command string The command to insert in the prompt
function M.set_cmd_prompt(buf, win, command)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { command })
    vim.api.nvim_win_set_cursor(win, { 1, #command + 1 })
end


return M
