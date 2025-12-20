local M = {}

local state = require 'command.state'

local COMMAND_WIN_HEIGHT = 1

function M.setup(opts)
    M._max_width = opts.max_width
    M._ghost_text = opts.ghost_text
end

function M.ghost_text_enabled()
    return M._ghost_text
end

local function get_title()
    local cwd = state.get_resolved_cwd()
    cwd = vim.fn.fnamemodify(cwd, ":~")
    return " " .. cwd .. " "
end

function M.update_title()
    local window = state.get_window_by_name('prompt')
    if not window then return end
    
    if vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_set_config(window.win, {
            title = get_title(),
        })
    end
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

    return {
        name = "prompt",
        buf = buf,
        opts = {
            title = get_title(),
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
