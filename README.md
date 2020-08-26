glow.nvim
=========

A [glow](https://github.com/charmbracelet/glow) preview directly in your neovim buffer.

## Installing

```
Plug 'npxbr/glow.nvim', {'do': ':GlowInstall'}
```

## Usage

```
:Glow [path-to-md-file]
```

- Pressing `q` will automatically close the window
- No path arg means glow uses current path in vim

You can also create a mapping getting a preview of the current file

```viml
nnoremap <leader>p :Glow<CR>
```

## Screenshot

![](https://i.postimg.cc/L5cBB0tm/Screenshot-from-2020-08-26-01-50-31.png)
