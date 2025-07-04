--- @type Command.Actions
local M = {}

local errors = require('command.actions.error_table').error_table
local hist = require 'command.history'
local utils = require 'command.utils'

--- Parse an error line for file, line, and column numbers
--- @param line string The error output line
--- @return {filename: string|nil, line: number|nil, col: number|nil}
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

--- Jump to file and position under cursor based on error pattern
--- @param win integer The window where the file will be opened
function M.follow_error_at_cursor(win)
    local line = vim.api.nvim_get_current_line()
    local info = parse_error_line(line)

    if not info.filename then
        utils.print_error("If this is an error," ..
            "I could not find a valid pattern for it.")
        return
    end

    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
    else
        vim.cmd("vsplit")
    end

    vim.cmd("edit " .. vim.fn.fnameescape(info.filename))
    vim.api.nvim_win_set_cursor(0, { info.line or 1, info.col or 1 })
end

--- Closes the prompt window and returns the command to execute
--- @param p Command.Prompt
--- @return string
function M.on_command_enter(p)
    local cmd = vim.api.nvim_buf_get_lines(p.buf, 0, 1, false)[1] or ""

    if cmd ~= "" and p.history[#p.history] ~= cmd then
        table.insert(p.history, cmd)
        hist.save_history(p.history)
    end

    M.on_command_cancel(p.buf, p.win)

    return cmd
end

--- Cancel the prompt without executing
--- @param buf integer Buffer handle of the prompt
--- @param win integer Window handle of the prompt
function M.on_command_cancel(buf, win)
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

return M
