-- goose.nvim/lua/goose/command.lua
-- Contains core command execution logic

local context = require("goose.context")
local state = require("goose.state")
local Job = require('plenary.job')
local util = require("util")

local M = {}

function M.build_args(options)
  options = options or {}

  local prompt = options.prompt
  if not prompt then
    prompt = vim.fn.input('Prompt: ')
    if prompt == "" then
      return nil -- User canceled
    end
  end

  local message = context.format_message(prompt)
  local args = { "run", "--text", message }

  if state.active_session then
    table.insert(args, "--name")
    table.insert(args, state.active_session.id)
    table.insert(args, "--resume")
  else
    local session_name = util.uid()
    state.new_session_name = session_name
    table.insert(args, "--name")
    table.insert(args, session_name)
  end

  return args
end

function M.execute(opts, handle_output)
  opts = opts or {}
  local args = M.build_args(opts)
  if not args then
    return nil
  end

  if state.goose_run_job then
    state.goose_run_job:shutdown()
  end

  state.goose_run_job = Job:new({
    command = 'goose',
    args = args,
    on_stdout = function(_, output)
      if output then
        vim.schedule(function()
          handle_output(output)
        end)
      end
    end,
    on_exit = function()
      vim.schedule(function()
        state.goose_run_job = nil
      end)
    end
  })

  state.goose_run_job:start()
end

return M
