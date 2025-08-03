local state = require 'command.state'
local config = require 'command.config'
local km = require 'command.ui.keymaps'
local errors = require 'command.errors'

local M = {}

local WINDOW_NAME = "terminal"

function M.apply()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        errors.WINDOW_NOT_FOUND('apply', WINDOW_NAME)
        return
    end

    local n = km.include_mode({ "n" }, vim.deepcopy(config.values.keymaps.terminal.n))

    km.apply(window.buf, n)
end

return M
