local utils = require 'command.utils'
local hist = require 'command.history'
local state = require 'command.state'
local actions = require 'command.actions'
local errors = require 'command.errors'
local ghost = require 'command.ui.ghost'

local M = {}

local WINDOW_NAME = "prompt"
local ERROR_COMMAND_NOT_PROVIDED = "No command was provided"

local function get_win(func_name)
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        errors.WINDOW_NOT_FOUND(func_name, WINDOW_NAME)
        return nil
    end
    return window
end

function M.setup(picker)
    M._picker = picker
end

function M.history_up()
    local window = get_win('history_up')
    if not window then return end

    local current = state._history.index
    if current > 1 then
        state.set_history_index(current - 1)
        utils.set_cmd_prompt(window.buf, window.win, state.history_list()[state._history.index] or "")
        ghost.update()
    end
end

function M.history_down()
    local window = get_win('history_down')
    if not window then return end

    local len = #state.history_list()
    local current = state._history.index

    if current < len then
        state.set_history_index(current + 1)
        utils.set_cmd_prompt(window.buf, window.win, state.history_list()[state._history.index] or "")
    else
        state.set_history_index(len + 1)
        utils.set_cmd_prompt(window.buf, window.win, "")
    end

    ghost.update()
end

function M.search()
    require('command.ui.picker').pick(hist._picker)
end

function M.enter()
    local window = get_win('enter')
    if not window then return end

    ghost.clear(window.buf)

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
    local window = get_win('cancel')
    if not window then return end

    ghost.clear(window.buf)

    local buf, win = window.buf, window.win

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end

    state.reset_history_index()
end

function M.accept_ghost()
    local window = get_win('accept_ghost')
    if not window then return end

    ghost.accept_all()
end

return M
