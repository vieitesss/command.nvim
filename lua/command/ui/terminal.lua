local M = {}

local WINDOW_NAME = 'terminal'

function M.setup(opts)
    M._height = opts.height
    M._split = opts.split
end

function M.create()
    local _ = vim.api.nvim_get_current_win()

    local win = require('command.state').get_window_by_name(WINDOW_NAME)

    if win then
        require('command.state').remove_window(WINDOW_NAME)
    end

    local buf = vim.api.nvim_create_buf(true, false)

    return {
        name = 'terminal',
        buf = buf,
        opts = {
            width = vim.o.columns,
            height = math.floor(vim.o.lines * M._height),
            split = M._split,
            win = 0,
        }
    }
end

return M
