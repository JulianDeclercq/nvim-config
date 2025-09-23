local module = {}

local paths = require 'config.paths'

---@param bufnr number
---@return string
local function get_obsidian_name(bufnr)
  -- get first alias
  local alias = ''
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)
  for i, line in ipairs(lines) do
    if vim.startswith(line, 'aliases') then
      alias = lines[i + 1]:match '%- (.+)%s*$' -- only keep the alias itself, remove all else from the line
    end
  end

  if alias == '' then
    return ''
  end

  local old_name = vim.api.nvim_buf_get_name(bufnr)
  local extension = vim.fn.fnamemodify(old_name, ':e')
  local new_name = alias:sub(1) .. (extension ~= '' and ('.' .. extension) or '')
  return new_name
end

function module.pick()
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local config = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local previewers = require 'telescope.previewers'
  local putils = require 'telescope.previewers.utils'
  local entry_display = require 'telescope.pickers.entry_display'

  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = 4 }, -- buf number
      { width = 2 }, -- buf icon
      { remaining = true }, -- filename (gets the rest of the space available)
    },
  }

  local entries = {}
  for _, bufinfo in ipairs(vim.fn.getbufinfo { buflisted = 1, bufloaded = 1 }) do
    local bufNr = bufinfo.bufnr
    if vim.api.nvim_buf_is_loaded(bufNr) then
      local bufferName = vim.api.nvim_buf_get_name(bufNr)
      local displayName = bufferName ~= '' and vim.fn.fnamemodify(bufferName, ':p:.') or ('[No Name] ' .. bufNr)
      local ordinal = displayName

      local icon, icon_highlight_group = require('nvim-web-devicons').get_icon(bufferName, vim.fn.fnamemodify(bufferName, ':e'), { default = true })

      if vim.startswith(bufferName, paths.obsidian) then
        local obsidian_name = get_obsidian_name(bufNr)
        if obsidian_name ~= '' then
          displayName = obsidian_name
          ordinal = vim.fn.fnamemodify(bufferName, ':t') .. obsidian_name -- include the filename
          icon = '\u{F219}' -- 
        end
      end

      table.insert(entries, {
        value = bufNr,
        ordinal = ordinal,
        path = bufferName,
        display = function()
          return displayer {
            { tostring(bufNr), 'TelescopeResultsNumber' }, -- shows bufnr, TeleScopeResultsNumber is the highlight group used for color coding
            { icon, icon_highlight_group },
            { displayName },
          }
        end,
      })
    end
  end

  -- Previewer: copy the selected buffer's text into the preview buffer
  local buffer_previewer = previewers.new_buffer_previewer {
    title = 'Grep Preview',
    get_buffer_by_name = function(_, entry)
      return 'telescope-bufpreview-' .. entry.value
    end,
    define_preview = function(self, entry, _)
      local bufnr = entry.value
      if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
        putils.set_preview_message(self.state.bufnr, self.state.winid, 'Invalid buffer')
        return
      end

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

      -- mirror filetype for syntax highlighting
      vim.bo[self.state.bufnr].filetype = vim.bo[bufnr].filetype
    end,
  }

  pickers
    .new({}, {
      prompt_title = 'Julles test',
      finder = finders.new_table {
        results = entries,
        entry_maker = function(e)
          return e
        end,
      },
      sorter = config.generic_sorter {},
      previewer = buffer_previewer,
      attach_mappings = function(prompt_bufnr, map)
        local open_buf = function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.api.nvim_set_current_buf(selection.value)
        end

        map('i', '<CR>', open_buf)
        map('n', '<CR>', open_buf)

        return true
      end,
    })
    :find()
end

return module
