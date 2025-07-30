local utils = require 'command.utils'

local M = {
    _history = {},
    _has_run = false,
    _windows = {},
    _main_win = 0
}

function M.set_main_win(win)
    local valid = vim.api.nvim_win_is_valid(win)

    if valid then
        M._main_win = win
    else
        utils.print_error("The window " .. win .. "is not valid.")
    end

    return valid
end

function M.setup_history(list)
    M._history.list = list
    M._history.index = #M._history.list + 1
end

function M.set_history_index(idx)
    M._history.index = idx
end

---@return table|nil -- the window with the given name
function M.get_window_by_name(name)
    for _, window in ipairs(M._windows) do
        if window.name == name then
            return window
        end
    end

    utils.print_error("Could not find a window with the name: " .. name)
    return nil
end

function M.add_window(opts)
    table.insert(M._windows, opts)
end

function M.remove_window(name)
    local idx = 0
    for index, window in ipairs(M._windows) do
        if window.name == name then
            idx = index
            break
        end
    end

    if idx == 0 then
        utils.print_error("Could not remove a window with the name: " .. name)
        return
    end

    table.remove(M._windows, idx)
end

function M.history_list()
    return vim.deepcopy(M._history.list)
end

function M.add_history_entry(cmd)
    table.insert(M._history.list, cmd)
    M._history.last = cmd
end

function M.remove_history_entry(idx)
    table.remove(M._history, idx)
end

function M.history_last()
    return M._history.list[#M._history.list]
end

function M.reset_history_index()
    M._history.index = #M._history.list + 1
end

return M
