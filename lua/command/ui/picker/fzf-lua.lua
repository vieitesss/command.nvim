local state = require 'command.state'
local errors = require 'command.errors'

local M = {}

function M.pick()
    local window = state.get_window_by_name(REFERENCE_WINDOW)
    if not window then
        errors.WINDOW_NOT_FOUND('apply', REFERENCE_WINDOW)
        return
    end

    local max_lines = vim.o.lines
    local max_columns = vim.o.columns

    local height = 0.30
    local width = window.opts.width
    local row = (window.opts.row + window.opts.height + BORDERS * 2 + SEARCH_HEADER + height / 2 * max_lines) / max_lines
    local col = (window.opts.col + BORDERS + width / 2) / max_columns
    require('fzf-lua').fzf_exec(state.history_list(), {
        prompt   = 'History> ',
        winopts  = { height = height, width = width, row = row, col = col },
        complete = function(selected, _, line, column)
            if selected and #selected > 0 then
                local command = selected[1]
                return command, #command - 1
            end
            return line, column
        end,
    })
end

return M
