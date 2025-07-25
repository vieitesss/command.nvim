local M = {}

vim.fn.mkdir(vim.fn.stdpath('data') .. '/command.nvim', 'p')
local hist_dir = vim.fn.stdpath('data') .. '/command.nvim'
local hist_file = hist_dir .. '/command_history.txt'

function M.read()
    if vim.fn.filereadable(hist_file) == 1 then
        return vim.fn.readfile(hist_file)
    end
end

function M.write(list)
    vim.fn.writefile(list, hist_file)
end

return M
