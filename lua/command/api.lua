local M = {}

local config = require('command.config')
local state = require('command.state')
local utils = require('command.utils')
local prompt = require('command.prompt')
local terminal = require('command.terminal')
local executor = require('command.executor')
local history = require('command.history')

local function capture_context()
    state.set_main_win(vim.api.nvim_get_current_win())
    state.set_context({
        buf = vim.api.nvim_get_current_buf(),
        win = vim.api.nvim_get_current_win(),
        cursor = vim.api.nvim_win_get_cursor(0),
        mode = vim.api.nvim_get_mode().mode,
    })
    state.set_cwd_mode(config.values.execution.cwd)
end

---Display a prompt to execute a new command
function M.execute()
    capture_context()

    local win = state.get_window_by_name('prompt')
    if win then
        if vim.api.nvim_win_is_valid(win.win) then
            vim.api.nvim_set_current_win(win.win)
            vim.cmd('startinsert')
            return
        else
            state.remove_window('prompt')
        end
    end

    local result = prompt.create(config.values.ui.prompt)
    if not result then
        utils.print_error('Could not create the prompt window')
        return
    end

    vim.cmd('startinsert')
end

---Execute the selected text as a command
function M.execute_selection()
    capture_context()

    local context = state.get_context()
    if not context then
        utils.print_error('Could not capture context')
        return
    end

    local selection = utils.get_visual_selection(context.buf)
    if selection == '' then
        utils.print_error('No selection found')
        return
    end

    selection = selection:gsub('^%s*(.-)%s*$', '%1')

    history.add(selection)

    terminal.create(config.values.ui.terminal)
    executor.run_command(selection)

    state._has_run = true
end

---Execute the last executed command
function M.execute_last()
    capture_context()

    if not state._has_run or #state._history == 0 then
        utils.print_error('Use first `:CommandExecute`')
        return
    end

    local last = history.get_last()
    if not last or last == '' then
        utils.print_error('No command history found')
        return
    end

    terminal.create(config.values.ui.terminal)
    executor.run_command(last)
end

return M
