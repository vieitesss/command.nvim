local utils = require('command.utils')

local M = {}

---Expand variables in the command string based on the context.
---@param cmd string The raw command string
---@param context ExecutionContext The execution context
---@return string expanded_cmd The command with variables expanded
function M.expand(cmd, context)
    if not context then
        return cmd
    end

    local replacements = {
        ['file'] = function()
            local path = vim.api.nvim_buf_get_name(context.buf)
            return vim.fn.fnamemodify(path, ':t')
        end,
        ['filePath'] = function()
            local path = vim.api.nvim_buf_get_name(context.buf)
            return vim.fn.fnamemodify(path, ':p')
        end,
        ['fileDir'] = function()
            local path = vim.api.nvim_buf_get_name(context.buf)
            return vim.fn.fnamemodify(path, ':p:h')
        end,
        ['fileName'] = function()
            local path = vim.api.nvim_buf_get_name(context.buf)
            return vim.fn.fnamemodify(path, ':t:r')
        end,
        ['line'] = function()
            return tostring(context.cursor[1])
        end,
        ['col'] = function()
            return tostring(context.cursor[2] + 1)
        end,
        ['cwd'] = function()
            return vim.fn.getcwd()
        end,
        ['selection'] = function()
            return utils.get_visual_selection(context.buf)
        end,
    }

    local function replace_var(key_with_modifier)
        local key, modifier = key_with_modifier:match('([^:]+):?(.*)')

        local func = replacements[key]
        if func then
            local value = func()
            if modifier == 'sh' then
                return vim.fn.shellescape(value)
            end
            return value
        end
        return '${' .. key_with_modifier .. '}' -- return original string if key not found
    end

    -- Replace ${var} or ${var:modifier}
    local expanded_cmd, _ = cmd:gsub('%${([%w_:]+)}', replace_var)
    return expanded_cmd
end

return M
