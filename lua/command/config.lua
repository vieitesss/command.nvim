local prompt_act = require 'command.actions.prompt'

local M = {}

local defaults = {
    history = {
        max = 200
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
    keymaps = {
        prompt = {
            ni = {
                { '<Up>', prompt_act.history_up },
                { '<Down>', prompt_act.history_down },
                { '<C-f>', prompt_act.search },
                { '<CR>', prompt_act.enter },
                { '<C-d>', prompt_act.cancel },
            },
            n = {
                { '<Esc>', prompt_act.cancel }
            }
        }
    }
}

M.values = vim.deepcopy(defaults)

function M.setup(opts)
    M.values = vim.tbl_extend("force", M.values, opts or {})
end

return M
