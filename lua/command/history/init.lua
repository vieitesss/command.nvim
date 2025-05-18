--- @type History
local M = {}

vim.fn.mkdir(vim.fn.stdpath('data') .. '/command.nvim', 'p')
local hist_dir = vim.fn.stdpath('data') .. '/command.nvim'
local hist_file = hist_dir .. '/command_history.txt'

--- @return string[]|nil
function M.get_history()
    if vim.fn.filereadable(hist_file) == 1 then
        return vim.fn.readfile(hist_file)
    end
    return nil
end

--- @param history string[] The commands executed during the session
function M.save_history(history)
    local len = #history
    if len > 200 then
        history = vim.list_slice(history, len - 199, len)
    end
    vim.fn.writefile(history, hist_file)
end

return M
