local config = require('command.config')
---@type CommandExecutor
local executor = require('command.execution.executor')
local history = require('command.history')
local notify = require('command.util.notify')
---@type CommandPrompt
local prompt = require('command.ui.prompt')
local ghost_text = require('command.ui.ghost_text')
local session = require('command.session')

local M = {}

---@param window CommandPromptWindow
---@return string
local function get_current_line(window)
    local cursor = vim.api.nvim_win_get_cursor(window.win)
    local line = vim.api.nvim_buf_get_lines(window.buf, cursor[1] - 1, cursor[1], false)[1]
    return line or ''
end

---@param window CommandPromptWindow
---@return boolean
local function line_ends_with_continuation(window)
    return get_current_line(window):match('\\%s*$') ~= nil
end

function M.enter()
    local window = prompt.get()
    if not window then
        notify.error('Prompt window not found')
        return
    end

    local cmd = prompt.get_text()
    ghost_text.clear(window.buf)

    local ran = executor.run(cmd, {
        context = window.opts and window.opts.context or nil,
        before_execute = function()
            history.reset_index()
            prompt.close()
        end,
    })

    if not ran then
        ghost_text.update(window.buf)
    end
end

function M.enter_insert()
    local window = prompt.get()
    if not window then
        notify.error('Prompt window not found')
        return
    end

    if line_ends_with_continuation(window) then
        M.newline()
        return
    end

    M.enter()
end

function M.newline()
    local window = prompt.get()
    if not window or not vim.api.nvim_buf_is_valid(window.buf) or not vim.api.nvim_win_is_valid(window.win) then
        return
    end

    ghost_text.clear(window.buf)

    local cursor = vim.api.nvim_win_get_cursor(window.win)
    local row = cursor[1] - 1
    local line = get_current_line(window)
    local col = cursor[2]

    if col >= math.max(#line - 1, 0) then
        col = #line
    end

    vim.api.nvim_buf_set_text(window.buf, row, col, row, col, { '', '' })
    vim.api.nvim_win_set_cursor(window.win, { cursor[1] + 1, 0 })

    prompt.refresh_layout()

    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

function M.cancel()
    local window = prompt.get()
    if not window then
        return
    end

    ghost_text.clear(window.buf)
    history.reset_index()
    prompt.close()
end

function M.prev_history()
    local window = prompt.get()
    if not window then
        return
    end

    prompt.set_text(history.prev())

    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

function M.next_history()
    local window = prompt.get()
    if not window then
        return
    end

    prompt.set_text(history.next())

    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

function M.search_history()
    local window = prompt.get()
    if not window then
        return
    end

    history.search(function(selected_cmd)
        if selected_cmd and vim.api.nvim_buf_is_valid(window.buf) then
            prompt.set_text(selected_cmd)

            if config.values.ui.prompt.ghost_text then
                ghost_text.update(window.buf)
            end
        end
    end)
end

function M.accept_ghost()
    local window = prompt.get()
    if not window then
        return
    end

    ghost_text.accept(window.buf)
end

function M.toggle_cwd()
    local current_mode = session.get_cwd_mode()
    local new_mode = current_mode == 'buffer' and 'root' or 'buffer'

    session.set_cwd_mode(new_mode)
    prompt.update_title()
    notify.info('CWD mode: ' .. new_mode)
end

return M
