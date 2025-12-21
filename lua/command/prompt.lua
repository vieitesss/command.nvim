---@class CommandPrompt
---Prompt window for command input with actions and keymaps combined

local M = {}
local config = require('command.config')
local state = require('command.state')
local history = require('command.history')
local ghost_text = require('command.ghost_text')
local utils = require('command.utils')
local validation = require('command.validation')
local executor = require('command.executor')
local terminal = require('command.terminal')

local WINDOW_NAME = 'prompt'
local PROMPT_HEIGHT = 1

-- ============================================================================
-- Window Creation
-- ============================================================================

---Creates the prompt window
---@param opts table|nil Optional configuration overrides
---@return table|nil Window|nil info {buf, win} or nil on error
function M.create(opts)
    opts = opts or {}

    -- 1. Create buffer
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })

    -- 2. Merge with config defaults
    local max_width = opts.max_width or config.values.ui.prompt.max_width or 40
    local width = math.max(max_width, math.floor(vim.o.columns * 0.5))
    local height = PROMPT_HEIGHT

    -- 3. Calculate position (centered)
    local row = math.floor((vim.o.lines - height) / 2 - 1)
    local col = math.floor((vim.o.columns - width) / 2)

    -- 4. Get title (cwd)
    local cwd = state.get_resolved_cwd()
    cwd = vim.fn.fnamemodify(cwd, ':~')
    local title = ' ' .. cwd .. ' '

    -- 5. Create floating window
    local win = vim.api.nvim_open_win(buf, true, {
        title = title,
        title_pos = 'right',
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })

    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_buf_delete(buf, { force = true })
        return nil
    end

    -- Set window-local options
    vim.api.nvim_set_option_value('wrap', false, { win = win })
    
    -- Explicitly disable statusline to prevent it from being shown after fzf
    vim.api.nvim_win_set_option(win, 'statusline', '')
    
    -- Ensure minimal UI is applied
    local win_config = vim.api.nvim_win_get_config(win)
    win_config.style = 'minimal'
    vim.api.nvim_win_set_config(win, win_config)

    -- 6. Register in state
    state.add_window({
        name = WINDOW_NAME,
        buf = buf,
        win = win,
        opts = {
            width = width,
            height = height,
            max_width = max_width,
        },
    })

    -- 7. Attach keymaps
    M.attach_keymaps(buf)

    -- 8. Attach ghost text if enabled
    if config.values.ui.prompt.ghost_text then
        ghost_text.attach(buf)
    end

    return { buf = buf, win = win }
end

---Shows the prompt window
function M.show()
    local window = state.get_window_by_name(WINDOW_NAME)
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_set_config(window.win, { hide = false })
    end
end

---Hides the prompt window
function M.hide()
    local window = state.get_window_by_name(WINDOW_NAME)
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_set_config(window.win, { hide = true })
    end
end

---Closes the prompt window completely
function M.close()
    local window = state.get_window_by_name(WINDOW_NAME)
    if window then
        if vim.api.nvim_win_is_valid(window.win) then
            vim.api.nvim_win_close(window.win, true)
        end
        state.remove_window(WINDOW_NAME)
    end
end

-- ============================================================================
-- Actions
-- ============================================================================

