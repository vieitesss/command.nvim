local notify = require('command.util.notify')
local session = require('command.session')

local M = {}
local ENTRY_DELIMITER = '\t'

---@param cmd string
---@return string
local function format_history_entry(cmd)
    return (cmd:gsub('\t', '  '):gsub('\n', ' \\n '))
end

---@param entries string[]
---@return string[], table<string, string>
local function build_picker_entries(entries)
    local picker_entries = {}
    local commands_by_id = {}
    local picker_index = 0

    for idx = #entries, 1, -1 do
        picker_index = picker_index + 1

        local id = tostring(picker_index)
        local cmd = entries[idx]
        picker_entries[picker_index] = id .. ENTRY_DELIMITER .. format_history_entry(cmd)
        commands_by_id[id] = cmd
    end

    return picker_entries, commands_by_id
end

---@param selected_entry string|nil
---@param commands_by_id table<string, string>
---@return string|nil
local function resolve_selected_command(selected_entry, commands_by_id)
    if not selected_entry then
        return nil
    end

    local id = selected_entry:match('^(%d+)' .. vim.pesc(ENTRY_DELIMITER))
    if id and commands_by_id[id] then
        return commands_by_id[id]
    end

    return selected_entry
end

---@param entries string[]
---@param callback function
function M.search(entries, callback)
    local ok, fzf = pcall(require, 'fzf-lua')
    if not ok then
        notify.error('fzf-lua not found - install nvim-fzf/fzf-lua for history search')
        return
    end

    local history_list, commands_by_id = build_picker_entries(entries)
    if #history_list == 0 then
        notify.info('No history available')
        return
    end

    local original_mode = vim.api.nvim_get_mode().mode

    local function restore_mode()
        vim.schedule(function()
            if original_mode == 'i' then
                vim.cmd.startinsert()
            end
        end)
    end

    ---@type CommandPromptWindow|nil
    local prompt_window = session.get_window('prompt')
    local fzf_opts = {
        prompt = 'History> ',
        winopts = {
            height = 0.35,
            width = 0.5,
            on_close = restore_mode,
        },
        fzf_opts = {
            ['--delimiter'] = ENTRY_DELIMITER,
            ['--with-nth'] = '2..',
        },
        actions = {
            default = function(selected)
                if selected and selected[1] then
                    callback(resolve_selected_command(selected[1], commands_by_id))
                end
            end,
        },
    }

    if prompt_window and vim.api.nvim_win_is_valid(prompt_window.win) then
        local pos = vim.api.nvim_win_get_position(prompt_window.win)
        local opts = prompt_window.opts or {}
        fzf_opts.winopts.row = pos[1] + (opts.height or 1) + 2
        fzf_opts.winopts.col = pos[2]
        fzf_opts.winopts.width = (opts.width or 40) + 2
        fzf_opts.winopts.relative = 'editor'
    end

    fzf.fzf_exec(history_list, fzf_opts)
end

M._build_entries = build_picker_entries
M._resolve_selected_command = resolve_selected_command

return M
