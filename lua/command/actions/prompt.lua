local utils = require 'command.utils'
local hist = require 'command.history'
local state = require 'command.state'

local M = {}

local BORDERS = 2
local SEARCH_HEADER = 3
local WINDOW_NAME = "prompt"
local ERROR_COMMAND_NOT_PROVIDED = "No command was provided"

function M.history_up()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    local current = state._history.index
    if current > 1 then
        state.set_history_index(current - 1)
        utils.set_cmd_prompt(window.buf, window.win, state.history_list()[state._history.index] or "")
    end
end

function M.history_down()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    local len = #state.history_list()
    local current = state._history.index

    if current < len then
        state.set_history_index(current + 1)
        utils.set_cmd_prompt(window.buf, window.win, state.history_list()[state._history.index] or "")
    else
        state.set_history_index(len + 1)
        utils.set_cmd_prompt(window.buf, window.win, "")
    end
end

function M.search()
    local windows = require('command.ui').windows()

    local command_win
    for _, value in ipairs(windows) do
        if value.name == WINDOW_NAME then
            command_win = value
            break
        end
    end

    local max_lines = vim.o.lines
    local max_columns = vim.o.columns

    local height = 0.30
    local width = command_win.width
    local row = (command_win.row + command_win.height + BORDERS * 2 + SEARCH_HEADER + height / 2 * max_lines) / max_lines
    local col = (command_win.col + BORDERS + width / 2) / max_columns

    require('fzf-lua').fzf_exec(M.history, {
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

function M.enter()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    local cmd = vim.api.nvim_buf_get_lines(window.buf, 0, 1, false)[1] or ""

    local history = state.history_list()
    if cmd ~= "" and history[#history] ~= cmd then
        hist.add(cmd)
    end

    M.cancel()

    if cmd == "" then
        utils.print_error(ERROR_COMMAND_NOT_PROVIDED)
    else
        utils.exec_command(cmd)
        require('command.state')._has_run = true
    end
end

function M.cancel()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    local buf, win = window.buf, window.win

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

return M
