## Neovim config
Originally started as a fork from [kickstart](https://github.com/nvim-lua/kickstart.nvim).

## Installing Neovim
### Neovim itself
['stable'](https://github.com/neovim/neovim/releases/tag/stable)

### Install External Dependencies
External Requirements:
- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation)
- Clipboard tool (xclip/xsel/win32yank or other depending on the platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true

> [!NOTE]
> See [Install Recipes](#Install-Recipes) for additional Windows specific notes and quick install snippets

### Installation
Neovim's configurations are located under the following paths, depending on your OS:

| OS | PATH |
| :- | :--- |
| Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| Windows (cmd)| `%localappdata%\nvim\` |
| Windows (powershell)| `$env:LOCALAPPDATA\nvim\` |

#### Clone the repo
<details><summary> Linux and Mac </summary>

```
git clone git@github.com:JulianDeclercq/nvim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

</details>

<details><summary> Windows </summary>
If you're using `cmd.exe`:

```
git clone git@github.com:JulianDeclercq/nvim-config.git "%localappdata%\nvim"
```

If you're using `powershell.exe`

```
git clone git@github.com:JulianDeclercq/nvim-config.git "${env:LOCALAPPDATA}\nvim"
```

</details>

### Uninstalling
See [lazy.nvim uninstall](https://lazy.folke.io/usage#-uninstalling) information

### Install Recipes
#### Windows Installation

<details><summary>Windows with Microsoft C++ Build Tools and CMake</summary>
Installation may require installing build tools and updating the run command for `telescope-fzf-native`

See `telescope-fzf-native` documentation for [more details](https://github.com/nvim-telescope/telescope-fzf-native.nvim#installation)

This requires:
- Install CMake and the Microsoft C++ Build Tools on Windows

```lua
{'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }
```
</details>
<details><summary>Windows with gcc/make using chocolatey</summary>
Alternatively, one can install gcc and make which don't require changing the config,
the easiest way is to use choco:

1. install [chocolatey](https://chocolatey.org/install)
either follow the instructions on the page or use winget,
run in cmd as **admin**:
```
winget install --accept-source-agreements chocolatey.chocolatey
```

2. install all requirements using choco, exit the previous cmd and
open a new one so that choco path is set, and run in cmd as **admin**:
```
choco install -y neovim git ripgrep wget fd unzip gzip mingw make
```
</details>
