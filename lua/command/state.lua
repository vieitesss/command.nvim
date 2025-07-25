local history = require 'command.history'
local utils = require 'command.utils'

local M = {}

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

function M.history_list()
    return vim.deepcopy(M._history.list)
end

function M.history_last()
    return M._history.last
end

function M.setup()
    M._last_command = ""
    M._has_run = false
    M._windows = {}
    M._history = {}
    M._history.list = history.load() or {}
    M._history.last = M._history.list[#M._history.list]
    M._history.index = #M._history.list + 1
    vim.print(M._history.list, M._history.index)
end

return M
