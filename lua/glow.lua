local api = vim.api
local win, buf
local M = {}

local function validate(path)
  if vim.fn.executable("glow") == 0 then
    api.nvim_err_writeln("glow is not installed. Call :GlowInstall to install it")
    return
  end

  -- trim and get the full path
  path = string.gsub(path, "%s+", "")
  path = string.gsub(path, "\"", "")
  path = path == "" and "%" or path
  path = vim.fn.expand(path)
  path = vim.fn.fnamemodify(path, ":p")
  local file_exists = vim.fn.filereadable(path) == 1 and vim.fn.bufexists(path) == 1
  -- check if file exists
  if not file_exists then
    api.nvim_err_writeln("file does not exists")
    return
  end

  local ext = vim.fn.fnamemodify(path, ":e")
  if ext ~= "md" or vim.bo.filetype ~= "markdown" then
    api.nvim_err_writeln("glow only support markdown files")
    return
  end

  return path
end

local function has_value(tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

local function install_glow()
  local os, arch, format, bin_path, download_command, extract_command
  local path_separator = "/"
  local version = "1.4.1"

  -- detect os first
  if vim.fn.has("win64") ~= 0 or vim.fn.has("win32") ~= 0 or vim.fn.has("win16") ~= 0 then
    os = "Windows"
  else
    os = vim.fn.substitute(vim.fn.system('uname'), '\n', '', '')
  end

  -- based on os value, detect architecture and format
  if os == "Darwin" then
    arch = vim.fn.substitute(vim.fn.system('uname -m'), '\n', '', '')
    if not has_value({"arm64", "x86_64"}, arch) then
      api.nvim_err_writeln("Architecture not supported/recognized!")
      return
    end
    format = "tar.gz"
  elseif os == "Linux" then
    -- linux releases have "linux" in the name instead of "Linux"
    os = "linux"
    arch = vim.fn.substitute(vim.fn.system('uname -p'), '\n', '', '')
    if arch == "unknown" then
      arch = vim.fn.substitute(vim.fn.system('uname -m'), '\n', '', '')
    end
    if not has_value({"armv6", "armv7", "i386", "x86_64"}, arch) then
      api.nvim_err_writeln("Architecture not supported/recognized!")
      return
    end
    format = "tar.gz"
  elseif os == "Windows" then
    arch = vim.fn.substitute(vim.fn.system('powershell -Command "$env:PROCESSOR_ARCHITECTURE"'), '\n', '', '')
    if arch == "AMD64" then arch = "x86_64" end
    if arch == "x86" then arch = "i386" end
    if arch == "ARM64" then arch = "armv6" end
    if not has_value({"armv6", "armv7", "i386", "x86_64"}, arch) then
      api.nvim_err_writeln("Architecture not supported/recognized!")
      return
    end
    format = "zip"
    path_separator = "\\"
  else
    api.nvim_err_writeln("OS not supported/recognized!")
    return
  end

  -- create the url based on os, arch, version and format
  local filename = "glow_" .. version .. "_" .. os .. "_" .. arch .. "." .. format
  local url = "https://github.com/charmbracelet/glow/releases/download/v" .. version .. "/" .. filename

  -- check if "GOPATH" is defined
  if vim.env.GOPATH == nil then
    api.nvim_err_writeln("GOPATH environment variable is not defined!")
    return
  else
    bin_path = vim.env.GOPATH .. path_separator .. "bin"
  end

  -- test if the download tool and the extractor tool are present
  -- if present, create the commands to download and extract
  if vim.fn.executable("curl") == 0 then
    api.nvim_err_writeln("cURL is not installed!")
    return
  else
    download_command = "curl -sL -o glow." .. format .. " " .. url
  end
  if format == "tar.gz" then
    if vim.fn.executable("tar") == 0 then
      api.nvim_err_writeln("tar is not installed!")
      return
    else
      extract_command = "tar -zxf glow.tar.gz -C " .. bin_path
    end
  elseif format == "zip" then
    if vim.fn.executable("unzip") == 0 then
      api.nvim_err_writeln("unzip is not installed!")
      return
    else
      extract_command = "unzip glow.zip -d " .. bin_path
    end
  end

  -- check for existing files / folders
  if vim.fn.isdirectory(bin_path) == 0 then
    vim.fn.mkdir(bin_path, "p")
  end
  if vim.fn.empty(vim.fn.glob(bin_path .. path_separator .. "glow")) ~= 1 then
    local success = vim.loop.fs_unlink(bin_path .. path_separator .. "glow")
    if not success then
      return api.nvim_err_writeln("Glow binary could not be removed!")
    end
  end
  if vim.fn.empty(vim.fn.glob("glow." .. format)) ~= 1 then
    local success = vim.loop.fs_unlink("glow." .. format)
    if not success then
      return api.nvim_err_writeln("Existing archive could not be removed!")
    end
  end

  -- download and install the glow binary
  vim.fn.system(download_command)
  vim.fn.system(extract_command)

  -- remove the archive after completion
  if vim.fn.empty(vim.fn.glob("glow." .. format)) ~= 1 then
    local success = vim.loop.fs_unlink("glow." .. format)
    if not success then
      return api.nvim_err_writeln("Existing archive could not be removed!")
    end
  end

  api.nvim_out_write("Glow installed successfully!\n")
end

function M.close_window()
  api.nvim_win_close(win, true)
end

function M.download_glow()
  if not vim.fn.executable("go") == 0 then
    api.nvim_err_writeln("golang not installed. Please provide it first")
  end

  if vim.fn.executable("glow") == 1 then
    local answer = vim.fn.input(
                     "latest glow already installed, do you want update? Y/n = ")
    answer = string.lower(answer)
    while answer ~= "y" and answer ~= "n" do
      answer = vim.fn.input("please answer Y or n = ")
      answer = string.lower(answer)
    end

    if answer == "n" then
      api.nvim_out_write("\n")
      return
    end
    api.nvim_out_write("updating glow..\n")
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

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = "shadow",
  }

  -- create preview buffer and set local options
  buf = api.nvim_create_buf(false, true)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_buf_set_keymap(buf, "n", "q", ":lua require('glow').close_window()<cr>",
                          {noremap = true, silent = true})
  api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":lua require('glow').close_window()<cr>",
                          {noremap = true, silent = true})

  -- set local options
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_win_set_option(win, "winblend", 0)
  vim.fn.termopen(string.format("glow %s", vim.fn.shellescape(path)))
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
