---@class HistoryModule
---Command history management with persistence to JSON and migration support

local M = {}
local config = require('command.config')
local state = require('command.state')
local history_migration = require('command.history_migration')

-- ============================================================================
-- Initialization & Persistence
-- ============================================================================

---Initializes history from disk (with migration support)
---Called during plugin setup
function M.init()
    -- 1. Attempt migration from old format
    history_migration.migrate()

    -- 2. Load history from disk (new format)
    local loaded = M.load_from_disk()

    -- 3. Initialize state
    state._history = loaded or {}
    state._history_index = #state._history + 1
end

---Loads history from disk
---Reads from config.history.file_path or default location
---@return table List of commands from disk, or empty table on error
function M.load_from_disk()
    local history_path = M.get_history_path()

    -- Check if file exists
    if vim.fn.filereadable(history_path) == 0 then
        return {}
    end

    -- Read and parse JSON
    local ok, result = pcall(function()
        local file = io.open(history_path, 'r')
        if not file then
            return {}
        end

        local content = file:read('*a')
        file:close()

        local decoded = vim.json.decode(content)
        return decoded or {}
    end)

    if not ok then
        vim.notify('Warning: Failed to load history file', vim.log.levels.WARN)
        return {}
    end

    return result or {}
end

---Saves history to disk in JSON format
---Called after adding new command
function M.save_to_disk()
    local history_path = M.get_history_path()

    -- Ensure directory exists
    local dir = vim.fn.fnamemodify(history_path, ':h')
    vim.fn.mkdir(dir, 'p')

    -- Serialize to JSON
    local ok, content = pcall(function()
        return vim.json.encode(state._history)
    end)

    if not ok then
        vim.notify('Warning: Failed to save history', vim.log.levels.WARN)
        return
    end

    -- Write to file
    local file = io.open(history_path, 'w')
    if not file then
        vim.notify('Warning: Could not write history file', vim.log.levels.WARN)
        return
    end

    file:write(content)
    file:close()
end

---Gets the history file path
---@return string Path to history file
function M.get_history_path()
    -- Check if custom path is configured
    if config.values.history and config.values.history.file_path then
        return config.values.history.file_path
    end

    -- Default path
    return vim.fn.stdpath('data') .. '/command_history.json'
end

-- ============================================================================
-- History Management
-- ============================================================================

---Adds a command to history
---@param cmd string Command to add
---@return boolean success Whether command was added
function M.add(cmd)
    -- Validate command
    if not cmd or cmd:match('^%s*$') then
        return false
    end

    -- Skip if identical to last command
    if state._history[#state._history] == cmd then
        return false
    end

    -- Append to history
    table.insert(state._history, cmd)

    -- Enforce max entries (from config or default 200)
    local max_entries = config.values.history and config.values.history.max or 200
    if #state._history > max_entries then
        table.remove(state._history, 1)
    end

    -- Reset navigation index
    state._history_index = #state._history + 1

    -- Save to disk
    M.save_to_disk()

    return true
end

---Navigate to previous command in history
---@return string Previous command or empty string if at start
function M.prev()
    local len = #state._history

    -- If at end (not navigating), move to last entry
    if state._history_index > len then
        state._history_index = len
    else
        -- Decrement index
        state._history_index = state._history_index - 1
    end

    -- Clamp to valid range
    if state._history_index < 1 then
        state._history_index = 1
        return ''
    end

    return state._history[state._history_index] or ''
end

---Navigate to next command in history
---@return string Next command or empty string if at end
function M.next()
    local len = #state._history

    -- Increment index
    state._history_index = state._history_index + 1

    -- If past end, return empty and reset
    if state._history_index > len then
        state._history_index = len + 1
        return ''
    end

    return state._history[state._history_index] or ''
end

---Get the last command in history
---@return string Last command or empty string if history empty
function M.get_last()
    return state._history[#state._history] or ''
end

-- ============================================================================
-- Search & Suggestions
-- ============================================================================

---Gets suggestions matching a prefix (for ghost text)
---@param prefix string Prefix to match
---@return string Suggestion (full command) or empty string if no match
function M.get_suggestions(prefix)
    if not prefix or prefix == '' then
        return ''
    end

    -- Search history in reverse (most recent first)
    for i = #state._history, 1, -1 do
        local cmd = state._history[i]
        if cmd:sub(1, #prefix) == prefix then
            return cmd
        end
    end

    return ''
end

---Opens fzf picker for history search
---@param callback function Callback function that receives selected command
function M.search(callback)
    -- Check if fzf-lua is available
    local ok, fzf = pcall(require, 'fzf-lua')
    if not ok then
        vim.notify('fzf-lua not found - install nvim-fzf/fzf-lua for history search', vim.log.levels.ERROR)
        return
    end

    -- Prepare history in reverse order (newest first)
    local history_list = vim.fn.reverse(vim.deepcopy(state._history))

    if #history_list == 0 then
        vim.notify('No history available', vim.log.levels.INFO)
        return
    end

    -- Get prompt window to position fzf below it
    local prompt_win = state.get_window_by_name('prompt')
    local fzf_opts = {
        prompt = 'History> ',
        winopts = {
            height = 0.35,
            width = 0.5,
        },
        actions = {
            default = function(selected)
                if selected and selected[1] then
                    callback(selected[1])
                end
            end,
        },
    }

    -- Position below prompt if it exists, matching its dimensions
    if prompt_win and vim.api.nvim_win_is_valid(prompt_win.win) then
        local pos = vim.api.nvim_win_get_position(prompt_win.win)
        fzf_opts.winopts.row = pos[1] + prompt_win.opts.height + 2
        fzf_opts.winopts.col = pos[2]
        fzf_opts.winopts.width = prompt_win.opts.width + 2
        fzf_opts.winopts.relative = 'editor'
    end

    fzf.fzf_exec(history_list, fzf_opts)
end

---Get all commands in history (copy)
---@return table List of all commands
function M.get_all()
    return vim.deepcopy(state._history)
end

---Clear all history
function M.clear()
    state._history = {}
    state._history_index = 1
    M.save_to_disk()
end

return M
