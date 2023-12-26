---@type string tmp file path
local tmpfile

---@alias StateType 'preview' | 'keep' | 'split'
local types = { "preview", "keep", "split" }

--- @class State
--- @field type StateType type of window.
--- @field input integer original buffer number to restore after Glow is closed.
--- @field copy integer buffer containing original text not modifiable to be used to show original text in Glow.
--- @field output integer buffer containing formatted output from Glow.
--- @field old_winbar string user defined winbar to be restored after Glow is closed.
local in_place_state = {}

local job = {}

-- types
---@alias border 'shadow' | 'none' | 'double' | 'rounded' | 'solid' | 'single' | 'rounded'
---@alias style 'dark' | 'light'

---@class Glow
local glow = {}

---@class Config
---@field glow_path string glow executable path
---@field install_path string glow binary installation path
---@field border border floating window border style
---@field style style floating window style
---@field pager boolean display output in pager style
---@field width integer floating window width
---@field height integer floating window height
-- default configurations
local config = {
  glow_path = vim.fn.exepath("glow"),
  install_path = vim.env.HOME .. "/.local/bin",
  border = "shadow",
  style = vim.o.background,
  pager = false,
  width = 100,
  height = 100,
  default_type = types[1], -- one of preview, keep, split
  split_dir = "vsplit",
  winbar = true,
  winbar_text = "%#Error#%=GLOW%=", -- `:h 'statusline'`
  mappings = {
    close = { "<Esc>", "q" }, -- to close Glow
    toggle = { "p" }, -- to toggle between input buffer and glow output in a Glow window
  },
}

-- default configs
glow.config = config

local function cleanup()
  if tmpfile ~= nil then
    vim.fn.delete(tmpfile)
  end
end

local function err(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "glow" })
end

local function safe_close(h)
  if not h:is_closing() then
    h:close()
  end
end

local function stop_job()
  if job == nil then
    return
  end
  if not job.stdout == nil then
    job.stdout:read_stop()
    safe_close(job.stdout)
  end
  if not job.stderr == nil then
    job.stderr:read_stop()
    safe_close(job.stderr)
  end
  if not job.handle == nil then
    safe_close(job.handle)
  end
  job = nil
end

local function close_window()
  local to_close_win = vim.fn.win_getid()
  if not to_close_win then return end
  local managed = in_place_state[to_close_win]
  -- Exit if trying to close from original buffer's window when in preview or split mode
  if not managed then return end

  stop_job()
  cleanup()

  in_place_state[to_close_win] = nil

  if managed.type ~= "keep" then -- It was a split window or a preview window so close it
    vim.api.nvim_win_close(to_close_win, true)
  else
    vim.api.nvim_win_set_buf(to_close_win, managed.input) -- restore previous buffer don't close
    vim.api.nvim_win_set_option(to_close_win, "winbar", managed.old_winbar) -- restore winbar
  end

  -- Completely remove glow output and input copy from buffer list
  pcall(vim.cmd.silent, "bwipe! " .. managed.output)
  pcall(vim.cmd.silent, "bwipe! " .. managed.copy)
end

---@return string
local function tmp_file()
  local output = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  if vim.tbl_isempty(output) then
    err("buffer is empty")
    return ""
  end
  local tmp = vim.fn.tempname() .. ".md"
  vim.fn.writefile(output, tmp)
  return tmp
end

local function toggle()
  local curr_win = vim.fn.win_getid()
  if not curr_win then return end
  local curr_buf = vim.fn.bufnr()
  local state = in_place_state[curr_win]
  -- Don't try to toggle from original buffer's window if in preview or split mode
  if not state then return end

  -- Buffer we will toggle to
  local other_buf = curr_buf == state.copy and state.output or state.copy
  vim.api.nvim_win_set_buf(curr_win, other_buf) -- toggle to the other buffer

  -- Keep the winbar after
  vim.api.nvim_win_set_option(curr_win, "winbar", glow.config.winbar_text)
end

local function set_state(win, type, input_buf, input_win, copy, glow_buf)
  in_place_state[win] = {
    type = type,
    input = input_buf,
    copy = copy,
    output = glow_buf,
    old_winbar = vim.api.nvim_win_get_option(input_win, "winbar"),
  }
end

local function duplicate_buf(buf)
  local out = vim.api.nvim_create_buf(false, true)
  local input_text = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  vim.api.nvim_buf_set_lines(out, 0, -1, true, input_text)
  vim.api.nvim_buf_set_option(out, "modifiable", false)
  vim.api.nvim_buf_set_option(out, "filetype", vim.api.nvim_buf_get_option(buf, "ft"))
  return out
