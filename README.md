<h1 align="center">
  <img src="https://i.postimg.cc/Y9Z030zC/glow-nvim.jpg" />
</h1>

<div align="center">
  <p>
    <strong>Preview markdown code directly in your neovim terminal</strong><br/>
    <small>Powered by charm's <a href="https://github.com/charmbracelet/glow">glow</a></small>
  </p>
  <img src="https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua" />
  <img src="https://img.shields.io/github/workflow/status/ellisonleao/glow.nvim/default?style=for-the-badge" />
</div>

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

## Setup

The script comes with the following defaults:

```lua
{
  glow_path = "", -- filled automatically with your glow bin in $PATH,
  border = "shadow", -- floating window border config
  style = "dark|light", -- filled automatically with your current editor background, you can override suing glow json style
  pager = false,
  width = 80,
}
```

To override the custom configuration, call:

```lua
require('glow').setup({
    -- your override config
})
```

Example:

```lua
require('glow').setup({
  style = "dark",
  width = 120,
})
```

## Usage

```
:GlowInstall
```

This will install the `glow` dependency into your config's `glow_install_path` or `$HOME/.local/bin` by default.

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

## Curiosities

For users who want to make glow.nvim buffer fullscreen, there's a native vim keybinding

- `Ctrl-w + |` set window's width max
- `Ctrl-w + _` set window's height max

Or you can have a fullscreen option by creating a mapping for setting both window's height and width max at once

```viml
noremap <C-w>z <C-w>\|<C-w>\_
```

## Screenshot

![](https://i.postimg.cc/rynmX2X8/glow.gif)
