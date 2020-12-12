" prevent loading file twice
if exists("g:loaded_glow")
  finish
endif

lua require("glow").create_commands()

let g:loaded_glow = 1
