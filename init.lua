vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
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

-- Fold settings - keep all folds open always
vim.opt.foldlevelstart = 99      -- Start with all folds open when loading a buffer
vim.opt.foldlevel = 99           -- Keep all folds open

-- Keep paste register intact when pasting over a visual selection
vim.keymap.set('x', 'p', [["_dP]], { desc = 'Paste without yanking replaced text' })

local is_windows = (vim.loop.os_uname().sysname == 'Windows_NT')

if not is_windows then
  vim.env.DOTNET_ROOT = '/usr/local/share/dotnet' -- Ensure OmniSharp locates the .NET SDK on Apple Silicon by setting DOTNET_ROOT
end

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

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Plugin Management with vim.pack (Neovim 0.12) ]]
local function gh(repo)
  return 'https://github.com/' .. repo
end

-- Post-install/update hook: build telescope-fzf-native
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
      local path = vim.fn.stdpath 'data' .. '/site/pack/core/opt/telescope-fzf-native.nvim'
      vim.fn.system { 'make', '-C', path }
    end
  end,
})

-- Plugins
vim.pack.add {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-tree/nvim-web-devicons',
  gh 'folke/tokyonight.nvim',
  gh 'rcarriga/nvim-notify',
  gh 'tpope/vim-sleuth',
  gh 'tpope/vim-surround',
  gh 'tpope/vim-commentary',
  gh 'lewis6991/gitsigns.nvim',
  gh 'folke/which-key.nvim',
  gh 'folke/todo-comments.nvim',
  gh 'echasnovski/mini.nvim',
  gh 'windwp/nvim-autopairs',
  gh 'vuciv/golf',
  gh 'stevearc/conform.nvim', -- Formatting (trim whitespace on save)
  gh 'L3MON4D3/LuaSnip',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-fzf-native.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
  gh 'benfowler/telescope-luasnip.nvim',
  gh 'tomasky/bookmarks.nvim',
  gh 'JulianDeclercq/obsidian-cli.nvim',
}

-- Colorscheme (first, so UI is themed immediately)
require('tokyonight').setup {
  styles = {
    comments = { italic = false }, -- Disable italics in comments
  },
  on_highlights = function(hl, _)
    -- all following settings are for when 'relativenumber' is on (always in my case)
    local color = '#5C8699'
    hl.LineNrAbove = { fg = color }
    hl.CursorLineNr = { fg = color }
    hl.LineNrBelow = { fg = color }
  end,
}
vim.cmd.colorscheme 'tokyonight-night'

-- Notifications
local notify = require 'notify'
notify.setup()
vim.notify = notify

-- Gitsigns
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

-- Which-key
require('which-key').setup {
  delay = 0, -- delay between pressing a key and opening which-key (milliseconds), this setting is independent of vim.opt.timeoutlen
  icons = {
    mappings = vim.g.have_nerd_font,
    keys = vim.g.have_nerd_font and {} or {
      Up = '<Up> ',
      Down = '<Down> ',
      Left = '<Left> ',
      Right = '<Right> ',
      C = '<C-…> ',
      M = '<M-…> ',
      D = '<D-…> ',
      S = '<S-…> ',
      CR = '<CR> ',
      Esc = '<Esc> ',
      ScrollWheelDown = '<ScrollWheelDown> ',
      ScrollWheelUp = '<ScrollWheelUp> ',
      NL = '<NL> ',
      BS = '<BS> ',
      Space = '<Space> ',
      Tab = '<Tab> ',
      F1 = '<F1>',
      F2 = '<F2>',
      F3 = '<F3>',
      F4 = '<F4>',
      F5 = '<F5>',
      F6 = '<F6>',
      F7 = '<F7>',
      F8 = '<F8>',
      F9 = '<F9>',
      F10 = '<F10>',
      F11 = '<F11>',
      F12 = '<F12>',
    },
  },

  spec = { -- Document existing key chains
    { '<leader>s', group = '[S]earch' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
  },
}

-- Todo-comments
require('todo-comments').setup { signs = false }

-- Mini.nvim
local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
  return '%2l:%-2v'
end

-- Autopairs
require('nvim-autopairs').setup()

-- Conform (formatting)
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

-- LuaSnip (Snippet Engine)
local ls = require 'luasnip'

ls.add_snippets('all', {
  ls.snippet({
    trig = 'character',
    -- hide from autocomplete,
    -- so you'll have to either expand it through the trigger + expand keybind
    -- or find it through telescope
    hidden = true,
  }, {
    ls.text_node {
      '# CHARACTERNAME MOC',
      '## Tutorials',
      '## Anti',
      '## Misc',
    },
  }),
  ls.snippet({
    trig = 'combo',
    hidden = true,
  }, {
    ls.text_node {
      '```fight',
      'input:',
      'name: Combo',
      'damage: 1',
      'hits: 1',
      '```',
    },
  }),
})

-- Telescope
require('telescope').setup {
  extensions = {
    ['ui-select'] = {
      require('telescope.themes').get_dropdown(),
    },
  },
  -- allow deleting buffers when Telescope is picking inside Builtin.Buffers
  pickers = {
    buffers = {
      mappings = {
        n = {
          ['dd'] = require('telescope.actions').delete_buffer,
        },
      },
    },
  },
}

-- Enable Telescope extensions if they are installed
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')
pcall(require('telescope').load_extension, 'luasnip')
pcall(require('telescope').load_extension, 'bookmarks')

-- See `:help telescope.builtin`
local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
vim.keymap.set('n', '<leader>fs', '<Cmd>Telescope luasnip<CR>', { desc = '[F]ind [S]nippets' })
vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })
vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[F]ind existing [B]uffers' })
vim.keymap.set(
  'n',
  '<leader>fof',
  "<Cmd>lua require('telescope.builtin').oldfiles()<CR>",
  { noremap = true, silent = true, desc = '[F]ind [O]ld [F]iles' }
)
vim.keymap.set('n', '<leader>fbm', require('bookmark-utils').open_bookmarks_picker, { desc = '[F]ind [B]ookmarks' })

