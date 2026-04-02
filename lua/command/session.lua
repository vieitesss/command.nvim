---@class CommandWindowOpts
---@field context ExecutionContext|nil Source context associated with a tracked UI window

---@class Window
---@field name string Window identifier
---@field buf integer Buffer handle
---@field win integer Window handle
---@field opts CommandWindowOpts|nil Window options
---@field job_id integer|nil Terminal job handle
---@field exit_code integer|nil Terminal job exit code

---@class ExecutionContext
---@field buf integer Buffer handle
---@field win integer Window handle
---@field cursor integer[] Cursor position {line, col}
---@field mode string Current mode

---@class CommandUnregisterWindowOpts
---@field close boolean|nil Close the tracked window
---@field delete_buffer boolean|nil Delete the tracked buffer

local notify = require('command.util.notify')

local M = {
    _windows = {},
    _jobs = {},
    _cwd_mode = nil, ---@type string|nil
    _has_run = false,
}

local function find_window(name)
    for idx, window in ipairs(M._windows) do
        if window.name == name then
            return idx, window
        end
    end

    return nil, nil
end

---@param buf integer
---@param win integer
---@return ExecutionContext|nil
local function find_window_context(buf, win)
    for _, window in ipairs(M._windows) do
        if window.buf == buf or window.win == win then
            local opts = window.opts or {}
            if opts.context then
                return opts.context
            end
        end
    end

    return nil
end

---@return ExecutionContext
function M.capture_context()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local window_context = find_window_context(buf, win)
    if window_context then
        return window_context
    end

    local ctx = {
        buf = buf,
        win = win,
        cursor = vim.api.nvim_win_get_cursor(0),
        mode = vim.api.nvim_get_mode().mode,
    }

    return ctx
end

---@param mode string
function M.set_cwd_mode(mode)
    M._cwd_mode = mode
end

---@return string|nil
function M.get_cwd_mode()
    return M._cwd_mode
end

---@param context ExecutionContext|nil
---@return string
function M.get_resolved_cwd(context)
    if M._cwd_mode == 'buffer' and context and context.buf then
        local file = vim.api.nvim_buf_get_name(context.buf)
        if file ~= '' then
            local dir = vim.fn.fnamemodify(file, ':h')
            if vim.fn.isdirectory(dir) == 1 then
                return dir
            end
        end
    end

    return vim.fn.getcwd()
end

function M.mark_has_run()
    M._has_run = true
end

---@return boolean
function M.has_run()
    return M._has_run
end

function M.reset_run()
    M._has_run = false
end

---@param window Window
function M.register_window(window)
    local idx = find_window(window.name)
    if idx then
        M._windows[idx] = window
        return
    end

    table.insert(M._windows, window)
end

---@param name string
---@return Window|nil
function M.get_window(name)
    local _, window = find_window(name)
    return window
end

---@param name string
---@param opts CommandUnregisterWindowOpts|nil
---@return Window|nil
function M.unregister_window(name, opts)
    ---@type CommandUnregisterWindowOpts
    local window_opts = opts or {}

    local idx, window = find_window(name)
    if not idx or not window then
        return nil
    end

    table.remove(M._windows, idx)

    if window_opts.close ~= false and window.win and vim.api.nvim_win_is_valid(window.win) then
        pcall(vim.api.nvim_win_close, window.win, true)
    end

    if window_opts.delete_buffer ~= false and window.buf and vim.api.nvim_buf_is_valid(window.buf) then
        pcall(vim.api.nvim_buf_delete, window.buf, { force = true })
    end

    return window
end

---@param win_id integer
function M.cleanup_window(win_id)
    for idx, window in ipairs(M._windows) do
        if window.win == win_id then
            if window.name == 'terminal' and window.buf and vim.api.nvim_buf_is_valid(window.buf) then
                window.win = nil
                return
            end

            table.remove(M._windows, idx)
            return
        end
    end
end

---@param job_id integer
function M.add_job(job_id)
    M._jobs[job_id] = true
end

---@param job_id integer
function M.remove_job(job_id)
    M._jobs[job_id] = nil
end

---@param force boolean|nil
function M.cleanup(force)
    local should_force = force or false

    local windows = M._windows
    local jobs = M._jobs

    M._windows = {}
    M._jobs = {}
    M._cwd_mode = nil
    M._has_run = false

    for _, window in ipairs(windows) do
        if window.win and vim.api.nvim_win_is_valid(window.win) then
            pcall(vim.api.nvim_win_close, window.win, should_force)
        end
        if window.buf and vim.api.nvim_buf_is_valid(window.buf) then
            pcall(vim.api.nvim_buf_delete, window.buf, { force = should_force })
        end
    end

    for job_id, _ in pairs(jobs) do
        pcall(vim.fn.jobstop, job_id)
    end
end

function M.setup_autocmds()
    local group = vim.api.nvim_create_augroup('command_session', { clear = true })

    vim.api.nvim_create_autocmd('WinClosed', {
        group = group,
        callback = function(args)
            local win_id = tonumber(args.match)
            if not win_id then
                notify.warn('Could not parse closed window id: ' .. tostring(args.match))
                return
            end

            M.cleanup_window(win_id)
        end,
    })
end

return M
