-- Test init file for command.nvim development
-- Add the plugin to runtime path
vim.opt.runtimepath:prepend('.')

vim.pack.add({
    { src = 'https://github.com/ibhagwan/fzf-lua' },
})

local actions = require('fzf-lua.actions')
require('fzf-lua').setup({
    winopts = {
        height = 1,
        width = 1,
        backdrop = 85,
        preview = {
            horizontal = 'right:70%',
        },
    },
    keymap = {
        builtin = {
            ['<C-f>'] = 'preview-page-down',
            ['<C-b>'] = 'preview-page-up',
            ['<C-p>'] = 'toggle-preview',
        },
        fzf = {
            ['ctrl-a'] = 'toggle-all',
            ['ctrl-t'] = 'first',
            ['ctrl-g'] = 'last',
            ['ctrl-d'] = 'half-page-down',
            ['ctrl-u'] = 'half-page-up',
        },
    },
    actions = {
        files = {
            ['ctrl-q'] = actions.file_sel_to_qf,
            ['ctrl-n'] = actions.toggle_ignore,
            ['ctrl-h'] = actions.toggle_hidden,
            ['enter'] = actions.file_edit_or_qf,
        },
    },
})

-- Test configuration with all default values
require('command').setup({
    history = {
        max = 200,
        picker = 'fzf-lua',
    },
    ui = {
        prompt = {
            max_width = 40,
            max_height = 10,
            ghost_text = true,
        },
        terminal = {
            height = 0.25,
            split = 'below',
        },
    },
    execution = {
        cwd = 'buffer',
    },
    validation = {
        warn = true,
    },
})

vim.g.mapleader = ' '
vim.keymap.set({ 'n', 'x', 'v' }, '<leader>r', '<Plug>(CommandExecute)')
vim.keymap.set({ 'n', 'x', 'v' }, '<leader>R', '<Plug>(CommandExecuteLast)')
