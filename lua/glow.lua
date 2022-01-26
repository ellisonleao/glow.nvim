local api = vim.api
local win, buf
local bin_path = vim.g.glow_binary_path
if bin_path == nil then
  bin_path = vim.env.HOME .. "/.local/bin"
end

local use_path_glow = vim.g.glow_binary_path == nil and vim.fn.executable("glow") == 1

local glow_path = use_path_glow and "glow" or bin_path .. "/glow"

local glow_style = vim.g.glow_style or "dark"
local glow_border = vim.g.glow_border
local glow_width = vim.g.glow_width
local glow_use_pager = vim.g.glow_use_pager

local M = {}

local function has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val:lower() then
      return true
    end
  end
  return false
end

local function validate(path)
  if vim.fn.executable(glow_path) == 0 then
    return M.download_glow()
  end

  -- trim and get the full path
  path = string.gsub(path, "%s+", "")
  path = string.gsub(path, "\"", "")
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
  if not has_value({"md", "markdown", "mkd", "mkdn", "mdwn", "mdown", "mdtxt", "mdtext"}, ext) then
    api.nvim_err_writeln("glow only support markdown files")
    return
  end

  return path
end

local function install_glow()
  local os, arch
  local version = "1.4.1"

  -- check pre-existence of required programs
  if vim.fn.executable("curl") == 0 then
    api.nvim_err_writeln("cURL is not installed!")
    return
  end

  if vim.fn.executable("tar") == 0 then
    api.nvim_err_writeln("tar is not installed!")
    return
  end

  -- win install not supported for now
  if vim.fn.has("win32") ~= 0 then
    api.nvim_err_writeln(
      "Install script not supported on Windows yet. Please install glow manually")
    return
  else
    os = vim.fn.trim(vim.fn.system("uname"))
  end

  -- based on os value, detect architecture and format
  if os == "Darwin" then
    arch = vim.fn.trim(vim.fn.system("uname -m"))
    if not has_value({"arm64", "x86_64"}, arch) then
      api.nvim_err_writeln("Architecture not supported/recognized!")
      return
    end
  elseif os == "Linux" or os == "FreeBSD" or os == "OpenBSD" then
    -- linux releases have "linux" in the name instead of "Linux"
    if os == "Linux" then
      os = "linux"
    end
    arch = vim.fn.trim(vim.fn.system("uname -p"))
    if arch == "unknown" then
      arch = vim.fn.trim(vim.fn.system("uname -m"))
    end
    if not has_value({"armv6", "armv7", "i386", "x86_64", "amd64"}, arch) then
      api.nvim_err_writeln("Architecture not supported/recognized!")
      return
    end
    if arch == "amd64" then
      arch = "x86_64"
    end
  else
    api.nvim_err_writeln("OS not supported/recognized!")
    return
  end

  -- create the url, filename based on os, arch, version
  local filename = "glow_" .. version .. "_" .. os .. "_" .. arch .. ".tar.gz"
  local url = "https://github.com/charmbracelet/glow/releases/download/v" .. version ..
                "/" .. filename

  local download_command = {"curl", "-sL", "-o", "glow.tar.gz", url}
  local extract_command = {"tar", "-zxf", "glow.tar.gz", "-C", bin_path}
  local output_filename = "glow.tar.gz"

  -- check for existing files / folders
  if vim.fn.isdirectory(bin_path) == 0 then
    vim.fn.mkdir(bin_path, "p")
  end

  if vim.fn.empty(vim.fn.glob(bin_path .. "/glow")) ~= 1 then
    local success = vim.loop.fs_unlink(bin_path .. "/glow")
    if not success then
      return api.nvim_err_writeln("Glow binary could not be removed!")
    end
  end

  if vim.fn.empty(vim.fn.glob(output_filename)) ~= 1 then
    local success = vim.loop.fs_unlink(output_filename)
    if not success then
      return api.nvim_err_writeln("Existing archive could not be removed!")
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
        local success = vim.loop.fs_unlink(output_filename)
        if not success then
          return api.nvim_err_writeln("Existing archive could not be removed!")
        end
      end
      print("Glow installed successfully!")
    end),
  }
  vim.fn.jobstart(download_command, callbacks)
end

function M.close_window()
  api.nvim_win_close(win, true)
end

function M.download_glow()
  if vim.fn.executable(bin_path .. "/glow") == 1 then
    local answer = vim.fn.input(
                     "latest glow already installed in ".. bin_path .."/glow, do you want update? Y/n = ")
    answer = string.lower(answer)
    while answer ~= "y" and answer ~= "n" do
      answer = vim.fn.input("please answer Y or n = ")
      answer = string.lower(answer)
    end

    if answer == "n" then
      return
    end
    print("updating glow..")
  else
    print("installing glow..")
  end
  install_glow()
end

-- open_window draws a custom window with the markdown contents
local function open_window(path)

  -- window size
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  if glow_width and glow_width < win_width then
    win_width = glow_width
  end

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = glow_border or "shadow",
  }

  -- create preview buffer and set local options
  buf = api.nvim_create_buf(false, true)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "filetype", "glowpreview")
  api.nvim_win_set_option(win, "winblend", 0)
  api.nvim_buf_set_keymap(buf, "n", "q", ":lua require('glow').close_window()<cr>",
                          {noremap = true, silent = true})
  api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":lua require('glow').close_window()<cr>",
                          {noremap = true, silent = true})

  local use_pager = glow_use_pager and '-p' or ''
  vim.fn.termopen(string.format("%s %s -s %s %s", glow_path, use_pager, glow_style, vim.fn.shellescape(path)))
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
