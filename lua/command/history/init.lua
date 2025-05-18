local M = {}

-- History file
vim.fn.mkdir(vim.fn.stdpath('data') .. '/command.nvim', 'p')
local hist_dir = vim.fn.stdpath('data') .. '/command.nvim'
local hist_file = hist_dir .. '/command_history.txt'

--- Load command history from disk
--- @return string[]|nil
M.get_history = function()
    if vim.fn.filereadable(hist_file) == 1 then
        return vim.fn.readfile(hist_file)
    end
    return nil
end

--- Save the history to disk, keeping only the most recent 200 entries
--- @param history table The commands executed during the session
M.save_history = function(history)
    local len = #history
    if len > 200 then
        history = vim.list_slice(history, len - 199, len)
    end
    vim.fn.writefile(history, hist_file)
end

return M
