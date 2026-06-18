require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    return {
      timeout_ms = 1000,
      lsp_fallback = false,
    }
  end,

  formatters = {
    frontmatter = {
      command = vim.fn.stdpath 'config' .. '/scripts/fmt-frontmatter',
      stdin = true,
    },
  },

  formatters_by_ft = {
    ['*'] = { 'trim_whitespace' },
    markdown = { 'frontmatter' }, -- normalize YAML frontmatter flow-lists -> block-lists
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>fmf', function()
  require('conform').format { async = true }
end, { desc = '[F]or[M]at [F]ile (buffer)' })
