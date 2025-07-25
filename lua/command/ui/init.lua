local hts = require 'command.ui.highlights'
local state = require 'command.state'

local M = {
}

--- @return boolean -- if the window was created
local function show(opts)
    local win = vim.api.nvim_open_win(opts.buf, true, opts.opts)

    if win == 0 then
        return false
    end

    opts.win = win

    hts.set(win)

    state.add_window(opts)

    return true
end

-- function M.show_terminal()
--     local opts = require('command.ui.terminal').create()
--     return show(opts)
-- end


function M.show_prompt()
    local opts = require('command.ui.prompt').create()
    return show(opts)
end

function M.windows()
    return vim.deepcopy(M._windows)
end

return M
