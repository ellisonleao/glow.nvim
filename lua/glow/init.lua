local api = vim.api
local uv = vim.loop
local win, buf
local utils = require("glow.utils")
local M = {}

-- default configs
M.config = {
  glow_path = vim.fn.exepath("glow"),
  glow_install_path = vim.env.HOME .. "/.local/bin",
  border = "shadow",
  style = vim.o.background,
  mouse = false,
  pager = false,
  width = 80,
}

local function install_glow()
  local release_url = utils.release_file_url()
  local install_path = M.config.glow_install_path
  local download_command = { "curl", "-sL", "-o", "glow.tar.gz", release_url }
  local extract_command = { "tar", "-zxf", "glow.tar.gz", "-C", install_path }
  local output_filename = "glow.tar.gz"
  local binary_path = install_path .. "/glow"

  -- check for existing files / folders
  if vim.fn.isdirectory(install_path) == 0 then
    uv.fs_mkdir(M.config.install_path, "p")
  end

  if vim.fn.empty(vim.fn.expand(binary_path)) ~= 1 then
    local success = uv.fs_unlink(binary_path)
    if not success then
      return utils.msg("glow binary could not be removed!")
    end
  end

  -- download and install the glow binary
  local callbacks = {
    on_sterr = vim.schedule_wrap(function(_, data, _)
      local out = table.concat(data, "\n")
      utils.msg(out)
    end),
    on_exit = vim.schedule_wrap(function()
      vim.fn.system(extract_command)
      -- remove the archive after completion
      if vim.fn.empty(output_filename) ~= 1 then
        local success = uv.fs_unlink(output_filename)
        if not success then
          return utils.msg("existing archive could not be removed!")
        end
      end
      print("glow installed successfully!")
      M.config.glow_path = vim.fn.exepath("glow")
    end),
  }
  vim.fn.jobstart(download_command, callbacks)
end

M.setup = function(params)
  M.config = vim.tbl_extend("force", {}, M.config, params or {})
end

local function close_window()
  local current_win = vim.fn.win_getid()
  if current_win == win then
    api.nvim_win_close(win, true)
  end
end

-- open_window draws a custom window with the markdown contents
local function open_window(cmd)
  local width = vim.o.columns
  local height = vim.o.lines
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  if M.config.width and M.config.width < win_width then
    win_width = M.config.width
  end

  local win_opts = {
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
  win = api.nvim_open_win(buf, true, win_opts)

  -- options
  api.nvim_win_set_option(win, "winblend", 0)
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "filetype", "glowpreview")

  -- keymaps
  local keymaps_opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set("n", "q", M.close_window, keymaps_opts)
  vim.keymap.set("n", "<Esc>", M.close_window(), keymaps_opts)
  vim.fn.termopen(cmd)

  if M.config.pager then
    vim.cmd("startinsert")
  end
end

M.glow = function(opts)
  if opts.bang then
    close_window()
  end

  local cmd = utils.get_glow_cmd(opts.fargs)
  open_window(cmd)
end

return M
