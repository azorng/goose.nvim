-- tests/unit/keymap_spec.lua
-- Tests for the keymap module

local keymap = require("goose.keymap")
local ui = require("goose.ui.ui")

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
        focus_input = "<leader>test",
        focus_input_new_session = "<leader>testNew"
      }

      keymap.setup(test_keymap)

      -- Verify the keymap was set up
      assert.equal(2, #set_keymaps)
      assert.same({ "n", "v" }, set_keymaps[1].modes)
      assert.equal("<leader>test", set_keymaps[1].key)
      assert.is_function(set_keymaps[1].callback)
      assert.is_table(set_keymaps[1].opts)
    end)

    it("sets up the correct callback function that calls focus_input", function()
      -- Spy on ui.focus_input
      local original_focus_input = ui.focus_input
      local focus_input_called = false
      local focus_input_opts = nil

      ui.focus_input = function(opts)
        focus_input_called = true
        focus_input_opts = opts
      end

      -- Setup the keymap
      keymap.setup({ 
        focus_input = "<leader>test",
        focus_input_new_session = "<leader>testNew"
      })

      -- Call the first callback (continue session)
      set_keymaps[1].callback()
      
      -- Verify the callback called focus_input with correct opts
      assert.is_true(focus_input_called)
      assert.same({ new_session = false }, focus_input_opts)
      
      -- Reset and test the second callback (new session)
      focus_input_called = false
      focus_input_opts = nil
      
      -- Call the second callback
      set_keymaps[2].callback()
      
      -- Verify the callback called focus_input with correct opts
      assert.is_true(focus_input_called)
      assert.same({ new_session = true }, focus_input_opts)

      -- Restore original
      ui.focus_input = original_focus_input
    end)
  end)
end)