local M = {}

local errors = require('command.actions.error_table').error_table
local hist = require 'command.history'

M.on_command_enter
--- Parse an error line for file, line, and column numbers
--- @param line string The error output line
--- @return (string|nil, number|nil, number|nil) filename, line number and column number
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
            return file, lnum, col
        end
    end

    local f, r, c = line:match("^([%w%./\\-_]+):(%d+):?(%d*)")
    if f then
        return f, tonumber(r), (c ~= "" and tonumber(c) or 1)
    end

    return nil, nil, nil
end

--- Jump to file and position under cursor based on error pattern
--- @param win int The window where the file will be opened
function M.follow_error_at_cursor(win)
    local line = vim.api.nvim_get_current_line()
    local fname, row, col = parse_error_line(line)

    if not fname then
        utils.print_error("If this is an error," ..
            "I could not find a valid pattern for it.")
        return
    end

    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
    else
        vim.cmd("vsplit")
    end

    vim.cmd("edit " .. vim.fn.fnameescape(fname))
    vim.api.nvim_win_set_cursor(0, { row or 1, col or 1 })
end

--- Closes the prompt window and returns the command to execute
--- @param buf number Buffer handle of the prompt
--- @param win number Window handle of the prompt
--- @param history string[] Table with the session history
--- @return string
function M.on_command_enter(buf, win, history)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    local cmd = line:match("^%S+%s+(.*)$") or ""

    if cmd ~= "" and history[#history] ~= cmd then
        table.insert(history, cmd)
        hist.save_history(history)
    end

    M.on_command_cancel(buf, win)

    return cmd
end

--- Cancel the prompt without executing
--- @param buf number Buffer handle of the prompt
--- @param win number Window handle of the prompt
function M.on_command_cancel(buf, win)
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

return M
