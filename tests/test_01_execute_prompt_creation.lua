local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local T = MiniTest.new_set()

T['execute'] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.setup()
            child.execute()
        end,
        post_once = child.stop,
    }
})

T['execute']['prompt window creation'] = MiniTest.new_set()

T['execute']['prompt window creation']['win id valid'] = function()
    neq(child.lua([[return require('command.state')._main_win]]), 0)
end

T['execute']['prompt window creation']['autocmd created'] = function()
    local autocmds = child.api.nvim_get_autocmds({ group = 'CommandAutocmd' })
    eq(#autocmds, 1)

    local au = autocmds[1]

    local win = child.lua([[return require('command.state').get_window_by_name('prompt')]])
    eq(au.buffer, win.buf)
end

T['execute']['prompt window creation']['window created'] = function()
    local wins = child.lua([[return require('command.state')._windows]])
    eq(#wins, 1)

    local win = child.lua([[return require('command.state').get_window_by_name('prompt')]])
    neq(win, nil)
    neq(win.name, nil)
    neq(win.buf, nil)
    eq(win.name, 'prompt')
    helpers.expect.greater(win.buf, 0)
end

T['execute']['prompt window creation']['window dimensions'] = function()
    local win = child.lua([[return require('command.state').get_window_by_name('prompt')]])
    local opts = win.opts
    -- columns = 100
    -- lines   = 100
    eq(opts.width, 50)
    eq(opts.height, 1)
    eq(opts.row, 48)
    eq(opts.col, 25)
end

T['execute']['prompt window creation']['keymaps applied'] = function()
    local win = child.lua([[return require('command.state').get_window_by_name('prompt')]])
    local keymaps = child.api.nvim_buf_get_keymap(win.buf, "n")

    eq(#keymaps, 6)
end

return T
