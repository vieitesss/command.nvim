local M = {}

function M.set(win)
    vim.api.nvim_set_option_value("winhl",
        "Normal:NormalFloat,FloatBorder:NormalFloat",
        { win = win }
    )
end

return M
