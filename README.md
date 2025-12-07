# command.nvim

Neovim plugin that allows you to:
- Type a command you want to run and execute it directly in a terminal inside Neovim.
    - You can use your shell configuration (e.g., aliases, functions).
- Keep a history of executed commands and easily access them.
- Re-execute the last executed command with a single command.
- Search through the history of executed commands using:
    - fzf-lua
- Get completion suggestions as virtual text while typing.
- Validate commands for potentially dangerous patterns (command substitution, piping to `rm`/`dd`, redirects to system files, etc.) with optional warnings and confirmation prompts.
- Follow compilation errors for some languages (credits to [compile-mode.nvim](https://github.com/ej-shafran/compile-mode.nvim/tree/main)).

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
            max_width = 40,
            ghost_text = true
        },
        terminal = {
            height = 0.25,
            split = "below"
        }
    },
    validation = {
        warn = true  -- Show warnings for potentially dangerous patterns
    },
    keymaps = {
        prompt = {
            -- WARNING: There is no `i` in prompt mode
            ni = { -- normal and insert modes
                { '<Up>', prompt_act.history_up },
                { '<Down>', prompt_act.history_down },
                { '<C-f>', prompt_act.search },
                { '<CR>', prompt_act.enter },
                { '<C-d>', prompt_act.cancel },
                { '<C-e>', prompt_act.accept_ghost },
            },
            n = { -- normal mode
                { '<Esc>', prompt_act.cancel }
            }
        },
        terminal = {
            -- WARNING: There is no `ni` in terminal mode
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

## Validation Warnings

The plugin validates commands for potentially dangerous patterns and shows a warning before execution. This helps prevent accidental execution of destructive commands.

### Detected Patterns

The plugin warns about:
- Command substitution: `$(...)` or `` `...` ``
- Piping to dangerous commands: `| rm`, `| dd`, `| mkfs`, `| shred`
- Redirects to system files: `> /etc/`, `> /sys/`, `> /dev/`
- Background execution: `&` at the end
- Command chains: `||`, `&&`

### Disabling Warnings

If you want to disable validation warnings, set `validation.warn = false`:

```lua
require('command').setup({
    validation = {
        warn = false
    }
})
```

When warnings are enabled (default), the plugin will display the dangerous pattern(s) detected and the full command, then prompt you to confirm execution with `(y/n):`.
