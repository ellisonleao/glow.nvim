local api = vim.api
local buf
local M = {}

-- title sets the window title
local function title(str)
  local width = api.nvim_win_get_width(0)
  local text_pos = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(" ", text_pos) .. str
end

-- glow grabs glow command results
-- local function glow() end

-- open_window draws a custom window with the markdown contents
local function open_window()
  buf = vim.api.nvim_create_buf(false, true)
  local border_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'glow')

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal";
    relative = "editor";
    width = win_width + 2;
    height = win_height + 2;
    row = row - 1;
    col = col - 1;
  }

  local opts = {
    style = "minimal";
    relative = "editor";
    width = win_width;
    height = win_height;
    row = row;
    col = col;
  }

  local border_lines = {'╔' .. string.rep('═', win_width) .. '╗'}
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  vim.api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)

  api.nvim_buf_set_lines(buf, 0, -1, false, {title('Hello world!'); ''; ''})
end

M.preview = function()
  open_window()
end

return M
