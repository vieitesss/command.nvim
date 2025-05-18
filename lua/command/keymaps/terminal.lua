
--- @param buf int The buffer the keymaps belongs to
--- @param win int The terminal window
function load_terminal_keys(buf, win)
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>",
        string.format(
            '<cmd>lua require("command.actions").follow_error_at_cursor(%d)<CR>',
            win
        ),
        { noremap = true, silent = true }
    )
end

return load_terminal_keys
