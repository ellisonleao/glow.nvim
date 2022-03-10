set rtp+=.
set rtp+=vendor/plenary.nvim

runtime plugin/plenary.vim
runtime plugin/glow.lua

lua require('plenary.busted')
