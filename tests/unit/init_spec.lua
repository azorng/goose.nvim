-- tests/unit/init_spec.lua
-- Tests for the init module (public API)

local goose = require("goose")

describe("goose", function()
  it("has setup function in the public API", function()
    assert.is_function(goose.setup)
  end)

  it("has goose_command function in the public API", function()
    assert.is_function(goose.goose_command)
  end)
end)
