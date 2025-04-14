local core = require("goose.core")
local ui = require("goose.ui.ui")
local state = require("goose.state")

local M = {}

-- Core API functions

function M.open_input()
  core.open({ new_session = false, focus = "input" })
  return true
end

function M.open_input_new_session()
  core.open({ new_session = true, focus = "input" })
  return true
end

function M.open_output()
  core.open({ new_session = false, focus = "output" })
  return true
end

function M.close()
  ui.close_windows(state.windows)
  return true
end

function M.stop()
  core.stop()
  return true
end

function M.run(prompt)
  core.run(prompt, {
    ensure_ui = true,
    new_session = false,
    focus = "output"
  })
  return true
end

function M.run_new_session(prompt)
  core.run(prompt, {
    ensure_ui = true,
    new_session = true,
    focus = "output"
  })
  return true
end

function M.toggle_code_ui()
  local windows = state.windows
  if not windows then
    -- If Goose UI isn't open, open it
    core.open({ new_session = false, focus = "output" })
    return true
  end

  -- Get the current window ID
  local current_win = vim.api.nvim_get_current_win()
  
  -- Check if we're in a Goose window
  if current_win == windows.input_win or current_win == windows.output_win then
    -- Remember the last buffer we were in before switching to Goose
    if state.last_code_buffer and vim.api.nvim_buf_is_valid(state.last_code_buffer) then
      local buf_windows = vim.fn.win_findbuf(state.last_code_buffer)
      if #buf_windows > 0 then
        vim.api.nvim_set_current_win(buf_windows[1])
        return true
      end
    end
    
    -- If we can't return to the last buffer, find any non-goose window to switch to
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win ~= windows.input_win and win ~= windows.output_win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
    
    -- If no other windows exist, we stay in the current Goose window
  else
    -- Save current buffer before switching to Goose
    state.last_code_buffer = vim.api.nvim_get_current_buf()
    -- Focus output window
    vim.api.nvim_set_current_win(windows.output_win)
  end
  
  return true
end

function M.toggle_fullscreen()
  if not state.windows then
    core.open({ new_session = false, focus = "output" })
  end

  ui.toggle_fullscreen()
  return true
end

function M.select_session()
  core.select_session()
  return true
end

function M.resume_session()
  core.resume_session()
  return true
end

-- Command definitions that call the API functions
M.commands = {
  open_input = {
    name = "GooseOpenInput",
    desc = "Opens and focuses on input window. Loads current buffer context",
    fn = function()
      M.open_input()
    end
  },

  open_input_new_session = {
    name = "GooseOpenInputNewSession",
    desc = "Opens and focuses on input window. Loads current buffer context. Creates a new session",
    fn = function()
      M.open_input_new_session()
    end
  },

  open_output = {
    name = "GooseOpenOutput",
    desc = "Opens and focuses on output window. Loads current buffer context",
    fn = function()
      M.open_output()
    end
  },

  close = {
    name = "GooseClose",
    desc = "Close UI windows",
    fn = function()
      M.close()
    end
  },

  stop = {
    name = "GooseStop",
    desc = "Stop a running job",
    fn = function()
      M.stop()
    end
  },

  toggle_fullscreen = {
    name = "GooseToggleFullscreen",
    desc = "Toggle between normal and fullscreen mode",
    fn = function()
      M.toggle_fullscreen()
    end
  },

  select_session = {
    name = "GooseSelectSession",
    desc = "Select and load a goose session",
    fn = function()
      M.select_session()
    end
  },

  resume_session = {
    name = "GooseResumeSession",
    desc = "Resume a previous goose session with full history",
    fn = function()
      M.resume_session()
    end
  },

  toggle_code_ui = {
    name = "GooseToggleCodeUI",
    desc = "Toggle between code buffer and goose UI",
    fn = function()
      M.toggle_code_ui()
    end
  },

  run = {
    name = "GooseRun",
    desc = "Run Goose with a prompt (continue last session)",
    fn = function(opts)
      M.run(opts.args)
    end
  },

  run_new_session = {
    name = "GooseRunNewSession",
    desc = "Run Goose with a prompt (new session)",
    fn = function(opts)
      M.run_new_session(opts.args)
    end
  }
}

function M.setup()
  -- Register commands without arguments
  for key, cmd in pairs(M.commands) do
    if key ~= "run" and key ~= "run_new_session" then
      vim.api.nvim_create_user_command(cmd.name, cmd.fn, {
        desc = cmd.desc
      })
    end
  end

  -- Register commands with arguments
  vim.api.nvim_create_user_command(M.commands.run.name, M.commands.run.fn, {
    desc = M.commands.run.desc,
    nargs = "+"
  })

  vim.api.nvim_create_user_command(M.commands.run_new_session.name, M.commands.run_new_session.fn, {
    desc = M.commands.run_new_session.desc,
    nargs = "+"
  })
end

return M
