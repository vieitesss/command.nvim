vim.opt.runtimepath:prepend('.')

local config = require('command.config')
local session = require('command.session')
local picker = require('command.history.picker')
local prompt = require('command.ui.prompt')
local prompt_actions = require('command.actions.prompt')

config.setup({
    history = {
        picker = 'fzf-lua',
    },
    ui = {
        prompt = {
            max_width = 40,
            max_height = 8,
            ghost_text = false,
        },
    },
    execution = {
        cwd = 'buffer',
    },
    validation = {
        warn = false,
    },
})

session.setup_autocmds()
session.set_cwd_mode('buffer')

local window = assert(prompt.create({ context = session.capture_context() }, prompt_actions), 'prompt was not created')
assert(window.opts.height == 1, 'expected single-line prompt height')

local multiline = table.concat({ 'echo \\', '  hello' }, '\n')
prompt.set_text(multiline)

assert(prompt.get_text() == multiline, 'multiline prompt text should round-trip')
assert(prompt.get().opts.height == 5, 'multiline prompt should expand to minimum visible height')

prompt.set_text('echo \\')
prompt_actions.enter_insert()
assert(prompt.get_text() == table.concat({ 'echo \\', '' }, '\n'), 'insert enter should continue lines ending in backslash')
assert(prompt.get().opts.height == 5, 'continuation newline should keep multiline height rules')

local tall_command = table.concat({ '1', '2', '3', '4', '5', '6', '7', '8', '9' }, '\n')
prompt.set_text(tall_command)
assert(prompt.get().opts.height == 8, 'multiline prompt should respect max_height')

assert(prompt._calculate_height({ 'a' }, 8) == 1, 'single-line command should keep height 1')
assert(prompt._calculate_height({ 'a', 'b' }, 8) == 5, 'two lines should expand to minimum visible height')
assert(prompt._calculate_height({ '1', '2', '3', '4', '5', '6', '7', '8', '9' }, 8) == 8, 'height should clamp to max_height')

local entries, commands_by_id = picker._build_entries({ 'echo hello', multiline })
assert(#entries == 2, 'expected encoded history entries')
assert(entries[1]:match('^1\t') ~= nil, 'expected picker entry id prefix')
assert(entries[1]:find(' \\n ', 1, true) ~= nil, 'expected multiline display marker')
assert(picker._resolve_selected_command(entries[1], commands_by_id) == multiline, 'expected picker selection to restore multiline command')

prompt.close()
session.cleanup(true)
