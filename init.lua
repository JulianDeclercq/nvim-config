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

-- Keep paste register intact when pasting over a visual selection
vim.keymap.set('x', 'p', [["_dP]], { desc = 'Paste without yanking replaced text' })

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
vim.keymap.set('n', '<leader>l', '<C-w>l', { desc = 'Go to right window' }) -- commented since I want to use it for lua stuff for now

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
          map('<leader>rn', function()
            -- open empty input instead of pre-filled
            local current_name = vim.fn.expand '<cword>'
            local new_name = vim.fn.input('Rename to: ', '')
            if new_name ~= '' and new_name ~= current_name then
              vim.lsp.buf.rename(new_name)
            end
          end, '[R]e[n]ame')

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
              diagnostics = {
                globals = { 'vim' }, -- Only vim global by default
              },
              runtime = {
                version = 'Lua 5.1', -- Default to Lua 5.1
              },
              workspace = {
                library = {
                  vim.fn.expand '$VIMRUNTIME/lua',
                  vim.fn.expand '$VIMRUNTIME/lua/vim/lsp',
                },
                checkThirdParty = false,
              },
            },
          },
        },
      }

      -- Installing more tools using Mason
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Lua formatter
        'prettier', -- Prettier CLI
        'prettierd', -- Prettierd daemon (faster)
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
        '<leader>fmf',
        function()
          require('conform').format { async = true } --, lsp_format = 'fallback' }
        end,
        mode = { 'n', 'v' },
        desc = '[F]or[M]at [F]ile (buffer)',
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
          timeout_ms = 1000,
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
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        -- json = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
        cs = { 'dotnet_format' },
        ['*'] = { 'trim_whitespace' },
      },
    },
  },
  { -- Snippet Engine
    'L3MON4D3/LuaSnip',
    version = '2.*',
    dependencies = {},
    opts = {},
    config = function()
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
    end,
  },
  { -- Autocompletion
    'saghen/blink.cmp',
    build = is_windows and nil or 'cargo +nightly build --release', -- my rust toolchain is wonky on Windows so let's just not build
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      'L3MON4D3/LuaSnip',
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
  -- Linting configuration (from kickstart.plugins.lint)
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- configure diagnostics display
      vim.diagnostic.config {
        signs = true,
        underline = true,
        update_in_insert = false,
        virtual_text = false,
        severity_sort = true,
      }

      local lint = require 'lint'

      -- explicitly load the built-in linters
      lint.linters.eslint = require 'lint.linters.eslint'
      lint.linters.stylelint = require 'lint.linters.stylelint'

      -- filetypes → linters
      lint.linters_by_ft = {
        -- JavaScript / TypeScript
        typescript = { 'eslint' },
        typescriptreact = { 'eslint' },
        javascript = { 'eslint' },
        javascriptreact = { 'eslint' },

        -- Stylesheets
        css = { 'stylelint' },
        scss = { 'stylelint' },
        less = { 'stylelint' },

        -- Markup / Single-file components
        html = { 'eslint', 'stylelint' },

        -- Lua
        -- lua = { 'luacheck' },
      }

      -- lint on save
      vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },
  -- Autopairs configuration (from kickstart.plugins.autopairs)
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  -- Telescope configuration (from plugins.telescope)
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
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
      -- vim.keymap.set('n', '<leader>fs', builtin.builtin, { desc = '[F]ind [S]elect Telescope' })
      vim.keymap.set('n', '<leader>fs', '<Cmd>Telescope luasnip<CR>', { desc = '[F]ind [S]nippets' })
      vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })
      vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
      vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
      vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
      -- vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
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
    end,
  },
  -- Obsidian configuration (from plugins.obsidian)
  {
    -- Use kostabekre's version until https://github.com/obsidian-nvim/obsidian.nvim/pull/142/files is merged for the alias searching support
    'kostabekre/obsidian.nvim',
    -- COMMUNITY FORK
    -- 'obsidian-nvim/obsidian.nvim',
    -- commit = '2d44b29dc71c26296cb6f267d0a615ec1ada908f',
    -- PERSONAL
    -- 'JulianDeclercq/obsidian.nvim',
    -- version = '*', -- use latest release
    -- branch = 'main',
    lazy = true,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp', -- autocomplete for note references
      'nvim-telescope/telescope.nvim', -- for snippet search
    },
    opts = {
      workspaces = {
        {
          name = 'vault',
          path = require('config.paths').obsidian,
        },
      },
      -- note_id_func = noteIdFunction,
      follow_url_func = function(url)
        -- Open the URL in the default web browser.
        vim.ui.open(url)
      end,
      -- Where to put new notes. Valid options are
      --  * "current_dir" - put new notes in same directory as the current buffer.
      --  * "notes_subdir" - put new notes in the default notes subdirectory.
      new_notes_location = 'notes_subdir',
      completion = {
        nvim_cmp = false,
        blink = true,
        min_chars = 2,
        file_popup = true,
      },
      ui = {
        enable = false,
      },
      legacy_commands = false,
      footer = {
        enabled = false,
      },
    },
    keys = {
      {
        '<leader>on',
        '<Cmd>Obsidian new<CR>',
        desc = '[O]bsidian: [N]ew Note',
      },
      {
        '<leader>ol',
        '<Cmd>Obsidian follow_link<CR>',
        desc = '[O]bsidian: Follow [L]ink',
      },
      {
        '<leader>oqs',
        '<Cmd>Obsidian quick_switch<CR>',
        desc = '[O]bsidian: [Q]uick [S]witch',
      },
      {
        '<leader>of',
        '<Cmd>Obsidian search<CR>',
        desc = '[O]bsidian: [F]ind',
      },
      {
        '<leader>og',
        '<Cmd>Obsidian search<CR>',
        desc = '[O]bsidian: [G]rep',
      },
      {
        '<leader>oo',
        '<Cmd>Obsidian open<CR>',
        desc = '[O]bsidian: [O]pen',
      },
      {
        '<leader>ob',
        '<Cmd>Obsidian backlinks<CR>',
        desc = '[O]bsidian [B]acklinks',
      },
      {
        '<leader>ot',
        '<Cmd>Obsidian today<CR>',
        desc = '[O]bsidian [T]oday',
      },
      {
        '<leader>os',
        function()
          require('telescope.builtin').find_files {
            cwd = obsidian_path .. '/.obsidian/snippets',
            hidden = true,
            prompt_title = 'Obsidian Snippets',
          }
        end,
        desc = '[O]bsidian [S]nippets',
      },
      {
        '<leader>oz',
        function()
          require('obsidian_zettelkasten_migration').migrate_file()
        end,
        desc = '[O]bsidian migrate note to [Z]ettelkasten',
      },
    },
  },
  -- Bookmarks configuration (from plugins.bookmarks)
  {
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
  },
  -- Git Blame configuration (from plugins.git-blame)
  {
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
  },
  -- Love2D support is now handled via .luarc.json files in Love2D projects
  -- Removed S1M0N38/love2d.nvim plugin due to LSP conflicts
  -- Notify configuration (from plugins.notify)
  {
    'rcarriga/nvim-notify',
    version = '*',
    lazy = true,
    -- load early so any vim.notify() calls get routed through nvim-notify
    event = 'VimEnter',
    -- optionally expose the setup opts here
    opts = {
      -- e.g. timeout = 3000,
      --      top_down = false,
      --      stages = "fade_in_slide_out",
    },
    config = function(_, opts)
      local notify = require 'notify'
      notify.setup(opts)
      -- override default vim.notify
      vim.notify = notify
    end,
  },
  -- Telescope LuaSnip configuration (from plugins.telescope-luasnip)
  {
    'benfowler/telescope-luasnip.nvim',
    dependencies = { -- telescope loads the extension, don't need to add as a dependency
      'L3MON4D3/LuaSnip',
    },
    version = '*',
    lazy = true,
  },
  -- Vim Commentary configuration (from plugins.vim-commentary)
  {
    'tpope/vim-commentary',
    event = 'VeryLazy',
  },
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

