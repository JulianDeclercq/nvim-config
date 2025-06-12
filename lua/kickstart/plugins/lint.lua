-- since prettier is a formatter, not a linter, that's handled by 'stevearc/conform.nvim'
return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- configure diagnostics display
      vim.diagnostic.config {
        signs = true,
        underline = true,
        update_in_insert = false,
        virtual_text = false,
        severity_sort = true,
      }

      local lint = require 'lint'

      -- explicitly load the built-in linters
      lint.linters.eslint = require 'lint.linters.eslint'
      lint.linters.stylelint = require 'lint.linters.stylelint'

      -- filetypes → linters
      lint.linters_by_ft = {
        -- JavaScript / TypeScript
        typescript = { 'eslint' },
        typescriptreact = { 'eslint' },
        javascript = { 'eslint' },
        javascriptreact = { 'eslint' },

        -- Stylesheets
        css = { 'stylelint' },
        scss = { 'stylelint' },
        less = { 'stylelint' },

        -- Markup / Single-file components
        html = { 'eslint', 'stylelint' },

        -- Lua
        lua = { 'luacheck' },
      }

      -- lint on save
      vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },
}
