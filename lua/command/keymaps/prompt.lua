local actions = require 'command.actions'
local utils = require 'command.utils'

--- @param history string[]|nil The list of commands executed
--- @return string The command to execute
function load_prompt_keys(buf, win, history)
    local hist_len = #history
    local hist_idx = hist_len + 1
    local opts = { buffer = buf, noremap = true, silent = true }

    vim.keymap.set({ 'i', 'n' }, '<Up>',
        function()
            if hist_idx > 1 then
                hist_idx = hist_idx - 1
                utils.set_cmd_prompt(buf, win, history[hist_idx] or "")
                vim.cmd("startinsert")
            end
        end, opts)

    vim.keymap.set({ 'i', 'n' }, '<Down>',
        function()
            if hist_idx < hist_len then
                hist_idx = hist_idx + 1
                utils.set_cmd_prompt(buf, win, history[hist_idx])
            else
                hist_idx = hist_len + 1
                utils.set_cmd_prompt(buf, win, "")
            end
            vim.cmd("startinsert")
        end, opts)

    vim.keymap.set({ 'i', 'n' }, '<C-f>', function()
        require('fzf-lua').fzf_exec(history, {
            prompt   = 'History> ',
            winopts  = { height = 0.30, width = 0.50, row = 0.75, col = 0.50 },
            complete = function(selected, opts, line, col)
                if selected and #selected > 0 then
                    local choice = selected[1]
                    local prefix = ' '
                    local newline = prefix .. choice
                    -- update hist_idx so up/down continue from here
                    for i, v in ipairs(history) do
                        if v == choice then
                            hist_idx = i
                            break
                        end
                    end
                    -- return new line and 0-based cursor column
                    return newline, #newline - 1
                end
                return line, col
            end,
        })
    end, opts)

    -- Confirm or cancel
    vim.keymap.set({ 'i', 'n' }, '<CR>',
        function()
            local command = actions.on_command_enter(buf, win, history)
            if command == "" then
                utils.print_error("No command was provided")
            else
                utils.exec_command(command)
                require('command').executed = true
            end
        end, opts)

    vim.keymap.set({ 'i', 'n' }, '<C-d>',
        function()
            actions.on_command_cancel(buf, win)
        end, opts)

    vim.keymap.set({ 'n' }, '<C-c>',
        function()
            actions.on_command_cancel(buf, win)
        end, opts)

    vim.keymap.set('n', '<Esc>',
        function()
            actions.on_command_cancel(buf, win)
        end, opts)
end

return load_prompt_keys
