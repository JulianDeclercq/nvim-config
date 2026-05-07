local function gh(repo)
  return 'https://github.com/' .. repo
end

-- Post-install/update hook: build telescope-fzf-native
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name ~= 'telescope-fzf-native.nvim' then return end
    local path = vim.fn.stdpath 'data' .. '/site/pack/core/opt/telescope-fzf-native.nvim'
    if vim.fn.has 'win32' == 1 then
      if vim.fn.executable 'cmake' ~= 1 then
        vim.notify('telescope-fzf-native: cmake not found, native sorter not built', vim.log.levels.WARN)
        return
      end
      vim.fn.system { 'cmake', '-S', path, '-B', path .. '/build', '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release' }
      vim.fn.system { 'cmake', '--build', path .. '/build', '--config', 'Release' }
      vim.fn.system { 'cmake', '--install', path .. '/build', '--prefix', path .. '/build' }
    else
      if vim.fn.executable 'make' ~= 1 then
        vim.notify('telescope-fzf-native: make not found, native sorter not built', vim.log.levels.WARN)
        return
      end
      vim.fn.system { 'make', '-C', path }
    end
  end,
})

-- Plugins
local specs = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-tree/nvim-web-devicons',
  gh 'folke/tokyonight.nvim',
  gh 'rcarriga/nvim-notify',
  gh 'tpope/vim-sleuth',
  gh 'tpope/vim-surround',
  gh 'tpope/vim-commentary',
  gh 'lewis6991/gitsigns.nvim',
  gh 'folke/which-key.nvim',
  gh 'folke/todo-comments.nvim',
  gh 'echasnovski/mini.nvim',
  gh 'windwp/nvim-autopairs',
  gh 'vuciv/golf',
  gh 'stevearc/conform.nvim', -- Formatting (trim whitespace on save)
  gh 'L3MON4D3/LuaSnip',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-fzf-native.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
  gh 'benfowler/telescope-luasnip.nvim',
}

-- Prefer local dev copy if present, else fall back to GitHub fork
local function local_or_gh(local_path, gh_repo)
  if vim.fn.isdirectory(local_path) == 1 then
    vim.opt.rtp:prepend(local_path)
  else
    table.insert(specs, gh(gh_repo))
  end
end

local_or_gh('C:/Repositories/obsidian-cli.nvim', 'JulianDeclercq/obsidian-cli.nvim')
local_or_gh('C:/Repositories/bookmarks.nvim', 'JulianDeclercq/bookmarks.nvim')

vim.pack.add(specs)


-- Plugin configurations (order matters: colorscheme first, then UI, then the rest)
require('plugins.tokyonight')
require('plugins.notify')
require('plugins.gitsigns')
require('plugins.which-key')
require('plugins.todo-comments')
require('plugins.mini')
require('plugins.autopairs')
require('plugins.conform')
require('plugins.luasnip')
require('plugins.telescope')
require('plugins.bookmarks')
require('plugins.obsidian')
