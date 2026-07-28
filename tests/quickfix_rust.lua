vim.opt.runtimepath:prepend('.')

local parser = require('command.quickfix.parser')
local error_info = parser.parse_line(' --> src/tui/sessions_list.rs:3:5')

assert(
    vim.deep_equal(error_info, {
        file = 'src/tui/sessions_list.rs',
        line = 3,
        col = 5,
    }),
    'Rust compiler locations should be jumpable'
)

assert(
    vim.deep_equal(parser.parse_line(' --> src/tui/sessions_list.rs'), {
        file = 'src/tui/sessions_list.rs',
        line = 1,
        col = 0,
    }),
    'Rust compiler paths should not include the arrow'
)
