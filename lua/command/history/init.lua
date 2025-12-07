---@class HistoryModule
---History management with error recovery

local storage = require 'command.history.storage'
local state = require 'command.state'

local M = {}

---Initialize history module with configuration.
---
---@param opts table Configuration table with max and picker
---@return nil
function M.setup(opts)
    M._max = opts.max
    M._picker = opts.picker

    local list = M.load()
    state.setup_history(list)
end

---Load command history from storage.
---
---Returns empty list if storage read fails (graceful degradation).
---@return string[] commands List of commands from storage
function M.load()
    return storage.read()
end

---Add a command to history and save to storage.
---
---Handles storage write failures gracefully - command is kept in memory
---even if persistent save fails.
---
---@param cmd string Command to add
---@return nil
function M.add(cmd)
    if not cmd or cmd:len() == 0 then
        return
    end

    state.add_history_entry(cmd)

    -- Prune old entries if history exceeds max
    if #state.history_list() > M._max then
        state.remove_history_entry(1)
    end

    -- Try to persist history, but don't fail if storage is unavailable
    local history_list = state.history_list()
    local ok = storage.write(history_list)

    if not ok then
        -- History is kept in memory even if persistence fails
        -- User can still use it in current session
    end
end

return M
