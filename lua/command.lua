local M = {}

local COMMAND = ""

M.setup = function ()
    vim.api.nvim_create_user_command("CommandExecute", M.new_command, {})
    vim.api.nvim_create_user_command("CommandRexecute", M.exec_command_again, {})

    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap("n", "<space>co", "<cmd>CommandExecute<cr>", opts)
    vim.api.nvim_set_keymap("n", "<space>cr", "<cmd>CommandRexecute<cr>", opts)
end

M._update_command = function()
    COMMAND = vim.fn.input("Command to execute: ")
end

M._print_error = function(msg)
    print("[ERROR] " .. msg)
end

M._exec_command = function()
    local buf = vim.api.nvim_create_buf(true, false)
    if buf == 0 then
        M._print_error("Could not create the buffer")
        return
    end

    local width = tonumber(vim.api.nvim_command_output("echo &columns"))
    local height = math.floor(tonumber(vim.api.nvim_command_output("echo &lines")) * 0.25)

    local win = vim.api.nvim_open_win(buf, true, {
        width = width,
        height = height,
        split = "below",
        win = 0,
    })
    if win == 0 then
        M._print_error("Could not open the window")
        return
    end

    local cmd = { "/usr/bin/env", "bash", "-c", COMMAND }

    local chan = vim.fn.termopen(cmd)
    if not chan or chan <= 0 then
        M._print_error("Could not open the terminal")
        return
    end
end

M.new_command = function()
    M._update_command()
    M._exec_command()
end

M.exec_command_again = function ()
    if COMMAND == "" then
        M._print_error("You have not executed a command before. Run `:CommandExecute`")
        return
    end
    M._exec_command()
end

M.setup()

return M
