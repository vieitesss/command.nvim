-- Guard against double-loading
if vim.g.loaded_command then
    return
end
vim.g.loaded_command = true

-- Lazy-load the plugin only when needed
local function load_command()
    local ok, command = pcall(require, 'command')
    if not ok then
        vim.notify('[command.nvim] failed to load', vim.log.levels.ERROR)
        return nil
    end
    return command
end

-- Define <Plug> mappings for user customization (lazy-loaded)
vim.keymap.set({'n', 'i'}, '<Plug>(CommandExecute)', function()
    local command = load_command()
    if command then
        command.execute()
    end
end, { desc = 'Open command prompt' })

vim.keymap.set({'n', 'i'}, '<Plug>(CommandExecuteLast)', function()
    local command = load_command()
    if command then
        command.execute_last()
    end
end, { desc = 'Execute last command' })

-- Create user commands (lazy-loaded)
vim.api.nvim_create_user_command("CommandExecute", function()
    local command = load_command()
    if command then
        command.execute()
    end
end, {})

vim.api.nvim_create_user_command("CommandExecuteLast", function()
    local command = load_command()
    if command then
        command.execute_last()
    end
end, {})
