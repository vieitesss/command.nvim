local config = require 'command.config'
local state = require 'command.state'
local km = require 'command.ui.keymaps'
local errors = require 'command.errors'

local M = {}

local WINDOW_NAME = "prompt"

function M.apply()
    local window = state.get_window_by_name(WINDOW_NAME)
    if not window then
        errors.WINDOW_NOT_FOUND('apply', WINDOW_NAME)
        return
    end

    local ni = km.include_mode({ "n", "i" }, vim.deepcopy(config.values.keymaps.prompt.ni))
    local n = km.include_mode({ "n" }, vim.deepcopy(config.values.keymaps.prompt.n))

    km.apply(window.buf, ni)
    km.apply(window.buf, n)
end

return M
