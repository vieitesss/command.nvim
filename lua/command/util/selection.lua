local M = {}

---@param buf integer The buffer handle
---@return string selection The selected text
function M.get_visual_selection(buf)
    local s_mark = vim.api.nvim_buf_get_mark(buf, '<')
    local s_row, s_col_0based = s_mark[1], s_mark[2]

    local e_mark = vim.api.nvim_buf_get_mark(buf, '>')
    local e_row, e_col_0based = e_mark[1], e_mark[2]

    if s_row == 0 or e_row == 0 then
        return ''
    end

    local text_lines = vim.api.nvim_buf_get_text(buf, s_row - 1, s_col_0based, e_row - 1, e_col_0based + 1, {})

    return table.concat(text_lines, '\n')
end

return M
