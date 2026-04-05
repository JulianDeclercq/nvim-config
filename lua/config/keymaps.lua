-- Keep paste register intact when pasting over a visual selection
vim.keymap.set('x', 'p', [["_dP]], { desc = 'Paste without yanking replaced text' })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Exit terminal mode in the builtin terminal with a shortcut instead of <C-\><C-n>
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Map <leader>W to <C-w> (window command mode) every standard window command still works.
vim.keymap.set('n', '<leader>w', '<C-w>', { noremap = true, silent = true, desc = 'Window command prefix' })
vim.keymap.set('v', '<leader>w', '<C-w>', { noremap = true, silent = true, desc = 'Window command prefix (visual)' })

-- window navigation with 1 less keystroke :)
vim.keymap.set('n', '<leader>h', '<C-w>h', { desc = 'Go to left window' })
vim.keymap.set('n', '<leader>j', '<C-w>j', { desc = 'Go to lower window' })
-- vim.keymap.set('n', '<leader>k', '<C-w>k', { desc = 'Go to upper window' }) -- commented since I want to use it for hover info for now
vim.keymap.set('n', '<leader>l', '<C-w>l', { desc = 'Go to right window' }) -- commented since I want to use it for lua stuff for now

-- Tekken
vim.keymap.set('n', '<leader>td', require('tekken-format').tekken_docs_link, { desc = 'Format [T]ekken [D]ocs link' })
vim.keymap.set('n', '<leader>to', require('tekken-format').okizeme_link, { desc = 'Format [T[ekken [O]kizeme link' })
vim.keymap.set('n', '<leader>ft', require('tekken-picker').pick, { desc = '[F]ind [T]ekken' })

-- Buffer picker
vim.keymap.set('n', '<leader><leader>', require('buffer-picker').pick, { desc = '[ ] Find existing buffers' })

-- Run Lua file and show output in vertical buffer
vim.keymap.set('n', '<leader>rf', function()
  vim.cmd.write()

  local file = vim.fn.fnameescape(vim.fn.expand '%:p')

  -- Open a vertical split with a normal buffer
  vim.cmd 'vnew'

  -- Read command output directly into the buffer
  vim.cmd('read !nvim --headless -c "luafile ' .. file .. '" +qa')

  -- Clean up the first empty line
  vim.cmd 'normal! ggdd'

  -- Set buffer options
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
end, { desc = 'Run Lua file and show output in vertical buffer' })

-- Run LOVE in a temporary terminal split
vim.keymap.set('n', '<leader>rl', function()
  local current_dir = vim.fn.expand '%:p:h'

  -- in some projects, I have all code inside a code directory instead of the main directory
  if current_dir:find 'code' ~= nil then
    current_dir = vim.fn.fnamemodify(current_dir, ':h')
  end

  local love_cmd = (vim.fn.has 'win32' == 1) and 'love.exe' or 'love'
  local cmd = love_cmd .. ' --console "' .. current_dir .. '"'

  vim.cmd 'split'
  vim.api.nvim_win_set_height(0, 10)
  vim.cmd('terminal ' .. cmd)

  -- make the buffer temporary
  local term_buf = vim.api.nvim_get_current_buf()
  vim.bo[term_buf].bufhidden = 'wipe'

  vim.cmd 'startinsert'
end, { desc = '[R]un [L]OVE' })
