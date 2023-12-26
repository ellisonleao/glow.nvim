require("plenary.reload").reload_module("glow", true)
local glow = require("glow")

describe("setup", function()
  it("setup with default configs", function()
    local expected = {
      glow_path = vim.fn.exepath("glow"),
      install_path = vim.env.HOME .. "/.local/bin",
      border = "shadow",
      style = vim.o.background,
      pager = false,
      width = 100,
      height = 100,
      default_type = "preview",
      split_dir = "vsplit",
      winbar = true,
      winbar_text = "%#Error#%=GLOW%=",
      mappings = {
        close = { "<Esc>", "q" }, -- to close Glow
        toggle = { "p" }
      }
    }
    glow.setup()
    assert.are.same(glow.config, expected)
  end)

  it("setup with custom configs", function()
    local expected = {
      glow_path = vim.fn.exepath("glow"),
      install_path = vim.env.HOME .. "/.local/bin",
      border = "shadow",
      style = "dark",
      pager = true,
      width = 200,
      height = 100,
      default_type = "keep",
      split_dir = "split",
      winbar = false,
      winbar_text = "test",
      mappings = {
        toggle = { "t", "e" },
        close = { "s", "t" }
      }
    }
    glow.setup(expected)
    assert.are.same(glow.config, expected)
  end)
end)
