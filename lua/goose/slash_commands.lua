local M = {}

local base_commands = { 'compact', 'clear', 'prompts', 'prompt' }

local function get_commands_from_config()
  local info = require('goose.info')
  return info.slash_commands()
end

---@return SlashCommand[]
function M.get_commands()
  local configured_commands = get_commands_from_config()

  local commands = {}

  for _, cmd_entry in ipairs(configured_commands) do
    if cmd_entry.command then
      table.insert(commands, M.new(cmd_entry.command))
    end
  end

  for _, base_cmd in ipairs(base_commands) do
    table.insert(commands, M.new(base_cmd))
  end

  return commands
end

---@return SlashCommand
function M.new(cmd)
  return { cmd = cmd }
end

---@return OmniFnCompleteItem
function M.get_completable()
  local commands = M.get_commands()
  return vim.tbl_map(function(command)
    return { word = '/' .. command.cmd }
  end, commands)
end

return M
