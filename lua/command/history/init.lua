local storage = require 'command.history.storage'
local state = require 'command.state'

local M = {}

function M.setup(opts)
    M._max = opts.max
    M._picker = opts.picker

    local list = M.load()
    state.setup_history(list)
end

function M.load()
    return storage.read()
end

function M.add(cmd)
    state.add_history_entry(cmd)
    if #state.history_list() > M._max then
        state.remove_history_entry(1)
    end
    storage.write(state.history_list())
end

return M
