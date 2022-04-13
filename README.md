# glow.nvim

A [glow](https://github.com/charmbracelet/glow) preview directly in your neovim buffer.

## Prerequisites

- Neovim 0.5 or higher

## Installing

with [vim-plug](https://github.com/junegunn/vim-plug)

```
Plug 'ellisonleao/glow.nvim', {'branch': 'main'}
```

with [packer.nvim](https://github.com/wbthomason/packer.nvim)

```
use {"ellisonleao/glow.nvim", branch = 'main'}
```

## Configuration

- `glow_binary_path`

Use `g:glow_binary_path` for vimscript config or `vim.g.glow_binary_path` for lua config.

If set, this path will be used to execute `glow`. Otherwise rely on `$PATH`.

If `glow` is not on `$PATH` or `glow_binary_path` is set and `glow` is not found
there, this path will be used to download the `glow` executable. It defaults to `$HOME/.local/bin`.

Example:

```viml
let g:glow_binary_path = $HOME . "/bin"
```

```lua
vim.g.glow_binary_path = vim.env.HOME .. "/bin"
```

- `glow_border`

Use `g:glow_border` for vimscript config or `vim.g.glow_border` for lua config.

If set, this will change the border of the window. Type `:help nvim_open_win` for border options.

Example:

```viml
let g:glow_border = "rounded"
```

```lua
vim.g.glow_border = "rounded"
```

- `glow_width`

Use `g:glow_width` for vimscript config or `vim.g.glow_width` for lua config.

If set, this will change the width of the window.

Example:

```viml
let g:glow_width = 120
```

```lua
vim.g.glow_width = 120
```

- `glow_use_pager`

Use `g:glow_use_pager` for vimscript config or `vim.g.glow_use_pager` for lua config.

If set true, `glow` uses the pager to show the doc.

Example:

```viml
let g:glow_use_pager = v:true
```

```lua
vim.g.glow_use_pager = true
```

- `glow_style`

Use `g:glow_style` for vimscript config or `vim.g.glow_style` for lua config.

If set, this will change the output style to either `dark` (default) or `light`.

Example:

```viml
let g:glow_style = "light"
```

```lua
vim.g.glow_style = "light"
```
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
