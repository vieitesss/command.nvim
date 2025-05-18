--- @class CommandExecute
--- @field new_command func Ask for a command and execute it
--- @field exec_command_again func Re-execute the last executed command
--- @field setup func The setup function

--- @class UI
--- @field term_buf int The buffer where the terminal is displayed

--- @class History
--- @field get_history func(): string[]|nil Load command history from disk
--- @field save_history func(h: string[]) Save the commands into the disk
