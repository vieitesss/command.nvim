--- @class Command.Execute
--- @field setup func The setup function

--- @class Command.Commands
--- @field history string[]
--- @field executed boolean If :CommandExecute was executed successfully before.
--- @field init func
--- @field new_command func
--- @field exec_command_again func

--- @class Command.UI
--- @field term_buf int The buffer where the terminal is displayed

--- @class Command.History
--- @field get_history func(): string[]|nil Load command history from disk
--- @field save_history func(h: string[]) Save the commands into the disk

--- @class Command.Prompt
--- @field buf int The prompt buffer number.
--- @field win int The prompt window number.
--- @field history string[] The history list.
--- @field hist_idx int The current history item.

--- @class Command.Actions
--- @field on_command_enter func
--- @field on_command_cancel func
--- @field follow_error_at_cursor func
