local M = {}

local PREFIX = '[command.nvim] '

local function notify(level, msg)
    vim.notify(PREFIX .. msg, level)
end

function M.error(msg)
    notify(vim.log.levels.ERROR, msg)
end

function M.warn(msg)
    notify(vim.log.levels.WARN, msg)
end

function M.info(msg)
    notify(vim.log.levels.INFO, msg)
end

return M
