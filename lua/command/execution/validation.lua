local M = {}

---@param cmd string
---@return string[] warnings
function M.check_dangerous_patterns(cmd)
    local warnings = {}

    if cmd:match('%$%(') or cmd:match('`') then
        table.insert(warnings, 'Command contains command substitution ($(...) or `...`)')
    end

    if cmd:match('|%s*rm') then
        table.insert(warnings, 'Command pipes to `rm` - be careful with file deletion')
    end
    if cmd:match('|%s*dd') then
        table.insert(warnings, 'Command pipes to `dd` - dangerous for disk operations')
    end
    if cmd:match('|%s*mkfs') then
        table.insert(warnings, 'Command pipes to `mkfs` - dangerous for filesystem operations')
    end
    if cmd:match('|%s*shred') then
        table.insert(warnings, 'Command pipes to `shred` - secure file deletion')
    end

    if cmd:match('>%s*/etc') then
        table.insert(warnings, 'Command redirects to /etc/ - system files protected')
    end
    if cmd:match('>%s*/sys') then
        table.insert(warnings, 'Command redirects to /sys/ - system files protected')
    end
    if cmd:match('>%s*/dev') then
        table.insert(warnings, 'Command redirects to /dev/ - be careful with device files')
    end

    if cmd:match('&%s*$') then
        table.insert(warnings, 'Command runs in background (&) - terminal may close before completion')
    end

    if cmd:match('||') or cmd:match('&&') then
        table.insert(warnings, 'Command chains multiple operations - review all commands')
    end

    return warnings
end

---@param cmd string
---@return boolean safe
function M.validate_command(cmd)
    if not cmd or cmd == '' then
        return false
    end

    local warnings = M.check_dangerous_patterns(cmd)
    local config = require('command.config')

    if #warnings > 0 and config.values.validation.warn then
        local warning_lines = {
            '[command.nvim] WARNING - Command contains potentially dangerous patterns:',
            '',
        }

        for i, warning in ipairs(warnings) do
            table.insert(warning_lines, '  ' .. i .. '. ' .. warning)
        end

        table.insert(warning_lines, '')
        table.insert(warning_lines, 'Command: ' .. cmd)
        table.insert(warning_lines, '')
        table.insert(warning_lines, 'Proceed with execution? (y/n): ')

        local choice = vim.fn.input(table.concat(warning_lines, '\n'))
        if choice:lower() ~= 'y' then
            return false
        end
    end

    return true
end

return M
