return {
  'f-person/git-blame.nvim',
  event = 'VeryLazy',
  opts = {
    enabled = false, -- disable by default
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
