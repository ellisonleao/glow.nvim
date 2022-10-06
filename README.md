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

https://user-images.githubusercontent.com/178641/179131739-36ca2225-9a9e-4894-924e-9e03211c0886.mp4

**Breaking changes are now moved to a fixed topic in Discussions. [Click here](https://github.com/ellisonleao/glow.nvim/discussions/77) to see them**

## Prerequisites

- Neovim 0.7+

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
  install_path = "~/.local/bin", -- default path for installing glow binary
  border = "shadow", -- floating window border config
  style = "dark|light", -- filled automatically with your current editor background, you can override using glow json style
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

### Preview file

```
:Glow [path-to-md-file]
```

### Preview current buffer

```
:Glow
```

### Close window

```
:Glow!
```

You can also close the floating window using `q` or `<Esc>` keys
