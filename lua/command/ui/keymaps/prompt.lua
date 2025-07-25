local config = require 'command.config'
local state = require 'command.state'
local km = require 'command.ui.keymaps'

local M = {}

function M.apply()
    local window = state.get_window_by_name("prompt")
    if not window then
        return
    end

    local ni = km.include_mode({ "n", "i" }, config.values.keymaps.prompt.ni)
    local n = km.include_mode({ "n" }, config.values.keymaps.prompt.n)

    km.apply(window.buf, ni)
    km.apply(window.buf, n)
end

return M
