local prompt_act = require 'command.actions.prompt'
local terminal_act = require 'command.actions.terminal'

local M = {}

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
    keymaps = {
        prompt = {
            ni = {
                { '<Up>', prompt_act.history_up },
                { '<Down>', prompt_act.history_down },
                { '<C-f>', prompt_act.search },
                { '<CR>', prompt_act.enter },
                { '<C-d>', prompt_act.cancel },
                { '<Right>', prompt_act.accept_ghost },
            },
            n = {
                { '<Esc>', prompt_act.cancel }
            }
        },
        terminal = {
            n = {
                { '<CR>', terminal_act.follow_error }
            }
        }
    }
}

M.values = vim.deepcopy(defaults)

function M.setup(opts)
    M.values = vim.tbl_extend("force", M.values, opts or {})
end

return M
