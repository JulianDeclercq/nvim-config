-- Module for bookmark utilities
local M = {}

-- Helper function for bookmark picker with delete functionality
function M.open_bookmarks_picker()
  require('telescope').extensions.bookmarks.list {
    attach_mappings = function(prompt_bufnr, map)
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      -- Function to delete bookmark
      local delete_bookmark = function()
        local selection = action_state.get_selected_entry()
        if selection then
          -- Close the picker first
          actions.close(prompt_bufnr)

          -- Store current buffer to return to it
          local current_buf = vim.api.nvim_get_current_buf()

          -- Open file in background buffer (without showing it)
          local buf = vim.fn.bufnr(selection.filename, true) -- Create buffer if doesn't exist
          vim.fn.bufload(buf) -- Load the buffer

          -- Temporarily switch to the buffer
          vim.api.nvim_set_current_buf(buf)
          vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })

          -- Toggle the bookmark (delete it)
          require('bookmarks').bookmark_toggle()

          -- Switch back to original buffer
          vim.api.nvim_set_current_buf(current_buf)

          -- Reopen the updated list (this will have the same mappings!)
          M.open_bookmarks_picker()
        end
      end

      -- Map `dd` in normal mode
      map('n', 'dd', delete_bookmark)

      return true
    end,
  }
end

return M
