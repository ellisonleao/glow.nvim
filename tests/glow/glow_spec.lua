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
      filetypes = { "markdown", "markdown.pandoc", "markdown.gfm", "wiki", "vimwiki", "telekasten" },
      extra_filetypes = {},
      extensions = { "md", "markdown", "mkd", "mkdn", "mdwn", "mdown", "mdtxt", "mdtext", "rmd", "wiki" },
      extra_extensions = {},
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
      filetypes = { "markdown", "markdown.pandoc" },
      extra_filetypes = { "wiki" },
      extensions = { "md", "markdown", "mkd", "mkdn" },
      extra_extensions = { "mdtext" },
    }
    glow.setup(expected)
    assert.are.same(glow.config, expected)
  end)
end)
