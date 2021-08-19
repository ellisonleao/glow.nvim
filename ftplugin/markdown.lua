-- create commands
vim.cmd("command! -nargs=? -complete=file Glow :lua require('glow').glow('<f-args>')")
