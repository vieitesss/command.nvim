local config = require('command.config')
local expansion = require('command.execution.expansion')
local history = require('command.history')
local notify = require('command.util.notify')
local session = require('command.session')
local terminal = require('command.ui.terminal')
local terminal_actions = require('command.actions.terminal')
local validation = require('command.execution.validation')

---@class CommandRunOpts
---@field context ExecutionContext|nil Context used for expansion and cwd resolution
---@field before_execute fun()|nil Callback run before creating the terminal
---@field record_history boolean|nil When false, skip adding the command to history

---@class CommandExecutor
---@field run fun(cmd: string, opts: CommandRunOpts|nil): boolean

---@type CommandExecutor
local M = {}

---@param cmd string
---@param opts CommandRunOpts|nil
---@return boolean
function M.run(cmd, opts)
    ---@type CommandRunOpts
    local run_opts = opts or {}

    local normalized = (cmd or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if normalized == '' then
        notify.error('No command was provided')
        return false
    end

    local context = run_opts.context
    if not context then
        notify.error('Could not resolve execution context')
        return false
    end

    local expanded = expansion.expand(normalized, context)

    if not validation.validate_command(expanded) then
        return false
    end

    if run_opts.before_execute then
        run_opts.before_execute()
    end

    if run_opts.record_history ~= false then
        history.add(normalized)
    end

    local terminal_opts = vim.tbl_extend('force', {}, config.values.ui.terminal or {}, {
        context = context,
    })

    local terminal_window = terminal.create(terminal_opts, terminal_actions)
    if not terminal_window then
        notify.error('Could not create terminal window')
        return false
    end

    if not terminal.send_command(expanded, context) then
        notify.error('Could not create terminal job')
        return false
    end

    terminal.enter_normal_mode()
    session.mark_has_run()
    return true
end

return M
