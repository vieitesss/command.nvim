local M = {
    _term_buf = -1,
}

function M.setup(opts)
    M._height = opts.height
    M._split = opts.split
end

function M.create()
    local _ = vim.api.nvim_get_current_win()

    if M._term_buf ~= -1 and vim.fn.bufexists(M._term_buf) == 1 then
        vim.api.nvim_buf_delete(M._term_buf, { force = true })
    end

    M._term_buf = vim.api.nvim_create_buf(true, false)

    return {
        name = "terminal",
        buf = M._term_buf,
        opts = {
            width = vim.o.columns,
            height = math.floor(vim.o.lines * M._height),
            split = M._split,
            win = 0,
        }
    }
end

return M
