local M = {}
local config = require("goose.config")
local keymap = require("goose.keymap")
local api = require("goose.api")
local highlight = require("goose.ui.highlight")

function M.setup(opts)
  config.setup(opts)
  highlight.setup()
  api.setup()
  keymap.setup(config.get("keymap"))
end

return M
