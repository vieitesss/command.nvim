local hts = require 'command.ui.highlights'
local state = require 'command.state'

local M = {}

local AUGROUP = 'CommandAutocmd'

function M.setup(opts)
    vim.api.nvim_create_augroup(AUGROUP, {})
    require('command.ui.prompt').setup(opts.prompt)
    require('command.ui.terminal').setup(opts.terminal)
end

--- @return boolean -- if the window was created
local function show(opts)
    local win = vim.api.nvim_open_win(opts.buf, true, opts.opts)

    if win == 0 then
        return false
    end

    vim.api.nvim_create_autocmd('WinClosed', {
        group = AUGROUP,
        buffer = opts.buf,
        callback = function()
            state.remove_window(opts.name)
        end
    })

    opts.win = win

    hts.set(win)

    state.add_window(opts)

    return true
end

function M.show_terminal()
    local opts = require('command.ui.terminal').create()

    return show(opts)
end


function M.show_prompt()
    local opts = require('command.ui.prompt').create()
    return show(opts)
end

function M.windows()
    return vim.deepcopy(M._windows)
end

return M
