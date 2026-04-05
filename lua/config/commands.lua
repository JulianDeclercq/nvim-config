vim.api.nvim_create_user_command('PwdCopy', function()
  local dir = vim.fn.expand '%:p:h'
  vim.fn.setreg('+', dir)
  vim.notify('Copied to clipboard: ' .. dir, vim.log.levels.INFO, { title = 'PwdCopy' })
end, { desc = 'Copy current buffer directory to clipboard' })

vim.api.nvim_create_user_command('FormatStackTrace', function()
  -- Substitute over the whole buffer: insert a newline before each "at"
  vim.cmd [[%s/\<at\>/\rat/g]]
end, { desc = 'Format stack trace: newline before each "at"' })

vim.api.nvim_create_user_command('FormatGPTMarkdown', function()
  vim.cmd [[silent! %s/\[\[TB\]\]/```/g]]
  vim.cmd [[silent! %s/\[\[BT\]\]/`/g]]
end, { desc = 'Format ChatGPT markdown' })

vim.api.nvim_create_user_command('DeleteFile', function()
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then
    return
  end

  if name:match('%.md$') then
    local stem = vim.fn.fnamemodify(name, ':t:r')
    require('obsidian-cli.cache').remove(stem)
  end

  vim.b.skip_autosave = true
  vim.fn.delete(name)
  vim.cmd 'enew' -- new empty buffer
  vim.cmd 'bdelete #' -- wipe the old buffer
end, { desc = 'Delete the file tied to the current buffer' })

vim.api.nvim_create_user_command('ZettelMigrateAlias', function()
  require('gpt-obsidian-migration').migrate_current_file_with_alias_links()
end, {})

vim.api.nvim_create_user_command('ZettelListUnmigrated', function()
  require('gpt-obsidian-migration').list_unmigrated_files()
end, {})

vim.api.nvim_create_user_command('ZettelMigrateAll', function()
  require('gpt-obsidian-migration').migrate_all_unmigrated()
end, {})
