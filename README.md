# glow.nvim

A [glow](https://github.com/charmbracelet/glow) preview directly in your neovim buffer.

## Installing

**NOTE: This plugin requires Neovim 0.5 versions**

with [vim-plug](https://github.com/junegunn/vim-plug)

```
Plug 'ellisonleao/glow.nvim', {'do': ':GlowInstall', 'branch': 'main'}
```

with [packer.nvim](https://github.com/wbthomason/packer.nvim)

```
use {"ellisonleao/glow.nvim", run = "GlowInstall"}
```

## Usage

```
:Glow [path-to-md-file]
```

- Pressing `q` will automatically close the window
- No path arg means glow uses current path in vim
- `:Glow` command will work as toogle feature, so calling it will open or close the current preview

You can also create a mapping getting a preview of the current file

```viml
noremap <leader>p :Glow<CR>
```

## Screenshot

![](https://i.postimg.cc/rynmX2X8/glow.gif)
