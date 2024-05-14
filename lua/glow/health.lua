local health = vim.health or require("health")

local report_start = health.start or health.report_start
local report_ok = health.ok or health.report_ok
local report_warn = health.warn or health.report_warn
local report_error = health.error or health.report_error

---@class GlowHealthPackage
---@field name string: package name
---@field cmd string[]: cmd command call
---@field url string: package url
---@field optional boolean: whether or not is an optional package
---@field args string[]|nil: check version command

---@class GlowHealthDependency
---@field cmd_name string: command name
---@table package GlowHealthPackage[]

---@type GlowHealthDependency[]
local optional_dependencies = {
  {
    cmd_name = "glow",
    package = {
      {
        name = "Glow",
        cmd = { "glow" },
        args = { "--version" },
        url = "[charmbracelet/glow](https://github.com/charmbracelet/glow)",
        optional = false,
      },
    },
  },
}
---Check if the cmd for the package are installed and which version
---@param pkg GlowHealthPackage
---@return boolean installed
---@return string|any
local check_binary_installed = function(pkg)
  local cmd = pkg.cmd or { pkg.name }
  for _, binary in ipairs(cmd) do
    if vim.fn.executable(binary) == 1 then
      local binary_version = ""
      local version_cmd = ""
      if pkg.args == nil then
        return vim.fn.executable(binary) == 1, ""
      else
        local cmd_args = table.concat(pkg.args, " ")
        version_cmd = table.concat({ binary, cmd_args }, " ")
      end
      local handle, err = io.popen(version_cmd)

      if err then
        report_error(err)
        vim.notify(err, vim.log.levels.ERROR, { title = "Glow" })
        return true, err
      end
      if handle then
        binary_version = handle:read("*a")
        handle:close()
        if
          binary_version:lower():find("illegal")
          or binary_version:lower():find("unknown")
          or binary_version:lower():find("invalid")
        then
          return true, ""
        end
        return true, binary_version
      end
    end
  end
  return false, ""
end

local M = {}

M.check = function()
  report_start("Checking for external dependencies")

  for _, opt_dep in pairs(optional_dependencies) do
    for _, pkg in ipairs(opt_dep.package) do
      local installed, version = check_binary_installed(pkg)
      if not installed then
        local err_msg = string.format("%s: not found.", pkg.name)
        if pkg.optional then
          local warn_msg =
            string.format("%s %s", err_msg, string.format("Install %s for extended capabilities", pkg.url))
          report_warn(warn_msg)
        else
          report_error(err_msg)
        end
      else
        if version ~= "not needed" then
          version = version == "" and "(unkown)" or version
          local eol = version:find("\n")
          if eol == nil then
            version = "(unkown)"
          else
            version = version:sub(0, eol - 1)
          end
          local ok_msg = string.format("%s: found! version: `%s`", pkg.name, version)
          report_ok(ok_msg)
        end
      end
    end
  end
end

return M
