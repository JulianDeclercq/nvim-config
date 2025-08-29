return {
  'tomasky/bookmarks.nvim',
  dependencies = {}, -- telescope loads the extension, don't need to add as a dependency
  -- version = '*',
  branch = 'main',
  lazy = true,
  config = function()
    local bm = require 'bookmarks'
    bm.setup()

    vim.keymap.set('n', '<leader>bmt', bm.bookmark_toggle, { desc = '[B]ook[m]ark [T]oggle' })
    vim.keymap.set('n', '<leader>bmda', bm.bookmark_clear_all, { desc = '[B]ook[m]ark [D]elete [A]ll' })
    -- Reference from documentation if I want to add some keymaps in the future
    -- vim.keymap.set("n","mi",bm.bookmark_ann) -- add or edit mark annotation at current line
    -- vim.keymap.set("n","mc",bm.bookmark_clean) -- clean all marks in local buffer
    -- vim.keymap.set("n","mn",bm.bookmark_next) -- jump to next mark in local buffer
    -- vim.keymap.set("n","mp",bm.bookmark_prev) -- jump to previous mark in local buffer
    -- vim.keymap.set("n","ml",bm.bookmark_list) -- show marked file list in quickfix window
    -- vim.keymap.set("n","mx",bm.bookmark_clear_all) -- removes all bookmarks
  end,
}
