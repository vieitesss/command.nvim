local M = {}

---@param mode table
---@param maps table -- The configs keymaps
---@return table
function M.include_mode(mode, maps)
    local res = {}

    for _, value in ipairs(maps) do
        table.insert(value, 1, mode)
        table.insert(res, value)
    end

    return res
end

function M.apply(buf, maps)
    local opts = { buffer = true, noremap = true, silent = true }
    for _, map in ipairs(maps) do
        local mode, lhs, rhs = map[1], map[2], map[3]
        opts.buffer = buf
        vim.keymap.set(mode, lhs, rhs, opts)
    end
end

return M
