local notify = require('command.util.notify')
local session = require('command.session')

local M = {}

---@param entries string[]
---@param callback function
function M.search(entries, callback)
    local ok, fzf = pcall(require, 'fzf-lua')
    if not ok then
        notify.error('fzf-lua not found - install nvim-fzf/fzf-lua for history search')
        return
    end

    local history_list = vim.fn.reverse(vim.deepcopy(entries))
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

    local prompt_window = session.get_window('prompt')
    local fzf_opts = {
        prompt = 'History> ',
        winopts = {
            height = 0.35,
            width = 0.5,
            on_close = restore_mode,
        },
        actions = {
            default = function(selected)
                if selected and selected[1] then
                    callback(selected[1])
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

return M
