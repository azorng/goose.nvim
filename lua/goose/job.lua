-- goose.nvim/lua/goose/job.lua
-- Contains goose job execution logic

local context = require("goose.context")
local state = require("goose.state")
local config = require("goose.config")
local Job = require('plenary.job')

local M = {}

function M.build_args(message)
  if not message then return nil end
  local args = { "run", "--text", message, "--output-format", "stream-json" }

  local system_instructions = config.get("system_instructions")
  if system_instructions and system_instructions ~= "" then
    table.insert(args, "--system")
    table.insert(args, system_instructions)
  end

  if state.active_session then
    table.insert(args, "--name")
    table.insert(args, state.active_session.name)
    table.insert(args, "--resume")
  end

  return args
end

function M.execute(prompt, handlers)
  if not prompt then
    return nil
  end

  local message = context.format_message(prompt)

  local args = M.build_args(message)

  state.goose_run_job = Job:new({
    command = 'goose',
    args = args,
    on_start = function()
      vim.schedule(function()
        handlers.on_start(message)
      end)
    end,
    on_stdout = function(_, out)
      if out then
        vim.schedule(function()
          handlers.on_output(out)
        end)
      end
    end,
    on_stderr = function(_, err)
      if err then
        vim.schedule(function()
          handlers.on_error(err)
        end)
      end
    end,
    on_exit = function()
      vim.schedule(function()
        handlers.on_exit()
      end)
    end
  })

  state.goose_run_job:start()
end

function M.stop(job)
  if job then
    pcall(function()
      vim.uv.process_kill(job.handle)
      job:shutdown()
    end)
  end
end

return M
