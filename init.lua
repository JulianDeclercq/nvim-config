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

local is_windows = (vim.loop.os_uname().sysname == 'Windows_NT')

if not is_windows then
  vim.env.DOTNET_ROOT = '/usr/local/share/dotnet' -- Ensure OmniSharp locates the .NET SDK on Apple Silicon by setting DOTNET_ROOT
end

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps, use Telescope’s built‑in diagnostics picker
vim.keymap.set('n', '<leader>K', vim.diagnostic.open_float, { desc = 'Open [D]iagnostic float' })

vim.keymap.set('n', '<leader>da', function()
  require('telescope.builtin').diagnostics {
    prompt_title = 'Diagnostics - Any',
  }
end, { desc = '[D]iagnostics [A]ny' })

vim.keymap.set('n', '<leader>de', function()
  require('telescope.builtin').diagnostics {
    prompt_title = 'Diagnostics - Errors',
    severity = vim.diagnostic.severity.ERROR,
  }
end, { desc = '[D]iagnostics [E]rrors' })

vim.keymap.set('n', '<leader>dw', function()
  require('telescope.builtin').diagnostics {
    prompt_title = 'Diagnostics - Warnings',
    severity = vim.diagnostic.severity.WARN,
  }
end, { desc = '[D]iagnostics [W]arnings' })

-- Next and previous diagnostics
vim.keymap.set('n', '<leader>dna', function()
  vim.diagnostic.jump {
    count = 1,
  }
end, { desc = '[D]iagnostics [N]ext [A]ny' })

vim.keymap.set('n', '<leader>dpa', function()
  vim.diagnostic.jump {
    count = -1,
  }
end, { desc = '[D]iagnostics [P]revious [A]ny' })

vim.keymap.set('n', '<leader>dne', function()
  vim.diagnostic.jump {
    count = 1,
    severity = vim.diagnostic.severity.ERROR,
  }
end, { desc = '[D]iagnostics [N]ext [E]rror' })

vim.keymap.set('n', '<leader>dpe', function()
  vim.diagnostic.jump {
    count = -1,
    severity = vim.diagnostic.severity.ERROR,
  }
end, { desc = '[D]iagnostics [P]revious [E]rror' })

vim.keymap.set('n', '<leader>dnw', function()
  vim.diagnostic.jump {
    count = 1,
    severity = vim.diagnostic.severity.WARN,
  }
end, { desc = '[D]iagnostics [N]ext [W]arning' })

vim.keymap.set('n', '<leader>dpw', function()
  vim.diagnostic.jump {
    count = -1,
    severity = vim.diagnostic.severity.WARN,
  }
end, { desc = '[D]iagnostics [P]revious [W]arning' })

-- Exit terminal mode in the builtin terminal with a shortcut instead of <C-\><C-n>
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Map <leader>W to <C-w> (window command mode) every standard window command still works.
vim.keymap.set('n', '<leader>w', '<C-w>', { noremap = true, silent = true, desc = 'Window command prefix' })
vim.keymap.set('v', '<leader>w', '<C-w>', { noremap = true, silent = true, desc = 'Window command prefix (visual)' })

