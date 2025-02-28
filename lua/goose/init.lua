local config = require("goose.config")
local command = require("goose.command")
local keymap = require("goose.keymap")

local M = {}

function M.setup(opts)
  config.setup(opts)
  keymap.setup(config.get("keymap"))
end

M.goose_command = command.execute_command

return M
