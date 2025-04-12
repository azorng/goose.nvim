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
    desc = "Opens and focuses on input window. Loads current buffer context",
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
