-- Strip \r carriage returns and set unix line endings on save
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[silent! %s/\r$//e]])
    vim.bo.fileformat = 'unix'
    vim.api.nvim_win_get_cursor(0)
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Auto-read: refresh buffers when files change on disk
local auto_read = vim.api.nvim_create_augroup('AutoReadAll', { clear = true })
vim.api.nvim_create_autocmd('FocusGained', {
  group = auto_read,
  pattern = '*',
  command = "if getcmdwintype() == '' | checktime | endif",
})

vim.api.nvim_create_autocmd('BufEnter', {
  group = auto_read,
  pattern = '*',
  command = "if &buftype == '' && !&modified && expand('%') != '' | exec 'checktime ' . expand('<abuf>') | endif",
})

-- Auto-save: write buffers on idle / focus loss
local function save_if_writable()
  if vim.b.skip_autosave or vim.bo.readonly or not vim.bo.modifiable then
    return
  end

  -- skip help/quickfix/terminal/etc.
  if vim.bo.buftype ~= '' then
    return
  end

  -- skip unnamed scratch buffers
  if vim.api.nvim_buf_get_name(0) == '' then
    return
  end

  -- only save if buffer has been modified
  if not vim.bo.modified then
    return
  end

  vim.cmd 'silent! write'
end

local auto_save = vim.api.nvim_create_augroup('AutoSaveAll', { clear = true })
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'CursorHold', 'CursorHoldI', 'InsertLeave' }, {
  group = auto_save,
  pattern = '*',
  callback = save_if_writable,
})

-- Auto-close LOVE terminal window when process exits
vim.api.nvim_create_autocmd('TermClose', {
  pattern = 'term://*love*',
  callback = function(args)
    vim.schedule(function()
      local info = vim.fn.getbufinfo(args.buf)[1]
      if info and info.windows then
        for _, win in ipairs(info.windows) do
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end)
  end,
})

-- Clean up temp files on Windows
local is_windows = (vim.loop.os_uname().sysname == 'Windows_NT')
if is_windows then
  local shada_dir = vim.fn.stdpath 'data' .. '/shada/'
  if vim.fn.isdirectory(shada_dir) == 1 then
    for _, file in ipairs(vim.fn.glob(shada_dir .. 'main.shada.tmp*', false, true)) do
      pcall(vim.fn.delete, file)
    end
  end
end
