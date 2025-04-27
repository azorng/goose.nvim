local core = require("goose.core")

local ui = require("goose.ui.ui")
local state = require("goose.state")
local review = require("goose.review")
local history = require("goose.history")

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

function M.change_mode(mode)
  local info_mod = require("goose.info")
  info_mod.set_config_value(info_mod.GOOSE_INFO.MODE, mode)

  if state.windows then
    require('goose.ui.topbar').render()
  else
    vim.notify('Goose mode changed to ' .. mode)
  end
end

-- Renamed functions to match keymap names
function M.goose_mode_chat()
  M.change_mode(require('goose.info').GOOSE_MODE.CHAT)
end

function M.goose_mode_auto()
  M.change_mode(require('goose.info').GOOSE_MODE.AUTO)
end

-- Alias set_chat_mode and set_auto_mode to the new names for backward compatibility
M.set_chat_mode = M.goose_mode_chat
M.set_auto_mode = M.goose_mode_auto

function M.configure_provider()
  core.configure_provider()
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

-- Renamed diff functions to match keymap names
function M.diff_open()
  review.review()
end

function M.diff_next()
  review.next_diff()
end

function M.diff_prev()
  review.prev_diff()
end

function M.diff_close()
  review.close_diff()
end

function M.diff_revert_all()
  review.revert_all()
end

function M.diff_revert_this()
  review.revert_current()
end

-- Alias old diff functions for backward compatibility
M.diff = M.diff_open
M.next_diff = M.diff_next
M.prev_diff = M.diff_prev
M.close_diff = M.diff_close
M.revert_all = M.diff_revert_all
M.revert_this = M.diff_revert_this

function M.set_review_breakpoint()
  review.set_breakpoint()
end

function M.prev_history()
  local prev_prompt = history.prev()
  if prev_prompt then
    ui.write_to_input(prev_prompt)
  end
end

function M.next_history()
  local next_prompt = history.next()
  if next_prompt then
    ui.write_to_input(next_prompt)
  end
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

  -- Updated command names
  goose_mode_chat = {
    name = "GooseModeChat",
    desc = "Set goose mode to `chat`. (Tool calling disabled. No editor context besides selections)",
    fn = function()
      M.goose_mode_chat()
    end
  },

  goose_mode_auto = {
    name = "GooseModeAuto",
    desc = "Set goose mode to `auto`. (Default mode with full agent capabilities)",
    fn = function()
      M.goose_mode_auto()
    end
  },

  configure_provider = {
    name = "GooseConfigureProvider",
    desc = "Quick provider and model switch from predefined list",
    fn = function()
      M.configure_provider()
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

  -- Updated diff command names
  diff_open = {
    name = "GooseDiff",
    desc = "Opens a diff tab of a modified file since the last goose prompt",
    fn = function()
      M.diff_open()
    end
  },

  diff_next = {
    name = "GooseDiffNext",
    desc = "Navigate to next file diff",
    fn = function()
      M.diff_next()
    end
  },

  diff_prev = {
    name = "GooseDiffPrev",
    desc = "Navigate to previous file diff",
    fn = function()
      M.diff_prev()
    end
  },

  diff_close = {
    name = "GooseDiffClose",
    desc = "Close diff view tab and return to normal editing",
    fn = function()
      M.diff_close()
    end
  },

  diff_revert_all = {
    name = "GooseRevertAll",
    desc = "Revert all file changes since the last goose prompt",
    fn = function()
      M.diff_revert_all()
    end
  },

  diff_revert_this = {
    name = "GooseRevertThis",
    desc = "Revert current file changes since the last goose prompt",
    fn = function()
      M.diff_revert_this()
    end
  },

  set_review_breakpoint = {
    name = "GooseSetReviewBreakpoint",
    desc = "Set a review breakpoint to track changes",
    fn = function()
      M.set_review_breakpoint()
    end
  },
}

-- Add back aliases for backward compatibility
M.commands.chat_mode = M.commands.goose_mode_chat
M.commands.auto_mode = M.commands.goose_mode_auto
M.commands.diff = M.commands.diff_open
M.commands.next_diff = M.commands.diff_next
M.commands.prev_diff = M.commands.diff_prev
M.commands.close_diff = M.commands.diff_close
M.commands.revert_all = M.commands.diff_revert_all
M.commands.revert_this = M.commands.diff_revert_this

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
