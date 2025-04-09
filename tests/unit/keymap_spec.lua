-- tests/unit/keymap_spec.lua
-- Tests for the keymap module

local keymap = require("goose.keymap")
local core = require("goose.core")

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
        prompt_new_session = "<leader>testNew"
      }

      keymap.setup(test_keymap)

      -- Verify the keymap was set up
      assert.same({ "n", "v" }, set_keymaps[1].modes)
      assert.equal("<leader>test", set_keymaps[1].key)
      assert.is_function(set_keymaps[1].callback)
      assert.is_table(set_keymaps[1].opts)
    end)

    it("sets up the correct callback function that calls prompt", function()
      -- Spy on ui.prompt
      local original_prompt = core.prompt
      local prompt_called = false
      local prompt_opts = nil

      core.prompt = function(opts)
        prompt_called = true
        prompt_opts = opts
      end

      -- Setup the keymap
      keymap.setup({
        prompt = "<leader>test",
        prompt_new_session = "<leader>testNew"
      })

      -- Call the first callback (continue session)
      set_keymaps[1].callback()

      -- Verify the callback called prompt with correct opts
      assert.is_true(prompt_called)
      assert.same({ new_session = false, focus = 'input' }, prompt_opts)

      -- Reset and test the second callback (new session)
      prompt_called = false
      prompt_opts = nil

      -- Call the second callback
      set_keymaps[2].callback()

      -- Verify the callback called prompt with correct opts
      assert.is_true(prompt_called)
      assert.same({ new_session = true, focus = 'input' }, prompt_opts)

      -- Restore original
      core.prompt = original_prompt
    end)
  end)
end)
