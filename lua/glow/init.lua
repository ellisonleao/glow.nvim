local win, buf, job_id
local glow = {}

-- default configs
glow.config = {
  glow_path = vim.fn.exepath("glow"),
  install_path = vim.env.HOME .. "/.local/bin",
  border = "shadow",
  style = vim.o.background,
  mouse = false,
  pager = false,
  width = 100,
  height = 100,
}

local function close_window()
  vim.api.nvim_win_close(win, true)
end

local function tmp_file()
  local output = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  if vim.tbl_isempty(output) then
    vim.notify("buffer is empty", vim.log.levels.ERROR)
    return
  end
  local tmp = vim.fn.tempname() .. ".md"
  vim.fn.writefile(output, tmp)
  return tmp
end

local function stop_job()
  if job_id == nil then
    return
  end
  vim.fn.jobstop(job_id)
end

local function open_window(cmd, tmp)
  local width = vim.o.columns
  local height = vim.o.lines
  local win_height = math.ceil(height * 0.7)
  local win_width = math.ceil(width * 0.7)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  if glow.config.width and glow.config.width < win_width then
    win_width = glow.config.width
  end

  if glow.config.height and glow.config.height < win_height then
    win_height = glow.config.height
  end

  local win_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = glow.config.border,
  }

  -- create preview buffer and set local options
  buf = vim.api.nvim_create_buf(false, true)
  win = vim.api.nvim_open_win(buf, true, win_opts)

  -- options
  vim.api.nvim_win_set_option(win, "winblend", 0)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "glowpreview")

  -- keymaps
  local keymaps_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set("n", "q", close_window, keymaps_opts)
  vim.keymap.set("n", "<Esc>", close_window, keymaps_opts)

  local cbs = {
    on_exit = function()
      if tmp ~= nil then
        vim.fn.delete(tmp)
      end
    end,
  }
  job_id = vim.fn.termopen(cmd, cbs)

  if glow.config.pager then
    vim.cmd("startinsert")
  end
end

local function release_file_url()
  local os, arch
  local version = "1.4.1"

  -- check pre-existence of required programs
  if vim.fn.executable("curl") == 0 or vim.fn.executable("tar") == 0 then
    vim.notify("cURL and/or tar are required!")
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
    vim.notify("OS not supported")
    return ""
  end

  -- win install not supported for now
  if os == "Windows" then
    vim.notify("install script not supported on Windows yet. Please install glow manually")
    return ""
  end

  -- create the url, filename based on os, arch, version
  local filename = "glow_" .. version .. "_" .. os .. "_" .. arch .. ".tar.gz"
  return "https://github.com/charmbracelet/glow/releases/download/v" .. version .. "/" .. filename
end

local function execute(opts)
  local file, tmp
  if not vim.tbl_isempty(opts.fargs) then
    -- check file
    file = opts.fargs[1]
    if not vim.fn.filereadable(file) then
      vim.notify("error on reading file", vim.log.levels.ERROR)
      return
    end

    local ext = vim.fn.fnamemodify(file, ":e")
    local allowed_exts = { "md", "markdown", "mkd", "mkdn", "mdwn", "mdown", "mdtxt", "mdtext", "rmd" }
    if not vim.tbl_contains(allowed_exts, ext) then
      vim.notify("preview only works on markdown files", vim.log.levels.ERROR)
      return
    end
  else
    if vim.bo.filetype ~= "markdown" then
      vim.notify("preview only works on markdown files", vim.log.levels.ERROR)
      return
    end

    file = tmp_file()
    if file == nil then
      vim.notify("error on preview for current buffer", vim.log.levels.ERROR)
      return
    end
    tmp = file
  end

  stop_job()

  local cmd = { glow.config.glow_path, "-s " .. glow.config.style }

  if glow.config.pager then
    table.insert(cmd, "-p")
  end

  table.insert(cmd, file)
  cmd = table.concat(cmd, " ")
  open_window(cmd, tmp)
end

local function install_glow(opts)
  local release_url = release_file_url()
  if release_url == "" then
    return
  end

  local install_path = glow.config.install_path
  local download_command = { "curl", "-sL", "-o", "glow.tar.gz", release_url }
  local extract_command = { "tar", "-zxf", "glow.tar.gz", "-C", install_path }
  local output_filename = "glow.tar.gz"
  ---@diagnostic disable-next-line: missing-parameter
  local binary_path = vim.fn.expand(table.concat({ install_path, "glow" }, "/"))

  -- check for existing files / folders
  if vim.fn.isdirectory(install_path) == 0 then
    vim.loop.fs_mkdir(glow.config.install_path, tonumber("777", 8))
  end

  ---@diagnostic disable-next-line: missing-parameter
  if vim.fn.filereadable(binary_path) == 1 then
    local success = vim.loop.fs_unlink(binary_path)
    if not success then
      vim.notify("glow binary could not be removed!")
      return
    end
  end

  -- download and install the glow binary
  local callbacks = {
    on_sterr = vim.schedule_wrap(function(_, data, _)
      local out = table.concat(data, "\n")
      vim.notify(out)
    end),
    on_exit = vim.schedule_wrap(function()
      vim.fn.system(extract_command)
      -- remove the archive after completion
      if vim.fn.filereadable(output_filename) == 1 then
        local success = vim.loop.fs_unlink(output_filename)
        if not success then
          return vim.notify("existing archive could not be removed!")
        end
      end
      glow.config.glow_path = binary_path
      execute(opts)
    end),
  }
  vim.fn.jobstart(download_command, callbacks)
end

glow.setup = function(params)
  glow.config = vim.tbl_extend("force", {}, glow.config, params or {})
end

glow.execute = function(opts)
  local current_win = vim.fn.win_getid()
  if current_win == win then
    if opts.bang then
      close_window()
    end
    -- do nothing
    return
  end

  if vim.fn.executable("glow") == 0 then
    install_glow(opts)
    return
  end

  execute(opts)
end

return glow
