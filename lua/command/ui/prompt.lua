local M = {}

local COMMAND_WIN_HEIGHT = 1

function M.setup(opts)
    M._max_width = opts.max_width or 40
    M._ghost_text = opts.ghost_text or true
end

function M.create()
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })

    local width = math.max(M._max_width, math.floor(vim.o.columns * 0.5))
    local height = COMMAND_WIN_HEIGHT

    local command_win = {
        row = math.floor((vim.o.lines - height) / 2 - 1),
        col = math.floor((vim.o.columns - width) / 2),
        height = height,
        width = width,
    }

    if M._ghost_text then
        require('command.ui.ghost').attach()
        require('command.ui.ghost').update()
    end

    return {
        name = "prompt",
        buf = buf,
        opts = {
            title = "Command to execute",
            title_pos = "right",
            relative = "editor",
            width = width,
            height = height,
            row = command_win.row,
            col = command_win.col,
            style = "minimal",
            border = "rounded",
        }
    }

end

return M