end

---@param cmd_args table glow command arguments
---@param type string preview|split|keep
local function open_window(cmd_args, type)
  local width = vim.o.columns
  local height = vim.o.lines
  local height_ratio = glow.config.height_ratio or 0.7
  local width_ratio = glow.config.width_ratio or 0.7
  local win_height = math.ceil(height * height_ratio)
  local win_width = math.ceil(width * width_ratio)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  if glow.config.width and glow.config.width < win_width then
    win_width = glow.config.width
  end

  if glow.config.height and glow.config.height < win_height then
    win_height = glow.config.height
  end

  -- pass through calculated window width
  table.insert(cmd_args, "-w")
  table.insert(cmd_args, win_width)

  local win_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = glow.config.border,
  }

  -- Get origin coordinates to pass to set_state
  local orig_buf = vim.fn.bufnr()
  local orig_win = vim.fn.win_getid()
  -- Duplicate input buffer to use for toggling to input text
  local copy_buf = duplicate_buf(orig_buf)

  -- create preview buffer and set local options
  local buf = vim.api.nvim_create_buf(false, true)

  if type == "split" then
    vim.cmd(glow.config.split_dir) -- Create split (hor or vert based on config)
    local split_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(split_win, buf)
    set_state(split_win, type, orig_buf, orig_win, copy_buf, buf)
    vim.api.nvim_win_set_option(split_win, "winblend", 0)
  elseif type == "keep" then
    orig_win = vim.api.nvim_get_current_win()
    set_state(orig_win, type, orig_buf, orig_win, copy_buf, buf)
    vim.api.nvim_win_set_buf(orig_win, buf)
  elseif type == "preview" then
    local new_win = vim.api.nvim_open_win(buf, true, win_opts)
    set_state(new_win, type, orig_buf, orig_win, copy_buf, buf)
    vim.api.nvim_win_set_option(new_win, "winblend", 0)
  else
    err("Invalid type")
    return
  end

  -- options
  vim.api.nvim_buf_set_option(buf, "filetype", "glowpreview")
  if glow.config.winbar then
    vim.api.nvim_win_set_option(0, "winbar", glow.config.winbar_text)
  end

  -- keymaps
  for _, b in ipairs({ copy_buf, buf }) do
    local keymaps_opts = { silent = true, buffer = b }
    local dict = { toggle = toggle, close = close_window }
    for group, fn in pairs(dict) do
      for _, rhs in ipairs(glow.config.mappings[group]) do
        vim.keymap.set("n", rhs, fn, keymaps_opts)
      end
    end
  end

  -- term to receive data
  local chan = vim.api.nvim_open_term(buf, {})

  -- callback for handling output from process
  local function on_output(e, data)
    if e then
      -- what should we really do here?
      err(vim.inspect(e))
    end
    if data then
      local lines = vim.split(data, "\n", {})
      for _, d in ipairs(lines) do
        vim.api.nvim_chan_send(chan, d .. "\r\n")
      end
    end
  end

  -- setup pipes
  job = {}
  job.stdout = vim.loop.new_pipe(false)
  job.stderr = vim.loop.new_pipe(false)

  -- callback when process completes
  local function on_exit()
    stop_job()
    cleanup()
  end

  -- setup and kickoff process
  local cmd = table.remove(cmd_args, 1)
  local job_opts = {
    args = cmd_args,
    stdio = { nil, job.stdout, job.stderr },
  }

  job.handle = vim.loop.spawn(cmd, job_opts, vim.schedule_wrap(on_exit))
  vim.loop.read_start(job.stdout, vim.schedule_wrap(on_output))
  vim.loop.read_start(job.stderr, vim.schedule_wrap(on_output))

  if glow.config.pager then
    vim.cmd("startinsert")
  end
end

