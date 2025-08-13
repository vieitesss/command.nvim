local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

-- More expectations
Helpers.expect.greater = MiniTest.new_expectation(
    'greater number',
    function(a, b) return a > b end,
    function(a, b) return string.format('Left: %s, Right: %s; %s > %s', a, b, a, b) end
)

-- Wrap new_child_neovim
Helpers.new_child_neovim = function()
    local child = MiniTest.new_child_neovim()

    function child.setup()
        child.restart({ '-u', 'scripts/minimal_init.lua' })
        child.lua([[M = require('command').setup({})]])
    end

    function child.execute()
        child.o.lines = 100
        child.o.columns = 100
        child.lua('M.execute()')
    end

    return child
end

return Helpers
