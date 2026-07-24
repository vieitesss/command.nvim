vim.opt.runtimepath:prepend('.')

local parser = require('command.quickfix.parser')
local error_info = parser.parse_line(' --> src/tui/mod.rs:6:29')

assert(
    vim.deep_equal(error_info, {
        file = 'src/tui/mod.rs',
        line = 6,
        col = 29,
    }),
    'Rust compiler locations should be jumpable'
)
