local M = {}

local MODULE_NAME = ...
local COMMAND     = ""
local BUF         = nil
local ORIG_WIN    = nil

local errors = require("error_table").error_table

M.setup = function()
  vim.api.nvim_create_user_command("CommandExecute",  M.new_command, {})
  vim.api.nvim_create_user_command("CommandRexecute", M.exec_command_again, {})
end

M._update_command = function()
  COMMAND = vim.fn.input("Command to execute: ")
end

M._print_error = function(msg)
  vim.api.nvim_err_writeln("[command] " .. msg)
end

--------------------------------------------------------------------------------
-- PARSING
--------------------------------------------------------------------------------
M._parse_error_line = function(line)
  for _, entry in pairs(errors) do
    local match = vim.fn.matchlist(line, entry.regex)
    if #match > 0 and match[1] ~= "" then
      local file, lnum, col
      for i = 2, #match do
        local v = match[i]
        if not file and v:match("[/\\]") or v:match("%.%w+$") then
          file = v
        elseif not lnum and v:match("^%d+$") then
          lnum = tonumber(v)
        elseif lnum and not col and v:match("^%d+$") then
          col = tonumber(v) - 1
        end
      end
      return file, lnum, col
    end
  end

  local f, r, c = line:match("^([%w%./\\-_]+):(%d+):?(%d*)")
  if f then
    return f, tonumber(r), (c ~= "" and tonumber(c) or 1)
  end

  return nil, nil, nil
end

--------------------------------------------------------------------------------
-- GOTO
--------------------------------------------------------------------------------
M._goto_file_at_cursor = function()
  local line = vim.api.nvim_get_current_line()
  local fname, row, col = M._parse_error_line(line)

  if not fname then
    M._print_error("If this is an error, I could not find a valid pattern for it.")
    return
  end

  if ORIG_WIN and vim.api.nvim_win_is_valid(ORIG_WIN) then
    vim.api.nvim_set_current_win(ORIG_WIN)
  else
    vim.cmd("vsplit")
  end

  -- abre el fichero y posiciona cursor
  vim.cmd("edit " .. vim.fn.fnameescape(fname))
  vim.api.nvim_win_set_cursor(0, { row or 1, col or 1 })
end

--------------------------------------------------------------------------------
-- TERMINAL
--------------------------------------------------------------------------------
M._exec_command = function()
  ORIG_WIN = vim.api.nvim_get_current_win()

  if BUF and vim.fn.bufexists(BUF) == 1 then
    vim.api.nvim_buf_delete(BUF, { force = true })
  end

  BUF = vim.api.nvim_create_buf(true, false)
  if BUF == 0 then
    M._print_error("The terminal buffer could not be created.")
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
    M._print_error("The terminal window could not be opened.")
    return
  end

  vim.api.nvim_buf_set_keymap(
    BUF, "n", "<CR>",
    string.format('<cmd>lua require("%s")._goto_file_at_cursor()<CR>', MODULE_NAME),
    { noremap = true, silent = true }
  )

  local cmd  = { "/usr/bin/env", "bash", "-c", COMMAND }
  local chan = vim.fn.termopen(cmd)
  if not chan or chan <= 0 then
    M._print_error("The terminal could not be launched.")
  end
end

M.new_command = function()
  M._update_command()
  M._exec_command()
end

M.exec_command_again = function()
  if COMMAND == "" then
    M._print_error("Use first `:CommandExecute`")
    return
  end
  M._exec_command()
end

M.setup()

return M

