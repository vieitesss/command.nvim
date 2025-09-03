-- lua/command/ui/ghost.lua
local state = require 'command.state'

local M = {}

local NS = vim.api.nvim_create_namespace('command_ghost')
local HL = 'CommandGhostText'

local function starts_with(s, p)
    return p ~= '' and s:sub(1, #p) == p
end

-- Neovim 0.10 supports inline; fall back gracefully
local SUPPORTS_INLINE = (vim.fn.has('nvim-0.10') == 1)

M._mark_id = nil
M._preview = nil

function M.clear(buf)
    if buf and vim.api.nvim_buf_is_valid(buf) and M._mark_id then
        pcall(vim.api.nvim_buf_del_extmark, buf, NS, M._mark_id)
    end
    M._mark_id = nil
    M._preview = nil
end

-- Choose the most recent history item that matches the current prefix
local function choose_suggestion(prefix, history)
    if prefix == '' then return nil end
    for i = #history, 1, -1 do
        local h = history[i]
        if starts_with(h, prefix) then
            return h
        end
    end
    return nil
end

local function render(buf, win, suggestion, prefix)
    M.clear(buf)
    if not suggestion then return end
    local suffix = suggestion:sub(#prefix + 1)
    if suffix == '' then return end

    local row = 0
    local line = (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or '')
    local col = #line -- byte index at EOL (what extmarks expect)

    pcall(vim.api.nvim_set_hl, 0, HL, { link = 'Comment', default = true })

    local ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, NS, row, col, {
        virt_text = { { suffix, HL } },
        virt_text_pos = SUPPORTS_INLINE and 'inline' or 'eol',
        hl_mode = 'combine',
        priority = 1,
    })
    if ok then
        M._mark_id = id
        M._preview = suggestion
    end
end

function M.update()
    local window = state.get_window_by_name('prompt')
    if not window then return end
    local buf, win = window.buf, window.win
    if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)) then return end

    local line = (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or '')
    local suggestion = choose_suggestion(line, state.history_list())
    render(buf, win, suggestion, line)
end

function M.accept_all()
    local window = state.get_window_by_name('prompt'); if not window then return end
    local buf, win = window.buf, window.win
    local preview = M._preview
    if not preview then return end
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { preview })
    vim.api.nvim_win_set_cursor(win, { 1, #preview })
    M.clear(buf)
end

function M.attach()
    vim.notify('Ghost text attaching', vim.log.levels.INFO)
    local window = state.get_window_by_name('prompt')
    if not window then
        vim.notify('Ghost text failed to attach: prompt window not found', vim.log.levels.WARN)
        return
    end

    local buf = window.buf
    if not vim.api.nvim_buf_is_valid(buf) then
        vim.notify('Ghost text failed to attach: prompt buffer not valid', vim.log.levels.WARN)
        return
    end

    local grp = vim.api.nvim_create_augroup('CommandGhost_' .. tostring(buf), { clear = true })

    vim.api.nvim_create_autocmd({ 'InsertEnter', 'TextChangedI', 'TextChanged', 'CursorMovedI' }, {
        group = grp,
        buffer = buf,
        callback = function() require('command.ui.ghost').update() end,
    })

    -- Hide ghost text when leaving insert or when buffer/window closes
    vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufWipeout', 'BufDelete', 'WinClosed' }, {
        group = grp,
        buffer = buf,
        callback = function()
            local b = vim.api.nvim_get_current_buf()
            require('command.ui.ghost').clear(b)
        end,
    })

    vim.notify('Ghost text enabled', vim.log.levels.INFO)
end

return M
