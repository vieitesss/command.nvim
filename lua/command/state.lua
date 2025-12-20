---@class Window
---@field name string Window identifier
---@field buf integer Buffer handle
---@field win integer Window handle
---@field opts table Window options

---@class HistoryState
---@field list string[] List of commands
---@field index integer Current position in history

---@class ExecutionContext
---@field buf integer Buffer handle
---@field win integer Window handle
---@field cursor integer[] Cursor position {line, col}
---@field mode string Current mode
---@field selection_start integer[]|nil Start of selection {line, col}
---@field selection_end integer[]|nil End of selection {line, col}

local utils = require 'command.utils'

local M = {
    _history = {},
    _has_run = false,
    _windows = {},
    _main_win = 0,
    _context = nil, ---@type ExecutionContext|nil
    _cwd_mode = nil ---@type string|nil
}

---Set the main window to return to after command execution.
---@param win integer Window handle
---@return boolean success Whether the window is valid
function M.set_main_win(win)
    local valid = vim.api.nvim_win_is_valid(win)

    if valid then
        M._main_win = win
    else
        utils.print_error("The window " .. win .. "is not valid.")
    end

    return valid
end

---Set the execution context (buffer, window, cursor, etc.).
---@param ctx ExecutionContext
function M.set_context(ctx)
    M._context = ctx
end

---Get the current execution context.
---@return ExecutionContext|nil
function M.get_context()
    return M._context
end

---Set the current cwd mode.
---@param mode string 'buffer'|'root'
function M.set_cwd_mode(mode)
    M._cwd_mode = mode
end

---Get the current cwd mode.
---@return string|nil mode
function M.get_cwd_mode()
    return M._cwd_mode
end

---Initialize history state from a list of commands.
---@param list string[] List of previously saved commands
---@return nil
function M.setup_history(list)
    M._history.list = list
    M._history.index = #M._history.list + 1
end

---Set the current position in command history.
---@param idx integer History index
---@return nil
function M.set_history_index(idx)
    M._history.index = idx
end

---Get a window by its name identifier.
---@param name string Window name
---@return Window|nil window The window object or nil if not found
function M.get_window_by_name(name)
    for _, window in ipairs(M._windows) do
        if window.name == name then
            return window
        end
    end

    return nil
end

---Add a window to the tracking list.
---@param opts Window Window object with name, buf, win, opts
---@return nil
function M.add_window(opts)
    table.insert(M._windows, opts)
end

---Remove a window from tracking and delete its buffer.
---@param name string Window name identifier
---@return nil
function M.remove_window(name)
    local idx = 0
    local win = nil
    for index, window in ipairs(M._windows) do
        if window.name == name then
            idx = index
            win = window
            break
        end
    end

    if idx == 0 or not win then
        utils.print_error("Could not remove a window with the name: " .. name)
        return
    end

    vim.api.nvim_buf_delete(win.buf, { force = true })

    table.remove(M._windows, idx)
end

---Get a copy of the command history list.
---@return string[] commands List of commands
function M.history_list()
    return vim.deepcopy(M._history.list)
end

---Add a command to the history.
---@param cmd string Command to add
---@return nil
function M.add_history_entry(cmd)
    table.insert(M._history.list, cmd)
    M._history.last = cmd
end

---Remove a command from history by index.
---@param idx integer Index to remove (1-based)
---@return nil
function M.remove_history_entry(idx)
    table.remove(M._history.list, idx)
end

---Get the last executed command.
---@return string|nil command Last command or nil if history empty
function M.history_last()
    return M._history.list[#M._history.list]
end

---Reset history index to the end of the list.
---Used when exiting history navigation mode.
---@return nil
function M.reset_history_index()
    M._history.index = #M._history.list + 1
end

return M
