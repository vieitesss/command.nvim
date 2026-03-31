local core = require('command.history.core')
local migration = require('command.history.migration')
local picker = require('command.history.picker')
local storage = require('command.history.storage')

local config = require('command.config')

local M = {}

function M.init()
    migration.migrate()
    core.setup(storage.load())
end

function M.load_from_disk()
    return storage.load()
end

function M.save_to_disk()
    return storage.save(core.get_all())
end

function M.get_history_path()
    return storage.get_path()
end

function M.add(cmd)
    local max_entries = (config.values.history and config.values.history.max) or 200
    local added = core.add(cmd, max_entries)
    if added then
        storage.save(core.get_all())
    end
    return added
end

function M.prev()
    return core.prev()
end

function M.next()
    return core.next()
end

function M.get_last()
    return core.last()
end

function M.get_suggestions(prefix)
    return core.suggest(prefix)
end

function M.search(callback)
    return picker.search(core.get_all(), callback)
end

function M.get_all()
    return core.get_all()
end

function M.clear()
    core.setup({})
    storage.save(core.get_all())
end

function M.reset_index()
    core.reset_index()
end

return M
