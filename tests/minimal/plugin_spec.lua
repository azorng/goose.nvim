-- tests/minimal/plugin_spec.lua
-- Integration tests for the full plugin

local helpers = require("tests.helpers")

describe("goose.nvim plugin", function()
  it("loads the plugin without errors", function()
    -- Simply test that the plugin can be required
    local goose = require("goose")
    assert.truthy(goose, "Plugin should be loaded")
    assert.is_function(goose.setup, "setup function should be available")

    -- We don't check for goose_command anymore as it's been removed
    -- Instead test the new command module
    local command = require("goose.command")
    assert.truthy(command, "command module should be loaded")
    assert.is_function(command.build_args, "build_args function should be available")
    assert.is_function(command.execute, "execute function should be available")
  end)

  it("can be set up with custom config", function()
    local goose = require("goose")

    -- Setup with custom config matching new structure
    goose.setup({
      keymap = {
        focus_input = "<leader>test"
      }
    })

    -- Check that config was set correctly
    local config = require("goose.config")
    assert.equal("<leader>test", config.get("keymap").focus_input)
  end)
end)
