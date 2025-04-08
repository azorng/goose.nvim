-- goose.nvim/lua/goose/command.lua
-- Contains core command execution logic

local context = require("goose.context")
local state = require("goose.state")
local Job = require('plenary.job')
local util = require("util")

local M = {}

function M.build_args(prompt)
  if not prompt then return nil end
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

function M.execute(prompt, handle_output)
  if not prompt then
    return nil
  end

  local args = M.build_args(prompt)

  print(vim.inspect(args))

  M.stop()

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

function M.stop()
  if state.goose_run_job then
    state.goose_run_job:shutdown()
    local _handle = io.popen("kill " .. state.goose_run_job.pid)
    if _handle ~= nil then
      _handle:close()
    end
    state.goose_run_job = nil
  end
end

return M
