local utils = require 'command.utils'

local M = {}

REFERENCE_WINDOW = "prompt"
BORDERS = 2
SEARCH_HEADER = 3

local ERROR_PICKER_NOT_AVAILABLE = function(picker)
    return "The picker " .. picker .. "is not available"
end

---@param picker string fzf-lua|telescope -- The picker to use
function M.pick(picker)
    if picker == 'fzf-lua' then
        require('command.ui.picker.fzf-lua').pick()
    elseif picker == 'telescope' then
        utils.print_error(ERROR_PICKER_NOT_AVAILABLE(picker))
    else
        utils.print_error(ERROR_PICKER_NOT_AVAILABLE(picker))
    end
end

return M
