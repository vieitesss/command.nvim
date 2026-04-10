# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by Keep a Changelog, and this project follows Semantic Versioning.
Before `1.0.0`, breaking changes increment the minor version.

## [Unreleased]

## [0.2.0] - 2026-04-10

- If you are upgrading, check the README again and update your plugin manager configuration if needed. In particular, prefer a tagged release selector instead of tracking `main` directly, such as `version = '*'` in `lazy.nvim` or `version = vim.version.range('*')` in `vim.pack`.

### Added
- Multiline prompt editing with automatic prompt resizing, including a minimum 5-line prompt for multiline commands when space allows.

### Changed
- Prompt history search now keeps multiline entries selectable by flattening them only for picker display.

### Fixed
- Normal-mode `<CR>` now warns instead of trying to execute syntactically incomplete commands.

## [0.1.1] - 2026-04-02

### Fixed
- Quickfix window no longer prefixes plain output lines with `||`; output text is rendered as-is using a list-local `quickfixtextfunc`, while parsed file/error entries remain jumpable.

## [0.1.0] - 2026-04-02

### Added
- Initial release of `command.nvim`.
- Run shell commands inside a terminal window in Neovim.
- Persistent command history with `fzf-lua` search.
- Context variable expansion for file, cursor, working directory, and selection values.
- Ghost text suggestions in the prompt.
- Validation warnings for potentially dangerous commands.
- Terminal reopen support to recover hidden output.
- Quickfix integration with output parsing for file paths and compiler errors.
