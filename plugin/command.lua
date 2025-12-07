local ok, command = pcall(require, 'command')

if not ok then
    vim.notify('[command.nvim] failed to load', vim.log.levels.ERROR)
    return
end

-- Define <Plug> mappings for user customization
vim.keymap.set({'n', 'i'}, '<Plug>(CommandExecute)', function()
    command.execute()
end, { desc = 'Open command prompt' })

vim.keymap.set({'n', 'i'}, '<Plug>(CommandExecuteLast)', function()
    command.execute_last()
end, { desc = 'Execute last command' })

-- Create user commands
vim.api.nvim_create_user_command("CommandExecute", function()
    command.execute()
end, {})

vim.api.nvim_create_user_command("CommandExecuteLast", function()
    command.execute_last()
end, {})
