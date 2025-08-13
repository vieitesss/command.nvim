local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect = MiniTest.expect
local eq = expect.equality
local neq = expect.no_equality

local T = MiniTest.new_set()

local defaults = {
    history = {
        max = 200,
        picker = "fzf-lua"
    },
    ui = {
        prompt = {
            max_width = 40
        },
        terminal = {
            height = 0.25,
            split = "below"
        }
    },
    -- keymaps = {
    --     prompt = {
    --         ni = {
    --             { '<Up>', prompt_act.history_up },
    --             { '<Down>', prompt_act.history_down },
    --             { '<C-f>', prompt_act.search },
    --             { '<CR>', prompt_act.enter },
    --             { '<C-d>', prompt_act.cancel },
    --         },
    --         n = {
    --             { '<Esc>', prompt_act.cancel }
    --         }
    --     },
    --     terminal = {
    --         n = {
    --             { '<CR>', terminal_act.follow_error }
    --         }
    --     }
    -- }
}

T['setup'] = MiniTest.new_set({
    hooks = {
        pre_case = child.setup,
        post_once = child.stop,
    }
})

T['setup']['history'] = function()
    eq(child.lua([[return require('command.history')._max]]), 200)
    eq(child.lua([[return require('command.history')._picker]]), "fzf-lua")
    neq(child.lua([[return require('command.state')._history.list]], nil))
    helpers.expect.greater(child.lua([[return require('command.state')._history.index]]), 0)
end

T['setup']['ui'] = function()
    eq(child.lua([[return require('command.ui.prompt')._max_width]]), 40)
    eq(child.lua([[return require('command.ui.terminal')._height]]), 0.25)
    eq(child.lua([[return require('command.ui.terminal')._split]]), "below")
end

return T
