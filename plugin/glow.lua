-- create install cmd
vim.cmd("command! GlowInstall :lua require('glow').download_glow()")
vim.cmd("command! -nargs=? -complete=file Glow :lua require('glow').glow('<f-args>')")
vim.cmd("command! -nargs=1 GlowString lua require('glow').glow_string('<args>')")
