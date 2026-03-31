local M = {}

local state = {
    entries = {},
    index = 1,
}

---@param entries string[]|nil
function M.setup(entries)
    state.entries = vim.deepcopy(entries or {})
    state.index = #state.entries + 1
end

---@return string[]
function M.get_all()
    return vim.deepcopy(state.entries)
end

---@return integer
function M.count()
    return #state.entries
end

---@param cmd string
---@param max_entries integer
---@return boolean
function M.add(cmd, max_entries)
    if not cmd or cmd:match('^%s*$') then
        return false
    end

    if state.entries[#state.entries] == cmd then
        return false
    end

    table.insert(state.entries, cmd)

    if #state.entries > max_entries then
        table.remove(state.entries, 1)
    end

    state.index = #state.entries + 1
    return true
end

---@return string
function M.prev()
    local len = #state.entries

    if state.index > len then
        state.index = len
    else
        state.index = state.index - 1
    end

    if state.index < 1 then
        state.index = 1
        return ''
    end

    return state.entries[state.index] or ''
end

---@return string
function M.next()
    local len = #state.entries

    state.index = state.index + 1

    if state.index > len then
        state.index = len + 1
        return ''
    end

    return state.entries[state.index] or ''
end

---@return string
function M.last()
    return state.entries[#state.entries] or ''
end

---@param prefix string
---@return string
function M.suggest(prefix)
    if not prefix or prefix == '' then
        return ''
    end

    for i = #state.entries, 1, -1 do
        local cmd = state.entries[i]
        if cmd:sub(1, #prefix) == prefix then
            return cmd
        end
    end

    return ''
end

function M.reset_index()
    state.index = #state.entries + 1
end

return M
