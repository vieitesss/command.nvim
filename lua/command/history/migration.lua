local storage = require('command.history.storage')
local notify = require('command.util.notify')

local M = {}

local function get_old_history_path()
    return vim.fn.stdpath('data') .. '/command.nvim/command_history.txt'
end

---@return boolean migrated
function M.migrate()
    local old_history_path = get_old_history_path()

    if vim.fn.filereadable(old_history_path) == 0 then
        return false
    end

    local new_history_path = storage.get_path()
    if vim.fn.filereadable(new_history_path) ~= 0 then
        return false
    end

    local old_history = M.load_old_format(old_history_path)
    if #old_history == 0 then
        return false
    end

    if not storage.save(old_history, new_history_path) then
        return false
    end

    M.backup_old_file(old_history_path)
    notify.info(string.format('Migrated %d commands to new history format', #old_history))

    return true
end

---@param old_path string
---@return string[]
function M.load_old_format(old_path)
    local ok, result = pcall(vim.fn.readfile, old_path)
    if not ok or type(result) ~= 'table' then
        notify.warn('Failed to read old history file')
        return {}
    end

    local commands = {}
    for _, line in ipairs(result) do
        if line and line ~= '' then
            table.insert(commands, line)
        end
    end

    return commands
end

---@param old_path string
---@return boolean
function M.backup_old_file(old_path)
    local ok, lines = pcall(vim.fn.readfile, old_path)
    if not ok or type(lines) ~= 'table' then
        return false
    end

    local backup_ok = pcall(vim.fn.writefile, lines, old_path .. '.backup')
    return backup_ok
end

return M
