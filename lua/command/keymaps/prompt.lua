local actions = require 'command.actions'
local utils = require 'command.utils'

--- @type Command.Prompt
local M = {}

--- @param opts Command.Prompt
local function init(opts)
    M = vim.tbl_deep_extend('force', M, opts)
    M.hist_idx = #M.history + 1
end

local function history_up()
    if M.hist_idx > 1 then
        M.hist_idx = M.hist_idx - 1
        utils.set_cmd_prompt(M.buf, M.win, M.history[M.hist_idx] or "")
        vim.cmd("startinsert")
    end
end

local function history_down()
    local len = #M.history
    if M.hist_idx < len then
        M.hist_idx = M.hist_idx + 1
        utils.set_cmd_prompt(M.buf, M.win, M.history[M.hist_idx])
    else
        M.hist_idx = len + 1
        utils.set_cmd_prompt(M.buf, M.win, "")
    end
    vim.cmd("startinsert")
end

local function search()
    require('fzf-lua').fzf_exec(M.history, {
        prompt   = 'History> ',
        winopts  = { height = 0.30, width = 0.50, row = 0.75, col = 0.50 },
        complete = function(selected, _, line, col)
            if selected and #selected > 0 then
                local command = selected[1]
                return command, #command - 1
            end
            return line, col
        end,
    })
end

local function enter()
    local command = actions.on_command_enter(M)
    if command == "" then
        utils.print_error("No command was provided")
    else
        utils.exec_command(command)
        require('command.commands')._set_executed(true)
    end
end

local function cancel()
    actions.on_command_cancel(M.buf, M.win)
end

--- @param opts Command.Prompt
-- @return string The command to execute
local function load_prompt_keys(opts)
    init(opts)

    local keyopts = { buffer = true, noremap = true, silent = true }
    local ni = { 'i', 'n' }
    local key = vim.keymap

    key.set(ni, '<Up>', history_up, keyopts)
    key.set(ni, '<Down>', history_down, keyopts)
    key.set(ni, '<C-f>', search, keyopts)
    key.set(ni, '<CR>', enter, keyopts)
    key.set(ni, '<C-d>', cancel, keyopts)
    key.set('n', '<Esc>', cancel, keyopts)
end

return load_prompt_keys
