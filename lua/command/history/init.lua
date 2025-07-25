local storage = require 'command.history.storage'

local M = {}

function M.setup(opts)
    M._max = opts.max
end

function M.load()
    return storage.read()
end

function M.add(cmd)
    table.insert(M._list, cmd)
    if #M._list > M._max then
        table.remove(M._list, 1)
    end
    M._last = cmd
    storage.write(M._list)
end

return M
