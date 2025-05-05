local core = require("goose.core")
local ui = require("goose.ui.ui")
local state = require("goose.state")
local review = require("goose.review")

local M = {}

-- Core API functions

function M.open_input()
  core.open({ new_session = false, focus = "input" })
  vim.cmd('startinsert')
end

function M.open_input_new_session()
  core.open({ new_session = true, focus = "input" })
  vim.cmd('startinsert')
end

function M.open_output()
  core.open({ new_session = false, focus = "output" })
end

function M.close()
  ui.close_windows(state.windows)
end

function M.toggle()
  if state.windows == nil then
    local focus = state.last_focused_goose_window or "input"
    core.open({ new_session = false, focus = focus })
  else
    M.close()
  end
end

function M.toggle_focus()
  if not ui.is_goose_focused() then
    local focus = state.last_focused_goose_window or "input"
    core.open({ new_session = false, focus = focus })
  else
    ui.return_to_last_code_win()
  end
end

function M.stop()
  core.stop()
end

function M.run(prompt)
  core.run(prompt, {
    ensure_ui = true,
    new_session = false,
    focus = "output"
  })
end

function M.run_new_session(prompt)
  core.run(prompt, {
    ensure_ui = true,
    new_session = true,
    focus = "output"
  })
end

function M.toggle_fullscreen()
  if not state.windows then
    core.open({ new_session = false, focus = "output" })
  end

  ui.toggle_fullscreen()
end

function M.select_session()
  core.select_session()
end

function M.toggle_pane()
  if not state.windows then
    core.open({ new_session = false, focus = "output" })
    return
  end

  ui.toggle_pane()
end

function M.diff()
  review.review()
end

function M.set_review_breakpoint()
  review.set_breakpoint()
end

function M.revert_all()
  review.revert_all()
end

function M.revert_this()
  review.revert_current()
end

-- Command definitions that call the API functions
M.commands = {
  toggle = {
    name = "Goose",
    desc = "Open goose. Close if opened",
    fn = function()
      M.toggle()
    end
  },

  toggle_focus = {
    name = "GooseToggleFocus",
    desc = "Toggle focus between goose and last window",
    fn = function()
      M.toggle_focus()
    end
  },

  open_input = {
    name = "GooseOpenInput",
    desc = "Opens and focuses on input window on insert mode",
    fn = function()
      M.open_input()
    end
  },

  open_input_new_session = {
    name = "GooseOpenInputNewSession",
    desc = "Opens and focuses on input window on insert mode. Creates a new session",
    fn = function()
      M.open_input_new_session()
    end
  },

  open_output = {
    name = "GooseOpenOutput",
    desc = "Opens and focuses on output window",
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
    desc = "Stop goose while it is running",
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

  toggle_pane = {
    name = "GooseTogglePane",
    desc = "Toggle between input and output panes",
    fn = function()
      M.toggle_pane()
    end
  },

  run = {
    name = "GooseRun",
    desc = "Run goose with a prompt (continue last session)",
    fn = function(opts)
      M.run(opts.args)
    end
  },

  run_new_session = {
    name = "GooseRunNewSession",
    desc = "Run goose with a prompt (new session)",
    fn = function(opts)
      M.run_new_session(opts.args)
    end
  },

  diff = {
    name = "GooseDiff",
    desc = "Display a vertical split diff of the changes since the last goose prompt",
    fn = function()
      M.diff()
    end
  },

  set_review_breakpoint = {
    name = "GooseSetReviewBreakpoint",
    desc = "Set a review breakpoint to track changes",
    fn = function()
      M.set_review_breakpoint()
    end
  },

  revert_all = {
    name = "GooseRevertAll",
    desc = "Revert all file changes since the last goose prompt",
    fn = function()
      M.revert_all()
    end
  },

  revert_this = {
    name = "GooseRevertThis",
    desc = "Revert current file changes since the last goose prompt",
    fn = function()
      M.revert_this()
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
