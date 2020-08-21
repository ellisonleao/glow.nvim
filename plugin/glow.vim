if exists('g:loaded_glow') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo
set cpo&vim

command! Glow lua require('glow').glow()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_glow = 1
