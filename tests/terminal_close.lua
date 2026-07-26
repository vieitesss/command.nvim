vim.opt.runtimepath:prepend('.')

local config = require('command.config')
local session = require('command.session')
local terminal = require('command.ui.terminal')
local terminal_actions = require('command.actions.terminal')

config.setup({})
session.setup_autocmds()

local window = assert(terminal.create({}, terminal_actions), 'terminal was not created')
local close_mapping = vim.fn.maparg('Q', 'n', false, true)
assert(type(close_mapping.callback) == 'function', 'Q should have a buffer-local terminal mapping')

assert(terminal.send_command('while :; do :; done'), 'terminal command did not start')
local job_id = window.job_id
close_mapping.callback()

assert(terminal.get() == nil, 'Q should close the terminal')
assert(vim.fn.jobwait({ job_id }, 1000)[1] ~= -1, 'Q should stop the running terminal job')

session.cleanup(true)
