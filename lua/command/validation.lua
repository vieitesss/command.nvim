---@class CommandValidation
---Input validation for shell command execution

local M = {}

---Check if a command contains potentially dangerous patterns.
---
---Warns about (but does not block):
---- Command substitution: $(...), `...`
---- Pipe chains to dangerous commands: | rm, | dd, etc.
---- Redirects to system files: > /etc/*, > /dev/*
---- Background execution: &
---
---@param cmd string The command to validate
---@return table warnings List of warning messages (empty if safe)
function M.check_dangerous_patterns(cmd)
    local warnings = {}

    -- Check for command substitution
    if cmd:match('%$%(') or cmd:match('`') then
        table.insert(warnings, 'Command contains command substitution ($(...) or `...`)')
    end

    -- Check for piping to dangerous commands
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

    -- Check for redirects to system files
    if cmd:match('>%s*/etc') then
        table.insert(warnings, 'Command redirects to /etc/ - system files protected')
    end
    if cmd:match('>%s*/sys') then
        table.insert(warnings, 'Command redirects to /sys/ - system files protected')
    end
    if cmd:match('>%s*/dev') then
        table.insert(warnings, 'Command redirects to /dev/ - be careful with device files')
    end

    -- Check for background execution
    if cmd:match('&%s*$') then
        table.insert(warnings, 'Command runs in background (&) - terminal may close before completion')
    end

    -- Check for chain operators that might execute unintended commands
    if cmd:match('||') or cmd:match('&&') then
        table.insert(warnings, 'Command chains multiple operations - review all commands')
    end

    return warnings
end

---Validate command input for execution.
---
---Performs basic validation:
---- Checks for dangerous patterns
---- Logs warnings if found
---- Prompts for user confirmation if warnings detected
---
---Returns true if command is safe to execute, false otherwise.
---
---@param cmd string The command to validate
---@return boolean safe Whether command is safe to execute
function M.validate_command(cmd)
    if not cmd or cmd:len() == 0 then
        return false
    end

    local warnings = M.check_dangerous_patterns(cmd)

    -- Require config lazily to avoid circular dependencies during lazy loading
    local config = require 'command.config'

    if #warnings > 0 and config.values.validation.warn then
        -- Build warning message with command and confirmation prompt
        local warning_lines = {
            '[command.nvim] WARNING - Command contains potentially dangerous patterns:',
            ''
        }
        for i, warning in ipairs(warnings) do
            table.insert(warning_lines, '  ' .. i .. '. ' .. warning)
        end
        table.insert(warning_lines, '')
        table.insert(warning_lines, 'Command: ' .. cmd)
        table.insert(warning_lines, '')
        table.insert(warning_lines, 'Proceed with execution? (y/n): ')

        local full_message = table.concat(warning_lines, '\n')
        local choice = vim.fn.input(full_message)

        if choice:lower() ~= 'y' then
            return false
        end
    end

    return true
end

---Escape special characters in a string for shell execution.
---
---Note: This is NOT used for command input (user-controlled).
---Only for internal strings that need shell escaping.
---
---@param str string String to escape
---@return string escaped Escaped string safe for shell
function M.escape_shell_arg(str)
    -- Wrap in single quotes and escape any single quotes
    return "'" .. str:gsub("'", "'\\''") .. "'"
end

---Check if a string looks like a shell variable reference.
---
---@param str string String to check
---@return boolean is_var Whether string is a variable reference
function M.is_shell_variable(str)
    return str:match('^%$[A-Za-z_][A-Za-z0-9_]*$') ~= nil
end

return M
