-- tests/unit/keymap_spec.lua
-- Tests for the keymap module

local keymap = require("goose.keymap")
local command = require("goose.command")

describe("goose.keymap", function()
  -- Keep track of set keymaps to verify
  local set_keymaps = {}

  -- Mock vim.keymap.set for testing
  local original_keymap_set

  before_each(function()
    set_keymaps = {}
    original_keymap_set = vim.keymap.set

    -- Mock the function to capture calls
    vim.keymap.set = function(modes, key, callback, opts)
      table.insert(set_keymaps, {
        modes = modes,
        key = key,
        callback = callback,
        opts = opts
      })
    end
  end)

  after_each(function()
    -- Restore original function
    vim.keymap.set = original_keymap_set
  end)

  describe("setup", function()
    it("sets up keymap with the configured keys", function()
      local test_keymap = {
        prompt = "<leader>test",
      }

      keymap.setup(test_keymap)

      -- Verify the keymap was set up
      assert.equal(2, #set_keymaps)
      assert.same({ "n", "v" }, set_keymaps[1].modes)
      assert.equal("<leader>test", set_keymaps[1].key)
      assert.is_function(set_keymaps[1].callback)
      assert.is_table(set_keymaps[1].opts)
    end)

    it("sets up the correct callback function that calls execute_command", function()
      -- Spy on command.execute_command
      local original_execute = command.execute_command
      local execute_called = false

      command.execute_command = function(opts)
        execute_called = true
        return "test_result"
      end

      -- Setup the keymap
      keymap.setup({ prompt = "<leader>test" })

      -- Call the callback that was passed to vim.keymap.set
      local result = set_keymaps[1].callback()

      -- Restore original
      command.execute_command = original_execute

      -- Verify the callback called execute_command
      assert.is_true(execute_called)
    end)
  end)
end)
