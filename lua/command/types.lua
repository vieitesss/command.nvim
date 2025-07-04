--- @class Command.Execute
--- @field setup? function The setup function
--- @field has_setup boolean If it has a setup function

--- @class Command.Commands
--- @field history? string[]
--- @field executed? boolean If :CommandExecute was executed successfully before.
--- @field init? function()
--- @field new_command? function()
--- @field exec_command_again? function()
--- @field _set_executed? function()

--- @class Command.UI
--- @field term_buf integer The buffer where the terminal is displayed
--- @field terminal_win? function(): boolean true if the window was successfully created, false if not
--- @field command_prompt? function(): {buf: integer, win: integer}


--- @class Command.History
--- @field get_history? function(): string[]|nil Load command history from disk
--- @field save_history? function(h: string[]) Save the commands into the disk

--- @class Command.Prompt
--- @field buf? integer The prompt buffer number.
--- @field win? integer The prompt window number.
--- @field history? string[] The history list.
--- @field hist_idx? integer The current history item.

--- @class Command.Actions
--- @field on_command_enter? function
--- @field on_command_cancel? function
--- @field follow_error_at_cursor? function
