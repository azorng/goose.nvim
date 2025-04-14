-- tests/unit/keymap_spec.lua
-- Tests for the keymap module

local keymap = require("goose.keymap")

describe("goose.keymap", function()
  -- Keep track of set keymaps to verify
  local set_keymaps = {}

  -- Track vim.cmd calls
  local cmd_calls = {}

  -- Mock vim.keymap.set and vim.cmd for testing
  local original_keymap_set
  local original_vim_cmd

  before_each(function()
    set_keymaps = {}
    cmd_calls = {}
    original_keymap_set = vim.keymap.set
    original_vim_cmd = vim.cmd

    -- Mock the functions to capture calls
    vim.keymap.set = function(modes, key, callback, opts)
      table.insert(set_keymaps, {
        modes = modes,
        key = key,
        callback = callback,
        opts = opts
      })
    end

    vim.cmd = function(command)
      table.insert(cmd_calls, command)
    end
  end)

  after_each(function()
    -- Restore original functions
    vim.keymap.set = original_keymap_set
    vim.cmd = original_vim_cmd
  end)

  describe("setup", function()
    it("sets up keymap with the configured keys", function()
      local test_keymap = {
        global = {
          open_input = "<leader>test",
          open_input_new_session = "<leader>testNew",
          open_output = "<leader>out",
          close = "<leader>close",
          toggle_fullscreen = "<leader>full",
          select_session = "<leader>select"
        }
      }

      keymap.setup(test_keymap)

      -- Verify the keymap was set up
      assert.same({ "n", "v" }, set_keymaps[1].modes)
      assert.equal("<leader>test", set_keymaps[1].key)
      assert.is_function(set_keymaps[1].callback)
      assert.is_table(set_keymaps[1].opts)
    end)

    it("sets up callbacks that execute the correct commands", function()
      -- Mock API functions to track calls
      local original_api_functions = {}
      local api_calls = {}
      local api = require("goose.api")
      
      -- Save original functions
      for k, v in pairs(api) do
        if type(v) == "function" then
          original_api_functions[k] = v
          api[k] = function()
            table.insert(api_calls, k)
          end
        end
      end
      
      -- Setup the keymap
      keymap.setup({
        global = {
          open_input = "<leader>test",
          open_input_new_session = "<leader>testNew",
          open_output = "<leader>out",
          close = "<leader>close",
          toggle_fullscreen = "<leader>full",
          select_session = "<leader>select"
        }
      })

      -- Call the first callback (continue session)
      set_keymaps[1].callback()
      assert.equal("open_input", api_calls[1])

      -- Call the second callback (new session)
      set_keymaps[2].callback()
      assert.equal("open_input_new_session", api_calls[2])

      -- Call the third callback (open output)
      set_keymaps[3].callback()
      assert.equal("open_output", api_calls[3])

      -- Call the fourth callback (close)
      set_keymaps[4].callback()
      assert.equal("close", api_calls[4])

      -- Call the fifth callback (toggle fullscreen)
      set_keymaps[5].callback()
      assert.equal("toggle_fullscreen", api_calls[5])

      -- Call the sixth callback (select session)
      set_keymaps[6].callback()
      assert.equal("select_session", api_calls[6])
      
      -- Restore original API functions
      for k, v in pairs(original_api_functions) do
        api[k] = v
      end
    end)
  end)
end)
