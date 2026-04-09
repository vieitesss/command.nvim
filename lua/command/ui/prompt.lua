local config = require('command.config')
local ghost_text = require('command.ui.ghost_text')
local session = require('command.session')

---@class CommandPromptCreateOpts: CommandConfigPromptOpts
---@field context ExecutionContext|nil Source context used by prompt actions and title rendering

---@class CommandPromptWindowOpts: CommandWindowOpts
---@field width integer Prompt window width
---@field height integer Prompt window height
---@field max_width integer Maximum prompt width used for layout
---@field max_height integer Maximum prompt height used for layout
---@field context ExecutionContext|nil Source context associated with the prompt

---@class CommandPromptWindow: Window
---@field name 'prompt'
---@field opts CommandPromptWindowOpts

---@class CommandPrompt
---@field create fun(opts: CommandPromptCreateOpts|nil, actions: table): CommandPromptWindow|nil
---@field get fun(): CommandPromptWindow|nil
---@field focus fun(context: ExecutionContext|nil): boolean
---@field update_title fun()
---@field refresh_layout fun()
---@field close fun()
---@field set_text fun(command: string)
---@field get_text fun(): string

---@type CommandPrompt
local M = {}

local WINDOW_NAME = 'prompt'
local PROMPT_HEIGHT = 1
local MIN_MULTILINE_HEIGHT = 5
local DEFAULT_MAX_HEIGHT = 10

---@param context ExecutionContext|nil
local function build_title(context)
    local cwd = vim.fn.fnamemodify(session.get_resolved_cwd(context), ':~')
    return ' ' .. cwd .. ' '
end

---@param command string|nil
---@return string[]
local function split_command_lines(command)
    if command == nil or command == '' then
        return { '' }
    end

    return vim.split(command, '\n', { plain = true, trimempty = false })
end

---@param buf integer
---@return string[]
local function get_buffer_lines(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #lines == 0 then
        return { '' }
    end

    return lines
end

---@param max_height integer|nil
---@return integer
local function resolve_max_height(max_height)
    local configured = max_height or config.values.ui.prompt.max_height or DEFAULT_MAX_HEIGHT
    if type(configured) ~= 'number' then
        configured = DEFAULT_MAX_HEIGHT
    end

    return math.max(math.floor(configured), MIN_MULTILINE_HEIGHT)
end

---@param opts CommandPromptCreateOpts|CommandPromptWindowOpts|nil
---@param lines string[]
---@return table
local function build_layout(opts, lines)
    local layout_opts = opts or {}
    local max_width = layout_opts.max_width or config.values.ui.prompt.max_width or 40
    if type(max_width) ~= 'number' then
        max_width = 40
    end

    local max_height = resolve_max_height(layout_opts.max_height)
    local width = math.max(max_width, math.floor(vim.o.columns * 0.5))
    width = math.min(width, math.max(vim.o.columns - 4, 1))

    local height = math.max(#lines, PROMPT_HEIGHT)
    if #lines > 1 then
        height = math.max(height, MIN_MULTILINE_HEIGHT)
    end
    height = math.min(height, max_height, math.max(vim.o.lines - 4, PROMPT_HEIGHT))

    local row = math.max(math.floor((vim.o.lines - height) / 2 - 1), 0)
    local col = math.max(math.floor((vim.o.columns - width) / 2), 0)

    return {
        width = width,
        height = height,
        max_width = max_width,
        max_height = max_height,
        row = row,
        col = col,
    }
end

---@param window CommandPromptWindow|nil
local function apply_layout(window)
    if not window or not window.buf or not vim.api.nvim_buf_is_valid(window.buf) then
        return
    end

    if not window.win or not vim.api.nvim_win_is_valid(window.win) then
        return
    end

    local layout = build_layout(window.opts, get_buffer_lines(window.buf))
    window.opts = vim.tbl_extend('force', window.opts or {}, {
        width = layout.width,
        height = layout.height,
        max_width = layout.max_width,
        max_height = layout.max_height,
    })

    vim.api.nvim_win_set_config(window.win, {
        title = build_title(window.opts.context),
        title_pos = 'right',
        relative = 'editor',
        width = layout.width,
        height = layout.height,
        row = layout.row,
        col = layout.col,
        style = 'minimal',
        border = 'rounded',
    })

    vim.api.nvim_set_option_value('wrap', false, { win = window.win })
end

---@param buf integer
local function attach_layout_autocmds(buf)
    local group = vim.api.nvim_create_augroup('command_prompt_layout_' .. buf, { clear = true })

    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
        group = group,
        buffer = buf,
        callback = function()
            local window = M.get()
            if not window or window.buf ~= buf then
                return
            end

            M.refresh_layout()
        end,
    })
