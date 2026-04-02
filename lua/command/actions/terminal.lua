local notify = require('command.util.notify')
local parser = require('command.quickfix.parser')
local terminal = require('command.ui.terminal')

local M = {}

function M.close()
    terminal.close()
end

function M.hide()
    terminal.hide()
end

function M.follow_error()
    local line = terminal.get_current_line()
    if not line then
        return
    end

    local error_info = parser.parse_line(line)
    if not error_info or not error_info.file then
        return
    end

    terminal.close()
    vim.cmd('edit ' .. vim.fn.fnameescape(error_info.file))

    if error_info.line then
        local buf = vim.api.nvim_get_current_buf()
        local line_count = vim.api.nvim_buf_line_count(buf)
        local target_line = math.max(1, math.min(error_info.line, line_count))
        vim.api.nvim_win_set_cursor(0, { target_line, error_info.col or 0 })
    end

    vim.cmd('normal! zz')
end

function M.send_to_quickfix()
    local qf_list = parser.build_quickfix_items(terminal.get_lines())
    if #qf_list == 0 then
        notify.warn('No output to add to quickfix list')
        return
    end

    vim.fn.setqflist(qf_list, 'r')
    terminal.close()
    vim.cmd('copen')
    notify.info(string.format('Added %d items to quickfix list', #qf_list))
end

return M
