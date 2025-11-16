-- Make sure to install RipGrep

local paths = require 'config.paths'

return {
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
        path = paths.obsidian,
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
}