---@return string
local function release_file_url()
  local os, arch
  local version = "1.5.1"

  -- check pre-existence of required programs
  if vim.fn.executable("curl") == 0 or vim.fn.executable("tar") == 0 then
    err("curl and/or tar are required")
    return ""
  end

  -- local raw_os = jit.os
  local raw_os = vim.loop.os_uname().sysname
  local raw_arch = jit.arch
  local os_patterns = {
    ["Windows"] = "Windows",
    ["Windows_NT"] = "Windows",
    ["Linux"] = "Linux",
    ["Darwin"] = "Darwin",
    ["BSD"] = "Freebsd",
  }

  local arch_patterns = {
    ["x86"] = "i386",
    ["x64"] = "x86_64",
    ["arm"] = "arm7",
    ["arm64"] = "arm64",
  }

  os = os_patterns[raw_os]
  arch = arch_patterns[raw_arch]

  if os == nil or arch == nil then
    err("os not supported or could not be parsed")
    return ""
  end

  -- create the url, filename based on os and arch
  local filename = "glow_" .. os .. "_" .. arch .. (os == "Windows" and ".zip" or ".tar.gz")
  return "https://github.com/charmbracelet/glow/releases/download/v" .. version .. "/" .. filename
end

---@return boolean
local function is_md_ft()
  local allowed_fts = { "markdown", "markdown.pandoc", "markdown.gfm", "wiki", "vimwiki", "telekasten" }
  if not vim.tbl_contains(allowed_fts, vim.bo.filetype) then
    return false
  end
  return true
end

---@return boolean
local function is_md_ext(ext)
  local allowed_exts = { "md", "markdown", "mkd", "mkdn", "mdwn", "mdown", "mdtxt", "mdtext", "rmd", "wiki" }
  if not vim.tbl_contains(allowed_exts, string.lower(ext)) then
    return false
  end
  return true
end

local function run(opts)
  local file

  -- check if glow binary is valid even if filled in config
  if vim.fn.executable(glow.config.glow_path) == 0 then
    err(
      string.format(
        "could not execute glow binary in path=%s . make sure you have the right config",
        glow.config.glow_path
      )
    )
    return
  end

  -- Reorder arguments first is file|nil and second is preview|split|keep|nil
  if vim.tbl_contains(types, opts.fargs[1]) then
    local arg1 = opts.fargs[1] -- Save because line below will overwrite
    opts.fargs[1] = opts.fargs[2] -- `Glow split` | `Glow split file.md` -> `nil` | `file.md`
    opts.fargs[2] = arg1 -- Becomes preview|keep|split
  end

  local filename = opts.fargs[1]

  if filename ~= nil and filename ~= "" then
    -- check file
    file = opts.fargs[1]
    if not vim.fn.filereadable(file) then
      err("error on reading file")
      return
    end

    local ext = vim.fn.fnamemodify(file, ":e")
    if not is_md_ext(ext) then
      err("preview only works on markdown files")
      return
    end
  else
    if not is_md_ft() then
      err("preview only works on markdown files")
      return
    end

    file = tmp_file()
    if file == nil then
      err("error on preview for current buffer")
      return
    end
    tmpfile = file
  end

  stop_job()

  local cmd_args = { glow.config.glow_path, "-s", glow.config.style }

  if glow.config.pager then
    table.insert(cmd_args, "-p")
  end

  table.insert(cmd_args, file)
  open_window(cmd_args, opts.fargs[2] or glow.config.default_type)
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
      err("glow binary could not be removed!")
      return
    end
  end

  -- download and install the glow binary
  local callbacks = {
    on_sterr = vim.schedule_wrap(function(_, data, _)
      local out = table.concat(data, "\n")
      err(out)
    end),
    on_exit = vim.schedule_wrap(function()
      vim.fn.system(extract_command)
      -- remove the archive after completion
      if vim.fn.filereadable(output_filename) == 1 then
        local success = vim.loop.fs_unlink(output_filename)
        if not success then
          err("existing archive could not be removed")
          return
        end
      end
      glow.config.glow_path = binary_path
      run(opts)
    end),
  }
  vim.fn.jobstart(download_command, callbacks)
end

---@return string
local function get_executable()
  if glow.config.glow_path ~= "" then
    return glow.config.glow_path
  end

  return vim.fn.exepath("glow")
end

local function create_autocmds()
  vim.api.nvim_create_user_command("Glow", function(opts)
    glow.execute(opts)
  end, { complete = "file", nargs = "*", bang = true })
end

---@param params Config? custom config
glow.setup = function(params)
  glow.config = vim.tbl_extend("force", {}, glow.config, params or {})
  create_autocmds()
end

glow.execute = function(opts)
  if vim.version().minor < 8 then
    vim.notify_once("glow.nvim: you must use neovim 0.8 or higher", vim.log.levels.ERROR)
    return
  end

  if in_place_state[vim.fn.win_getid()] then
    if opts.bang then
      close_window()
    end
    -- do nothing
    return
  end

  if get_executable() == "" then
    install_glow(opts)
    return
  end

  run(opts)
end

return glow
