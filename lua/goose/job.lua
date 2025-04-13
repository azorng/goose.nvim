-- goose.nvim/lua/goose/job.lua
-- Contains goose job execution logic

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
    table.insert(args, state.active_session.name)
    table.insert(args, "--resume")
  else
    local session_name = util.uid()
    state.new_session_name = session_name
    table.insert(args, "--name")
    table.insert(args, session_name)
  end

  return args
end

function M.execute(prompt, handle_output, handle_err)
  if not prompt then
    return nil
  end

  local args = M.build_args(prompt)
  
  -- Get provider and model info for displaying in the output
  state.session_info = M.get_session_info()
  if not state.active_session and state.new_session_name then
    state.session_info.path = vim.fn.expand("~/.local/share/goose/sessions/") .. state.new_session_name .. ".jsonl"
  elseif state.active_session then
    state.session_info.path = state.active_session.path
  end

  state.goose_run_job = Job:new({
    command = 'goose',
    args = args,
    on_stdout = function(_, out)
      if out then
        vim.schedule(function()
          handle_output(out)
        end)
      end
    end,
    on_stderr = function(_, out)
      if out then
        vim.schedule(function()
          handle_err(out)
        end)
      end
    end,
    on_exit = function()
      vim.schedule(function()
        state.goose_run_job = nil
        
        -- If user is currently in the output window, move to the input window
        if state.windows and vim.api.nvim_get_current_win() == state.windows.output_win then
          require('goose.ui.ui').focus_input()
        end
      end)
    end
  })

  state.goose_run_job:start()
end

function M.get_session_info()
  local config_path = vim.fn.expand("~/.config/goose/config.yaml")
  local provider = "unknown"
  local model = "unknown"
  
  if vim.fn.filereadable(config_path) == 1 then
    local config_content = vim.fn.readfile(config_path)
    
    for _, line in ipairs(config_content) do
      if line:match("^GOOSE_PROVIDER:") then
        provider = line:match("^GOOSE_PROVIDER:%s*(.+)")
      elseif line:match("^GOOSE_MODEL:") then
        model = line:match("^GOOSE_MODEL:%s*(.+)")
      end
    end
  end
  
  return {
    provider = provider,
    model = model,
    path = ""
  }
end

function M.stop()
  if state.goose_run_job then
    pcall(function()
      vim.uv.process_kill(state.goose_run_job.handle)
      state.goose_run_job:shutdown()
    end)

    state.goose_run_job = nil
  end
end

return M
