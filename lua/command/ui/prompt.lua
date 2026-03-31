local config = require('command.config')
local ghost_text = require('command.ui.ghost_text')
local session = require('command.session')

local M = {}

local WINDOW_NAME = 'prompt'
local PROMPT_HEIGHT = 1

local function build_title()
    local cwd = vim.fn.fnamemodify(session.get_resolved_cwd(), ':~')
    return ' ' .. cwd .. ' '
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
        vim.keymap.set('i', '<CR>', actions.enter, opts)
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

---@param opts table|nil
---@param actions table
---@return table|nil
function M.create(opts, actions)
    opts = opts or {}

    if M.get() then
        M.close()
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })

    local max_width = opts.max_width or config.values.ui.prompt.max_width or 40
    local width = math.max(max_width, math.floor(vim.o.columns * 0.5))
    local height = PROMPT_HEIGHT
    local row = math.floor((vim.o.lines - height) / 2 - 1)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        title = build_title(),
        title_pos = 'right',
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })

    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_buf_delete(buf, { force = true })
        return nil
    end

    vim.api.nvim_set_option_value('wrap', false, { win = win })

    session.register_window({
        name = WINDOW_NAME,
        buf = buf,
        win = win,
        opts = {
            width = width,
            height = height,
            max_width = max_width,
        },
    })

    attach_default_keymaps(buf, actions)

    if config.values.ui.prompt.ghost_text then
        ghost_text.attach(buf)
    end

    return { buf = buf, win = win }
end

---@return table|nil
function M.get()
    return session.get_window(WINDOW_NAME)
end

function M.focus()
    local window = M.get()
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_set_current_win(window.win)
        vim.cmd('startinsert')
        return true
    end

    return false
end

function M.update_title()
    local window = M.get()
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_set_config(window.win, { title = build_title() })
    end
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
    if not window then
        return
    end

    vim.api.nvim_buf_set_lines(window.buf, 0, -1, false, { command })
    vim.api.nvim_win_set_cursor(window.win, { 1, #command })
end

---@return string
function M.get_text()
    local window = M.get()
    if not window then
        return ''
    end

    local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
    return table.concat(lines, '\n')
end

return M
