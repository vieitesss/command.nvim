local M = {}

function M.WINDOW_NOT_FOUND(name, func)
    return string.format("::%s::Could not found a window with name '%s'", func, name)
end

return M
