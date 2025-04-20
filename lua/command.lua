local M = {}

local MODULE_NAME = "command"
local COMMAND     = ""
local BUF         = nil
local ORIG_WIN    = nil

M.setup = function()
  vim.api.nvim_create_user_command("CommandExecute",  M.new_command, {})
  vim.api.nvim_create_user_command("CommandRexecute", M.exec_command_again, {})

  local opts = { silent = true, noremap = true }
  vim.api.nvim_set_keymap("n", "<space>co", "<cmd>CommandExecute<cr>",  opts)
  vim.api.nvim_set_keymap("n", "<space>cr", "<cmd>CommandRexecute<cr>", opts)
end

M._update_command = function()
  COMMAND = vim.fn.input("Command to execute: ")
end

M._print_error = function(msg) print("[ERROR] " .. msg) end

M._goto_file_at_cursor = function()
  local line = vim.api.nvim_get_current_line()
  local fname, row, col = line:match("^([%w%./\\-_]+):(%d+):?(%d*)")
  if not fname then
    M._print_error("No se encontró patrón file:line[:col].")
    return
  end
  row = tonumber(row)
  col = tonumber(col ~= "" and col or 1)

  if ORIG_WIN and vim.api.nvim_win_is_valid(ORIG_WIN) then
    vim.api.nvim_set_current_win(ORIG_WIN)
  else
    vim.cmd("vsplit")
  end

  vim.cmd("edit " .. vim.fn.fnameescape(fname))
  vim.api.nvim_win_set_cursor(0, { row, col })
end

M._exec_command = function()
  ORIG_WIN = vim.api.nvim_get_current_win()   -- ★ guarda ventana de origen

  if BUF and vim.fn.bufexists(BUF) == 1 then
    vim.api.nvim_buf_delete(BUF, { force = true })
  end

  BUF = vim.api.nvim_create_buf(true, false)
  if BUF == 0 then
    M._print_error("Could not create the buffer")
    return
  end

  local width  = tonumber(vim.api.nvim_command_output("echo &columns"))
  local height = math.floor(tonumber(vim.api.nvim_command_output("echo &lines")) * 0.25)

  local win = vim.api.nvim_open_win(BUF, true, {
    width  = width,
    height = height,
    split  = "below",
    win    = 0,
  })
  if win == 0 then
    M._print_error("Could not open the window")
    return
  end

  vim.api.nvim_buf_set_keymap(
    BUF,
    "n",
    "<CR>",
    string.format('<cmd>lua require("%s")._goto_file_at_cursor()<CR>', MODULE_NAME),
    { noremap = true, silent = true }
  )

  local cmd  = { "/usr/bin/env", "bash", "-c", COMMAND }
  local chan = vim.fn.termopen(cmd)
  if not chan or chan <= 0 then
    M._print_error("Could not open the terminal")
  end
end

M.new_command = function()
  M._update_command()
  M._exec_command()
end

M.exec_command_again = function()
  if COMMAND == "" then
    M._print_error("You have not executed a command before. Run `:CommandExecute`")
    return
  end
  M._exec_command()
end

M.setup()
return M

