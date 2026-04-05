require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    return {
      timeout_ms = 1000,
      lsp_fallback = false,
    }
  end,

  formatters_by_ft = {
    ['*'] = { 'trim_whitespace' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>fmf', function()
  require('conform').format { async = true }
end, { desc = '[F]or[M]at [F]ile (buffer)' })
