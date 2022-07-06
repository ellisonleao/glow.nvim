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
      width = 100,
      height = 100,
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
      height = 100,
    }
    glow.setup(expected)
    assert.are.same(glow.config, expected)
  end)
end)

describe("utils.release_file_url", function()
  it("returns a valid release url valid os", function()
    local expected_results = {
      { "Linux", "x86", "https://github.com/charmbracelet/glow/releases/download/v1.4.1/glow_1.4.1_linux_i386.tar.gz" },
      { "Linux", "x64", "https://github.com/charmbracelet/glow/releases/download/v1.4.1/glow_1.4.1_linux_x86_64.tar.gz" },
      { "Windows", "x64", "" },
      { "Windows", "x86", "" },
      { "Darwin", "x86", "https://github.com/charmbracelet/glow/releases/download/v1.4.1/glow_1.4.1_Darwin_i386.tar.gz" },
      { "Darwin", "x64", "https://github.com/charmbracelet/glow/releases/download/v1.4.1/glow_1.4.1_Darwin_x86_64.tar.gz" },
    }

    for _, test_case in pairs(expected_results) do
      jit.os = test_case[1]
      jit.arch = test_case[2]
      assert.are.equal(utils.release_file_url(), test_case[3])
    end
  end)
end)

describe("utils.get_glow_cmd", function()
  it("file param should return correct cmd", function()
    local tmpfile = vim.loop.cwd() .. "/tests/glow/TEST.md"
    local expected = string.format("%s -s dark -p '%s'", glow.config.glow_path, tmpfile)
    local fargs = { tmpfile }
    assert.are.same(utils.get_glow_cmd(fargs), expected)
  end)

  it("string param should return correct cmd", function()
    local expected = string.format("echo '# hello world' | %s -s dark -p", glow.config.glow_path)
    local fargs = { "-", "# hello world" }
    assert.are.same(utils.get_glow_cmd(fargs), expected)
  end)
end)
