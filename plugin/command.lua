local ok, command = pcall(require, 'command')

if not ok then
    vim.notify('[command.nvim] failed to load', vim.log.levels.ERROR)
end

vim.api.nvim_create_user_command("CommandExecute", function()
    command.run()
end, {})

vim.api.nvim_create_user_command("CommandRexecute", function()
    command.repeat_last()
end, {})
