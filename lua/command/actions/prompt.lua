local utils = require 'command.utils'
local hist = require 'command.history'
local state = require 'command.state'
local actions = require 'command.actions'
local errors = require 'command.errors'

local M = {}

local WINDOW_NAME = "prompt"
local ERROR_COMMAND_NOT_PROVIDED = "No command was provided"

function M.setup(picker)
    M._picker = picker
end


function M.history_up()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        errors.WINDOW_NOT_FOUND('history_up', WINDOW_NAME)
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
        errors.WINDOW_NOT_FOUND('history_down', WINDOW_NAME)
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
    require('command.ui.picker').pick(hist._picker)
end

function M.enter()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        errors.WINDOW_NOT_FOUND('enter', WINDOW_NAME)
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
        actions.exec_command(cmd)
        state._has_run = true
    end

    state.reset_history_index()
end

function M.cancel()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        errors.WINDOW_NOT_FOUND('cancel', WINDOW_NAME)
        return
    end

    local buf, win = window.buf, window.win

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end

    state.reset_history_index()
end

return M
