local module = {}

-- Notations taken from https://github.com/Loac/obsidian-fight-note/blob/main/README.md
local NOTATIONS = {
  -- Common stance
  { key = 'WS', desc = 'While Standing', category = 'Shared' },
  { key = 'iWS', desc = 'Instant While Standing', category = 'Shared' },
  { key = 'BT', desc = 'Back Turned', category = 'Shared' },
  { key = 'FC', desc = 'Full Crouch', category = 'Shared' },
  { key = 'CC', desc = 'Crouch Cancel', category = 'Shared' },
  { key = 'LP', desc = 'Low Parry', category = 'Shared' },
  { key = 'CH', desc = 'Counter Hit', category = 'Shared' },

  -- Special moves
  { key = 'DASH', desc = 'Dash', category = 'Movement' },
  { key = 'WR', desc = 'While Running', category = 'Movement' },
  { key = 'SS', desc = 'Side Step', category = 'Movement' },
  { key = 'SSL', desc = 'Side Step Left', category = 'Movement' },
  { key = 'SSR', desc = 'Side Step Right', category = 'Movement' },

  -- Stage related
  { key = 'W!', desc = 'Wall Splat', category = 'Stage' },
  { key = 'WB!', desc = 'Wall Break', category = 'Stage' },
  { key = 'F!', desc = 'Floor Break', category = 'Stage' },
  { key = 'BB!', desc = 'Balcony Break', category = 'Stage' },

  -- Shortcuts
  { key = 'qcb', desc = 'Quarter Circle Back', category = 'Circle' },
  { key = 'QCB', desc = 'Quarter Circle Back', category = 'Circle' },
  { key = 'qcf', desc = 'Quarter Circle Forward', category = 'Circle' },
  { key = 'QCF', desc = 'Quarter Circle Forward', category = 'Circle' },
  { key = 'hcf', desc = 'Half Circle Forward', category = 'Circle' },
  { key = 'HCF', desc = 'Half Circle Forward', category = 'Circle' },
  { key = 'hcb', desc = 'Half Circle Back', category = 'Circle' },
  { key = 'HCB', desc = 'Half Circle Back', category = 'Circle' },

  -- Specific (characters/stances)
  { key = 'AOP', desc = 'Art of Phoenix (Xiaoyu)', category = 'Stance' },
  { key = 'BKP', desc = 'Backup (Alisa)', category = 'Stance' },
  { key = 'BOK', desc = 'Fo Bu (Leo)', category = 'Stance' },
  { key = 'BOOT', desc = 'Boot (Alisa)', category = 'Stance' },
  { key = 'CDS', desc = 'Crouching Demon Stance (Jin)', category = 'Stance' },
  { key = 'DBT', desc = 'Dual Boot (Alisa)', category = 'Stance' },
  { key = 'DCK', desc = 'Ducking (Steve)', category = 'Stance' },
  { key = 'DEN', desc = 'Dynamic Entry (Lars)', category = 'Stance' },
  { key = 'DES', desc = 'Destructive Form (Alisa)', category = 'Stance' },
  { key = 'DEW', desc = 'Dew Glide (Lili)', category = 'Stance' },
  { key = 'DGF', desc = 'Manji Dragonfly (Yoshimitsu)', category = 'Stance' },
  { key = 'DPD', desc = 'Deep Dive (Paul)', category = 'Stance' },
  { key = 'DSS', desc = 'Dragon Sign Stance (Law)', category = 'Stance' },
  { key = 'EWGF', desc = 'Electric Wind God Fist', category = 'Stance' },
  { key = 'EXD', desc = 'Ducking In (Steve)', category = 'Stance' },
  { key = 'FLE', desc = 'Flea (Yoshimitsu)', category = 'Stance' },
  { key = 'FLK', desc = 'Flicker Stance (Steve)', category = 'Stance' },
  { key = 'FLY', desc = 'Fly (Devil Jin)', category = 'Stance' },
  { key = 'GEN', desc = 'Genjitsu (Jun)', category = 'Stance' },
  { key = 'GMH', desc = 'Gamma Howl (Jack-8)', category = 'Stance' },
  { key = 'HAZ', desc = 'Haze (Raven)', category = 'Stance' },
  { key = 'HMS', desc = 'Hit Man Stance (Lee)', category = 'Stance' },
  { key = 'HPF', desc = 'Whiplash Combo (Asuka/Jun)', category = 'Stance' },
  { key = 'HRM', desc = 'Hermit (Leroy)', category = 'Stance' },
  { key = 'HSP', desc = 'Bananeira (Eddy)', category = 'Stance' },
  { key = 'HYP', desc = 'Hypnotist (Xiaoyu)', category = 'Stance' },
  { key = 'IND', desc = 'Indian Stance (Yoshimitsu)', category = 'Stance' },
  { key = 'IZU', desc = 'Izumo (Jun)', category = 'Stance' },
  { key = 'JGR', desc = 'Jaguar Sprint/Run (King)', category = 'Stance' },
  { key = 'JGS', desc = 'Jaguar Step (King)', category = 'Stance' },
  { key = 'KIN', desc = 'Kincho (Yoshimitsu)', category = 'Stance' },
  { key = 'KNK', desc = 'Jin Ji Du Li (Leo)', category = 'Stance' },
  { key = 'SSH', desc = 'Senshin (Reina)', category = 'Stance' },
  { key = 'UNS', desc = 'Unsoku (Reina)', category = 'Stance' },
  { key = 'WRA', desc = "Heaven's Wrath (Reina)", category = 'Stance' },
  { key = 'KNP', desc = 'Kenpo step (Feng)', category = 'Stance' },
  { key = 'LCT', desc = 'Leg Cutter (Asuka/Jun)', category = 'Stance' },
  { key = 'LFF', desc = 'Left Foot Forward (Hwoarang)', category = 'Stance' },
  { key = 'LFS', desc = 'Left Flamingo Stance (Hwoarang)', category = 'Stance' },
  { key = 'LIB', desc = 'Libertador (Azucena)', category = 'Stance' },
  { key = 'LNH', desc = 'Lionheart (Steve)', category = 'Stance' },
  { key = 'LTG', desc = 'Lightning Glare (Leo)', category = 'Stance' },
  { key = 'LWV', desc = 'Ducking Left (Steve)', category = 'Stance' },
  { key = 'MCR', desc = 'Mourning Crow (Devil Jin)', category = 'Stance' },
  { key = 'MED', desc = 'Meditation (Yoshimitsu)', category = 'Stance' },
  { key = 'MIA', desc = 'Miare (Jun)', category = 'Stance' },
  { key = 'MNT', desc = 'Mantis Stance (Zafina)', category = 'Stance' },
  { key = 'NSS', desc = 'No Sword Stance (Yoshimitsu)', category = 'Stance' },
  { key = 'PDP', desc = 'Bad Stomach (Yoshimitsu)', category = 'Stance' },
  { key = 'PKB', desc = 'Peekaboo (Steve)', category = 'Stance' },
  { key = 'RDS', desc = 'Rain Dance (Xiaoyu)', category = 'Stance' },
  { key = 'RFF', desc = 'Right Foot Forward (Hwoarang)', category = 'Stance' },
  { key = 'RFS', desc = 'Right Flamingo Stance (Hwoarang)', category = 'Stance' },
  { key = 'RLX', desc = 'Negativa (Eddy)', category = 'Stance' },
  { key = 'RWV', desc = 'Ducking Right (Steve)', category = 'Stance' },
  { key = 'SCR', desc = 'Scarecrow Stance (Zafina)', category = 'Stance' },
  { key = 'SDW', desc = 'Shadow stance (Raven)', category = 'Stance' },
  { key = 'SEN', desc = 'Sentai (Reina)', category = 'Stance' },
  { key = 'SIT', desc = 'Sit Down (Jack-8)', category = 'Stance' },
  { key = 'SLS', desc = 'Slither Step (Bryan)', category = 'Stance' },
  { key = 'SNE', desc = 'Snake Eyes (Bryan)', category = 'Stance' },
  { key = 'SNK', desc = 'Sneak (Dragunov)', category = 'Stance' },
  { key = 'STB', desc = 'Starburst (Claudio)', category = 'Stance' },
  { key = 'STC', desc = 'Shifting Clouds (Feng)', category = 'Stance' },
  { key = 'SWA', desc = 'Sway (Bryan)', category = 'Stance' },
  { key = 'SWY', desc = 'Sway Back (Steve)', category = 'Stance' },
  { key = 'TFS', desc = 'Fake Step (Law)', category = 'Stance' },
  { key = 'TRT', desc = 'Tarantula Stance (Zafina)', category = 'Stance' },
  { key = 'WDS', desc = 'Wind Step (Reina)', category = 'Stance' },
  { key = 'WGS', desc = 'Wind God Step (Reina)', category = 'Stance' },
  { key = 'ZEN', desc = 'Zenshin (Jin)', category = 'Stance' },
}

