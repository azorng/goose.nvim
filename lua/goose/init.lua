local M = {}
local config = require("goose.config")
local keymap = require("goose.keymap")
local api = require("goose.api")

function M.setup(opts)
  config.setup(opts)
  api.setup()
  keymap.setup(config.get("keymap"))
end

return M
