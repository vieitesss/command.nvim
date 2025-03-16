local M = {}

M.printHello = function()
    local buf = vim.api.nvim_create_buf(true, false)
    if buf == 0 then
        print("Error creating the buffer")
        return
    end

    local width = tonumber(vim.api.nvim_command_output("echo &columns"))
    local height = math.floor(tonumber(vim.api.nvim_command_output("echo &lines")) * 0.2)

    local win = vim.api.nvim_open_win(buf, true, {
        width = width,
        height = height,
        split = "below",
        win = 0,
    })
    if win == 0 then
        print("Error opening the window")
        return
    end

    local cmd = { "/usr/bin/env", "bash", "-c", "./script.sh dani" }

    local chan = vim.fn.termopen(cmd)
    if not chan or chan <= 0 then
        print("Error al abrir el terminal")
        return
    end
end

M.printHello()

return M
