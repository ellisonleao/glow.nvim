-- utils module
local utils = {}

utils.release_file_url = function()
  local os, arch
  local version = "1.4.1"
  local cfg = require("glow").config
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

utils.get_glow_cmd = function(fargs)
  local cfg = require("glow").config
  local cmd = { cfg.glow_path, "-s " .. cfg.style }

  if cfg.pager then
    table.insert(cmd, "-p")
  end

  -- stdin should start with "-" char followed by string text
  if fargs[1] == "-" then
    -- remove "-" char
    table.remove(fargs, 1)
    local output = table.concat(fargs, " ")
    table.insert(cmd, 1, string.format("echo '%s' |", output))
  else
    local path = utils.validate_file(fargs[1])
    table.insert(cmd, vim.fn.shellescape(path))
  end

  cmd = table.concat(cmd, " ")
  return cmd
end

utils.validate_file = function(path)
  -- trim and get the full path
  path = vim.trim(path)
  path = path == "" and "%" or path
  path = vim.fn.expand(path)
  path = vim.fn.fnamemodify(path, ":p")
  local file_exists = vim.fn.filereadable(path) == 1

  -- check if file exists
  if not file_exists then
    error("file does not exist")
  end

  local ext = vim.fn.fnamemodify(path, ":e")
  local allowed_exts = { "md", "markdown", "mkd", "mkdn", "mdwn", "mdown", "mdtxt", "mdtext", "rmd" }
  if not vim.tbl_contains(allowed_exts, ext) then
    error("glow only support markdown files")
  end

  return path
end

return utils
