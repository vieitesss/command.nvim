# command.nvim

Neovim plugin that allows you to:
- Type a command you want to run and execute it directly in a terminal inside Neovim.
- Follow compilation errors for some languages (credits to [compile-mode.nvim](https://github.com/ej-shafran/compile-mode.nvim/tree/main)).

>[!NOTE]
> This plugin is not configurable yet because it works fine for me as it is. If I get feedback on it, I'll add the option to customize some things.

# Installation

## vim.pack

```lua
vim.pack.add({
    { src = "https://github.com/vieitesss/command.nvim" }
})

require('command').setup()
```

## lazy.nvim

```lua

return {
    "vieitesss/command.nvim",
    lazy = false,
    opts = true,
}
```

# Configuration

```lua
local prompt_act = require 'command.actions.prompt'
local terminal_act = require 'command.actions.terminal'
defaults = {
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
```

# How to use

The plugin provides you two commands:
- `CommandExecute`: Opens a prompt and asks you for the command that you want to execute. Then, a terminal appears and runs the command.
- `CommandExecuteLast`: Runs the last executed command. `CommandExecute` must have been called previously during the session.
