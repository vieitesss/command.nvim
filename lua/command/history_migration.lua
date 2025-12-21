---@class HistoryMigration
---Migration from old text-based history to new JSON format

local M = {}

-- ============================================================================
-- Migration
-- ============================================================================

---Performs one-time migration from old format to new JSON format
---Called during history.init()
---@return boolean migrated Whether migration was performed
function M.migrate()
    -- 1. Check if old history file exists
    local old_history_dir = vim.fn.stdpath('data') .. '/command.nvim'
    local old_history_path = old_history_dir .. '/command_history.txt'

    if vim.fn.filereadable(old_history_path) == 0 then
        -- No old history to migrate
        return false
    end

    -- 2. Check if new JSON file already exists
    local config = require('command.config')
    local new_history_path = config.values.history and config.values.history.file_path
        or vim.fn.stdpath('data') .. '/command_history.json'

    if vim.fn.filereadable(new_history_path) ~= 0 then
        -- New format already exists, skip migration
        return false
    end

    -- 3. Load old text format
    local old_history = M.load_old_format(old_history_path)

    if not old_history or #old_history == 0 then
        return false
    end

    -- 4. Save in new JSON format
    M.save_new_format(new_history_path, old_history)

    -- 5. Optionally backup old file
    M.backup_old_file(old_history_path)

    vim.notify(
        string.format('command.nvim: Migrated %d commands to new history format', #old_history),
        vim.log.levels.INFO
    )

    return true
end

---Loads history from old text format (one command per line)
---@param old_path string Path to old history file
---@return table List of commands
function M.load_old_format(old_path)
    local ok, result = pcall(function()
        if vim.fn.filereadable(old_path) == 0 then
            return {}
        end
        return vim.fn.readfile(old_path)
    end)

    if not ok or not result then
        vim.notify('Warning: Failed to read old history file', vim.log.levels.WARN)
        return {}
    end

    -- Filter out empty lines
    local commands = {}
    for _, line in ipairs(result) do
        if line and line ~= '' then
            table.insert(commands, line)
        end
    end

    return commands
end

---Saves history in new JSON format
---@param new_path string Path to save JSON file
---@param history table List of commands to save
function M.save_new_format(new_path, history)
    -- 1. Ensure directory exists
    local dir = vim.fn.fnamemodify(new_path, ':h')
    vim.fn.mkdir(dir, 'p')

    -- 2. Serialize to JSON
    local ok, content = pcall(function()
        return vim.json.encode(history)
    end)

    if not ok then
        vim.notify('Failed to encode history to JSON', vim.log.levels.ERROR)
        return
    end

    -- 3. Write to file
    local file = io.open(new_path, 'w')
    if not file then
        vim.notify('Failed to save migrated history', vim.log.levels.ERROR)
        return
    end

    file:write(content)
    file:close()
end

---Backs up the old history file
---@param old_path string Path to old history file
function M.backup_old_file(old_path)
    local backup_path = old_path .. '.backup'

    -- Use vim.fn.system to copy
    local cmd = string.format('cp %s %s 2>/dev/null', vim.fn.shellescape(old_path), vim.fn.shellescape(backup_path))
    pcall(function()
        vim.fn.system(cmd)
    end)
end

return M
