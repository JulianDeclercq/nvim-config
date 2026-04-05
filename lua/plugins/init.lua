local function gh(repo)
  return 'https://github.com/' .. repo
end

-- Post-install/update hook: build telescope-fzf-native
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
      local path = vim.fn.stdpath 'data' .. '/site/pack/core/opt/telescope-fzf-native.nvim'
      vim.fn.system { 'make', '-C', path }
    end
  end,
})

-- Plugins
vim.pack.add {
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
  gh 'tomasky/bookmarks.nvim',
  gh 'JulianDeclercq/obsidian-cli.nvim',
}

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
