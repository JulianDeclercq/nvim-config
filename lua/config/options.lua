vim.g.have_nerd_font = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a' -- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.showmode = false -- Don't show the mode, since it's already in the status line
vim.schedule(function() -- Sync clipboard between OS and Neovim. Schedule the setting after `UiEnter` because it can increase startup-time.
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.wrap = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 10
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true -- Ignore case in searches
vim.opt.smartcase = true -- Re-enable case in searches if the search contains \C or one or more capital letters in the search term
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = false
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split' -- Preview substitutions live, as you type!
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.confirm = true -- If performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
vim.opt.history = 100 -- how many `:` commands and messages are kept
vim.opt.fixeol = false -- don't add a final newline
vim.opt.fileformats = { 'unix', 'dos' } -- auto-detect line endings, hide ^M

-- Fold settings - keep all folds open always
vim.opt.foldlevelstart = 99      -- Start with all folds open when loading a buffer
vim.opt.foldlevel = 99           -- Keep all folds open

local is_windows = (vim.loop.os_uname().sysname == 'Windows_NT')

if not is_windows then
  vim.env.DOTNET_ROOT = '/usr/local/share/dotnet' -- Ensure OmniSharp locates the .NET SDK on Apple Silicon by setting DOTNET_ROOT
end

vim.o.termguicolors = true

-- remove automatic commenting after a comment
vim.opt.formatoptions:remove 'r'
vim.opt.formatoptions:remove 'o'

-- auto-read
vim.o.autoread = true

-- auto-save timing
vim.opt.updatetime = 1000 -- fire CursorHold and CursorHoldI events after 1000ms instead of the default
vim.o.autowrite = true

-- Tab title
vim.o.title = true

-- helper: grab first n folders, then file
local function first_n_folders_with_file(n)
  local full = vim.fn.expand '%:p' -- e.g. "/home/user/projects/foo/src/bar.lua"
  if full == '' then
    return ''
  end

  local dir = vim.fn.fnamemodify(full, ':h') -- "/home/user/projects/foo/src"
  local stripped = dir:gsub('^/', '') -- "home/user/projects/foo/src"
  stripped = stripped:gsub('^Users/Julian/', '') -- remove prefix on MacOS
  stripped = stripped:gsub('^Repositories/', '')
  local parts = vim.split(stripped, '/', { plain = true })

  -- take up to n of them
  local sel = {}
  for i = 1, math.min(n, #parts) do
    sel[#sel + 1] = parts[i]
  end

  -- reassemble
  local title = '/' .. table.concat(sel, '/') -- "/home/user/projects"
  local filename = vim.fn.expand '%:t' -- "bar.lua"

  if #parts > n then
    title = title .. '/.../' .. filename -- "/home/user/projects/.../bar.lua"
  else
    title = title .. '/' .. filename -- shallow: "/home/user/projects/bar.lua"
  end

  return title
end

-- set it initially
vim.o.titlestring = first_n_folders_with_file(3)

-- refresh on buffer/tab switch
vim.api.nvim_create_autocmd({ 'BufEnter', 'TabEnter' }, {
  callback = function()
    vim.opt.titlestring = first_n_folders_with_file(3)
  end,
})
