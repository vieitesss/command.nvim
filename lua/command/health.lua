---@class CommandHealth Health check module for command.nvim

local M = {}

---Check if the configured shell is available.
---@return nil
local function check_shell()
    vim.health.info('Checking shell configuration...')

    local shell = vim.env.SHELL or '/bin/sh'

    if vim.fn.executable(shell) == 1 then
        vim.health.ok('Shell found: ' .. shell)
    else
        vim.health.error('Shell not found: ' .. shell, {
            'Install ' .. shell .. ' or set SHELL environment variable',
        })
    end
end

---Check if the configured history picker is available.
---@return nil
local function check_picker()
    vim.health.info('Checking history picker...')

    local ok, config = pcall(require, 'command.config')
    if not ok then
        vim.health.warn('Could not load config module')
        return
    end

    local picker = config.values.history.picker
    vim.health.info('Configured picker: ' .. picker)

    if picker == 'fzf-lua' then
        local fzf_ok = pcall(require, 'fzf-lua')
        if fzf_ok then
            vim.health.ok('fzf-lua is installed')
        else
            vim.health.warn('fzf-lua is not installed', {
                'Install fzf-lua if you want to use history search',
                'GitHub: https://github.com/ibhagwan/fzf-lua',
            })
        end
    elseif picker ~= nil then
        vim.health.warn('Unknown picker: ' .. tostring(picker), {
            'Supported pickers: fzf-lua',
            'Verify your configuration',
        })
    end
end

---Check history storage file and directory.
---@return nil
local function check_history_storage()
    vim.health.info('Checking history storage...')

    local ok, history = pcall(require, 'command.history')
    if not ok then
        vim.health.warn('Could not load history module')
        return
    end

    local history_path = history.get_history_path()
    local history_dir = vim.fn.fnamemodify(history_path, ':h')

    -- Check if directory exists or can be created
    if vim.fn.isdirectory(history_dir) == 1 then
        vim.health.ok('History directory exists: ' .. history_dir)
    else
        -- Try to create it
        local mkdir_ok = pcall(vim.fn.mkdir, history_dir, 'p')
        if mkdir_ok then
            vim.health.ok('History directory can be created: ' .. history_dir)
        else
            vim.health.error('Cannot create history directory: ' .. history_dir, {
                'Check directory permissions',
                'Ensure parent directory is writable',
            })
            return
        end
    end

    -- Check if directory is writable by attempting to write a test file
    local test_file = history_dir .. '/.command_nvim_write_test'
    local write_ok, write_err = io.open(test_file, 'w')

    if write_ok then
        write_ok:close()
        os.remove(test_file)
        vim.health.ok('History directory is writable')
    else
        vim.health.error('History directory is not writable: ' .. history_dir, {
            'Fix directory permissions',
            'Run: chmod 755 ' .. history_dir,
            'Write test failed: ' .. tostring(write_err),
        })
    end
end

---Run health checks for command.nvim.
---Verifies that all dependencies and configurations are properly set up.
---Can be invoked with :checkhealth command
---@return nil
function M.check()
    vim.health.start('command.nvim')

    -- Check shell availability
    check_shell()

    -- Check picker availability
    check_picker()

    -- Check history storage
    check_history_storage()
end

return M
