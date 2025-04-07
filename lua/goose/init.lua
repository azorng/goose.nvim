local config = require("goose.config")
local keymap = require("goose.keymap")

local M = {}

function M.setup(opts)
  config.setup(opts)
  keymap.setup(config.get("keymap"))
end

return M
