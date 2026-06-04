vim.opt.runtimepath:prepend('.')

local session = require('command.session')

local original_cwd = vim.fn.getcwd()
local tmp = vim.fn.tempname()
local file_dir = tmp .. '/file-dir'
local file_path = file_dir .. '/example.txt'

vim.fn.mkdir(file_dir, 'p')
vim.fn.writefile({ 'example' }, file_path)
vim.cmd('cd ' .. vim.fn.fnameescape(tmp))
local cwd = vim.fn.getcwd()

session.set_cwd_mode('buffer')

local file_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(file_buf, file_path)
local expected_file_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(file_buf), ':h')
assert(
    session.get_resolved_cwd({ buf = file_buf }) == expected_file_dir,
    'file buffers should resolve to their file directory'
)

local nofile_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(nofile_buf, file_dir .. '/nofile-buffer')
vim.api.nvim_set_option_value('buftype', 'nofile', { buf = nofile_buf })
assert(
    session.get_resolved_cwd({ buf = nofile_buf }) == cwd,
    'non-file buffers should resolve to the current working directory'
)

session.set_cwd_mode('root')
assert(session.get_resolved_cwd({ buf = file_buf }) == cwd, 'root mode should resolve to the current working directory')

vim.api.nvim_buf_delete(file_buf, { force = true })
vim.api.nvim_buf_delete(nofile_buf, { force = true })
vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
session.cleanup(true)