-- Slightly advanced example of overriding default behavior and theme
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
vim.keymap.set('n', '<leader>s/', function()
  builtin.live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end, { desc = '[F]ind [/] in Open Files' })

-- Shortcut for searching your Neovim configuration files
vim.keymap.set('n', '<leader>fn', function()
  builtin.find_files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[F]ind [N]eovim files' })

-- Bookmarks
local bm = require 'bookmarks'
bm.setup()
vim.keymap.set('n', '<leader>bmt', bm.bookmark_toggle, { desc = '[B]ook[m]ark [T]oggle' })
vim.keymap.set('n', '<leader>bmda', bm.bookmark_clear_all, { desc = '[B]ook[m]ark [D]elete [A]ll' })

-- Obsidian
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

-- All plugins loaded
vim.notify('Neovim ready!', vim.log.levels.INFO)

vim.o.termguicolors = true
vim.keymap.set('n', '<leader>oz', function()
  require('obsidian_zettelkasten_migration').migrate_file()
end, { desc = '[O]bsidian migrate note to [Z]ettelkasten' })

-- Set tab title to current buffer's path -- TODO: Update this it's way too long for windows for example
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

-- remove automatic commenting after a comment
vim.opt.formatoptions:remove 'r'
vim.opt.formatoptions:remove 'o'

-- User commands
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

-- auto-read
vim.o.autoread = true

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

-- auto-save
vim.opt.updatetime = 1000 -- fire CursorHold and CursorHoldI events after 1000ms instead of the default
vim.o.autowrite = true

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

vim.keymap.set('n', '<leader>td', require('tekken-format').tekken_docs_link, { desc = 'Format [T]ekken [D]ocs link' })
vim.keymap.set('n', '<leader>to', require('tekken-format').okizeme_link, { desc = 'Format [T[ekken [O]kizeme link' })
vim.keymap.set('n', '<leader>ft', require('tekken-picker').pick, { desc = '[F]ind [T]ekken' })
vim.keymap.set('n', '<leader><leader>', require('buffer-picker').pick, { desc = '[ ] Find existing buffers' })

vim.api.nvim_create_user_command('ZettelMigrateAlias', function()
  require('gpt-obsidian-migration').migrate_current_file_with_alias_links()
end, {})

vim.api.nvim_create_user_command('ZettelListUnmigrated', function()
  require('gpt-obsidian-migration').list_unmigrated_files()
end, {})

vim.api.nvim_create_user_command('ZettelMigrateAll', function()
  require('gpt-obsidian-migration').migrate_all_unmigrated()
end, {})

-- works for lua files, but commented now in favor of the next one
-- vim.keymap.set('n', '<leader>rf', '<cmd>source %<CR>', { desc = '[R]un current [F]ile' })

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

-- auto-close LOVE terminal window when process exits
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

-- clean up temp files on Windows
if is_windows then
  local shada_dir = vim.fn.stdpath 'data' .. '/shada/'
  if vim.fn.isdirectory(shada_dir) == 1 then
    for _, file in ipairs(vim.fn.glob(shada_dir .. 'main.shada.tmp*', false, true)) do
      pcall(vim.fn.delete, file)
    end
  end
end
