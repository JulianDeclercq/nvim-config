return {
  'f-person/git-blame.nvim',
  event = 'VeryLazy',
  opts = {
    enabled = true,
    message_template = ' <summary> * <date> * <author> * <<sha>> ',
    date_format = '%d-%m-%Y',
  },
  keys = {
    {
      '<leader>gb',
      '<Cmd>GitBlameToggle<CR>',
      desc = '[G]it [B]lame',
    },
  },
}
