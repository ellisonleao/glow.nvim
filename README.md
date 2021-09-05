# glow.nvim

A [glow](https://github.com/charmbracelet/glow) preview directly in your neovim buffer.

## Prerequisites

- Neovim 0.5 or higher

## Installing

with [vim-plug](https://github.com/junegunn/vim-plug)

```
Plug 'ellisonleao/glow.nvim'
```

with [packer.nvim](https://github.com/wbthomason/packer.nvim)

```
use {"ellisonleao/glow.nvim"}
```

## Configuration

- Binary path

This config will be used to set where the `glow` binary is installed if already available in `$PATH`. Same path will be
used if you need to download it

Use `g:glow_binary_path` for vimscript config or `vim.g.glow_binary_path` for lua config. Example:

```viml
let g:glow_binary_path = $HOME . "/bin"
```

```lua
vim.g.glow_binary_path = vim.env.HOME .. "/bin"
```

If no config is available, the default path will be `$HOME/.local/bin` . Make sure to add it into `$PATH` if that's the
case.

## Usage

```
:GlowInstall
```

This will install the `glow` dependency into `g:glow_binary_path` or `$HOME/.local/bin` if not defined.

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

For users who want to make glow.nvim buffer fullscreen, there's a native vim keybinding

- `Ctrl-w + |` set window's width max
- `Ctrl-w + _` set window's height max

Or you can have a fullscreen option by creating a mapping for setting both window's height and width max at once

```viml
noremap <C-w>z <C-w>\|<C-w>\_
```

## Screenshot

![](https://i.postimg.cc/rynmX2X8/glow.gif)
