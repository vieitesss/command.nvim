---@class Command
---@field execute fun(): nil
---@field execute_last fun(): nil
---@field teardown fun(): nil

local M = {}

local ui = require 'command.ui'
local utils = require 'command.utils'
local state = require 'command.state'
local actions = require 'command.actions'
local hist = require 'command.history'

local function capture_context()
    state.set_main_win(vim.api.nvim_get_current_win())
    state.set_context({
        buf = vim.api.nvim_get_current_buf(),
        win = vim.api.nvim_get_current_win(),
        cursor = vim.api.nvim_win_get_cursor(0),
        mode = vim.api.nvim_get_mode().mode
    })
end

---Display a prompt to execute a new command.
---Opens an interactive command input window where users can type and execute shell commands.
---The command is stored in history and can be re-executed later.
---@return nil
function M.execute()
    capture_context()

    local win = state.get_window_by_name('prompt')
    if win then
        if vim.api.nvim_win_is_valid(win.win) then
            vim.api.nvim_set_current_win(win.win)
            vim.cmd("startinsert")
            return
        else
            state.remove_window('prompt')
        end
    end

    local ok = ui.show_prompt()
    if not ok then
        utils.print_error("Could not create the prompt window")
        return
    end

    vim.cmd("startinsert")

    require('command.ui.keymaps.prompt').apply()
end

---Execute the selected text as a command.
---Retrieves the text from the current visual selection (or last selection)
---and executes it immediately as a shell command.
---Adds the command to history.
---@return nil
function M.execute_selection()
    capture_context()

    local context = state.get_context()
    if not context then
        utils.print_error("Could not capture context")
        return
    end

    local selection = utils.get_visual_selection(context.buf)
    if selection == "" then
        utils.print_error("No selection found")
        return
    end

    -- Clean up selection: remove trailing newlines which might cause issues
    selection = selection:gsub("^%s*(.-)%s*$", "%1")

    -- Add to history so it can be re-run with CommandExecuteLast
    hist.add(selection)

    local exec_ok = actions.exec_command(selection)

    if exec_ok then
        state._has_run = true
        require('command.ui.keymaps.terminal').apply()
    end
end

---Execute the last executed command.
---Re-runs the most recently executed command without opening the prompt.
---Requires that at least one command has been executed in the current session.
---@return nil
function M.execute_last()    capture_context()

    if not state._has_run or #state.history_list() == 0 then
        utils.print_error("Use first `:CommandExecute`")
        return
    end

    local last = state.history_last()
    if not last then
        utils.print_error("No command history found")
        return
    end

    local exec_ok = actions.exec_command(last)

    if exec_ok then
        require('command.ui.keymaps.terminal').apply()
    end
end

return M
