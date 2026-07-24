# Development context

## Current goal

Make Rust compiler source locations such as `--> src/tui/mod.rs:6:29` jumpable from terminal output and quickfix.

## Approach

Keep location parsing centralized in `lua/command/quickfix/parser.lua` so both navigation paths share the fix.
