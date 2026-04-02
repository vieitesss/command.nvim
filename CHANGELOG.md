# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by Keep a Changelog, and this project follows Semantic Versioning.
Before `1.0.0`, breaking changes increment the minor version.

## [Unreleased]

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
