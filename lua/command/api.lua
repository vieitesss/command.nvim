local config = require('command.config')
local executor = require('command.execution.executor')
local history = require('command.history')
local notify = require('command.util.notify')
---@type CommandPrompt
local prompt = require('command.ui.prompt')
local prompt_actions = require('command.actions.prompt')
local selection = require('command.util.selection')
local session = require('command.session')

local M = {}

local function prepare_context()
    local context = session.capture_context()
    session.set_cwd_mode(config.values.execution.cwd)
    return context
end

function M.execute()
    local context = prepare_context()

    if prompt.focus(context) then
        return
    end

    ---@type CommandPromptCreateOpts
    local prompt_opts = vim.tbl_extend('force', {}, config.values.ui.prompt or {}, {
        context = context,
    })

    local result = prompt.create(prompt_opts, prompt_actions)
    if not result then
        notify.error('Could not create the prompt window')
        return
    end

    vim.cmd('startinsert')
end

function M.execute_selection()
    local context = prepare_context()
    local selected = selection.get_visual_selection(context.buf)
    if selected == '' then
        notify.error('No selection found')
        return
    end

    executor.run(selected, { context = context })
end

function M.execute_last()
    local context = prepare_context()

    if not session.has_run() then
        notify.error('Use first `:CommandExecute`')
        return
    end

    local last = history.get_last()
    if not last or last == '' then
        notify.error('No command history found')
        return
    end

    executor.run(last, {
        context = context,
        record_history = false,
    })
end

return M
