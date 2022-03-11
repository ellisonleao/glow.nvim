describe("glow", function()
  it("can be required", function()
    require("glow")
  end)

  it("setup with default configs", function()
    local glow = require("glow")
    local expected = {
      glow_path = vim.fn.exepath("glow"),
      border = "shadow",
      style = vim.opt.background:get(),
      ["local"] = false,
      mouse = false,
      pager = false,
      width = 80,
    }
    assert(glow.config, expected)
  end)

  it("setup with custom configs", function()
    local glow = require("glow")
    local expected = {
      glow_path = vim.fn.exepath("glow"),
      border = "shadow",
      style = "dark",
      pager = true,
      width = 80,
    }
    glow.setup(expected)
    assert(glow.config, expected)
  end)
end)
