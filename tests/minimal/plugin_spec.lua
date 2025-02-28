-- tests/minimal/plugin_spec.lua
-- Integration tests for the full plugin

local helpers = require("tests.helpers")

describe("goose.nvim plugin", function()
  it("loads the plugin without errors", function()
    -- Simply test that the plugin can be required
    local goose = require("goose")
    assert.truthy(goose, "Plugin should be loaded")
    assert.is_function(goose.setup, "setup function should be available")
    assert.is_function(goose.goose_command, "goose_command function should be available")
  end)

  it("can be set up with custom config", function()
    local goose = require("goose")
    local custom_callback = function(cmd) return "modified: " .. cmd end

    -- Setup with custom config
    goose.setup({
      command_callback = custom_callback,
      keymap = {
        prompt = "<leader>test"
      }
    })

    -- Check that config was set correctly
    local config = require("goose.config")
    assert.equal(custom_callback, config.get("command_callback"))
    assert.equal("<leader>test", config.get("keymap").prompt)
  end)
end)