---User pressed <CR> - execute the command
---Reads input, validates, adds to history, closes prompt, executes command
function M.enter()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        utils.print_error('Prompt window not found')
        return
    end

    -- 1. Get command text
    local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
    local cmd = table.concat(lines, '\n')

    -- 2. Trim whitespace
    cmd = cmd:gsub('^%s+', ''):gsub('%s+$', '')

    -- 3. Clear ghost text
    ghost_text.clear(window.buf)

    -- 4. Validate command
    if cmd == '' then
        utils.print_error('No command was provided')
        return
    end

    if not validation.validate_command(cmd) then
        return
    end

    -- 5. Add to history (skip if identical to last)
    local history_list = state.history_list()
    if cmd ~= '' and history_list[#history_list] ~= cmd then
        history.add(cmd)
    end

    -- 6. Reset history index
    state.reset_history_index()

    -- 7. Close prompt
    M.close()

    -- 8. Execute command
    state._has_run = true
    terminal.create(config.values.ui.terminal)
    executor.run_command(cmd)
    terminal.enter_normal_mode()
end

---User pressed <Esc> - cancel without executing
function M.cancel()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    ghost_text.clear(window.buf)
    state.reset_history_index()
    M.close()
end

---Navigate to previous command in history
---Called when user presses <Up> or <C-p>
function M.prev_history()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    local cmd = history.prev()
    utils.set_cmd_prompt(window.buf, window.win, cmd)

    -- Update ghost text
    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

---Navigate to next command in history
---Called when user presses <Down> or <C-n>
function M.next_history()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    local cmd = history.next()
    utils.set_cmd_prompt(window.buf, window.win, cmd)

    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

---Opens history search picker (fzf-lua)
---Called when user presses <C-f>
function M.search_history()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    -- Save current content and options
    local content = ""
    local win_opts = {}
    
    if vim.api.nvim_buf_is_valid(window.buf) then
        local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
        content = lines[1] or ""
        win_opts = window.opts or {}
    end
    
    -- Close the window to avoid statusline leaking
    if vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_close(window.win, true)
    end
    
    -- Remove from state
    state.remove_window_by_name(WINDOW_NAME)

    history.search(function(selected_cmd)
        -- Recreate the prompt window
        local new_win = M.create(win_opts)
        
        if new_win then
            -- Set the prompt content
            if selected_cmd then
                utils.set_cmd_prompt(new_win.buf, new_win.win, selected_cmd)
            else
                utils.set_cmd_prompt(new_win.buf, new_win.win, content)
            end
            
            -- Attach ghost text if enabled
            if config.values.ui.prompt.ghost_text then
                ghost_text.update(new_win.buf)
            end
        end
    end)
end

---Accepts the ghost text suggestion
---Called when user presses <C-e>
function M.accept_ghost()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        return
    end

    ghost_text.accept(window.buf)
end

---Toggle cwd mode between 'buffer' and 'root'
---Called when user presses <C-o>
function M.toggle_cwd()
    local current_mode = state.get_cwd_mode()
    local new_mode = current_mode == 'buffer' and 'root' or 'buffer'

    state.set_cwd_mode(new_mode)

    -- Update the prompt window title
    local window = state.get_window_by_name(WINDOW_NAME)
    if window and vim.api.nvim_win_is_valid(window.win) then
        local cwd = state.get_resolved_cwd()
        cwd = vim.fn.fnamemodify(cwd, ':~')
        local title = ' ' .. cwd .. ' '

        vim.api.nvim_win_set_config(window.win, { title = title })
    end

    vim.notify('CWD mode: ' .. new_mode, vim.log.levels.INFO)
end

-- ============================================================================
-- Keymaps
-- ============================================================================

---Attaches keymaps to the prompt buffer
---@param buf integer Buffer ID
function M.attach_keymaps(buf)
    local opts = { noremap = true, silent = true, buffer = buf }

    -- Get keymaps from config or use defaults
    local keymaps = (config.values.keymaps and config.values.keymaps.prompt) or {}

    -- Apply insert/normal mode keymaps
    if keymaps.ni then
        for _, keymap in ipairs(keymaps.ni) do
            local key, action = keymap[1], keymap[2]
            vim.keymap.set('i', key, action, opts)
        end
    end

    -- Apply normal mode keymaps
    if keymaps.n then
        for _, keymap in ipairs(keymaps.n) do
            local key, action = keymap[1], keymap[2]
            vim.keymap.set('n', key, action, opts)
        end
    end

    -- Default keymaps (if not overridden)
    if not keymaps.ni or #keymaps.ni == 0 then
        vim.keymap.set('i', '<CR>', M.enter, opts)
        vim.keymap.set('i', '<Up>', M.prev_history, opts)
        vim.keymap.set('i', '<Down>', M.next_history, opts)
        vim.keymap.set('i', '<C-f>', M.search_history, opts)
        vim.keymap.set('i', '<C-e>', M.accept_ghost, opts)
        vim.keymap.set('i', '<C-o>', M.toggle_cwd, opts)
    end

    if not keymaps.n or #keymaps.n == 0 then
        vim.keymap.set('n', '<CR>', M.enter, opts)
        vim.keymap.set('n', '<Up>', M.prev_history, opts)
        vim.keymap.set('n', '<Down>', M.next_history, opts)
        vim.keymap.set('n', '<C-f>', M.search_history, opts)
        vim.keymap.set('n', '<C-e>', M.accept_ghost, opts)
        vim.keymap.set('n', '<C-o>', M.toggle_cwd, opts)
        vim.keymap.set('n', '<Esc>', M.cancel, opts)
    end
end

return M
