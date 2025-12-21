---@class CommandTerminal
---Terminal window for command execution with actions and keymaps combined

local M = {}
local config = require('command.config')
local state = require('command.state')
local error_parser = require('command.error_parser')

local WINDOW_NAME = 'terminal'

-- ============================================================================
-- Window Creation
-- ============================================================================

---Creates the terminal window
---@param opts table|nil Optional configuration overrides
---@return table Window info {buf, win} or nil on error
function M.create(opts)
    opts = opts or {}

    -- 1. Get height and position from config
    local height = opts.height or config.values.ui.terminal.height or 0.25
    local position = opts.position or config.values.ui.terminal.split or 'below'

    -- Convert fraction to lines if needed
    if height < 1 then
        height = math.floor(vim.o.lines * height)
    end
    height = math.max(height, 3) -- Minimum 3 lines

    -- 2. Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })

    -- 3. Create split based on position
    if position == 'below' then
        vim.cmd('botright ' .. height .. ' split')
    elseif position == 'above' then
        vim.cmd('topleft ' .. height .. ' split')
    elseif position == 'right' then
        vim.cmd('botright ' .. height .. ' vsplit')
    elseif position == 'left' then
        vim.cmd('topleft ' .. height .. ' vsplit')
    else
        vim.cmd('botright ' .. height .. ' split')
    end

    -- 4. Get window and attach buffer
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)

    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_buf_delete(buf, { force = true })
        return nil
    end

    -- 5. Register in state
    state.add_window({
        name = WINDOW_NAME,
        buf = buf,
        win = win,
        opts = {
            height = height,
            position = position,
        },
    })

    -- 6. Attach keymaps
    M.attach_keymaps(buf)

    return { buf = buf, win = win }
end

---Shows the terminal window
function M.show()
    local window = state.get_window_by_name(WINDOW_NAME)
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_set_config(window.win, { hide = false })
    end
end

---Enter normal mode in terminal
function M.enter_normal_mode()
    local window = state.get_window_by_name(WINDOW_NAME)
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_call(window.win, function()
            vim.cmd('stopinsert')
        end)
    end
end

---Hides the terminal window
function M.hide()
    local window = state.get_window_by_name(WINDOW_NAME)
    if window and vim.api.nvim_win_is_valid(window.win) then
        vim.api.nvim_win_set_config(window.win, { hide = true })
    end
end

---Closes the terminal window
function M.close()
    local window = state.get_window_by_name(WINDOW_NAME)
    if window then
        -- Stop running job if any
        if window.job_id then
            pcall(function()
                vim.fn.jobstop(window.job_id)
            end)
            state.remove_job(window.job_id)
        end

        -- Close window
        if vim.api.nvim_win_is_valid(window.win) then
            vim.api.nvim_win_close(window.win, true)
        end

        state.remove_window(WINDOW_NAME)
    end
end

-- ============================================================================
-- Command Execution
-- ============================================================================

---Sends a command to the terminal
---Caller must have created terminal window via M.create()
---@param cmd string Command to execute
function M.send_command(cmd)
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window or not vim.api.nvim_buf_is_valid(window.buf) then
        return
    end

    -- Get shell and use interactive mode
    local shell = vim.env.SHELL or '/bin/sh'

    -- Start terminal and run command
    local job_id = vim.fn.termopen({ shell, '-ic', cmd }, {
        on_exit = function(jid, exit_code)
            M.on_job_exit(jid, exit_code)
        end,
    })

    if job_id > 0 then
        window.job_id = job_id
        state.add_job(job_id)
    end
end

---Handles job completion
---@param job_id integer Job ID
---@param exit_code integer Exit code
function M.on_job_exit(job_id, exit_code)
    state.remove_job(job_id)

    local window = state.get_window_by_name(WINDOW_NAME)
    if window then
        window.exit_code = exit_code
    end
end

-- ============================================================================
-- Error Following
-- ============================================================================

---User pressed <CR> in terminal - follow error at cursor
function M.follow_error()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window or not vim.api.nvim_buf_is_valid(window.buf) then
        return
    end

    -- 1. Get current line
    local cursor_pos = vim.api.nvim_win_get_cursor(window.win)
    local line_num = cursor_pos[1]

    local lines = vim.api.nvim_buf_get_lines(window.buf, line_num - 1, line_num, false)
    if #lines == 0 then
        return
    end

    local line = lines[1]

    -- 2. Parse error using error_parser
    local error_info = error_parser.parse_line(line)

    if not error_info or not error_info.file then
        return
    end

    -- 3. Close terminal
    M.close()

    -- 4. Open file
    vim.cmd('edit ' .. vim.fn.fnameescape(error_info.file))

    -- 5. Jump to line/column if available
    if error_info.line then
        local col = error_info.col or 0
        vim.api.nvim_win_set_cursor(0, { error_info.line, col })
    end

    -- 6. Center view
    vim.cmd('normal! zz')
end

-- ============================================================================
-- Keymaps
-- ============================================================================

---Attaches keymaps to the terminal buffer
---@param buf integer Buffer ID
function M.attach_keymaps(buf)
    local opts = { noremap = true, silent = true, buffer = buf }

    -- Get keymaps from config or use defaults
    local keymaps = (config.values.keymaps and config.values.keymaps.terminal) or {}

    -- In terminal mode, we can't intercept normal insert mode keys
    -- Use normal mode keymaps instead
    if keymaps.n then
        for _, keymap in ipairs(keymaps.n) do
            local key, action = keymap[1], keymap[2]
            vim.keymap.set('n', key, action, opts)
        end
    end

    -- Default keymaps if not configured
    if not keymaps.n or #keymaps.n == 0 then
        vim.keymap.set('n', '<CR>', M.follow_error, opts)
        vim.keymap.set('n', 'q', M.close, opts)
    end

    -- Also add terminal mode keymap for quick close
    vim.keymap.set('t', '<C-q>', M.close, opts)
end

return M
