-- Make sure to install RipGrep
-- Platform specific paths
local obsidian_path
if vim.fn.has 'macunix' == 1 then
  obsidian_path = '/Users/Julian/Repositories/obsidian'
elseif vim.fn.has 'win32' == 1 then
  obsidian_path = 'C:\\Users\\Julian\\Documents\\The Cache'
else
  obsidian_path = vim.fn.expand '~' .. '/Repositories/obsidian'
end

return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- use latest release
  lazy = true,
  event = 'VimEnter', -- load on startup (no file)…, looks like this also works if you do any file so it's kind of pointless for me at the moment, need to figure out why this is or if there's another solution
  ft = 'markdown', -- …or on any markdown buffer
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp', -- autocomplete for note references
    'nvim-telescope/telescope.nvim', -- for snippet search
  },
  opts = {
    workspaces = {
      {
        name = 'vault',
        path = obsidian_path,
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
      nvim_cmp = true,
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
      '<leader>os',
      function()
        require('telescope.builtin').find_files {
          cwd = obsidian_path .. '/.obsidian/snippets',
          hidden = true,
          prompt_title = 'Obsidian Snippets',
        }
      end,
      desc = '[O]bsidian: [S]nippets',
    },
  },
}
