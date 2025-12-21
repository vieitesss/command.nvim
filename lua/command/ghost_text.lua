---@class CommandGhostText
---Virtual text completion suggestions for command prompt

local M = {}
local config = require('command.config')
local history = require('command.history')

local ns_id = vim.api.nvim_create_namespace('command_ghost_text')

-- ============================================================================
-- Lifecycle
-- ============================================================================

---Attaches ghost text to prompt buffer
---Sets up autocommands for updates
---@param buf integer Buffer ID
function M.attach(buf)
    if not config.values.ui.prompt.ghost_text then
        return
    end

    local group = vim.api.nvim_create_augroup('command_ghost_text_' .. buf, { clear = true })

    vim.api.nvim_create_autocmd('TextChangedI', {
        group = group,
        buffer = buf,
        callback = function()
            M.update(buf)
        end,
    })

    vim.api.nvim_create_autocmd('InsertEnter', {
        group = group,
        buffer = buf,
        callback = function()
            M.update(buf)
        end,
    })

    vim.api.nvim_create_autocmd('InsertLeave', {
        group = group,
        buffer = buf,
        callback = function()
            M.detach(buf)
        end,
    })

    M.update(buf)
end

-- ============================================================================
-- Suggestion Management
-- ============================================================================

---Updates ghost text based on current prompt content
---@param buf integer Buffer ID
function M.update(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
    if #lines == 0 then
        return
    end

    local prefix = lines[1]

    local suggestion = history.get_suggestions(prefix)

    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

    if suggestion and suggestion ~= prefix and prefix ~= '' then
        local completion = suggestion:sub(#prefix + 1)

        vim.api.nvim_buf_set_extmark(buf, ns_id, 0, #prefix, {
            virt_text = { { completion, 'Comment' } },
            virt_text_pos = 'inline',
            hl_mode = 'combine',
        })
    end
end

---Accepts the ghost text suggestion
---@param buf integer Buffer ID
function M.accept(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
    if #lines == 0 then
        return
    end

    local prefix = lines[1]
    local suggestion = history.get_suggestions(prefix)

    if suggestion and suggestion ~= prefix then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { suggestion })

        local current_win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_is_valid(current_win) then
            vim.api.nvim_win_set_cursor(current_win, { 1, #suggestion })
        end

        vim.defer_fn(function()
            M.update(buf)
        end, 10)
    end
end

---Clears ghost text from buffer
---@param buf integer Buffer ID
function M.clear(buf)
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
    end
end

---Detaches ghost text from buffer
---@param buf integer Buffer ID
function M.detach(buf)
    M.clear(buf)
end

return M
