-- TODO:
-- - Window options.
-- - Use or not personal shell.
-- - Structure in more files.


--- @class CommandExecutor
--- @field history string[] In-memory list of past commands

--- @type CommandExecutor
local M = {
    history = {}
}

-- Name of the module
local MODULE_NAME = ...

-- Last command to execute
local COMMAND = ""

-- Float buffer handle for the prompt
local BUF = nil

-- Original window handle before opening the terminal
local ORIG_WIN = nil

-- Compilation error patterns from external module
local errors = require("error_table").error_table

-- History file
vim.fn.mkdir(vim.fn.stdpath('data') .. '/command.nvim', 'p')
local hist_dir = vim.fn.stdpath('data') .. '/command.nvim'
local hist_file = hist_dir .. '/command_history.txt'

--- Load command history from disk into M.history
local function load_history()
    if vim.fn.filereadable(hist_file) == 1 then
        M.history = vim.fn.readfile(hist_file)
    end
end

--- Save M.history to disk, keeping only the most recent 200 entries
local function save_history()
    if #M.history > 200 then
        M.history = vim.list_slice(M.history, #M.history - 199, #M.history)
    end
    vim.fn.writefile(M.history, hist_file)
end

--- Handle command confirmation: store, close prompt, then execute
--- @param buf number Buffer handle of the prompt
--- @param win number Window handle of the prompt
M._on_command_enter = function(buf, win)
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    COMMAND = line:match("^%S+%s+(.*)$") or ""

    if COMMAND ~= "" and M.history[#M.history] ~= COMMAND then
        table.insert(M.history, COMMAND)
        save_history()
    end

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end

    M._exec_command()
end

--- Cancel the prompt without executing
--- @param buf number Buffer handle of the prompt
--- @param win number Window handle of the prompt
M._on_command_cancel = function(buf, win)
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

--- Open a floating prompt for user input, with history navigation
M._update_command = function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'prompt')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)

    local width  = math.max(40, math.floor(vim.o.columns * 0.5))
    local height = 1
    local row    = math.floor((vim.o.lines - height) / 2 - 1)
    local col    = math.floor((vim.o.columns - width) / 2)

    local win    = vim.api.nvim_open_win(buf, true, {
        title     = "Command to execute",
        title_pos = "right",
        relative  = "editor",
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = "minimal",
        border    = "rounded",
    })

    vim.fn.prompt_setprompt(buf, " ")
    vim.cmd("startinsert")

    local hist_idx = #M.history + 1
    local function set_cmd(str)
        local prompt = " " .. str
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt })
        vim.api.nvim_win_set_cursor(win, { 1, #prompt + 1 })
    end

    local opts = { buffer = buf, silent = true }

    -- History navigation
    vim.keymap.set({ 'i', 'n' }, '<Up>', function()
        if hist_idx > 1 then
            hist_idx = hist_idx - 1
            set_cmd(M.history[hist_idx] or "")
            vim.cmd("startinsert")
        end
    end, opts)

    vim.keymap.set({ 'i', 'n' }, '<Down>', function()
        if hist_idx < #M.history then
            hist_idx = hist_idx + 1
            set_cmd(M.history[hist_idx])
        else
            hist_idx = #M.history + 1
            set_cmd("")
        end
        vim.cmd("startinsert")
    end, opts)

    -- Confirm or cancel
    vim.keymap.set({ 'i', 'n' }, '<CR>', function()
        M._on_command_enter(buf, win)
    end, opts)

    vim.keymap.set({ 'i', 'n' }, '<C-d>', function()
        M._on_command_cancel(buf, win)
    end, opts)

    vim.keymap.set({ 'n' }, '<C-c>', function()
        M._on_command_cancel(buf, win)
    end, opts)

    vim.keymap.set('n', '<Esc>', function()
        M._on_command_cancel(buf, win)
    end, opts)
end

--- Print an error message prefixed for this plugin
--- @param msg string Error message
M._print_error = function(msg)
    vim.api.nvim_err_writeln("[command] " .. msg)
end

--- Parse an error line for file, line, and column numbers
--- @param line string The error output line
--- @return (string|nil, number|nil, number|nil) filename, line number and column number
M._parse_error_line = function(line)
    for _, entry in pairs(errors) do
        local match = vim.fn.matchlist(line, entry.regex)
        if #match > 0 and match[1] ~= "" then
            local file, lnum, col
            for i = 2, #match do
                local v = match[i]
                if not file and (v:match("[/\\]") or v:match("%.%w+$")) then
                    file = v
                elseif not lnum and v:match("^%d+$") then
                    lnum = tonumber(v)
                elseif lnum and not col and v:match("^%d+$") then
                    col = tonumber(v) - 1
                end
            end
            return file, lnum, col
        end
    end

    local f, r, c = line:match("^([%w%./\\-_]+):(%d+):?(%d*)")
    if f then
        return f, tonumber(r), (c ~= "" and tonumber(c) or 1)
    end

    return nil, nil, nil
end

--- Jump to file and position under cursor based on error pattern
M._goto_file_at_cursor = function()
    local line = vim.api.nvim_get_current_line()
    local fname, row, col = M._parse_error_line(line)

    if not fname then
        M._print_error("If this is an error," ..
            "I could not find a valid pattern for it.")
        return
    end

    if ORIG_WIN and vim.api.nvim_win_is_valid(ORIG_WIN) then
        vim.api.nvim_set_current_win(ORIG_WIN)
    else
        vim.cmd("vsplit")
    end

    vim.cmd("edit " .. vim.fn.fnameescape(fname))
    vim.api.nvim_win_set_cursor(0, { row or 1, col or 1 })
end

--- Execute the stored COMMAND in a terminal split and set up error navigation
M._exec_command = function()
    ORIG_WIN = vim.api.nvim_get_current_win()

    if BUF and vim.fn.bufexists(BUF) == 1 then
        vim.api.nvim_buf_delete(BUF, { force = true })
    end

    BUF          = vim.api.nvim_create_buf(true, false)
    local width  = tonumber(vim.api.nvim_command_output("echo &columns"))
    local height = math.floor(tonumber(vim.api.nvim_command_output("echo &lines")) * 0.25)

    local win    = vim.api.nvim_open_win(BUF, true, {
        width  = width,
        height = height,
        split  = "below",
        win    = 0,
    })

    vim.api.nvim_buf_set_keymap(
        BUF, "n", "<CR>",
        string.format('<cmd>lua require("%s")._goto_file_at_cursor()<CR>', MODULE_NAME),
        { noremap = true, silent = true }
    )

    -- local cmd = { "/usr/bin/env", "bash", "-c", COMMAND }
    local shell = vim.env.SHELL or "/bin/sh"
    local cmd = { shell, "-ic", COMMAND }
    vim.fn.termopen(cmd)
end

--- Prompt for a new command and open the floating window
M.new_command = function()
    M._update_command()
end

--- Re-execute the last entered command
M.exec_command_again = function()
    if COMMAND == "" then
        M._print_error("Use first `:CommandExecute`")
        return
    end
    M._exec_command()
end

--- Register commands and initialize history
M.setup = function()
    load_history()
    vim.api.nvim_create_user_command("CommandExecute", M.new_command, {})
    vim.api.nvim_create_user_command("CommandRexecute", M.exec_command_again, {})
end

M.setup()
M.new_command()

return M