-- window navigation with 1 less keystroke :)
vim.keymap.set('n', '<leader>h', '<C-w>h', { desc = 'Go to left window' })
vim.keymap.set('n', '<leader>j', '<C-w>j', { desc = 'Go to lower window' })
-- vim.keymap.set('n', '<leader>k', '<C-w>k', { desc = 'Go to upper window' }) -- commented since I want to use it for hover info for now
vim.keymap.set('n', '<leader>l', '<C-w>l', { desc = 'Go to right window' })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install Lazy, the plugin manager and plugins]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { import = 'plugins' },
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    'folke/which-key.nvim', -- Show pending keybinds
    event = 'VimEnter',
    opts = {
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
    },
  },
  { -- configures Lua LSP for your Neovim config, runtime and plugins used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } }, -- Load luvit types when the `vim.uv` word is found
      },
    },
  },
  { -- main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} }, -- useful status updates for LSP.
      'saghen/blink.cmp', -- allows extra capabilities provided by blink.cmp
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Rename the variable under your cursor, most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error or a suggestion from your LSP for this to activate.
          map('<leader>ca', vim.lsp.buf.code_action, 'Goto [C]ode [A]ction', { 'n', 'x' })

          -- Show hover info
          map('<leader>k', vim.lsp.buf.hover, 'Hover Info')

          -- Find references for the word under your cursor.
          map('<leader>gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          map('<leader>gi', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the definition of the word under your cursor.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- WARN: This is not Goto Definition, this is Goto Declaration. For example, in C this would take you to the header.
          map('<leader>gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Fuzzy find all the symbols in your current document. Symbols are things like variables, functions, types, etc.
          map('<leader>fds', require('telescope.builtin').lsp_document_symbols, '[F]ind [D]ocument [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace. Similar to document symbols, except searches over your entire project.
          map('<leader>fws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[F]ind [W]orkspace [S]ymbols')

          -- Jump to the type of the word under your cursor. Useful when you're not sure what type a variable is and you want to see the definition of its *type*, not where it was *defined*.
          map('<leader>gt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          -- The following two autocommands are used to highlight references of the word under your cursor when your cursor rests there for a little while.
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        -- clangd = {},
        -- gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        ts_ls = {},
        csharp_ls = {},
        -- omnisharp = is_windows and (function()
        --   return {
        --     cmd = {
        --       'omnisharp',
        --       '-z',
        --       '--hostPID',
        --       tostring(vim.fn.getpid()),
        --       '--encoding',
        --       'utf-8',
        --       '--languageserver',
        --       'FormattingOptions:EnableEditorConfigSupport=true',
        --       'Sdk:IncludePrereleases=true',
        --     },
        --   }
        -- end)() or {}, -- use empty table for non-windows
        cssls = {},
        cssmodules_ls = {
          filetypes = { 'css', 'scss', 'sass', 'less' },
        },
        css_variables = {},
        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
      }

      -- Installing more tools using Mason
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })

      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
        integrations = {
          ['mason-lspconfig'] = true,
        },
      }

      require('mason-lspconfig').setup {
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        automatic_enable = true,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true } --, lsp_format = 'fallback' }
        end,
        mode = { 'n', 'v' },
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't have a well standardized coding style.
        local disable_filetypes = { c = true, cpp = true, cs = true }
        local fileType = vim.bo[bufnr].filetype
        if disable_filetypes[fileType] then
          return nil
        end

        return {
          timeout_ms = 500,
          lsp_fallback = true,
        }
      end,

      formatters = {
        dotnet_format = {
          inherit = false,
          command = 'dotnet',
          -- args = { 'format', '--no-restore', '--include', '$FILENAME' }, --no-restore so it skips package restore for faster formatting
          args = { 'format', '--no-restore', '--include', '$RELATIVE_FILEPATH' }, -- THIS WAS NEEDED BC I SET CWD
          stdin = false, --dotnet format reads from files, not stdin
          require_cwd = true,
          -- Run from the nearest folder that has a .sln or .csproj so dotnet format can find the workspace
          cwd = function()
            local bufname = vim.api.nvim_buf_get_name(0)
            local start_dir = bufname ~= '' and vim.fs.dirname(bufname) or vim.loop.cwd()

            local candidates = vim.fs.find(function(name)
              return name:match '%.sln$' or name:match '%.csproj$'
            end, { path = start_dir, type = 'file', upward = true })

            if #candidates > 0 then
              local result = vim.fs.dirname(candidates[1])
              print('[DEBUG] Found workspace at:', result)
              return result
            else
              print('[DEBUG] No .sln or .csproj found, starting dir was:', start_dir)
              return nil
            end
          end,
        },
      },

      formatters_by_ft = {
        lua = { 'stylua' },
        cs = { 'dotnet_format' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },

        -- TODO: Why are these both here and in my LINT setup? Need to check which ones are needed and which are not
        html = { 'prettier' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
        json = { 'prettier' },
        css = { 'prettier' },
        markdown = { 'prettier' },

        ['*'] = { 'trim_whitespace' },
      },
    },
  },
  { -- Autocompletion
    'saghen/blink.cmp',
    build = 'cargo +nightly build --release',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- TODO No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        -- preset = 'default',

        -- Julle: I just can't stand the keymap <C-y>, it's too clumsy. Having preset `enter` still allows you to cycle with <C-p> and <C-n>
        preset = 'enter',
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'. Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },
  { -- I don't really want to use nvim-cmp but obsidian for nvim uses this by default so let's just map the keymaps and call it a day
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter', -- load on Insert mode
    opts = function()
      local cmp = require 'cmp'
      return {
        snippet = { expand = function(_) end }, -- we don’t use snippets here, so this can be a no-op
        mapping = {
          ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
          ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
          ['<C-y>'] = cmp.mapping.confirm { select = true },
        },
      }
    end,
  },
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
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

      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- NOTE: Julle: I use tpope/vim-surround instead of the mini surround
      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      -- require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      -- Julle: I'm disabling ensure_installed and auto_install since it doesn't work on Windows, so manually install with TSInstallSync when an error pops up instead.
      --ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      -- Autoinstall languages that are not installed
      -- auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
  {
    'tpope/vim-surround',
    event = 'VeryLazy', -- loads after UI is ready
    keys = { -- so :Lazy can lazy load on first use
      { 'ys', mode = { 'n', 'v' } },
      { 'yS', mode = { 'n', 'v' } },
      { 'ds', mode = 'n' },
      { 'cs', mode = 'n' },
    },
  },
  {
    'vuciv/golf',
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    lazy = false, -- neo-tree will lazily load itself
    ---@module "neo-tree"
    ---@type neotree.Config?
    keys = {
      { '<leader>nt', '<cmd>Neotree toggle<CR>', desc = '[N]eoTree [T]oggle', silent = true },
      { '<leader>ntr', '<cmd>Neotree reveal<CR>', desc = '[N]eoTree [R]eveal', silent = true },
    },
    opts = {},
  },

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --  Julle: the syntax 'kickstart.plugins.WHATEVER' is a directory name pretty much. Check the kickstart.plugin directory or look for lint/autopair files through telescope <leader>tn.
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree',
  -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps
  --

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.o.termguicolors = true

-- Julle TermHere command
local function term_here(args)
  -- Try to get the full path of the current buffer:
  local cur_path = vim.api.nvim_buf_get_name(0)
  local bufdir = ''

  if cur_path ~= '' then
    -- Current buffer has a file: use its directory
    bufdir = vim.fn.fnamemodify(cur_path, ':h')
  else
    -- Current buffer is empty: try to find the alternate buffer (#)
    local alt_buf = vim.fn.bufnr '#'
    if alt_buf ~= 0 then
      local alt_name = vim.api.nvim_buf_get_name(alt_buf)
      if alt_name ~= '' then
        bufdir = vim.fn.fnamemodify(alt_name, ':h')
      end
    end
  end

  -- If we still have no directory, fall back to cwd (or empty string)
  if bufdir == '' then
    bufdir = vim.loop.cwd() or ''
  end

  -- Notify so you see exactly where we’re opening the terminal:
  vim.notify('Opening terminal in: ' .. bufdir)

  -- Change the window-local directory to bufdir
  vim.cmd('lcd ' .. vim.fn.fnameescape(bufdir))

  -- Build the terminal‐launch command depending on OS:
  local term_cmd
  if is_windows then
    -- On Windows, try pwsh (PowerShell Core); if not found, fallback to powershell.exe
    local pwsh_exists = vim.fn.executable 'pwsh' == 1
    if pwsh_exists then
      term_cmd = 'pwsh'
    else
      term_cmd = 'powershell.exe'
    end

    -- If the user passed additional arguments, append them after the shell executable.
    if #args.fargs > 0 then
      term_cmd = term_cmd .. ' ' .. table.concat(args.fargs, ' ')
    end

    vim.cmd('terminal ' .. term_cmd)
  else
    -- On Unix/macOS, just launch the default terminal; forward any extra arguments:
    if #args.fargs > 0 then
      vim.cmd('terminal ' .. table.concat(args.fargs, ' '))
    else
      vim.cmd 'terminal'
    end
  end
end

vim.api.nvim_create_user_command('TermHere', term_here, {
  nargs = '*',
  bang = true,
})

-- Set tab title to current buffer's path
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

  -- re­assemble
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

vim.api.nvim_create_user_command('StackTraceFmt', function()
  -- Substitute over the whole buffer: insert a newline before each "at"
  vim.cmd [[%s/\<at\>/\rat/g]]
end, { desc = 'Format stack trace: newline before each "at"' })

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
  if vim.bo.readonly or not vim.bo.modifiable then
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

  vim.cmd 'silent! write'
end

local auto_save = vim.api.nvim_create_augroup('AutoSaveAll', { clear = true })
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'CursorHold', 'CursorHoldI', 'InsertLeave' }, {
  group = auto_save,
  pattern = '*',
  callback = save_if_writable,
})

