-- utils module
local utils = {}
local cfg = require("glow").config

utils.release_file_url = function()
  local os, arch
  local version = "1.4.1"
  local install_path = cfg.glow_install_path

  -- check pre-existence of required programs
  if vim.fn.executable("curl") == 0 or vim.fn.executable("tar") == 0 then
    utils.msg("cURL and/or tar are required!")
    return
  end

  -- local on_windows = vim.loop.os_uname().version:match("Windows")

  local raw_os = jit.os
  local raw_arch = jit.arch
  local os_patterns = {
    ["Windows"] = "Windows",
    ["Linux"] = "linux",
    ["Darwin"] = "Darwin",
    ["BSD"] = "freebsd",
  }

  local arch_patterns = {
    ["x86"] = "i386",
    ["x64"] = "x86_64",
    ["arm"] = "arm7",
  }

  os = os_patterns[raw_os]
  arch = arch_patterns[raw_arch]

  if os == nil or arch == nil then
    utils.msg("OS not supported")
    return ""
  end

  -- win install not supported for now
  if os == "Windows" then
    utils.msg("Install script not supported on Windows yet. Please install glow manually")
    return ""
  end

  -- create the url, filename based on os, arch, version
  local filename = "glow_" .. version .. "_" .. os .. "_" .. arch .. ".tar.gz"
  return "https://github.com/charmbracelet/glow/releases/download/v" .. version .. "/" .. filename
end

utils.msg = function(msg, level)
  local l = level and string.upper(level) or "ERROR"
  return vim.notify(msg, vim.log.levels[l])
end

return utils
