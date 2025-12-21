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

---@class CommandConfigExecutionOpts
---@field cwd string Working directory mode: 'buffer'|'root' (default: 'buffer')

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
---@field execution CommandConfigExecutionOpts
---@field validation CommandConfigValidationOpts
---@field keymaps CommandConfigKeymaps

local M = {}

local defaults = {
    history = {
        max = 200,
        picker = 'fzf-lua',
    },
    ui = {
        prompt = {
            max_width = 40,
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
}

M.values = vim.deepcopy(defaults)

function M.setup(opts)
    M.values = vim.tbl_deep_extend('force', M.values, opts or {})

    if M.values.execution.cwd ~= 'buffer' and M.values.execution.cwd ~= 'root' then
        vim.notify(
            "command.nvim: Invalid execution.cwd '" .. tostring(M.values.execution.cwd) .. "'. Defaulting to 'buffer'.",
            vim.log.levels.WARN
        )
        M.values.execution.cwd = 'buffer'
    end

    if M.values.history.picker ~= 'fzf-lua' then
        vim.notify(
            "command.nvim: Invalid history.picker '"
                .. tostring(M.values.history.picker)
                .. "'. Only 'fzf-lua' is supported. Defaulting to 'fzf-lua'.",
            vim.log.levels.WARN
        )
        M.values.history.picker = 'fzf-lua'
    end
end

return M