vim.keymap.set('n', '<leader>td', require('tekken-format').tekken_docs_link, { desc = 'Format [T]ekken [D]ocs link' })
vim.keymap.set('n', '<leader>to', require('tekken-format').okizeme_link, { desc = 'Format [T[ekken [O]kizeme link' })
vim.keymap.set('n', '<leader>ft', require('tekken-picker').pick, { desc = '[F]ind [T]ekken' })
vim.keymap.set('n', '<leader><leader>', require('buffer-picker').pick, { desc = '[ ] Find existing buffers' })

vim.api.nvim_create_user_command('ZettelMigrateAlias', function()
  require('gpt-obsidian-migration').migrate_current_file_with_alias_links()
end, {})

vim.keymap.set('n', '<leader>r', '<cmd>source %<CR>', { desc = '[R]un current file' }) -- works for lua files
-- Run LOVE in a temporary terminal split: <leader>rl
vim.keymap.set('n', '<leader>rl', function()
  local current_dir = vim.fn.expand '%:p:h'

  local love_cmd = (vim.fn.has 'win32' == 1) and 'love.exe' or 'love'
  local cmd = love_cmd .. ' --console "' .. current_dir .. '"'

  vim.cmd 'split'
  vim.cmd('terminal ' .. cmd)

  -- make the buffer temporary
  local term_buf = vim.api.nvim_get_current_buf()
  vim.bo[term_buf].bufhidden = 'wipe'

  vim.cmd 'startinsert'
end, { desc = '[R]un [L]ÖVE' })

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
