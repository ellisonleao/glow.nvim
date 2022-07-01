require("plenary.reload").reload_module("glow", true)
local glow = require("glow")
local utils = require("glow.utils")

describe("setup", function()


  it("setup with default configs", function()
    local expected = {
      glow_path = vim.fn.exepath("glow"),
      glow_install_path = vim.env.HOME .. "/.local/bin",
      border = "shadow",
      style = vim.o.background,
      mouse = false,
      pager = false,
      width = 80,
    }
    glow.setup()
    assert.are.same(glow.config, expected)
  end)

  it("setup with custom configs", function()
    local expected = {
      glow_path = vim.fn.exepath("glow"),
      glow_install_path = vim.env.HOME .. "/.local/bin",
      border = "shadow",
      style = "dark",
      pager = true,
      mouse = false,
      width = 200,
    }
    glow.setup(expected)
    assert.are.same(glow.config, expected)
  end)
end)

describe("utils", function()
  it("returns a valid release url valid os", function()
    local expected_results = {
      { "Linux", "x86", "https://github.com/charmbracelet/glow/releases/download/v1.4.1/glow_1.4.1_linux_i386.tar.gz" },
      { "Linux", "x64", "https://github.com/charmbracelet/glow/releases/download/v1.4.1/glow_1.4.1_linux_x86_64.tar.gz" },
    }

    for _, test_case in pairs(expected_results) do
      jit.os = test_case[1]
      jit.arch = test_case[2]
      assert.are.equal(utils.release_file_url(), test_case[3])
    end
  end)
end)
