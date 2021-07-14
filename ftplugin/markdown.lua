-- create commands
vim.cmd("command! -nargs=? -complete=file Glow :lua require('glow').glow('<f-args>')")
vim.cmd("command! GlowInstall :lua require('glow').download_glow()")
