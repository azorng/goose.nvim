-- goose.nvim/lua/goose/command.lua
-- Contains core command execution logic

local context = require("goose.context")
local session = require("goose.session")
local ui = require("goose.ui")

local M = {}

function M.build_command(options)
  options = options or {}

  local prompt = options.prompt
  if not prompt then
    prompt = vim.fn.input('Prompt: ')
    if prompt == "" then
      return nil -- User canceled
    end
  end

  local message = context.format_message(prompt)
  local escaped_message = vim.fn.shellescape(message)
  local cmd_parts = { "goose", "run", "--interactive", "--text", escaped_message }

  if options.resume_session then
    local current_dir = vim.fn.getcwd()
    local last_session = session.get_last_session(current_dir)

    if last_session then
      table.insert(cmd_parts, "--name")
      table.insert(cmd_parts, last_session.id)
      table.insert(cmd_parts, "--resume")
    end
  end

  return table.concat(cmd_parts, " ")
end

function M.execute_command(opts)
  opts = opts or {}
  local cmd = M.build_command(opts)
  if not cmd then
    return nil
  end

  ui.run(cmd)
end

return M
