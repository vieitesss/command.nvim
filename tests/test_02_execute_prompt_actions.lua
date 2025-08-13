local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality
local state = require('command.state')

local T = MiniTest.new_set()

local history_mock = { "echo 1", "echo 2", "echo 3", "echo 4", "echo 5" }
-- _history.index = 6
-- history_last() = "echo 5"

local get_lines = function() return child.api.nvim_buf_get_lines(0, 0, -1, true) end
---@param elem string -- The func or field to call/get with return
local state_get = function(elem, ...)
    return child.lua_get(string.format("require('command.state').%s", elem), ...)
end

---@param elem string -- The func or field to call/get without return
local state = function(elem, ...)
    return child.lua(string.format("require('command.state').%s", elem), ...)
end

T['execute'] = MiniTest.new_set()

T['execute']['prompt actions'] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.setup()
            child.execute()
            state('setup_history(...)', { history_mock })
        end,
        post_once = child.stop,
    }
})

T['execute']['prompt actions']['history up'] = function()
    eq(child.fn.mode(), "i")
    eq(state_get('history_list()'), history_mock)
    
    eq(get_lines(), { '' })
    eq(state_get('_history.index'), 6)
    eq(get_lines(), { '' })
    child.type_keys('<Up>')
    eq(state_get('_history.index'), 5)
    eq(get_lines(), { 'echo 5' })
    child.type_keys('<Up>')
    child.type_keys('<Up>')
    child.type_keys('<Up>')
    eq(state_get('_history.index'), 2)
    eq(get_lines(), { 'echo 2' })
    child.type_keys('<Up>')
    eq(state_get('_history.index'), 1)
    eq(get_lines(), { 'echo 1' })
    child.type_keys('<Up>')
    child.type_keys('<Up>')
    child.type_keys('<Up>')
    child.type_keys('<Up>')
    eq(state_get('_history.index'), 1)
    eq(get_lines(), { 'echo 1' })
    -- eq(state.history_list(), history_mock)
    -- eq(state, 0)
    -- eq(state._history.index, 0)

    -- Insert mode
    -- child.type_keys("<Up>")
    -- eq(state._history.index, 5)

    -- -- Normal mode
    -- vim.cmd("stopinsert")
end

return T
