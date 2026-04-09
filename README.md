# command.nvim

Run shell commands inside Neovim, keep a searchable history, and navigate terminal output without leaving the editor.

`command.nvim` runs commands through `$SHELL -ic` and falls back to `/bin/sh`, so your aliases, functions, and shell startup config are available.

## What It Does

- Open a centered prompt and run any shell command in a Neovim terminal split
- Re-run the last command in the current Neovim session
- Execute the current visual selection as a shell command
- Persist command history across sessions
- Search command history with `fzf-lua`
- Show ghost text suggestions from previous commands while typing
- Expand editor-aware variables like `${filePath}`, `${line}`, `${cwd}`, and `${selection}`
- Choose whether commands run from the current file directory or Neovim's current working directory
- Ask for confirmation before risky commands
- Hide and reopen the last terminal without losing its output
- Jump from terminal output to files and errors
- Send terminal output to quickfix

## Installation

### vim.pack

```lua
vim.pack.add({
  { src = 'https://github.com/vieitesss/command.nvim' },
})

require('command').setup()
```

### lazy.nvim

```lua
return {
  'vieitesss/command.nvim',
  lazy = false,
  version = '*',
  opts = {},
}
```

Install `ibhagwan/fzf-lua` if you want history search from the prompt with `<C-f>`.

Use `:checkhealth command.nvim` if you want to verify your shell, history storage, and `fzf-lua` setup.

## Commands

`command.nvim` does not define global keymaps by default. You can use the commands directly:

- `:CommandExecute` opens the prompt and runs a new command
- `:CommandExecuteLast` re-runs the last command after one has already been executed in the current Neovim session
- `:CommandExecuteSelection` runs the current visual selection as a shell command
- `:CommandReopenTerminal` reopens the last hidden terminal window if its buffer is still available

It also exposes `<Plug>` mappings if you want your own keys:

```lua
vim.keymap.set({ 'n', 'i' }, '<M-;>', '<Plug>(CommandExecute)')
vim.keymap.set({ 'n', 'i' }, '<M-l>', '<Plug>(CommandExecuteLast)')
vim.keymap.set('x', '<M-;>', '<Plug>(CommandExecuteSelection)')
vim.keymap.set('n', '<M-r>', '<Plug>(CommandReopenTerminal)')
```

## Prompt

The prompt stays a regular Neovim buffer. You can paste multiline commands, use normal-mode edits like `o` and `O`, and the floating window grows with the command up to `ui.prompt.max_height`.

Default prompt keys:

- `<CR>` runs the command. In insert mode, if the current line ends with `\`, it inserts a newline instead.
- `<Up>` and `<Down>` browse history
- `<C-f>` searches history with `fzf-lua`
- `<C-e>` accepts the ghost text suggestion
- `<C-o>` toggles the execution directory
- `<Esc>` cancels in normal mode

When the command spans multiple lines, the prompt expands to show at least 5 lines when space allows.

The prompt title shows the directory that will be used for execution. `<C-o>` switches between:

- `buffer`: the current file's directory
- `root`: Neovim's current working directory from `:pwd` / `getcwd()`

## Terminal

Default terminal keys:

- `q` hides the terminal
- `<CR>` opens the file or error under the cursor
- `<C-q>` sends the full output to quickfix

`q` hides the window instead of deleting it, so `:CommandReopenTerminal` can bring it back. The saved terminal is replaced the next time you run a new command.

When you send output to quickfix, the window keeps the original command output text. File paths and error lines are still parsed into jumpable quickfix entries, while non-matching lines stay as plain text rows.

## Context Variables

You can use these variables in commands typed into the prompt. They are expanded before execution.

| Variable | Expands to |
| --- | --- |
| `${file}` | Current filename with extension |
| `${filePath}` | Absolute path of the current buffer |
| `${fileDir}` | Directory of the current buffer |
| `${fileName}` | Current filename without extension |
| `${line}` | Current cursor line |
| `${col}` | Current cursor column |
| `${cwd}` | Resolved execution directory |
| `${selection}` | Raw visual selection |
| `${selection:sh}` | Shell-escaped visual selection |

Use `${selection}` when you want the shell to interpret the selected text as-is. Use `${selection:sh}` when the selection should be treated as one safe shell argument.

Examples:

- `python ${filePath}`
- `git blame -L ${line},+1 ${filePath}`
- `rm ${selection}`
- `git commit -m ${selection:sh}`

## Safety

By default, `command.nvim` asks for confirmation when a command contains risky patterns such as:

- command substitution: `$(...)` or `` `...` ``
- pipes to `rm`, `dd`, `mkfs`, or `shred`
- redirects to `/etc`, `/sys`, or `/dev`
- background execution with trailing `&`
- command chains with `&&` or `||`

Turn the warning off with:

```lua
require('command').setup({
  validation = {
    warn = false,
  },
})
```

## Configuration

Full setup example:

```lua
local prompt = require('command.actions.prompt')
local terminal = require('command.actions.terminal')

require('command').setup({
  history = {
    max = 200,
    picker = 'fzf-lua',
    -- file_path = vim.fn.stdpath('data') .. '/command_history.json',
  },
  ui = {
    prompt = {
      max_width = 40,
      max_height = 10,
      ghost_text = true,
    },
    terminal = {
      height = 0.25,
      split = 'below',
    },
  },
  execution = {
    cwd = 'buffer',
  },
  validation = {
    warn = true,
  },
  keymaps = {
    prompt = {
      ni = {
        { '<Up>', prompt.prev_history },
        { '<Down>', prompt.next_history },
        { '<C-f>', prompt.search_history },
        { '<CR>', prompt.enter_insert },
        { '<C-e>', prompt.accept_ghost },
        { '<C-o>', prompt.toggle_cwd },
      },
      n = {
        { '<CR>', prompt.enter },
        { '<Esc>', prompt.cancel },
      },
    },
    terminal = {
      n = {
        { '<CR>', terminal.follow_error },
        { '<C-q>', terminal.send_to_quickfix },
        { 'q', terminal.hide },
      },
    },
  },
})
```

Option reference:

| Key | Default | Description |
| --- | --- | --- |
| `history.max` | `200` | Maximum number of commands stored in history |
| `history.picker` | `'fzf-lua'` | History picker used by `<C-f>`. Only `fzf-lua` is supported |
| `history.file_path` | `stdpath('data') .. '/command_history.json'` | Optional custom path for persisted history |
| `ui.prompt.max_width` | `40` | Base width used for the centered prompt window |
| `ui.prompt.max_height` | `10` | Maximum height used for the centered prompt window. Multiline commands expand up to this limit |
| `ui.prompt.ghost_text` | `true` | Show inline history suggestions while typing |
| `ui.terminal.height` | `0.25` | Size of the terminal split |
| `ui.terminal.split` | `'below'` | Where the terminal opens: `below`, `above`, `left`, or `right` |
| `execution.cwd` | `'buffer'` | `buffer` uses the current file directory, `root` uses Neovim's current working directory |
| `validation.warn` | `true` | Ask for confirmation before executing risky commands |

Keymap notes:

- `keymaps.prompt.ni` defines prompt mappings for both insert and normal mode
- `keymaps.prompt.n` defines prompt mappings for normal mode
- `keymaps.terminal.n` defines terminal mappings for normal mode
- If you want to fully replace the prompt defaults in normal mode, set both `keymaps.prompt.ni` and `keymaps.prompt.n`
- `<C-q>` in terminal mode always sends the output to quickfix
