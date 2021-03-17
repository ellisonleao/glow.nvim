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
  -- check if file exists
  local ok, _, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return path
    end
    api.nvim_err_writeln("file does not exists")
    return
  end

  local ext = vim.fn.fnamemodify(path, ":e")
  if ext ~= "md" then
    api.nvim_err_writeln("glow only support markdown files")
    return
  end

  return path
end

local function call_go_command()
  local cmd = {"go", "get", "-u", "github.com/charmbracelet/glow"}
  vim.fn.jobstart(cmd, {
    on_exit = function(_, d, _)
      if d == 0 then
        api.nvim_out_write("latest glow installed")
        return
      end
      api.nvim_err_writeln("failed to install glow")
    end,
  })
end

function M.close_window()
  api.nvim_win_close(win, true)
end

function M.create_commands()
  vim.cmd("command! -nargs=? Glow :lua require('glow').glow('<f-args>')")
  vim.cmd("command! GlowInstall :lua require('glow').download_glow()")
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
  call_go_command()
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
  local title = vim.fn.fnamemodify(path, ":.")
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
  }
  local border_lines = {
    '┌' .. title .. string.rep('─', win_width - #title) .. '┐',
  }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for _ = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '└' .. string.rep('─', win_width) .. '┘')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
  api.nvim_open_win(border_buf, true, border_opts)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  -- create preview buffer and set local options
  buf = api.nvim_create_buf(false, true)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command("au BufWipeout <buffer> exe 'silent bwipeout! '" .. border_buf)
  api.nvim_buf_set_keymap(buf, "n", "q", ":lua require('glow').close_window()<cr>",
                          {noremap = true, silent = true})

  -- set local options
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_win_set_option(win, "winblend", 0)
  vim.fn.termopen(string.format("glow %s", vim.fn.shellescape(path)))
end

function M.glow(file)
  local path = validate(file)
  if path == nil then
    return
  end
  open_window(path)
end

return M
