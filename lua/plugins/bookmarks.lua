local bm = require 'bookmarks'
bm.setup()
vim.keymap.set('n', '<leader>bmt', bm.bookmark_toggle, { desc = '[B]ook[m]ark [T]oggle' })
vim.keymap.set('n', '<leader>bmda', bm.bookmark_clear_all, { desc = '[B]ook[m]ark [D]elete [A]ll' })
