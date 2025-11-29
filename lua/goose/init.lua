local M = {}
local config = require("goose.config")
local keymap = require("goose.keymap")
local api = require("goose.api")
local state = require("goose.state")
local session = require("goose.session")

function M.setup(opts)
  config.setup(opts)
  api.setup()
  keymap.setup(config.get("keymap"))
  state.active_session = session.get_last_session()
end

return M
