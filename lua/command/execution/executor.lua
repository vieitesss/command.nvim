local config = require('command.config')
local expansion = require('command.execution.expansion')
local history = require('command.history')
local notify = require('command.util.notify')
local session = require('command.session')
local terminal = require('command.ui.terminal')
local terminal_actions = require('command.actions.terminal')
local validation = require('command.execution.validation')

local M = {}

---@param cmd string
---@param opts table|nil
---@return boolean
function M.run(cmd, opts)
    opts = opts or {}

    local normalized = (cmd or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if normalized == '' then
        notify.error('No command was provided')
        return false
    end

    local context = opts.context or session.get_context()
    local expanded = expansion.expand(normalized, context)

    if not validation.validate_command(expanded) then
        return false
    end

    if opts.before_execute then
        opts.before_execute()
    end

    if opts.record_history ~= false then
        history.add(normalized)
    end

    local terminal_window = terminal.create(config.values.ui.terminal, terminal_actions)
    if not terminal_window then
        notify.error('Could not create terminal window')
        return false
    end

    if not terminal.send_command(expanded) then
        notify.error('Could not create terminal job')
        return false
    end

    terminal.enter_normal_mode()
    session.mark_has_run()
    return true
end

return M
