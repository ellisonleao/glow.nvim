if exists('g:loaded_glow')
  finish
endif " prevent loading file twice

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=1 Glow :lua require('glow').glow("<args>")
command! GlowInstall :lua require('glow').download_glow()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_glow = 1
