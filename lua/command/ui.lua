--- @type Command.UI
local M = {
    term_buf = nil
}

--- @return boolean true if the window was successfully created, false if not
function M.terminal_win()
    local orig_win = vim.api.nvim_get_current_win()

    if M.term_buf and vim.fn.bufexists(M.term_buf) == 1 then
        vim.api.nvim_buf_delete(M.term_buf, { force = true })
    end

    M.term_buf = vim.api.nvim_create_buf(true, false)
    local width = tonumber(vim.api.nvim_command_output("echo &columns"))
    local height = math.floor(tonumber(vim.api.nvim_command_output("echo &lines")) * 0.25)

    local win = vim.api.nvim_open_win(M.term_buf, true, {
        width = width,
        height = height,
        split = "below",
        win = 0,
    })

    if win == 0 then
        return false
    end

    -- Load terminal keymaps
    require('command.keymaps.terminal')(M.term_buf, win)

    return true
end

--- @return (int, int) (buffer, window)
function M.command_prompt()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)

    local width = math.max(40, math.floor(vim.o.columns * 0.5))
    local height = 1
    local row = math.floor((vim.o.lines - height) / 2 - 1)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        title = "Command to execute",
        title_pos = "right",
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    if win == 0 then
        return -1, -1
    end

    vim.cmd("startinsert")

    return buf, win
end

return M
