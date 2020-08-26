" prevent loading file twice
if exists("g:loaded_glow")
  finish
endif

command! -nargs=? Glow :lua require("glow").glow("<args>")
command! GlowInstall :lua require("glow").download_glow()

let g:loaded_glow = 1
