require('obsidian-cli').setup {
  vault = 'The Cache',
  vault_path = require('config.paths').obsidian,
}

vim.keymap.set('n', '<leader>on', function() require('obsidian-cli').create_note() end, { desc = '[O]bsidian: [N]ew Note' })
vim.keymap.set('n', '<leader>ol', function() require('obsidian-cli').follow_link() end, { desc = '[O]bsidian: Follow [L]ink' })
vim.keymap.set('n', '<leader>of', function() require('obsidian-cli').search_notes() end, { desc = '[O]bsidian: [S]earch' })
vim.keymap.set('n', '<leader>og', function() require('obsidian-cli').grep_notes() end, { desc = '[O]bsidian: [G]rep' })
vim.keymap.set('n', '<leader>oo', function() require('obsidian-cli').open_note() end, { desc = '[O]bsidian: [O]pen in App' })
vim.keymap.set('n', '<leader>ob', function() require('obsidian-cli').backlinks() end, { desc = '[O]bsidian: [B]acklinks' })
vim.keymap.set('n', '<leader>ot', function() require('obsidian-cli').today() end, { desc = '[O]bsidian: [T]oday' })
vim.keymap.set('n', '<leader>os', function() require('obsidian-cli').snippets() end, { desc = '[O]bsidian: [S]nippets' })

vim.keymap.set('n', '<leader>oz', function()
  require('obsidian_zettelkasten_migration').migrate_file()
end, { desc = '[O]bsidian migrate note to [Z]ettelkasten' })
