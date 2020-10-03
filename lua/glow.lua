local api = vim.api
local win, buf

local function set_mappings()
  local mappings = {q = 'close_window()'}

  for key, val in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, "n", key, ":lua require('glow')." .. val .. "<cr>",
                            {nowait = true; noremap = true; silent = true})
  end
end

local function close_window()
  api.nvim_win_close(win, true)
end

local function validate(path)
  -- trim and get the full path
  path = string.gsub(path, "%s+", "")
  path = path == "" and "%" or path
  path = api.nvim_call_function("expand", {path})
  path = api.nvim_call_function("fnamemodify", {path; ":p"})

  -- check if file exists
  local ok, _, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return path
    end
    error("file does not exists")
  end

  return path
end

local function download_glow()
  if not api.nvim_call_function("executable", {"go"}) then
    error("golang not installed. Please provide it first")
  end

  if api.nvim_call_function("executable", {"glow"}) then
    return
  end
  api.nvim_call_function("system", {"go get github.com/charmbracelet/glow"})
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
  local border_buf = api.nvim_create_buf(false, true)
  local title = api.nvim_call_function("fnamemodify", {path; ":."})
  local border_opts = {
    style = "minimal";
    relative = "editor";
    width = win_width + 2;
    height = win_height + 2;
    row = row - 1;
    col = col - 1;
  }
  local border_lines = {
    '┌' .. title .. string.rep('─', win_width - #title) .. '┐';
  }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for _ = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '└' .. string.rep('─', win_width) .. '┘')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
  api.nvim_open_win(border_buf, true, border_opts)

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
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command("au BufWipeout <buffer> exe 'silent bwipeout! '" .. border_buf)

  -- set local options
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_win_set_option(win, "winblend", 0)
  api.nvim_call_function("termopen", {string.format("glow '%s'", path)})
end

-- exporting functions
local M = {
  glow = function(file)
    local path = validate(file)
    open_window(path)
    set_mappings()
  end;
  close_window = close_window;
  download_glow = download_glow;
}

return M