end

---@param buf integer
---@param actions table
local function attach_default_keymaps(buf, actions)
    local opts = { noremap = true, silent = true, buffer = buf }
    local keymaps = (config.values.keymaps and config.values.keymaps.prompt) or {}

    if keymaps.ni then
        for _, keymap in ipairs(keymaps.ni) do
            vim.keymap.set({ 'i', 'n' }, keymap[1], keymap[2], opts)
        end
    else
        vim.keymap.set('i', '<CR>', actions.enter_insert or actions.enter, opts)
        vim.keymap.set('i', '<Up>', actions.prev_history, opts)
        vim.keymap.set('i', '<Down>', actions.next_history, opts)
        vim.keymap.set('i', '<C-f>', actions.search_history, opts)
        vim.keymap.set('i', '<C-e>', actions.accept_ghost, opts)
        vim.keymap.set('i', '<C-o>', actions.toggle_cwd, opts)
    end

    if keymaps.n then
        for _, keymap in ipairs(keymaps.n) do
            vim.keymap.set('n', keymap[1], keymap[2], opts)
        end
    else
        vim.keymap.set('n', '<CR>', actions.enter, opts)
        vim.keymap.set('n', '<Up>', actions.prev_history, opts)
        vim.keymap.set('n', '<Down>', actions.next_history, opts)
        vim.keymap.set('n', '<C-f>', actions.search_history, opts)
        vim.keymap.set('n', '<C-e>', actions.accept_ghost, opts)
        vim.keymap.set('n', '<C-o>', actions.toggle_cwd, opts)
        vim.keymap.set('n', '<Esc>', actions.cancel, opts)
    end
end

---@param opts CommandPromptCreateOpts|nil
---@param actions table
---@return CommandPromptWindow|nil
function M.create(opts, actions)
    ---@type CommandPromptCreateOpts
    local create_opts = opts or {}

    if M.get() then
        M.close()
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })

    local layout = build_layout(create_opts, { '' })

    local win = vim.api.nvim_open_win(buf, true, {
        title = build_title(create_opts.context),
        title_pos = 'right',
        relative = 'editor',
        width = layout.width,
        height = layout.height,
        row = layout.row,
        col = layout.col,
        style = 'minimal',
        border = 'rounded',
    })

    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_buf_delete(buf, { force = true })
        return nil
    end

    vim.api.nvim_set_option_value('wrap', false, { win = win })

    ---@type CommandPromptWindow
    local window = {
        name = WINDOW_NAME,
        buf = buf,
        win = win,
        opts = {
            width = layout.width,
            height = layout.height,
            max_width = layout.max_width,
            max_height = layout.max_height,
            context = create_opts.context,
        },
    }

    session.register_window(window)

    attach_default_keymaps(buf, actions)
    attach_layout_autocmds(buf)

    if config.values.ui.prompt.ghost_text then
        ghost_text.attach(buf)
    end

    return window
end

---@return CommandPromptWindow|nil
function M.get()
    ---@type CommandPromptWindow|nil
    local window = session.get_window(WINDOW_NAME)
    return window
end

---@param context ExecutionContext|nil
function M.focus(context)
    local window = M.get()
    if window and vim.api.nvim_win_is_valid(window.win) then
        if context then
            window.opts = window.opts or {}
            window.opts.context = context
            M.update_title()
        end

        vim.api.nvim_set_current_win(window.win)
        vim.cmd('startinsert')
        return true
    end

    return false
end

function M.update_title()
    local window = M.get()
    if window and vim.api.nvim_win_is_valid(window.win) then
        apply_layout(window)
    end
end

function M.refresh_layout()
    apply_layout(M.get())
end

function M.close()
    local window = M.get()
    if not window then
        return
    end

    ghost_text.clear(window.buf)
    session.unregister_window(WINDOW_NAME)
end

---@param command string
function M.set_text(command)
    local window = M.get()
    if not window or not window.buf or not vim.api.nvim_buf_is_valid(window.buf) then
        return
    end

    local lines = split_command_lines(command)
    vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, lines)
    M.refresh_layout()

    if window.win and vim.api.nvim_win_is_valid(window.win) then
        local last_line = lines[#lines] or ''
        vim.api.nvim_win_set_cursor(window.win, { #lines, #last_line })
    end
end

---@return string
function M.get_text()
    local window = M.get()
    if not window or not window.buf or not vim.api.nvim_buf_is_valid(window.buf) then
        return ''
    end

    local lines = get_buffer_lines(window.buf)
    return table.concat(lines, '\n')
end

M._split_lines = split_command_lines
M._calculate_height = function(lines, max_height)
    return build_layout({ max_height = max_height }, lines).height
end

return M
