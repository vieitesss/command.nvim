local config = require('command.config')
local session = require('command.session')

---@class CommandTerminalCreateOpts: CommandConfigTerminalOpts
---@field context ExecutionContext|nil Source context used for cwd resolution and terminal reuse

---@class CommandTerminalWindowOpts: CommandWindowOpts
---@field height number Terminal height used when opening the split
---@field split string Terminal split direction
---@field context ExecutionContext|nil Source context associated with the terminal

---@class CommandTerminalWindow: Window
---@field name 'terminal'
---@field opts CommandTerminalWindowOpts

---@class CommandTerminal
---@field create fun(opts: CommandTerminalCreateOpts|nil, actions: table): CommandTerminalWindow|nil
---@field get fun(): CommandTerminalWindow|nil
---@field enter_normal_mode fun()
---@field hide fun()
---@field close fun()
---@field reopen fun(actions: table): CommandTerminalWindow|nil
---@field send_command fun(cmd: string, context: ExecutionContext|nil): boolean
---@field get_lines fun(): string[]
---@field get_current_line fun(): string|nil

---@type CommandTerminal
local M = {}

local WINDOW_NAME = 'terminal'

---@param opts CommandTerminalCreateOpts|CommandTerminalWindowOpts|nil
---@return integer, string
local function resolve_layout(opts)
    local height = (opts and opts.height) or config.values.ui.terminal.height or 0.25
    local split = (opts and opts.split) or config.values.ui.terminal.split or 'below'

    if height < 1 then
        height = math.floor(vim.o.lines * height)
    end

    height = math.max(height, 3)

    return height, split
end

---@param buf integer
---@param opts CommandTerminalCreateOpts|CommandTerminalWindowOpts|nil
---@return integer|nil, integer, string
local function open_window(buf, opts)
    local height, split = resolve_layout(opts)

    if split == 'below' then
        vim.cmd('botright ' .. height .. ' split')
    elseif split == 'above' then
        vim.cmd('topleft ' .. height .. ' split')
    elseif split == 'right' then
        vim.cmd('botright ' .. height .. ' vsplit')
    elseif split == 'left' then
        vim.cmd('topleft ' .. height .. ' vsplit')
    else
        vim.cmd('botright ' .. height .. ' split')
    end

    local win = vim.api.nvim_get_current_win()
    if not win or not vim.api.nvim_win_is_valid(win) then
        return nil, height, split
    end

    vim.api.nvim_win_set_buf(win, buf)

    return win, height, split
end

---@param buf integer
---@param actions table
local function attach_default_keymaps(buf, actions)
    local opts = { noremap = true, silent = true, buffer = buf }
    local keymaps = (config.values.keymaps and config.values.keymaps.terminal) or {}

    if keymaps.n then
        for _, keymap in ipairs(keymaps.n) do
            vim.keymap.set('n', keymap[1], keymap[2], opts)
        end
    else
        vim.keymap.set('n', '<CR>', actions.follow_error, opts)
        vim.keymap.set('n', '<C-q>', actions.send_to_quickfix, opts)
        vim.keymap.set('n', 'q', actions.hide or actions.close, opts)
    end

    vim.keymap.set('t', '<C-q>', actions.send_to_quickfix, opts)
end

---@param opts CommandTerminalCreateOpts|nil
---@param actions table
---@return CommandTerminalWindow|nil
function M.create(opts, actions)
    ---@type CommandTerminalCreateOpts
    local create_opts = opts or {}

    if M.get() then
        M.close()
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })

    local win, height, split = open_window(buf, create_opts)

    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_buf_delete(buf, { force = true })
        return nil
    end

    ---@type CommandTerminalWindow
    local window = {
        name = WINDOW_NAME,
        buf = buf,
        win = win,
        opts = {
            height = height,
            split = split,
            context = create_opts.context,
        },
    }

    session.register_window(window)

    attach_default_keymaps(buf, actions)

    return window
end

---@return Window|nil
function M.get()
    ---@type Window|nil
    local window = session.get_window(WINDOW_NAME)
    return window
end

function M.enter_normal_mode()
    local window = M.get()
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_call(window.win, function()
            vim.cmd('stopinsert')
        end)
    end
end

function M.hide()
    local window = M.get()
    if not window or not window.win or not vim.api.nvim_win_is_valid(window.win) then
        return
    end

    pcall(vim.api.nvim_win_close, window.win, true)
end

function M.close()
    local window = M.get()
    if not window then
        return
    end

    if window.job_id then
        pcall(vim.fn.jobstop, window.job_id)
        session.remove_job(window.job_id)
    end

    session.unregister_window(WINDOW_NAME)
end

---@param actions table
---@return CommandTerminalWindow|nil
function M.reopen(actions)
    local window = M.get()
    if not window then
        return nil
    end

    if not window.buf or not vim.api.nvim_buf_is_valid(window.buf) then
        session.unregister_window(WINDOW_NAME, { close = false, delete_buffer = false })
        return nil
    end

    if window.win and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_set_current_win(window.win)
        return window
    end

    local win, height, split = open_window(window.buf, window.opts)
    if not win or not vim.api.nvim_win_is_valid(win) then
        return nil
    end

    window.win = win
    window.opts = window.opts or {}
    window.opts.height = height
    window.opts.split = split
    session.register_window(window)

    attach_default_keymaps(window.buf, actions)

    return window
end

---@param cmd string
---@param context ExecutionContext|nil
---@return boolean
function M.send_command(cmd, context)
    local window = M.get()
    if not window or not vim.api.nvim_buf_is_valid(window.buf) then
        return false
    end

    local shell = vim.env.SHELL or '/bin/sh'
    local cwd = session.get_resolved_cwd(context or (window.opts and window.opts.context or nil))

    local job_id = vim.fn.jobstart({ shell, '-ic', cmd }, {
        term = true,
        cwd = cwd,
        on_exit = function(jid, exit_code)
            session.remove_job(jid)

            local current_window = M.get()
            if current_window then
                current_window.exit_code = exit_code
            end
        end,
    })

    if job_id > 0 then
        window.job_id = job_id
        session.add_job(job_id)
        return true
    end

    return false
end

---@return string[]
function M.get_lines()
    local window = M.get()
    if not window or not vim.api.nvim_buf_is_valid(window.buf) then
        return {}
    end

    return vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
end

---@return string|nil
function M.get_current_line()
    local window = M.get()
    if not window or not vim.api.nvim_buf_is_valid(window.buf) then
        return nil
    end

    if not window.win or not vim.api.nvim_win_is_valid(window.win) then
        return nil
    end

    local cursor_pos = vim.api.nvim_win_get_cursor(window.win)
    local line_num = cursor_pos[1]
    local lines = vim.api.nvim_buf_get_lines(window.buf, line_num - 1, line_num, false)

    return lines[1]
end

return M
