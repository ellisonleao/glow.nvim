local api = vim.api
local uv = vim.loop
local win, buf
local M = {}

-- default configs
M.config = {
  glow_path = vim.fn.exepath("glow"),
  glow_install_path = vim.env.HOME .. "/.local/bin",
  border = "shadow",
  style = vim.opt.background:get(),
  pager = false,
  width = 80,
}

local function has_value(val, tab)
  for _, value in ipairs(tab) do
    if value == val:lower() then
      return true
    end
  end
  return false
end

local function install_glow()
  local os, arch
  local version = "1.4.1"
  local install_path = M.config.glow_install_path

  -- check pre-existence of required programs
  if vim.fn.executable("curl") == 0 or vim.fn.executable("tar") == 0 then
    api.nvim_err_writeln("cURL and/or tar are not installed!")
    return
  end

  -- win install not supported for now
  if vim.fn.has("win32") ~= 0 then
    api.nvim_err_writeln("Install script not supported on Windows yet. Please install glow manually")
    return
  end

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
    api.nvim_err_writeln("OS not supported")
  end

  -- create the url, filename based on os, arch, version
  local filename = "glow_" .. version .. "_" .. os .. "_" .. arch .. ".tar.gz"
  local url = "https://github.com/charmbracelet/glow/releases/download/v" .. version .. "/" .. filename

  local download_command = { "curl", "-sL", "-o", "glow.tar.gz", url }
  local extract_command = { "tar", "-zxf", "glow.tar.gz", "-C", install_path }
  local output_filename = "glow.tar.gz"

  -- check for existing files / folders
  if vim.fn.isdirectory(M.config.glow_install_path) == 0 then
    uv.fs_mkdir(M.config.install_path, "p")
  end

  if vim.fn.empty(vim.fn.glob(install_path .. "/glow")) ~= 1 then
    local success = uv.fs_unlink(install_path .. "/glow")
    if not success then
      return api.nvim_err_writeln("Glow binary could not be removed!")
    end
  end

  -- download and install the glow binary
  local callbacks = {
    on_sterr = vim.schedule_wrap(function(_, data, _)
      local out = table.concat(data, "\n")
      api.nvim_err_writeln(out)
    end),
    on_exit = vim.schedule_wrap(function(_, _, _)
      vim.fn.system(extract_command)
      -- remove the archive after completion
      if vim.fn.empty(vim.fn.glob(output_filename)) ~= 1 then
        local success = uv.fs_unlink(output_filename)
        if not success then
          return api.nvim_err_writeln("existing archive could not be removed!")
        end
      end
      print("glow installed successfully!")
      M.config.glow_path = vim.fn.exepath("glow")
    end),
  }
  vim.fn.jobstart(download_command, callbacks)
end

local function validate(path)
  if M.config.glow_path == "" then
    print("glow not installed.. initiating installation..")
    return install_glow()
  end

  -- trim and get the full path
  path = string.gsub(path, "%s+", "")
  path = string.gsub(path, '"', "")
  path = path == "" and "%" or path
  path = vim.fn.expand(path)
  path = vim.fn.fnamemodify(path, ":p")
  local file_exists = vim.fn.filereadable(path) == 1

  -- check if file exists
  if not file_exists then
    api.nvim_err_writeln("file does not exists")
    return
  end

  local ext = vim.fn.fnamemodify(path, ":e")
  local allowed_exts = { "md", "markdown", "mkd", "mkdn", "mdwn", "mdown", "mdtxt", "mdtext", "rmd" }
  if not has_value(ext, allowed_exts) then
    api.nvim_err_writeln("glow only support markdown files")
    return
  end

  return path
end

function M.setup(params)
  M.config = vim.tbl_deep_extend("force", {}, M.config, params or {})
end

function M.close_window()
  api.nvim_win_close(win, true)
end

-- open_window draws a custom window with the markdown contents
local function open_window(path)
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  if M.config.width and M.config.width < win_width then
    win_width = M.config.width
  end

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = M.config.border,
  }

  -- create preview buffer and set local options
  buf = api.nvim_create_buf(false, true)
  win = api.nvim_open_win(buf, true, opts)

  api.nvim_win_set_option(win, "winblend", 0)
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "filetype", "glowpreview")
  api.nvim_buf_set_keymap(buf, "n", "q", ":lua require('glow').close_window()<cr>", { noremap = true, silent = true })
  api.nvim_buf_set_keymap(
    buf,
    "n",
    "<Esc>",
    ":lua require('glow').close_window()<cr>",
    { noremap = true, silent = true }
  )

  local cmd = { M.config.glow_path, "-s " .. M.config.style }
  if M.config.pager then
    table.insert(cmd, "-p")
  end
  table.insert(cmd, vim.fn.shellescape(path))
  cmd = table.concat(cmd, " ")
  vim.fn.termopen(cmd)

  if M.config.pager then
    vim.cmd("startinsert")
  end
end

function M.glow(file)
  local current_win = vim.fn.win_getid()
  if current_win == win then
    M.close_window()
  else
    local path = validate(file)
    if path == nil then
      return
    end
    open_window(path)
  end
end

return M
