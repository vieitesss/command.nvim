local ui = require 'command.ui'
local utils = require 'command.utils'
local validation = require 'command.validation'
local expansion = require 'command.expansion'
local state = require 'command.state'

local M = {}

local ERROR_TERMINAL_NOT_CREATED = "Could not create the terminal window"
local ERROR_CONTEXT_NOT_CREATED = "Could not get the current context"
local ERROR_INVALID_COMMAND = "Command is empty"
local ERROR_INVALID_SHELL = "Shell not found or not executable"

---Execute a shell command in a terminal window.
---
---Handles errors gracefully:
---- Empty command validation
---- Context variable expansion
---- Dangerous pattern detection
---- Shell availability checking
---- Terminal window creation errors
---- Job start failures with recovery
---
---@param command string The command to execute
---@return boolean success Whether execution was successful
function M.exec_command(command)
    -- Check if command is empty
    if not command or command:len() == 0 then
        utils.print_error(ERROR_INVALID_COMMAND)
        return false
    end

    -- Expand context variables
    local context = state.get_context()
    if not context then
        utils.print_error(ERROR_CONTEXT_NOT_CREATED)
        return false
    end
    local expanded_command = expansion.expand(command, context)

    -- Validate command for dangerous patterns (may prompt user)
    if not validation.validate_command(expanded_command) then
        -- Command is not empty, so validation returned false because user cancelled confirmation
        -- Silently return without error message
        return false
    end

    -- Create terminal window
    if not ui.show_terminal() then
        utils.print_error(ERROR_TERMINAL_NOT_CREATED)
        return false
    end

    -- Get and validate shell
    local shell = vim.env.SHELL or "/bin/sh"
    if vim.fn.executable(shell) == 0 then
        utils.print_error(ERROR_INVALID_SHELL .. ": " .. shell)
        -- Try to recover with default shell
        shell = "/bin/sh"
        if vim.fn.executable(shell) == 0 then
            utils.print_error("No shell available for execution")
            return false
        end
        vim.notify("Falling back to /bin/sh", vim.log.levels.WARN)
    end

    -- Start the job
    local cmd = { shell, "-ic", expanded_command }
    
    local opts = { term = true }
    local cwd_mode = state.get_cwd_mode()

    if cwd_mode == "buffer" and context and context.buf then
        local file = vim.api.nvim_buf_get_name(context.buf)
        if file ~= "" then
            local dir = vim.fn.fnamemodify(file, ":h")
            if vim.fn.isdirectory(dir) == 1 then
                opts.cwd = dir
            end
        end
    elseif cwd_mode == "root" then
        opts.cwd = vim.fn.getcwd()
    end

    local ok, job_id = pcall(vim.fn.jobstart, cmd, opts)

    if not ok or job_id <= 0 then
        local error_msg = "Failed to start command execution"
        if job_id == -1 then
            error_msg = error_msg .. " (invalid shell)"
        elseif job_id == -2 then
            error_msg = error_msg .. " (invalid arguments)"
        elseif job_id == -3 then
            error_msg = error_msg .. " (terminal creation failed)"
        end
        utils.print_error(error_msg)
        return false
    end

    vim.cmd("stopinsert")

    require('command.ui.keymaps.terminal').apply()

    return true
end

return M
