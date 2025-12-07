---@class CommandConfigHistoryOpts
---@field max integer Maximum number of commands to store (default: 200)
---@field picker string History picker to use: 'fzf-lua' (default: 'fzf-lua')

---@class CommandConfigPromptOpts
---@field max_width integer Maximum width of prompt window (default: 40)
---@field ghost_text boolean Enable ghost text suggestions (default: true)

---@class CommandConfigTerminalOpts
---@field height number Terminal height as fraction of screen (default: 0.25)
---@field split string Split direction: 'below'|'above'|'left'|'right' (default: 'below')

---@class CommandConfigUIOptions
---@field prompt CommandConfigPromptOpts
---@field terminal CommandConfigTerminalOpts

---@class CommandConfigValidationOpts
---@field warn boolean Show validation warnings for dangerous patterns (default: true)

---@class CommandConfigKeymap
---@field [integer] table Keymap definition {key, action}

---@class CommandConfigKeymaps
---@field prompt table Prompt mode keymaps
---@field terminal table Terminal mode keymaps

---@class CommandConfig
---@field history CommandConfigHistoryOpts
---@field ui CommandConfigUIOptions
---@field validation CommandConfigValidationOpts
---@field keymaps CommandConfigKeymaps

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
            max_width = 40,
            ghost_text = true
        },
        terminal = {
            height = 0.25,
            split = "below"
        }
    },
    validation = {
        warn = true
    },
    keymaps = {
        prompt = {
            ni = {
                { '<Up>', prompt_act.history_up },
                { '<Down>', prompt_act.history_down },
                { '<C-f>', prompt_act.search },
                { '<CR>', prompt_act.enter },
                { '<C-d>', prompt_act.cancel },
                { '<C-e>', prompt_act.accept_ghost },
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
    M.values = vim.tbl_deep_extend("force", M.values, opts or {})
end

return M
