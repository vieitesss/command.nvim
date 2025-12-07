---@class HistoryStorage
---Storage backend for command history with error recovery

local M = {}

local hist_dir = vim.fn.stdpath('data') .. '/command.nvim'
local hist_file = hist_dir .. '/command_history.txt'

---Initialize history storage directory.
---Creates the directory if it doesn't exist.
---@return boolean success Whether initialization succeeded
local function init_storage()
    local ok = pcall(vim.fn.mkdir, hist_dir, 'p')
    if not ok then
        vim.notify('Warning: Could not create history directory: ' .. hist_dir, vim.log.levels.WARN)
        return false
    end
    return true
end

---Read command history from storage.
---Returns empty list on read errors (graceful degradation).
---
---@return string[] commands List of previously saved commands
function M.read()
    if not init_storage() then
        -- If storage init fails, return empty history and continue
        return {}
    end

    local ok, result = pcall(function()
        if vim.fn.filereadable(hist_file) == 0 then
            -- File doesn't exist, create empty one
            vim.fn.writefile({}, hist_file)
            return {}
        end

        -- Try to read the file
        return vim.fn.readfile(hist_file)
    end)

    if not ok then
        -- If read fails, log warning but don't crash
        vim.notify('Warning: Could not read history file: ' .. hist_file, vim.log.levels.WARN)
        return {}
    end

    return result or {}
end

---Write command history to storage.
---If write fails, warns user but doesn't crash.
---
---@param list string[] List of commands to save
---@return boolean success Whether write succeeded
function M.write(list)
    if not init_storage() then
        vim.notify('Warning: Could not write history - storage unavailable', vim.log.levels.WARN)
        return false
    end

    local ok = pcall(function()
        vim.fn.writefile(list, hist_file)
    end)

    if not ok then
        vim.notify('Warning: Could not write history file: ' .. hist_file, vim.log.levels.WARN)
        return false
    end

    return true
end

return M
