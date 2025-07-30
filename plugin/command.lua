local ok, command = pcall(require, 'command')

if not ok then
    vim.notify('[command.nvim] failed to load', vim.log.levels.ERROR)
end

vim.api.nvim_create_user_command("CommandExecute", function()
    command.execute()
end, {})

vim.api.nvim_create_user_command("CommandExecuteLast", function()
    command.execute_last()
end, {})