-- Debug stuff for LspInfo
vim.api.nvim_create_user_command('LspInfoFormatting', function()
  local clients = vim.lsp.get_clients { bufnr = 0 }
  if #clients == 0 then
    vim.notify('No LSP clients attached to this buffer', vim.log.levels.INFO)
    return
  end

  local lines = {}
  for _, client in ipairs(clients) do
    local supports_format = client.server_capabilities.documentFormattingProvider
    local status = supports_format and 'supports formatting' or 'does NOT support formatting'
    table.insert(lines, client.name .. ': ' .. status)
  end

  -- Open a scratch buffer and fill it
  vim.cmd 'new'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end, {})

vim.api.nvim_create_user_command('LspInfoCapabilities', function()
  local clients = vim.lsp.get_clients { bufnr = 0 }
  if #clients == 0 then
    vim.notify('No LSP clients attached to this buffer', vim.log.levels.INFO)
    return
  end

  local lines = {}
  for _, client in ipairs(clients) do
    table.insert(lines, 'Client: ' .. client.name)
    local caps = vim.split(vim.inspect(client.server_capabilities), '\n')
    for _, cap in ipairs(caps) do
      table.insert(lines, '  ' .. cap)
    end
    table.insert(lines, '') -- blank line between clients
  end

  -- Open scratch buffer
  vim.cmd 'new'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end, {})

-- Conform dotnet format messages
vim.api.nvim_create_autocmd('User', {
  pattern = 'ConformFormatPre',
  callback = function(args)
    if vim.bo[args.buf].filetype == 'cs' then
      vim.notify('Running dotnet format..', vim.log.levels.INFO)
    end
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'ConformFormatPost',
  callback = function(args)
    if vim.bo[args.buf].filetype == 'cs' then
      vim.notify('Finished dotnet format!', vim.log.levels.INFO)
    end
  end,
})
