local api = vim.api
local win, buf

local function set_mappings()
  local mappings = {q = 'close_window()'}

  for key, val in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, "n", key, ":lua require('glow')." .. val .. "<cr>",
                            {nowait = true; noremap = true; silent = true})
  end
end

local function close_term_buffers()
  local range = vim.fn.range
  local bufnr = vim.fn.bufnr

  for _, v in ipairs(range(1, bufnr("$"))) do
    if vim.api.nvim_buf_is_loaded(v) then
      local buftype = vim.api.nvim_buf_get_option(v, "buftype")
      if buftype == "terminal" then
        api.nvim_command("bd! " .. v)
      end
    end
  end

end

local function close_window()
  api.nvim_win_close(win, true)
  close_term_buffers()
end

local function validate(path)
  -- trim and get the full path
  path = string.gsub(path, "%s+", "")
  path = path == "" and "%" or path
  path = vim.fn.expand(path)

  -- check if file exists
  local ok, _, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
    error("file does not exists")
  end

  return ok
end

local function download_glow()
  vim.cmd("silent !go get github.com/charmbracelet/glow")
  print("glow installed!")
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

  -- BORDERS
  -- local border_buf = api.nvim_create_buf(false, true)
  -- local border_opts = {
  --   style = "minimal";
  --   relative = "editor";
  --   width = win_width + 2;
  --   height = win_height + 2;
  --   row = row - 1;
  --   col = col - 1;
  -- }
  -- local border_lines = {'╔' .. string.rep('═', win_width) .. '╗'}
  -- local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  -- for _ = 1, win_height do
  --   table.insert(border_lines, middle_line)
  -- end
  -- table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  -- api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
  -- api.nvim_open_win(border_buf, true, border_opts)

  local opts = {
    style = "minimal";
    relative = "editor";
    width = win_width;
    height = win_height;
    row = row;
    col = col;
  }

  -- create preview buffer and set local options
  buf = api.nvim_create_buf(false, true)

  -- main floating window buffer
  win = api.nvim_open_win(buf, true, opts)

  -- set local options
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_win_set_option(win, "winblend", 0)
  vim.fn.termopen(string.format("glow %s", path))
end

-- exporting functions
local M = {
  glow = function(file)
    validate(file)
    open_window(file)
    set_mappings()
  end;
  close_window = close_window;
  download_glow = download_glow;
}

return M
