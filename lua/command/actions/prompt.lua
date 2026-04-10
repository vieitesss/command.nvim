local config = require('command.config')
---@type CommandExecutor
local executor = require('command.execution.executor')
local history = require('command.history')
local notify = require('command.util.notify')
---@type CommandPrompt
local prompt = require('command.ui.prompt')
local ghost_text = require('command.ui.ghost_text')
local session = require('command.session')

local M = {}

---@param window CommandPromptWindow
---@return string
local function get_current_line(window)
    local cursor = vim.api.nvim_win_get_cursor(window.win)
    local line = vim.api.nvim_buf_get_lines(window.buf, cursor[1] - 1, cursor[1], false)[1]
    return line or ''
end

---@param window CommandPromptWindow
---@return boolean
local function line_ends_with_continuation(window)
    return get_current_line(window):match('\\%s*$') ~= nil
end

---@param cmd string
---@return string[]
local function split_lines(cmd)
    return vim.split(cmd or '', '\n', { plain = true, trimempty = false })
end

---@param line string
---@return string
local function trim_right(line)
    return (line or ''):gsub('%s+$', '')
end

---@param lines string[]
---@return string
local function get_last_nonempty_line(lines)
    for idx = #lines, 1, -1 do
        local line = trim_right(lines[idx])
        if line ~= '' then
            return line
        end
    end

    return ''
end

---@param cmd string
---@return integer, integer, integer, integer
local function scan_shell_state(cmd)
    local single_quotes = 0
    local double_quotes = 0
    local command_substitutions = 0
    local parameter_expansions = 0
    local escaped = false

    for idx = 1, #cmd do
        local ch = cmd:sub(idx, idx)
        local next_two = cmd:sub(idx, idx + 1)

        if escaped then
            escaped = false
        elseif ch == '\\' and single_quotes == 0 then
            escaped = true
        elseif single_quotes == 0 and ch == '"' then
            double_quotes = 1 - double_quotes
        elseif double_quotes == 0 and ch == "'" then
            single_quotes = 1 - single_quotes
        elseif single_quotes == 0 and next_two == '$(' then
            command_substitutions = command_substitutions + 1
        elseif single_quotes == 0 and ch == ')' and command_substitutions > 0 then
            command_substitutions = command_substitutions - 1
        elseif single_quotes == 0 and next_two == '${' then
            parameter_expansions = parameter_expansions + 1
        elseif single_quotes == 0 and ch == '}' and parameter_expansions > 0 then
            parameter_expansions = parameter_expansions - 1
        end
    end

    return single_quotes, double_quotes, command_substitutions, parameter_expansions
end

---@param lines string[]
---@return integer
local function count_unclosed_blocks(lines)
    local depth = 0

    for _, raw_line in ipairs(lines) do
        local line = trim_right(raw_line)
        if line ~= '' then
            if line:match('^%s*[%(%{]%s*$') then
                depth = depth + 1
            elseif line:match('^%s*[%)%}]%s*$') and depth > 0 then
                depth = depth - 1
            end

            if line:match('%f[%w]then$') or line:match('%f[%w]do$') or line:match('%f[%w]case%s+.-%s+in$') then
                depth = depth + 1
            elseif line:match('%f[%w]fi$') or line:match('%f[%w]done$') or line:match('%f[%w]esac$') then
                if depth > 0 then
                    depth = depth - 1
                end
            end
        end
    end

    return depth
end

---@param line string
---@return boolean
local function line_has_trailing_operator(line)
    if line == '' then
        return false
    end

    return line:match('\\$') ~= nil
        or line:match('[|&][|&]$') ~= nil
        or line:match('%|$') ~= nil
        or line:match('%f[%w](do|then|else|elif)$') ~= nil
        or line:match('^%s*[%(%{]%s*$') ~= nil
        or line:match('<<[%-%w_]*$') ~= nil
end

---@param cmd string
---@return boolean
local function command_needs_continuation(cmd)
    local normalized = (cmd or ''):gsub('%s+$', '')
    if normalized == '' then
        return false
    end

    local lines = split_lines(normalized)
    local last_line = get_last_nonempty_line(lines)
    local single_quotes, double_quotes, command_substitutions, parameter_expansions = scan_shell_state(normalized)

    if line_has_trailing_operator(last_line) then
        return true
    end

    if single_quotes > 0 or double_quotes > 0 then
        return true
    end

    if command_substitutions > 0 or parameter_expansions > 0 then
        return true
    end

    if count_unclosed_blocks(lines) > 0 then
        return true
    end

    return false
end

M._command_needs_continuation = command_needs_continuation

function M.enter()
    local window = prompt.get()
    if not window then
        notify.error('Prompt window not found')
        return
    end

    local cmd = prompt.get_text()
    ghost_text.clear(window.buf)

    local ran = executor.run(cmd, {
        context = window.opts and window.opts.context or nil,
        before_execute = function()
            history.reset_index()
            prompt.close()
        end,
    })

    if not ran then
        ghost_text.update(window.buf)
    end
end

function M.enter_insert()
    local window = prompt.get()
    if not window then
        notify.error('Prompt window not found')
        return
    end

    if line_ends_with_continuation(window) or command_needs_continuation(prompt.get_text()) then
        M.newline()
        return
    end

    M.enter()
end

function M.newline()
    local window = prompt.get()
    if not window or not vim.api.nvim_buf_is_valid(window.buf) or not vim.api.nvim_win_is_valid(window.win) then
        return
    end

    ghost_text.clear(window.buf)

    local cursor = vim.api.nvim_win_get_cursor(window.win)
    local row = cursor[1] - 1
    local line = get_current_line(window)
    local col = cursor[2]

    if col >= math.max(#line - 1, 0) then
        col = #line
    end

    vim.api.nvim_buf_set_text(window.buf, row, col, row, col, { '', '' })
    prompt.refresh_layout()
    prompt.set_cursor({ cursor[1] + 1, 0 })

    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

function M.cancel()
    local window = prompt.get()
    if not window then
        return
    end

    ghost_text.clear(window.buf)
    history.reset_index()
    prompt.close()
end

function M.prev_history()
    local window = prompt.get()
    if not window then
        return
    end

    prompt.set_text(history.prev())

    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

function M.next_history()
    local window = prompt.get()
    if not window then
        return
    end

    prompt.set_text(history.next())

    if config.values.ui.prompt.ghost_text then
        ghost_text.update(window.buf)
    end
end

function M.search_history()
    local window = prompt.get()
    if not window then
        return
    end

    history.search(function(selected_cmd)
        if selected_cmd and vim.api.nvim_buf_is_valid(window.buf) then
            prompt.set_text(selected_cmd)

            if config.values.ui.prompt.ghost_text then
                ghost_text.update(window.buf)
            end
        end
    end)
end

function M.accept_ghost()
    local window = prompt.get()
    if not window then
        return
    end

    ghost_text.accept(window.buf)
end

function M.toggle_cwd()
    local current_mode = session.get_cwd_mode()
    local new_mode = current_mode == 'buffer' and 'root' or 'buffer'

    session.set_cwd_mode(new_mode)
    prompt.update_title()
    notify.info('CWD mode: ' .. new_mode)
end

return M
