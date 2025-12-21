# command.nvim

## Project Overview

`command.nvim` is a Neovim plugin designed to enhance the terminal experience within the editor. It allows users to execute shell commands directly in a terminal split, manage command history, and provides safety features like command validation.

**Key Features:**
*   **Command Execution:** Run shell commands in a dedicated terminal split.
*   **History Management:** Store and retrieve previously executed commands.
*   **Ghost Text:** Completion suggestions based on history.
*   **Safety Validation:** Warnings for potentially dangerous commands (e.g., `rm`, `dd`, redirects to system files).
*   **Integrations:** Supports `fzf-lua` for searching command history.
*   **Error Following:** Ability to jump to file locations from error messages (inspired by `compile-mode.nvim`).

## Architecture

The project is structured as a standard Neovim Lua plugin:

*   **`lua/command/`**: Core plugin logic.
    *   **`init.lua`**: Entry point.
    *   **`config.lua`**: Configuration handling and defaults.
    *   **`api.lua`**: Public API functions.
    *   **`state.lua`**: State management.
    *   **`validation.lua`**: Logic for validating command safety.
    *   **`actions/`**: Implementation of user actions (prompt interaction, terminal actions).
    *   **`history/`**: Logic for storing and loading command history.
    *   **`ui/`**: UI components (Prompt buffer, Terminal buffer, Ghost text).
    *   **`picker/`**: Integration with external pickers (e.g., `fzf-lua`).
*   **`plugin/`**: Neovim plugin entry point (defines commands).
*   **`tests/`**: Test suite using `mini.test`.

## Building and Running

### Prerequisites
*   **Neovim:** The target editor.
*   **Make:** For running build/test automation.
*   **Git:** For fetching dependencies.

### Testing
The project uses `mini.test` from `mini.nvim` for testing.

1.  **Run all tests:**
    ```bash
    make test
    ```
    This command will automatically clone `mini.nvim` into `deps/` if it's missing.

2.  **Run a specific test file:**
    ```bash
    make test_file FILE=tests/test_01_execute_prompt_creation.lua
    ```

## Development Conventions

*   **Language:** Lua.
*   **Style:** Follows standard Lua formatting.
*   **Testing:** Tests are located in `tests/` and should be prefixed with `test_`. Use `mini.test` for assertions and test structure.
*   **Configuration:** All user-configurable options are defined in `lua/command/config.lua` with type annotations.
*   **Dependencies:** External dependencies (like `mini.nvim` for testing) are managed in the `deps/` directory (git ignored).

## Usage
The plugin exposes two main commands:
*   `:CommandExecute`: Opens the prompt to type and run a command.
*   `:CommandExecuteLast`: Re-runs the last executed command.
