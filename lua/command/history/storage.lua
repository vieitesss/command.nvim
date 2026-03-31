local config = require('command.config')
local notify = require('command.util.notify')

local M = {}

---@return string
function M.get_path()
    if config.values.history and config.values.history.file_path then
        return config.values.history.file_path
    end

    return vim.fn.stdpath('data') .. '/command_history.json'
end

---@param path string|nil
---@return string[]
function M.load(path)
    local history_path = path or M.get_path()

    if vim.fn.filereadable(history_path) == 0 then
        return {}
    end

    local file = io.open(history_path, 'r')
    if not file then
        notify.warn('Failed to load history file')
        return {}
    end

    local content = file:read('*a')
    file:close()

    local ok, decoded = pcall(vim.json.decode, content)
    if not ok or type(decoded) ~= 'table' then
        notify.warn('Failed to decode history file')
        return {}
    end

    return decoded
end

---@param entries string[]
---@param path string|nil
---@return boolean
function M.save(entries, path)
    local history_path = path or M.get_path()
    local dir = vim.fn.fnamemodify(history_path, ':h')
    vim.fn.mkdir(dir, 'p')

    local ok, content = pcall(vim.json.encode, entries)
    if not ok then
        notify.warn('Failed to encode history')
        return false
    end

    local file = io.open(history_path, 'w')
    if not file then
        notify.warn('Could not write history file')
        return false
    end

    file:write(content)
    file:close()

    return true
end

return M
