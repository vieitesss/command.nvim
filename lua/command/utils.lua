local M = {}

--- Print an error message prefixed for this plugin
--- @param msg string Error message
function M.print_error(msg)
    vim.notify('[command] ' .. msg, vim.log.levels.ERROR)
end

--- @param buf integer The prompt buffer
--- @param win integer The prompt window
--- @param command string The command to insert in the prompt
function M.set_cmd_prompt(buf, win, command)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { command })
    vim.api.nvim_win_set_cursor(win, { 1, #command + 1 })
end

--- Get text from the last visual selection
--- @param buf integer The buffer handle
--- @return string selection The selected text
function M.get_visual_selection(buf)
    local s_mark = vim.api.nvim_buf_get_mark(buf, '<')
    local s_row, s_col_0based = s_mark[1], s_mark[2]

    local e_mark = vim.api.nvim_buf_get_mark(buf, '>')
    local e_row, e_col_0based = e_mark[1], e_mark[2]

    -- If marks are not set (0,0) or invalid
    if s_row == 0 or e_row == 0 then
        return ''
    end

    -- nvim_buf_get_text end_pos is exclusive, so add 1 to the column of the end mark
    local text_lines = vim.api.nvim_buf_get_text(
        buf,
        s_row - 1, -- start_row (0-based)
        s_col_0based, -- start_col (0-based)
        e_row - 1, -- end_row (0-based)
        e_col_0based + 1, -- end_col (0-based, exclusive)
        {} -- opts
    )

    return table.concat(text_lines, '\n')
end

return M
