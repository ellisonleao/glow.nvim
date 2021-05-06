glow.nvim
=========

A [glow](https://github.com/charmbracelet/glow) preview directly in your neovim buffer.

## Installing

**NOTE: This plugin requires Neovim 0.5 versions**

```
Plug 'npxbr/glow.nvim', {'do': ':GlowInstall','branch':'main'}
```

## Usage

```
:Glow [path-to-md-file]
```

- Pressing `q` will automatically close the window
- No path arg means glow uses current path in vim

You can also create a mapping getting a preview of the current file

```viml
nmap <leader>p :Glow<CR>
```

## Screenshot

[![glow.nvim](https://i.postimg.cc/y6GX34Mq/glow.gif)](https://postimg.cc/4nzhjM4w)
