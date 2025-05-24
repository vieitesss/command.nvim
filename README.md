# command.nvim

Neovim plugin that allows you to:
- Type a command you want to run and execute it directly in a terminal inside Neovim.
- Follow compilation errors for some languages (credits to [compile-mode.nvim](https://github.com/ej-shafran/compile-mode.nvim/tree/main)).

>[!NOTE]
> This plugin is not configurable yet because it works fine for me as it is. If I get feedback on it, I'll add the option to customize some things.

# Installation

## lazy.nvim

```lua

return {
    "vieitesss/command.nvim",
    lazy = true,
    opts = true,
}
```

# How to use

The plugin provides you two commands:

- `CommandExecute`: Opens a prompt and asks you for the command that you want to execute. Then, a terminal appears and runs the command.

> [!NOTE]
> The terminal will always appear at the bottom, taking up a quarter of Neovim window. This is not configurable yet.

- `CommandRexecute`: Runs the last executed command. `CommandExecute` must have been called previously during the session.
