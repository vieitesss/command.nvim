local selection = require('command.util.selection')
local session = require('command.session')

local M = {}

---@param cmd string The raw command string
---@param context ExecutionContext|nil The execution context
---@return string expanded_cmd
function M.expand(cmd, context)
    if not context then
        return cmd
    end

    local path = vim.api.nvim_buf_get_name(context.buf)
    local replacements = {
        file = function()
            return vim.fn.fnamemodify(path, ':t')
        end,
        filePath = function()
            return vim.fn.fnamemodify(path, ':p')
        end,
        fileDir = function()
            return vim.fn.fnamemodify(path, ':p:h')
        end,
        fileName = function()
            return vim.fn.fnamemodify(path, ':t:r')
        end,
        line = function()
            return tostring(context.cursor[1])
        end,
        col = function()
            return tostring(context.cursor[2] + 1)
        end,
        cwd = function()
            return session.get_resolved_cwd()
        end,
        selection = function()
            return selection.get_visual_selection(context.buf)
        end,
    }

    local function replace_var(key_with_modifier)
        local key, modifier = key_with_modifier:match('([^:]+):?(.*)')
        local resolve = replacements[key]

        if not resolve then
            return '${' .. key_with_modifier .. '}'
        end

        local value = resolve()
        if modifier == 'sh' then
            return vim.fn.shellescape(value)
        end

        return value
    end

    return (cmd:gsub('%${([%w_:]+)}', replace_var))
end

return M
