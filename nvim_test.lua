-- Test init file for miniharp.nvim development
-- Add the plugin to runtime path
vim.opt.runtimepath:prepend('.')

vim.g.mapleader = ' '
vim.opt.relativenumber = true
vim.opt.number = true
vim.cmd('colorscheme catppuccin')

vim.pack.add({
    { src = vim.env.HOME .. '/personal/command.nvim' },
})

local cmd = require('command').setup({
})

vim.keymap.set('n', '<leader>ce', function()
    cmd.execute()
end)
vim.keymap.set('n', '<leader>cl', function()
    cmd.execute_last()
end)
vim.keymap.set('n', '<leader>cc', function()
    cmd.cycle_terminal_side()
end)
