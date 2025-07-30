local state = require 'command.state'
local errors = require 'command.actions.error_table'
local utils = require 'command.utils'

local M = {}

local function parse_error_line(line)
    for _, entry in pairs(errors) do
        local match = vim.fn.matchlist(line, entry.regex)
        if #match > 0 and match[1] ~= "" then
            local file, lnum, col
            for i = 2, #match do
                local v = match[i]
                if not file and (v:match("[/\\]") or v:match("%.%w+$")) then
                    file = v
                elseif not lnum and v:match("^%d+$") then
                    lnum = tonumber(v)
                elseif lnum and not col and v:match("^%d+$") then
                    col = tonumber(v) - 1
                end
            end
            return {filename = file, line = lnum, col = col}
        end
    end

    local f, r, c = line:match("^([%w%./\\-_]+):(%d+):?(%d*)")
    if f then
        return { filename = f, line = tonumber(r), col = (c ~= "" and tonumber(c) or 1) }
    end

    return {}
end

function M.follow_error()
    local line = vim.api.nvim_get_current_line()
    local info = parse_error_line(line)

    if not info.filename then
        utils.print_error("If this is an error," ..
            "I could not find a valid pattern for it.")
        return
    end

    local win = state._main_win
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
    else
        vim.cmd("vsplit")
    end

    vim.cmd("edit " .. vim.fn.fnameescape(info.filename))
    vim.api.nvim_win_set_cursor(0, { info.line or 1, info.col or 1 })
end

return M
