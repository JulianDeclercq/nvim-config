-- Takes a file from before zettelkasten and makes it into a zettelkasten file

local module = {}

local paths = require 'config.paths'

local function generate_zetelkasten_id()
  -- mimic the oen from obsidian-nvim/obsidian.nvim (not super important)
  local suffix = ''
  for _ = 1, 4 do -- append 4 random uppercase letters
    suffix = suffix .. string.char(math.random(65, 90))
  end

  return tostring(os.time()) .. '-' .. suffix
end

local function update_frontmatter_alias(old_title)
  local buf = 0 -- is this correct?
  for i = 1, vim.api.nvim_buf_line_count(buf) do
    local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
    if line and line:find '^aliases:%s*%[' then
      -- replace the first [...] after 'aliases:' on that line
      local new_line = line:gsub('^(aliases:%s*)%b[]', '%1[' .. old_title .. ']', 1)
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { new_line })
      return
    end

    -- TODO: Save for formatting to kick in?
  end
end

module.migrate_file = function()
  -- get the current file and save it as a new file
  local old_id = vim.fn.expand '%:t:r'
  local new_id = generate_zetelkasten_id()
  if new_id == nil then
    return
  end

  vim.cmd('Obsidian rename ' .. new_id)
  vim.cmd 'wa' -- ensure backlink updates are written, see the README

  update_frontmatter_alias(old_id)
  require('conform').format()

  -- TODO: Update frontmatter to have current_title as first alias, needs to be done after the rename command has been run
end

return module