function module.pick()
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local config = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local entries = {}
  for _, item in ipairs(NOTATIONS) do
    table.insert(entries, {
      value = item,
      display = string.format('%-8s %s [%s]', item.key, item.desc, item.category),
      ordinal = table.concat({ item.key, item.desc, item.category }, ' '), -- 'ordinal' controls fuzzy matching; include key, desc and category
    })
  end

  pickers
    .new({}, {
      prompt_title = 'Tekken Notations',
      finder = finders.new_table {
        results = entries,
        entry_maker = function(e)
          return e
        end,
      },
      sorter = config.generic_sorter {},
      attach_mappings = function(_, map)
        -- Default enter: insert token at cursor
        actions.select_default:replace(function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value then
            vim.api.nvim_put({ selection.value.key }, 'c', true, true)
          end
        end)
        return true
      end,
    })
    :find()
end

function module.buffer_pick()
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
      { width = 4 }, -- bufnr
      { remaining = true }, -- filename
    },
  }

  local entries = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local short = name ~= '' and vim.fn.fnamemodify(name, ':t') or ('[No Name] ' .. buf)
      table.insert(entries, {
        value = buf,
        ordinal = name ~= '' and name or short,
        display = function()
          return displayer {
            { tostring(buf), 'TelescopeResultsNumber' }, -- shows bufnr
            { short },
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
        putils.set_preview_message(self.state.bufnr, 'Invalid buffer')
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
